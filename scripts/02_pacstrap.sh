#!/bin/bash
# 02_pacstrap.sh - Install the base system.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

echo "Installing base system with pacstrap..."
PACSTRAP_CMD="pacstrap -K /mnt base base-devel linux linux-firmware \
git vim nvim btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift \
networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
reflector bash bash-completions bash-autosuggestions zsh zsh-completion \
openssh man ${MICROCODE}"
run_cmd "$PACSTRAP_CMD"

echo "Generating fstab..."
run_cmd "genfstab -U /mnt >> /mnt/etc/fstab"
echo "Verify /mnt/etc/fstab."

echo "Pacstrap complete. You can now chroot into /mnt."
