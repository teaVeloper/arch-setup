#!/bin/bash
# 01_mount.sh - Format partitions, create Btrfs subvolumes, and mount them.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

# Verify TARGET_DISK partitions exist (we expect p1 and p2)
EFI_PART="${TARGET_DISK}p1"
ROOT_PART="${TARGET_DISK}p2"


echo "Mounting root partition..."
run_cmd "mount $ROOT_PART /mnt"

echo "Creating Btrfs subvolumes (@, @home, @srv, @log, @cache, @tmp)..."
for subvol in @ @home @srv @log @cache @tmp; do
    run_cmd "btrfs subvolume create /mnt/$subvol"
done

echo "Unmounting /mnt and remounting subvolumes..."
run_cmd "umount /mnt"
run_cmd "mount -o compress=zstd,subvol=@ $ROOT_PART /mnt"
run_cmd "mkdir -p /mnt/{home,srv,tmp,var/log,var/cache}"

run_cmd "mount -o compress=zstd,subvol=@home $ROOT_PART /mnt/home"
run_cmd "mount -o compress=zstd,subvol=@srv $ROOT_PART /mnt/srv"
run_cmd "mount -o compress=zstd,subvol=@tmp $ROOT_PART /mnt/tmp"
run_cmd "mount -o compress=zstd,subvol=@log $ROOT_PART /mnt/var/log"
run_cmd "mount -o compress=zstd,subvol=@cache $ROOT_PART /mnt/var/cache"

echo "Mounting EFI partition..."
run_cmd "mkdir -p /mnt/efi"
run_cmd "mount $EFI_PART /mnt/efi"

if [ "$SWAPFILE" == "yes" ]; then
    echo "Setting up swap file for hibernation..."
    run_cmd "btrfs subvolume create /mnt/@swap"
    run_cmd "mkdir -p /mnt/swap"
    run_cmd "mount -o subvol=@swap $ROOT_PART /mnt/swap"
    run_cmd "chattr +C /mnt/swap"
    run_cmd "btrfs filesystem mkswapfile --size 2G /mnt/swap/swapfile"
    run_cmd "swapon /mnt/swap/swapfile"
    RESUME_OFFSET=$(btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile)
    echo "Calculated resume offset: $RESUME_OFFSET"
    echo "$RESUME_OFFSET" | tee /sys/power/resume_offset
fi

echo "Mounting complete. Verify with lsblk."
