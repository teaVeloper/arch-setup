#!/bin/bash
# common.sh
# This file is meant to be sourced by other scripts for utility functions and settings.

# Load configuration file.
CONFIG_FILE="scripts/config.sh"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found! Please run ./configure.sh first."
    exit 1
fi

# Option parsing for --force, --dry, --sudo, and --nosudo
FORCE=false
DRY_RUN=false

# Allow the config file to preset SUDO (as a string: "true" or "false").
# If not set, then we choose the default based on the current user.
if [ -z "$SUDO" ]; then
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=false
    else
        SUDO=true
    fi
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--force) FORCE=true ;;
        --dry) DRY_RUN=true ;;
        --sudo) SUDO=true ;;
        --nosudo) SUDO=false ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Set SUDO_CMD based on SUDO flag.
if $SUDO; then
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

# Helper function to run commands.
run_cmd() {
    # Prepend the sudo command if SUDO_CMD is not empty.
    local cmd="$*"
    if $DRY_RUN; then
        echo "[DRY RUN] ${SUDO_CMD:+$SUDO_CMD }$cmd"
    else
        # Evaluate with sudo if needed.
        eval "${SUDO_CMD:+$SUDO_CMD }$cmd"
    fi
}

# Optionally, you could also add a logging function here.
log() {
    echo "[LOG] $*"
}
