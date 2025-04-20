#!/bin/bash

# Install Menu
echo "Set root Password:"
read root_password
echo "Set username:"
read username
echo "Set password for $username"
read password

# Prepare Partitions
mkfs.fat -F 32 /dev/nvme0n1p5
mkfs.ext4 /dev/nvme0n1p6
mount /dev/nvme0n1p6 /mnt
mount --mkdir /dev/nvme0n1p5 /mnt/boot

# Installing Base System
pacstrap -K /mnt base linux linux-firmware amd-ucode networkmanager
genfstab -U /mnt > /mnt/etc/fstab

# Configurate System in chroot
arch-chroot /mnt <<EOF
    # Setting locale stuff
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    hwclock --systohc
    sed -i '/de_DE.UTF-8/s/^#//g' /etc/locale.gen
    locale-gen
    echo "LANG=de_DE.UTF-8" > /etc/locale.conf
    echo "KEYMAP=de-latin1" > /etc/vconsole.conf
    echo "arch" > /etc/hostname

    # Configuring user
    pacman -S sudo
    echo "root:$root_password" | chpasswd
    useradd -mG wheel -s /bin/bash $username
    echo '%wheel ALL=(ALL:ALL) ALL' | sudo tee -a /etc/sudoers > /dev/null
    echo "$username:$password" | chpasswd

    # Installing Bootloader
    pacman -S grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg

    # Installing Essential Software
    pacman -S gdm hyprland hyprpaper kitty git chromium nano spotify-launcher

    # Enabling Essential Services
    systemctl enable NetworkManager
    systemctl enable gdm

    exit
EOF

umount -R /mnt
reboot now