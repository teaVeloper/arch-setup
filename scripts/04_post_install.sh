#!/bin/bash
# 04_post_install.sh: Post-installation configuration.
#
# Run this script after the first boot into your new system.
# It enables services and installs additional packages as needed.
CONFIG_FILE="config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

echo "Enabling time synchronization..."
timedatectl set-ntp true

echo "Enabling NetworkManager service..."
sudo systemctl enable --now NetworkManager

# Example: Enable YubiKey support tools and additional packages
# TODO: move into ansible!
echo "Installing YubiKey support packages..."
sudo pacman -S --needed libfido2 yubikey-manager yubico-piv-tool pam-u2f yubioath-desktop

# Example: Copy udev rules for peripherals (modify path as needed)
# TODO: could be ansible, or stay here.>
if [ -f ~/arch-setup/udev/50-zsa.rules ]; then
  echo "Copying udev rules..."
  sudo cp ~/arch-linux-setup/udev/50-zsa.rules /etc/udev/rules.d/
  sudo udevadm control --reload-rules
fi

# Additional package installations can be added here (fonts, dev tools, etc.)
# TODO: move to ansible!
echo "Installing additional packages..."
sudo pacman -S --needed vim neovim wget curl rsync htop git bat fzf

echo "Post-install configuration complete."
