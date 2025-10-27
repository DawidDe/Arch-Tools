#!/bin/bash

set -xeuo pipefail

pacstrapapps=(
    base
    linux
    linux-firmware
    amd-ucode
    networkmanager
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
pacstrap -K /mnt "${pacstrapapps[@]}"
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
arch-chroot /mnt pacman -S sudo
arch-chroot /mnt echo "root:$root_password" | chpasswd
arch-chroot /mnt useradd -mG wheel -s /bin/bash $username
arch-chroot /mnt echo '%wheel ALL=(ALL:ALL) ALL' | sudo tee -a /etc/sudoers > /dev/null
arch-chroot /mnt echo "$username:$password" | chpasswd

# Installing Bootloader
arch-chroot /mnt pacman -S grub efibootmgr
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# Installing Essential Software
arch-chroot /mnt pacman -S gdm gnome

# Enabling Essential Services
arch-chroot /mnt systemctl enable gdm

arch-chroot /mnt exit

# Unmount and reboot Sytem
umount -R /mnt
reboot now