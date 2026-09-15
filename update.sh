#!/bin/bash

# Author: Hanzo
# Created: 31/07/2022
# Modified: 15/09/2026

# Description:
# Updates the system packages and checks whether a reboot is required.

# Usage:
# ./update.sh

set -e

# Load distribution information
source /etc/os-release

echo "Updating system: $PRETTY_NAME"
echo

case "$ID" in
    ubuntu|debian)
        echo "Running APT update..."
        sudo apt update
        sudo apt upgrade -y
        ;;

    rhel|centos|fedora|rocky|almalinux)
        if command -v dnf >/dev/null 2>&1; then
            echo "Running DNF update..."
            sudo dnf upgrade -y
        elif command -v yum >/dev/null 2>&1; then
            echo "Running YUM update..."
            sudo yum update -y
        else
            echo "Error: Neither dnf nor yum was found."
            exit 1
        fi
        ;;

    *)
        echo "Unsupported distribution: $PRETTY_NAME"
        echo "Please update this script to support your distribution."
        exit 1
        ;;
esac

echo
echo "System update completed successfully."

# Check whether a reboot is required
if [ -f /var/run/reboot-required ]; then
    echo
    echo "A reboot is required to complete the updates."

    read -r -p "Do you want to reboot now? [y/N]: " answer

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Rebooting..."
        sudo systemctl reboot
    else
        echo "Reboot skipped. Please reboot the system later."
    fi
else
    echo "No reboot is required."
fi
