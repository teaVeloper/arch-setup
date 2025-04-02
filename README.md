# Arch Linux Automated Installation & Configuration

This repository provides my streamlined  approach for installing Arch Linux.
It inclludes an instruction (this file), some shell scripts for the core to run from the live system and ansible playbooks to further set up the system.

I have 2 options:
 - with disk encryption - for mobile devices .. TBD 
 - without disk encryption - for desktop systems (why bother with encryption on your home device?)

It is designed to work the way I want a system set up, please use/copy with care - always know/review what you are doing!

You will find more documentation in [docs](docs) where I include a manual guid of what happens and some explanations of parts!


## What This Repo Provides

1. **Configure script** run to create a config file used for the setup.
2. **Core Installation Scripts (Low-Level Steps):**
   - **00_partition.sh:** Formats and partitions your disk (with safety prompts).
   - **01_mount.sh:** Formats partitions (EFI as FAT32, root as Btrfs), creates Btrfs subvolumes (e.g., `@` for root, `@home`), and mounts them.
   - **02_pacstrap.sh:** Uses pacstrap to install the bare minimum packages (base system, kernel, bootloader tools, etc.).
   - **03_chroot_setup.sh:** Runs the essential configuration within the chroot (timezone, locale, hostname, users, and bootloader installation).
   - **04_post_install.sh:** Enables critical services and installs additional packages required for system operation.
   - **05_ansible_install.sh:** Bootstrap ansible and run system setup with ansible.

3. **Ansible Configuration:**
   - After the core installation, run the Ansible playbook to configure everything else (desktop environment, dotfiles, additional packages, and peripheral configurations).
   - Your dotfiles repository can be cloned and deployed via an Ansible role, so your shell and configurations are set up as you like.

4. **Documentation** some documentation I thought of.

## Usage

1. **Preparation:**
   - Boot from the Arch Linux live ISO in UEFI mode.
   - Connect to the Internet and verify your system prerequisites (keyboard layout, UEFI mode, NTP, etc.).

2. **Run Core Installation Scripts:**
   - Clone this repository on your live system:
     ```bash
     git clone https://github.com/teaveloper/arch-setup.git
     cd arch-setup
     # run (interactive) configure script
     ./configure
     # or alternatively create a scripts/configure.sh file with all needed values (as in config.template.sh
     ```
   - Run each script step-by-step:
     1. `./scripts/00_partition.sh`
     2. `./scripts/01_mount.sh`
     3. `./scripts/02_pacstrap.sh`
   - Chroot into your new system:
     ```bash
     arch-chroot /mnt
     ```
   - Run the chroot configuration:
     ```bash
     ./scripts/03_chroot_setup.sh
     ```
   - After rebooting into your new system, run the post-install script:
     ```bash
     ./scripts/04_post_install.sh
     ```

3. **Ansible Post-Configuration:**
   - Once your system is up, install Ansible if needed and run the playbook:
     ```bash
     git clone https://github.com/teaveloper/arch-setup.git
     cd arch-setup/ansible
     ansible-playbook playbook.yml --ask-become-pass
     ```
   - This will install your desktop environment, dotfiles, and any additional tools you have defined.

## Credits & Inspiration

This setup is inspired by several excellent Arch installation guides and automation repositories: 
- [mjkstra/arch_linux_installation_guide](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae)
- [Tim Assavarant - Installing Arch Linux with Brtfs and Encryption](https://dev.to/tassavarat/installing-arch-linux-with-btrfs-and-encryption-48na)
- [loganmarchione/ansible-arch-linux](https://github.com/loganmarchione/ansible-arch-linux)
- [dliebichNET/ansible-archlinux](https://codeberg.org/dliebichNET/ansible-archlinux.git)


Special thanks to the Arch community for their in-depth documentation and tips.

## Troubleshooting

### FAQ (or actually just what I thought of)
**What happens if GRUB breaks after pacman updates**
you can maybe fix it from a live-stick and running `grub install`. But how to fix this issue completely I have no idea!

**What happens if I mess up disk encryption? e.g. loose my key**
your data becomes unavailable!

### Useful links:

[grub mount points](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points)


## Disclaimer & Warning
**Disclaimer:**  
_These scripts execute critical system commands. Review and test them (preferably in a VM) before running on production hardware._

## Contribution

If you have any ideas on how to improve, I am happy about a pull-request. I am happy to merge anything that fits my needs. But this is meant as my setup so probably forking might be a better idea. I am happy about being mentioned in the case of a fork.
