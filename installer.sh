#!/bin/bash

set -xeuo pipefail

basepapps=(
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

systemapps=(
    pipewire-jack
    gnome
    git
    nano
    chromium
    discord
    steam
    code
    spotify-launcher
    bitwarden
    vlc
    obs-studio
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
    loupe
    malcontent
    papers
    showtime
    simple-scan
    snapshot
    baobab
    decibels
    epiphany
)

# Install Menu
echo "Set root Password:"
read root_password
echo "Set username:"
read username
echo "Set password for $username"
read password

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
arch-chroot /mnt sed -i '/de_DE.UTF-8/s/^#//g' /etc/locale.gen
arch-chroot /mnt locale-gen
arch-chroot /mnt echo "LANG=de_DE.UTF-8" > /etc/locale.conf
arch-chroot /mnt echo "KEYMAP=de-latin1" > /etc/vconsole.conf
arch-chroot /mnt echo "arch" > /etc/hostname

# Configuring user
arch-chroot /mnt bash -c "echo 'root:$root_password' | chpasswd"
arch-chroot /mnt useradd -m -G wheel -s /bin/bash $username
arch-chroot /mnt bash -c "echo '%wheel ALL=(ALL:ALL) ALL' | sudo tee -a /etc/sudoers > /dev/null"
arch-chroot /mnt bash -c "echo '$username:$password' | chpasswd"

# Installing Bootloader
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Configuring System Apps
sudo pacman -Syu --noconfirm "${systemapps[@]}"
sudo pacman -Rns --noconfirm "${bloatapps[@]}"

# Enabling Essential Services
arch-chroot /mnt systemctl enable gdm

# Unmount and reboot Sytem
umount -R /mnt
reboot now
