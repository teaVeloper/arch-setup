#!/bin/bash
# bootstrap.sh - Bootstraps the Arch install scripts on a live system
# This script downloads and extracts the repository archive and then runs a chosen script.

set -e

# Configuration: update these URLs to point to your repository and desired branch or tag.
REPO_URL="https://github.com/teaveloper/arch-setup"
BRANCH="main"
ARCHIVE_URL="${REPO_URL}/archive/${BRANCH}.tar.gz"

# Temporary working directory.
WORK_DIR=$(mktemp -d -t arch-setup-XXXXXXXX)

cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "Downloading repository archive from ${ARCHIVE_URL}..."
# Use curl if available, otherwise fallback to wget.
if command -v curl &>/dev/null; then
    curl -L -o "${WORK_DIR}/arch-setup.tar.gz" "$ARCHIVE_URL"
elif command -v wget &>/dev/null; then
    wget -O "${WORK_DIR}/arch-setup.tar.gz" "$ARCHIVE_URL"
else
    echo "Error: Neither curl nor wget is installed on this system."
    exit 1
fi

echo "Extracting archive..."
tar -xzf "${WORK_DIR}/arch-setup.tar.gz" -C "$WORK_DIR"

# The repository is extracted into a directory like "arch-setup-main"
REPO_DIR=$(find "$WORK_DIR" -maxdepth 1 -type d -name "arch-setup-*")
if [ -z "$REPO_DIR" ]; then
    echo "Error: Repository directory not found after extraction."
    exit 1
fi

echo "Repository downloaded and extracted to ${REPO_DIR}."

# Change directory to the repository directory.
cd "$REPO_DIR"

# At this point, you could run your setup script.
# For example, if you have a script in the 'scripts' directory, run:
if [ -x "scripts/00_partition.sh" ]; then
    echo "Starting installation script..."
    # You might want to run with sudo or set flags, e.g., -f for force if necessary.
    bash scripts/00_partition.sh
else
    echo "No executable partition script found. Please check your repository."
    exit 1
fi

