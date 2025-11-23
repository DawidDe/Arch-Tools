#!/bin/bash

set -xeuo pipefail

baseapps=(
    base
    linux
    linux-firmware
    amd-ucode
    networkmanager
    sudo
    grub 
    efibootmgr 
    os-prober
)

nativeapps=(
    # Essential Tools
    bluez
    bluez-utils
    gnome-bluetooth
    pipewire-jack
    gnome
    flatpak

    # General Tools
    nano
    obs-studio
    vlc
    bitwarden
    libreoffice-fresh

    # Dev Tools
    git
    code
    kubectl
    talosctl

    # Gaming Tools
    steam
    lutris
)

flatpakapps=(
    # General Tools
    com.discordapp.Discord
    com.spotify.Client
    cafe.avery.Delfin

    # Dev Tools
    com.termius.Termius

    # Gaming Tools
    app.twintaillauncher.ttl

    # Security Tools
    com.github.tchx84.Flatseal
    com.yubico.yubioath
)

bloatapps=(
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-maps
    gnome-music
    gnome-calendar
    gnome-characters
    gnome-tour
    gnome-font-viewer
    gnome-logs
    gnome-disk-utility
    gnome-system-monitor
    gnome-user-docs
    loupe
    malcontent
    papers
    showtime
    simple-scan
    snapshot
    baobab
    decibels
    epiphany
    yelp
)

loadkeys de-latin1
clear

# Install Menu
echo "Set root Password:"
read -s root_password
clear
echo "Set username:"
read username
clear
echo "Set password for $username"
read -s password
clear
echo "Set git name:"
read git_name
clear
echo "Set git email:"
read git_email
clear

# Prepare Partitions
mkfs.fat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nvme0n1p2

# Installing Base System
pacstrap -K /mnt "${baseapps[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

# Starting internet connection
arch-chroot /mnt systemctl enable NetworkManager

# Setting locale stuff
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
arch-chroot /mnt hwclock --systohc
sed -i '/de_DE.UTF-8/s/^#//g' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=de_DE.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=de-latin1" > /mnt/etc/vconsole.conf
echo "arch" > /mnt/etc/hostname

# Configuring user
arch-chroot /mnt bash -c "echo 'root:$root_password' | chpasswd"
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $username
echo '%wheel ALL=(ALL:ALL) ALL' | tee -a /mnt/etc/sudoers > /dev/null
arch-chroot /mnt bash -c "echo '$username:$password' | chpasswd"

# Installing Bootloader
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i '/GRUB_DISABLE_OS_PROBER=false/s/^#//g' /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Enable multilib repo
sed -i '/\[multilib\]/s/^#//g' /mnt/etc/pacman.conf
sed -i '\|Include = /etc/pacman.d/mirrorlist|s/^#//g' /mnt/etc/pacman.conf

# Configuring System Apps
arch-chroot /mnt pacman -Syu --noconfirm "${nativeapps[@]}"
for app in "${flatpakapps[@]}"; do
  arch-chroot /mnt flatpak install flathub -y "$app"
done
arch-chroot /mnt pacman -Rns --noconfirm "${bloatapps[@]}"

# Cleanup app icons
rm /mnt/usr/share/applications/bvnc.desktop
rm /mnt/usr/share/applications/bssh.desktop
rm /mnt/usr/share/applications/avahi-discover.desktop
rm /mnt/usr/share/applications/qv4l2.desktop
rm /mnt/usr/share/applications/qvidcap.desktop
rm /mnt/usr/share/applications/electron36.desktop
rm /mnt/usr/share/applications/electron37.desktop
rm /mnt/usr/share/applications/org.gnome.Evince.desktop

# Enabling System Services
arch-chroot /mnt systemctl enable gdm
arch-chroot /mnt systemctl enable bluetooth
arch-chroot /mnt systemctl enable pcscd

# Configuring Git
arch-chroot /mnt git config --global user.name "$git_name"
arch-chroot /mnt git config --global user.email $git_email

# Configure kubelogin
arch-chroot /mnt curl -L -o kubelogin.zip https://github.com/int128/kubelogin/releases/download/v1.34.2/kubelogin_linux_amd64.zip
arch-chroot /mnt unzip kubelogin.zip
arch-chroot /mnt rm -r kubelogin.zip README.md LICENSE
arch-chroot /mnt chmod +x kubelogin
arch-chroot /mnt mv kubelogin /bin/kubectl-oidc_login

# Unmount and reboot Sytem
umount -R /mnt
reboot now