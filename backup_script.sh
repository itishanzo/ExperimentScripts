#!/bin/bash

# Author: Hanzo
# Date Created: 07/07/2022
# Last Modified: 15/09/2026

# Description:
# Creates a compressed backup of the user's home directory.
# The backup destination is provided as a command-line argument.
#
# Usage:
# ./backup_script.sh /path/to/backup/directory
#
# Example:
# ./backup_script.sh /mnt/backup

set -u

echo "Hello, ${USER^}!"
echo

# Check whether a backup destination was provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 /path/to/backup/directory"
    echo
    echo "Example:"
    echo "  $0 /mnt/backup"
    exit 1
fi

backup_dir="$1"

# Check whether the destination exists
if [[ ! -d "$backup_dir" ]]; then
    echo "Error: Backup directory does not exist:"
    echo "$backup_dir"
    exit 1
fi

# Check whether the destination is writable
if [[ ! -w "$backup_dir" ]]; then
    echo "Error: Backup directory is not writable:"
    echo "$backup_dir"
    exit 1
fi

timestamp="$(date '+%d-%m-%Y_%H-%M-%S')"
backup_file="$backup_dir/backup-$timestamp.tar.gz"

echo "Source:"
echo "  $HOME"
echo
echo "Destination:"
echo "  $backup_file"
echo

echo "Creating backup..."

if tar -czf "$backup_file" -C "$HOME" .; then
    echo
    echo "Backup completed successfully!"
    echo
    echo "Backup file:"
    echo "  $backup_file"
    echo
    echo "Backup size:"
    du -h "$backup_file" | cut -f1
else
    echo
    echo "Error: Backup failed."

    # Remove incomplete archive if tar failed
    rm -f "$backup_file"

    exit 1
fi

exit 0
