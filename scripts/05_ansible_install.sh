#!/bin/bash
# 05_ansible_install.sh - Bootstrap and run Ansible playbook for further configuration.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

# Ensure pipx is installed
if ! command -v pipx &>/dev/null; then
    echo "pipx not found. Installing pipx..."
    run_cmd "pacman -S python-pipx"
    run_cmd "pipx ensurepath"
fi

echo "Installing Ansible via pipx..."
run_cmd "pipx install ansible || pipx upgrade ansible"

echo "Changing directory to ansible folder..."
run_cmd "cd ansible || exit 1"

if [ -f "requirements.yml" ]; then
    run_cmd "ansible-galaxy install -r requirements.yml"
fi

echo "Running Ansible playbook..."
run_cmd "ansible-playbook site.yml --ask-become-pass"
