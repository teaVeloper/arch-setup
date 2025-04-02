#!/bin/bash
# 00_partition.sh - Partition the disk (use with extreme caution).

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "${SCRIPT_DIR}/common.sh"

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

# Check if swap is active on the disk (by checking /proc/swaps)
if grep -q "$TARGET_DISK" /proc/swaps; then
    echo "Error: Swap is active on ${TARGET_DISK}. Please turn off swap (swapoff) before continuing."
    exit 1
fi

# Confirm action unless forced
if ! $FORCE; then
    echo "WARNING: This script will partition ${TARGET_DISK} and destroy all data on it."
    read -p "Are you sure you want to continue? (yes/no): " answer
    if [[ "$answer" != "yes" ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Partitioning command
echo "Partitioning ${TARGET_DISK}..."
PARTITION_CMD="sfdisk ${TARGET_DISK} <<EOF
,512M,U
,,L
EOF"
run_cmd "$PARTITION_CMD"

echo "Partitioning complete. Please verify with lsblk or fdisk -l."
