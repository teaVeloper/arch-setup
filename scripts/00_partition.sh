#!/bin/bash
# 00_partition.sh - Completely wipe disk, create partition table and partitions

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

# Verify TARGET_DISK partitions exist (we expect p1 and p2)
EFI_PART="${TARGET_DISK}p1"
ROOT_PART="${TARGET_DISK}p2"

# Verify target disk exists
if [ ! -b "$TARGET_DISK" ]; then
    echo "Error: Target disk ${TARGET_DISK} does not exist."
    exit 1
fi

# Check if any partitions on TARGET_DISK are mounted
if mount | grep -q "^$TARGET_DISK"; then
    echo "Error: Some partitions on ${TARGET_DISK} appear to be mounted."
    exit 1
fi

# Check if swap is active on the disk
if grep -q "$TARGET_DISK" /proc/swaps; then
    echo "Error: Swap is active on ${TARGET_DISK}. Please turn off swap (swapoff) before continuing."
    exit 1
fi

if ! $FORCE; then
    echo "WARNING: This script will wipe all data on ${TARGET_DISK}."
    read -p "Are you sure you want to continue? (yes/no): " answer
    if [[ "$answer" != "yes" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "Wiping existing partition table and filesystem signatures on ${TARGET_DISK}..."
run_cmd "sgdisk --zap-all $TARGET_DISK"
run_cmd "wipefs -a $TARGET_DISK"

echo "Creating new GPT partition table on ${TARGET_DISK}..."
run_cmd "parted --script $TARGET_DISK mklabel gpt"

echo "Creating EFI partition (512M) and Linux filesystem partition..."
# Here we create the EFI partition (first 512M) and then use the rest for root.
run_cmd "sfdisk $TARGET_DISK <<EOF
,512M,U
,,L
EOF"
run_cmd "partprobe "$TARGET_DISK""


if [ ! -b "$EFI_PART" ]; then
    echo "Error: EFI partition ($EFI_PART) not found."
    exit 1
fi

if [ ! -b "$ROOT_PART" ]; then
    echo "Error: Root partition ($ROOT_PART) not found."
    exit 1
fi

echo "Formatting EFI partition ($EFI_PART) as FAT32..."
run_cmd "mkfs.fat -F32 -n EFI $EFI_PART"

echo "Formatting root partition ($ROOT_PART) as Btrfs..."
run_cmd "wipefs -a "$ROOT_PART""

run_cmd "mkfs.btrfs -L ARCH $ROOT_PART"

echo "Partitioning complete. Verify with lsblk or fdisk -l."
