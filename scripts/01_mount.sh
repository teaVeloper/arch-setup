#!/bin/bash
# 01_mount.sh - Format partitions, create Btrfs subvolumes, and mount them.
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

# Assume partitions follow naming convention: p1 for EFI, p2 for root.
EFI_PART="${TARGET_DISK}p1"
ROOT_PART="${TARGET_DISK}p2"

echo "Formatting EFI partition ($EFI_PART) as FAT32..."
sudo mkfs.fat -F32 -n EFI "$EFI_PART"

echo "Formatting root partition ($ROOT_PART) as Btrfs..."
sudo mkfs.btrfs -L ARCH "$ROOT_PART"

echo "Mounting root partition..."
sudo mount "$ROOT_PART" /mnt

echo "Creating Btrfs subvolumes (@, @home, @srv, @log, @cache, @tmp)..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@tmp

echo "Unmounting /mnt and remounting subvolumes..."
sudo umount /mnt
sudo mount -o compress=zstd,subvol=@ "$ROOT_PART" /mnt
sudo mkdir -p /mnt/home /mnt/srv /mnt/tmp /mnt/var/log /mnt/var/cache
sudo mount -o compress=zstd,subvol=@home "$ROOT_PART" /mnt/home
sudo mount -o compress=zstd,subvol=@srv "$ROOT_PART" /mnt/srv
sudo mount -o compress=zstd,subvol=@tmp "$ROOT_PART" /mnt/tmp
sudo mount -o compress=zstd,subvol=@log "$ROOT_PART" /mnt/var/log
sudo mount -o compress=zstd,subvol=@cache "$ROOT_PART" /mnt/var/cache

echo "Mounting EFI partition..."
sudo mkdir -p /mnt/efi
sudo mount "$EFI_PART" /mnt/efi

if [[ "$SWAPFILE" == "yes" ]]; then
    echo "Setting up swap file for hibernation..."
    btrfs subvolume create /mnt/@swap
    mkdir -p /mnt/swap
    # Mount the swap subvolume without compression for reliability.
    mount -o subvol=@swap "$ROOT_PART" /mnt/swap
    chattr +C /mnt/swap
    btrfs filesystem mkswapfile --size 2G /mnt/swap/swapfile
    sudo swapon /mnt/swap/swapfile
    RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile)
    echo "Calculated resume offset: $RESUME_OFFSET"
    echo "$RESUME_OFFSET" | sudo tee /sys/power/resume_offset
fi

echo "Mounting complete. Verify with lsblk."
