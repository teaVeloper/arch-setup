#!/bin/bash
# 03_chroot_setup.sh - Configure system settings in chroot.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

echo "Setting timezone to Europe/Vienna..."
run_cmd "ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime"
run_cmd "hwclock --systohc"

echo "Generating locales..."
run_cmd "locale-gen"
run_cmd "echo 'LANG=en_US.UTF-8' > /etc/locale.conf"

echo "Setting console keymap to US..."
run_cmd "echo 'KEYMAP=us' > /etc/vconsole.conf"

echo "Setting hostname..."
run_cmd "echo '$HOSTNAME' > /etc/hostname"
cat <<EOF | run_cmd "tee /etc/hosts"
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME
EOF

echo "Setting root password (you will be prompted)..."
if ! $DRY_RUN; then passwd; fi

echo "Creating new user $USERNAME and setting password (you will be prompted)..."
run_cmd "useradd -mG wheel '$USERNAME'"
if ! $DRY_RUN; then passwd "$USERNAME"; fi

echo "Opening sudoers with visudo for wheel group..."
if ! $DRY_RUN; then EDITOR=vim visudo; fi

echo "Installing GRUB bootloader..."
run_cmd "grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB"
run_cmd "grub-mkconfig -o /boot/grub/grub.cfg"

echo "Enabling NetworkManager..."
run_cmd "systemctl enable NetworkManager"

echo "Chroot setup complete. Exit chroot and reboot when ready."
