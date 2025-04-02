#!/bin/bash
# 05_ansible_install.sh - Bootstrap and run Ansible playbook for further configuration.
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

# Install Ansible via pipx (ensure pipx is installed)
if ! command -v pipx &>/dev/null; then
    echo "pipx not found. Installing pipx..."
    sudo pacman -S python-pipx
    pipx ensurepath
fi

echo "Installing Ansible via pipx..."
pipx install ansible || pipx upgrade ansible

# Change directory to ansible folder
cd ansible || exit 1

# Install Galaxy roles from requirements.yml (if you have one)
if [ -f "requirements.yml" ]; then
    ansible-galaxy install -r requirements.yml
fi

# Run the main playbook with privilege escalation
ansible-playbook site.yml --ask-become-pass
