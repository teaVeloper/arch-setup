#!/bin/bash
# 00_partition.sh - Partition the disk (use with extreme caution).
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

echo "WARNING: This script will partition ${TARGET_DISK} and destroy all data on it."
read -p "Are you sure you want to continue? (yes/no): " answer
if [[ "$answer" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Create GPT table with an EFI partition (512M) and one Linux filesystem partition.
sudo sfdisk "$TARGET_DISK" <<EOF
,512M,U
,,L
EOF

echo "Partitioning complete. Please verify with lsblk or fdisk -l."
