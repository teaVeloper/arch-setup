#!/bin/bash
# 03_chroot_setup.sh - Configure system settings in chroot.
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

echo "Setting timezone to Europe/Vienna..."
ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime
hwclock --systohc

echo "Generating locales..."
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "Setting console keymap to US..."
echo "KEYMAP=us" > /etc/vconsole.conf

echo "Setting hostname..."
echo "$HOSTNAME" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME
EOF

echo "Setting root password (you will be prompted)..."
passwd

echo "Creating new user $USERNAME and setting password (you will be prompted)..."
useradd -mG wheel "$USERNAME"
passwd "$USERNAME"

echo "Opening sudoers with visudo for wheel group..."
EDITOR=vim visudo

echo "Installing GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Enabling NetworkManager..."
systemctl enable NetworkManager

echo "Chroot setup complete. Exit chroot and reboot when ready."
