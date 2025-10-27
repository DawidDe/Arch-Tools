#!/bin/bash

# Install Menu
echo "Set root Password:"
read root_password
echo "Set username:"
read username
echo "Set password for $username"
read password

# Prepare Partitions
mkfs.fat -F 32 /dev/nvme0n1p
mkswap /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
mount /dev/nvme0n1p3 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
swapon /dev/nmve0n1p2

# Installing Base System
pacstrap -K /mnt base linux linux-firmware amd-ucode networkmanager
genfstab -U /mnt > /mnt/etc/fstab

# Configurate System in chroot
arch-chroot /mnt <<EOF
    # Starting internet connection
    systemctl enable NetworkManager

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
    pacman -S gdm gnome

    # Enabling Essential Services
    systemctl enable gdm

    exit
EOF

# Unmount and reboot Sytem
umount -R /mnt
reboot now