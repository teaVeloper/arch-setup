#!/bin/bash
# 02_pacstrap.sh - Install the base system.
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

echo "Installing base system with pacstrap..."
pacstrap -K /mnt base base-devel linux linux-firmware \
git vim nvim btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift \
networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
reflector bash bash-completions bash-autosuggestions zsh zsh-completion \
openssh man sudo "${MICROCODE}"

echo "Generating fstab..."
sudo genfstab -U /mnt >> /mnt/etc/fstab
echo "Verify /mnt/etc/fstab."

echo "Pacstrap complete. You can now chroot into /mnt."
