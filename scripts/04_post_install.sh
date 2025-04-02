#!/bin/bash
# 04_post_install.sh: Post-installation configuration.
#
# Run this script after the first boot into your new system.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

echo "Enabling time synchronization..."
run_cmd "timedatectl set-ntp true"

echo "Enabling NetworkManager service..."
run_cmd "systemctl enable --now NetworkManager"

echo "Installing YubiKey support packages..."
run_cmd "pacman -S --needed libfido2 yubikey-manager yubico-piv-tool pam-u2f yubioath-desktop"

if [ -f ~/arch-setup/udev/50-zsa.rules ]; then
    echo "Copying udev rules..."
    run_cmd "cp ~/arch-linux-setup/udev/50-zsa.rules /etc/udev/rules.d/"
    run_cmd "udevadm control --reload-rules"
fi

echo "Installing additional packages..."
run_cmd "pacman -S --needed vim neovim wget curl rsync htop git bat fzf"

echo "Post-install configuration complete."
