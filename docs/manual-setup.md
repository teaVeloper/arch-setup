# Manual Guide

this follows a lot [mjkstra](https://github.com/mjkstra) so credtis to him! Some sections I changed more, some kept the same!
My changes are mostly adaptions how I use it, but I learned a lot from 'mjkstra'

# Table of contents

- [Introduction](#introduction)
- [Preliminary Steps](#preliminary-steps)
  - [Media Preparation](#media-preparation)
  - [In your live environment](#in-your-live-environment)
- [Main installation](#main-installation)
  - [Disk partitioning](#disk-partitioning)
  - [Disk formatting](#disk-formatting)
  - [Disk mounting](#disk-mounting)
  - [Packages installation](#packages-installation)
  - [Fstab](#fstab)
  - [Context switch to our new system](#context-switch-to-our-new-system)
  - [Set up the time zone](#set-up-the-time-zone)
  - [Set up the language and tty keyboard map](#set-up-the-language-and-tty-keyboard-map)
  - [Hostname and Host configuration](#hostname-and-host-configuration)
  - [Root and users](#root-and-users)
  - [Grub configuration](#grub-configuration)
  - [Unmount everything and reboot](#unmount-everything-and-reboot)
  - [Automatic snapshot boot entries update](#automatic-snapshot-boot-entries-update)
  - [Aur helper and additional packages installation](#aur-helper-and-additional-packages-installation)
  - [Finalization](#finalization)
- [Video drivers](#video-drivers)
  - [Amd](#amd)
    - [32 Bit support](#32-bit-support)
  - [Nvidia](#nvidia)
  - [Intel](#intel)
- [Setting up a graphical environment](#setting-up-a-graphical-environment)
  - [Option 1: KDE Plasma](#option-1-kde-plasma)
  - [Option 2: Hyprland \[WIP\]](#option-2-hyprland-wip)
- [Adding a display manager](#adding-a-display-manager)
- [Additional notes](#additional-notes)
  - [Virtualbox support](#virtualbox-support)

# Introduction

This is the way I like to have my Arch setup and provides as a streamlined Guide of my setup so I can always recover what I did. For a more generic Intro refer to my [main](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae) [inspirations](https://dev.to/tassavarat/installing-arch-linux-with-btrfs-and-encryption-48na)
Also consult [official setup guide](https://wiki.archlinux.org/title/Installation_guide)
Generally check [arch wiki](https://wiki.archlinux.org/title/Main_page) if youre unclear about anything!


# Preliminary steps  

## Media preparation

For Arch media preparations follow [the arch guide](https://wiki.archlinux.org/title/USB_flash_installation_medium)
I personally made best experience with `cp`

e.g.
```bash
sudo cp archlinux-x86_64.iso /dev/sdb
```
because `cat` with redirection does not use `sudo` on both sides of the pipe, and I avoid using `dd` if there is no need!.


## In your live environment

First set up your keyboard layout  - I use `us` for everything, but e.g. german would be `de-latin1`

```bash
# for a list of all available ones
localectl list-keymaps

# set 
loadkeys us
```


Check that we are in UEFI mode  

```bash
# If this command prints 64 or 32 then you are in UEFI
cat /sys/firmware/efi/fw_platform_size
```



Check the internet connection  

```bash
ping -c 5 archlinux.org 
```


If necessary check network devices you can consult [docs](https://wiki.archlinux.org/title/Network_configuration#Network_interfaces) if more detail is needed.
```bash
ip link
```


Check the system clock

```bash
# Check if ntp is active and if the time is right
timedatectl

# In case it's not active you can do
timedatectl set-ntp true

# Or this
systemctl enable systemd-timesyncd.service
```



# Main installation

## Disk partitioning

I will make 2 partitions:  

| Number | Type | Size |
| --- | --- | --- |
| 1 | EFI | 512 Mb |
| 2 | Linux Filesystem | \(all of the remaining space \) |  


I particularly like `fdisk` and its API, but if you feel for a more GUI Tool `gparted` might serve your needs.
EFI is sometimes called 'EFI system partition' and thus abbreviated to 'ESP'.

```bash
# Check the drive name. Mine is /dev/nvme0n1
# If you have an hdd is something like sdax
fdisk -l


# Invoke fdisk to partition
fdisk /dev/nvme0n1

# use fdisk help `m` whenever you dont know what to do, and guide yourself through fdisk!
```

Steps with fdisk (or whatever):
- create GPT partition table (command `g`)
- create new EFI partition (FAT, command `n`)
- set its size (e.g. `+512M`)
- change partition type (command `t`) to 'EFI System' type `1` (list types with command `l`)
- create a new BTRFS partition (command `n`)
- set size (all remaining?)
- verify by printing partition table (command `p`)
- write settigns (command `w`) - only after this step all previous becomes persistent
- exit (command `q`)


## Disk formatting  

The filesystem is [**BTRFS**](https://wiki.archlinux.org/title/Btrfs) it has some nice features and is pretty stable nowdays.

```bash
# Find the efi partition with fdisk -l or lsblk. For me it's /dev/nvme0n1p1 and format it.
mkfs.fat -F 32 /dev/nvme0n1p1

# Find the root partition. For me it's /dev/nvme0n1p2 and format it. I will use BTRFS.
mkfs.btrfs /dev/nvme0n1p2

# Mount the root fs to make it accessible
mount /dev/nvme0n1p2 /mnt
```



## Disk mounting


I follow [this guide](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae#disk-formatting)
And also link [this section of the old sysadmin guide](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/SysadminGuide.html#Layout).


Create the subvolumes, I explain more in the [btrfs docs](docs/btrfs.md).
```bash
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp


# Unmount the root fs
umount /mnt
```

Again I follow [this guide](https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae#disk-formatting)
and also link to [a good algorithm among the choices](https://www.phoronix.com/review/btrfs-zstd-compress).

```bash
# Mount the root and home subvolume. If you don't want compression just remove the compress option.
mount -o compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/home
mkdir -p /mnt/srv
mkdir -p /mnt/tmp
mkdir -p /mnt/var/log
mkdir -p /mnt/var/cache

mount -o compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o compress=zstd,subvol=@srv /dev/nvme0n1p2 /mnt/srv
mount -o compress=zstd,subvol=@tmp /dev/nvme0n1p2 /mnt/tmp
mount -o compress=zstd,subvol=@log /dev/nvme0n1p2 /mnt/var/log
mount -o compress=zstd,subvol=@cache /dev/nvme0n1p2 /mnt/var/cache
```



Now add the efi partition more details [here](https://wiki.archlinux.org/title/EFI_system_partition#Typical_mount_points)

```bash
mkdir -p /mnt/efi
mount /dev/nvme0n1p1 /mnt/efi
```

And if you want a swap-partition/swapfile (e.g. because you want hiberntion possible) then we follow
[the docs](https://btrfs.readthedocs.io/en/latest/ch-swapfile.html)
```bash
# Create a Btrfs subvolume for swap and set up a swap file for hibernation

# Create the dedicated swap subvolume
btrfs subvolume create /mnt/@swap

# Create the mount point for the swap subvolume
mkdir -p /mnt/swap

# Mount the subvolume (consider not using compression for swap)
mount -o subvol=@swap /dev/nvme0n1p2 /mnt/swap

# Disable Copy-on-Write on the swap directory
chattr +C /mnt/swap

# Create and activate the swap file (2G in this example)
btrfs filesystem mkswapfile --size 2G /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Calculate and set the resume offset for hibernation
RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile)
echo "Calculated resume offset: $RESUME_OFFSET"
echo "$RESUME_OFFSET" | sudo tee /sys/power/resume_offset
```



## Packages installation  

```bash
# This will install some packages to "bootstrap" methaphorically our system. Feel free to add the ones you want
# "base, linux, linux-firmware" are needed. If you want a more stable kernel, then swap linux with linux-lts
# "base-devel" base development packages
# "git" to install the git vcs
# "btrfs-progs" are user-space utilities for file system management ( needed to harness the potential of btrfs )
# "grub" the bootloader
# "efibootmgr" needed to install grub
# "grub-btrfs" adds btrfs support for the grub bootloader and enables the user to directly boot from snapshots
# "inotify-tools" used by grub btrfsd deamon to automatically spot new snapshots and update grub entries
# "timeshift" a GUI app to easily create,plan and restore snapshots using BTRFS capabilities
# "amd-ucode" microcode updates for the cpu. If you have an intel one use "intel-ucode"
# "vim" my goto editor, if unfamiliar use nano
# "networkmanager" to manage Internet connections both wired and wireless ( it also has an applet package network-manager-applet )
# "pipewire pipewire-alsa pipewire-pulse pipewire-jack" for the new audio framework replacing pulse and jack. 
# "wireplumber" the pipewire session manager.
# "reflector" to manage mirrors for pacman
# "bash" my favourite shell
# "bash-completions" for bash additional completions
# "bash-autosuggestions" very useful, it helps writing commands [ Needs configuration in .bashrc ]
# "openssh" to use ssh and manage keys
# "man" for manual pages
# "sudo" to run commands as other users
pacstrap -K /mnt base \
base-devel linux linux-firmware \
git vim nvim \
btrfs-progs grub efibootmgr grub-btrfs inotify-tools timeshift \
networkmanager \
pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
reflector \
bash bash-completions bash-autosuggestions \
zsh zsh-completion \
openssh man sudo \
intel-ucode
```

## Fstab  

```bash
# Fetch the disk mounting points as they are now ( we mounted everything before ) and generate instructions to let the system know how to mount the various disks automatically
genfstab -U /mnt >> /mnt/etc/fstab

# Check if fstab is fine ( it is if you've faithfully followed the previous steps )
cat /mnt/etc/fstab
```



## Context switch to our new system  

```bash
# To access our new system we chroot into it
arch-chroot /mnt
```


## Set up the time zone

```bash
# In our new system we have to set up the local time zone, find your one in /usr/share/zoneinfo mine is /usr/share/zoneinfo/Europe/Rome and create a symbolic link to /etc/localtime
ln -sf /usr/share/zoneinfo/Europe/Vienna /etc/localtime

# Now sync the system time to the hardware clock
hwclock --systohc
```



## Set up the language and tty keyboard map

Edit `/etc/locale.gen` and uncomment `en_US.UTF-8 UTF-8` and other needed 'UTF-8 locales'. Generate the locales by running: 
```bash
locale-gen
```

More details [here](https://wiki.archlinux.org/title/Locale#Variables)

```bash
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```



Now to make the current keyboard layout permanent for tty sessions , create `/etc/vconsole.conf` and write `KEYMAP=your_key_map` substituting the keymap with the one previously set [here](#preliminary-steps). 

```bash
echo "KEYMAP=us" > /etc/vconsole.conf
```



## Hostname and Host configuration

```bash
# Create /etc/hostname then choose and write the name of your pc in the first line. In my case I'll use Arch
echo "Setting hostname..."
echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch
EOF
```


## Root and users  

```bash
# Set up the root password
passwd

# Add a new user, in my case berti
# -m creates the home dir automatically
# -G adds the user to an initial list of groups, in this case wheel, the administration group. If you are on a Virtualbox VM and would like to enable shared folders between host and guest machine, then also add the group vboxsf besides wheel.
useradd -mG wheel berti
passwd berti

# The command below is a one line command that will open the /etc/sudoers file with your favourite editor.
# You can choose a different editor than vim by changing the EDITOR variable
# Once opened, you have to look for a line which says something like "Uncomment to let members of group wheel execute any action"
# and uncomment exactly the line BELOW it, by removing the #. This will grant superuser priviledges to your user.
# Why are we issuing this command instead of a simple vim /etc/sudoers ? 
# Because visudo does more than opening the editor, for example it locks the file from being edited simultaneously and
# runs syntax checks to avoid committing an unreadable file.
EDITOR=vim visudo
```



## Grub configuration  

Now I'll [deploy grub](https://wiki.archlinux.org/title/GRUB#Installation)  

```bash
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB  
```


Generate the grub configuration ( it will include the microcode installed with pacstrap earlier )  

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```



## Unmount everything and reboot 

```bash
# Enable newtork manager before rebooting otherwise, you won't be able to connect
systemctl enable NetworkManager

# Exit from chroot
exit

# Unmount everything to check if the drive is busy
umount -R /mnt

# Reboot the system and unplug the installation media
reboot


# Enable and start the time synchronization service
timedatectl set-ntp true
```



## Automatic snapshot boot entries update  

Each time a system snapshot is taken with timeshift, it will be available for boot in the bootloader, however you need to manually regenerate the grub configuration, this can be avoided thanks to `grub-btrfs`, which can automatically update the grub boot entries.  

Edit the **`grub-btrfsd`** service and because I will rely on timeshift for snapshotting, I am going to replace `ExecStart=...` with `ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto`. If you don't use timeshift or prefer to manually update the entries then lookup [here](https://github.com/Antynea/grub-btrfs)  

```bash 
sudo systemctl edit --full grub-btrfsd

# Enable grub-btrfsd service to run on boot
sudo systemctl enable grub-btrfsd
```


## Aur helper and additional packages installation  

I will use `yay`

Here is some interesting article [partial upgrades](https://wiki.archlinux.org/title/System_maintenance#Partial_upgrades_are_unsupported). This is also why later when installing KDE, I will exclude the KDE discovery store from the list of packages.  

To learn more about yay read [here](https://github.com/Jguer/yay#yay)  

> Note: you can't execute makepkg as root, so you need to log in your main account. For me it's berti

```bash
# Install yay
sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si

# Install "timeshift-autosnap", a configurable pacman hook which automatically makes snapshots before pacman upgrades.
yay -S timeshift-autosnap
```

> Learn more about timeshift autosnap [here](https://gitlab.com/gobonja/timeshift-autosnap)



## Finalization

```bash
# To complete the main/basic installation reboot the system
reboot
```

> After these steps you **should** be able to boot on your newly installed Arch Linux, if so congrats !  

> The basic installation is complete but we add a GUI.



# Video drivers

In order to have the smoothest experience on a graphical environment, **Gaming included**, we first need to install video drivers. To help you choose which one you want or need, read [this section](https://wiki.archlinux.org/title/Xorg#Driver_installation) of the arch wiki.  



## Amd  

For this guide I'll install the [**AMDGPU** driver](https://wiki.archlinux.org/title/AMDGPU) which is the open source one and the recommended, but be aware that this works starting from the **GCN 3** architecture, which means that cards **before** RX 400 series are not supported. _\( I have an RX 5700 XT \)_  

```bash

# What are we installing ?
# mesa: DRI driver for 3D acceleration.
# xf86-video-amdgpu: DDX driver for 2D acceleration in Xorg. I won't install this, because I prefer the default kernel modesetting driver.
# vulkan-radeon: vulkan support.
# libva-mesa-driver: VA-API h/w video decoding support.
# mesa-vdpau: VDPAU h/w accelerated video decoding support.

sudo pacman -S mesa vulkan-radeon libva-mesa-driver mesa-vdpau
```

### 32 Bit support

If you want to add **32-bit** support, we need to enable the `multilib` repository on pacman: edit `/etc/pacman.conf` and uncomment the `[multilib]` section _\( ie: remove the hashtag from each line of the section. Should be 2 lines \)_. Now we can install the additional packages.

```bash
# Refresh and upgrade the system
yay

# Install 32bit support for mesa, vulkan, VA-API and VDPAU
sudo pacman -S lib32-mesa lib32-vulkan-radeon lib32-libva-mesa-driver lib32-mesa-vdpau
```



## Nvidia  

In summary if you have an Nvidia card you have 2 options:  

1. [**NVIDIA** proprietary driver](https://wiki.archlinux.org/title/NVIDIA)
2. [**Nouveau** open source driver](https://wiki.archlinux.org/title/Nouveau)

The recommended is the proprietary one, however I won't explain further because I don't have an Nvidia card and the process for such cards is tricky unlike for AMD or Intel cards. Moreover for reason said before, I can't even test it.



## Intel

Installation looks almost identical to the AMD one, but every time a package contains the `radeon` word substitute it with `intel`. However this does not stand for [h/w accelerated decoding](https://wiki.archlinux.org/title/Hardware_video_acceleration), and to be fair I would recommend reading [the wiki](https://wiki.archlinux.org/title/Intel_graphics#Installation) before doing anything.



# Setting up a graphical environment

I'll provide 2 options:  

1. **KDE-plasma**  
2. **Hyprland**

On top of that I'll add a **display manager**, which you can omit if you don't like ( if so, you have additional configuration steps to perform ).  



## Option 1: KDE-plasma

**KDE Plasma** is a very popular DE which comes bundled in many distributions. It supports both the older **Xorg** and the newer **Wayland** protocols. It's **user friendly**, **light** and it's also used on the Steam Deck, which makes it great for **gaming**. I'll provide the steps for a minimal installation and add some basic packages.

```bash
# plasma-desktop: the barebones plasma environment.
# plasma-pa: the KDE audio applet.
# plasma-nm: the KDE network applet.
# plasma-systemmonitor: the KDE task manager.
# plasma-firewall: the KDE firewall.
# plasma-browser-integration: cool stuff, it lets you manage things from your browser like media currently played via the plasma environment. Make sure to install the related extension on firefox ( you will be prompted automatically upon boot ).
# kscreen: the KDE display configurator.
# kwalletmanager: manage secure vaults ( needed to store the passwords of local applications in an encrypted format ). This also installs kwallet as a dependency, so I don't need to specify it.
# kwallet-pam: automatically unlocks secure vault upon login ( without this, each time the wallet gets queried it asks for your password to unlock it ).
# bluedevil: the KDE bluetooth manager.
# powerdevil: the KDE power manager.
# power-profiles-daemon: adds 3 power profiles selectable from powerdevil ( power saving, balanced, performance ). Make sure that its service is enabled and running ( it should be ).
# kdeplasma-addons: some useful addons.
# xdg-desktop-portal-kde: better integrates the plasma desktop in various windows like file pickers.
# xwaylandvideobridge: exposes Wayland windows to XWayland-using screen sharing apps ( useful when screen sharing on discord, but also in other instances ).
# kde-gtk-config: the native settings integration to manage GTK theming.
# breeze-gtk: the breeze GTK theme.
# cups, print-manager: the CUPS print service and the KDE front-end.
# konsole: the KDE terminal.
# dolphin: the KDE file manager.
# ffmpegthumbs: video thumbnailer for dolphin.
# firefox: the web browser.
# kate: the KDE text editor.
# okular: the KDE pdf viewer.
# gwenview: the KDE image viewer.
# ark: the KDE archive manager.
# pinta: a paint.net clone written in GTK.
# spectacle: the KDE screenshot tool.
# dragon: a simple KDE media player. A more advanced alternative based on libmpv is Haruna.
sudo pacman -S plasma-desktop plasma-pa plasma-nm plasma-systemmonitor plasma-firewall plasma-browser-integration kscreen kwalletmanager kwallet-pam bluedevil powerdevil power-profiles-daemon kdeplasma-addons xdg-desktop-portal-kde xwaylandvideobridge kde-gtk-config breeze-gtk cups print-manager konsole dolphin ffmpegthumbs firefox kate okular gwenview ark pinta spectacle dragon
```

Now don't reboot your system yet. If you want a display manager, which is generally recommended, head to the [related section](#adding-a-display-manager) in this guide and proceed from there otherwise you'll have to [manually configure](https://wiki.archlinux.org/title/KDE#From_the_console) and launch the graphical environment each time \(which I would advise to avoid\).



## Option 2: Hyprland [WIP]  

> Note: this section needs configuration and is basically empty, I don't know when and if I will expand it but at least you have a starting point.


**Hyprland** is a **tiling WM** that sticks to the wayland protocol. It looks incredible and it's one of the best Wayland WMs right now. It's based on **wlroots** the famous library used by Sway, the most mature Wayland WM there is. I don't know if I would recommend this to beginners because it's a totally different experience and it may not be better. Moreover it requires you to read the [wiki](https://wiki.hyprland.org/) for configuration but it also features a [master tutorial](https://wiki.hyprland.org/Getting-Started/Master-Tutorial). The good part is that even if it seems discouraging, it's actually an easy read because it is written beautifully.  

```bash
# Install hyprland from tagged releases and other utils:
# swaylock: the lockscreen
# wofi: the wayland version of rofi, an application launcher, extremely configurable
# waybar: a status bar for wayland wm's
# dolphin: a powerful file manager from KDE applications
# alacritty: a beautiful and minimal terminal application, super configurable
pacman -S --needed hyprland swaylock wofi waybar dolphin alacritty

# wlogout: a logout/shutdown menu
yay -S wlogout
```



# Adding a display manager

**Display managers** are useful when you have multiple DE or WMs and want to choose where to boot from or select the display protocol \( Wayland or Xorg \) in a GUI fashion, also they take care of the launch process. I'll show the installation process of **SDDM**, which is highly customizable and compatible.

> Note: hyprland does not support any display manager, however SDDM is reported to work flawlessly from the [wiki](https://wiki.hyprland.org/Getting-Started/Master-Tutorial/#launching-hyprland)

```bash
# Install SDDM
sudo pacman -S sddm

# Enable SDDM service to make it start on boot
sudo systemctl enable sddm

# If using KDE I suggest installing this to control the SDDM configuration from the KDE settings App
pacman -S --needed sddm-kcm

# Now it's time to reboot the system
reboot
```

# Additional notes

- On KDE disabling mouse acceleration is simple, just go to the settings via the GUI and on the mouse section enable the flat acceleration profile. If not using KDE then read [here](https://wiki.archlinux.org/title/Mouse_acceleration)

- To enable Freesync or Gsync you can read [here](https://wiki.archlinux.org/title/Variable_refresh_rate), depending on your session \( Wayland or Xorg \) and your gfx provider \( Nvidia, AMD, Intel \) the steps may differ. On a KDE wayland session, you can directly enable it from the monitor settings under the name of **adaptive sync** 

- Some considerations if you are thinking about switching to a custom kernel:
  - You have to manually recompile it each time there is a new update unless you use a precompiled kernel from pacman or aur such as `linux-zen`.
  - There is no such thing as the best kernel, all kernels make tradeoffs \( eg: latency for throughtput \) and this it why it's generally advised to stick with the generic one.
  - If you are mainly a gamer you MAY consider the **TKG** or **CachyOS** kernel. These kernels contain many optimizations and are highly customizable, however the TKG kernel has to be compiled \( mainly it's time consuming, not hard \), while CachyOS kernel comes already packaged and optimized for specific hardware configurations, and can be simply installed with pacman upon adding their repos to `pacman.conf`. Some users have reported to experience a smoother experience with lower latency, however I couldn't find consistent information about this and it seems that is all backed by a personal sensation and not a result obtained through objective measurements \( Also this is difficult because in Linux there can be countless configuration variables and it also depends by the graphic card being used \). 
    
- Some recommended reads:
  - [How to build your KDE environment](https://community.kde.org/Distributions/Packaging_Recommendations)
  - [Arch linux system maintenance](https://wiki.archlinux.org/title/System_maintenance)
  - [Arch linux general recommendations](https://wiki.archlinux.org/title/General_recommendations)



## Virtualbox support  

Follow these steps if you are running Arch on a Virtualbox VM.
This will enable features such as **clipboard sharing**, **shared folders** and **screen resolution tweaks**

```bash
# Install the guest utils
pacman -S virtualbox-guest-utils

# Enable this service to automatically load the kernel modules
systemctl enable vboxservice.service
```

> Note: the utils will only work after a reboot is performed.

> Warning: the utils seems to only work in a graphical environment.
