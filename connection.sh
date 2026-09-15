#!/bin/bash

# Author: Hanzo
# Created: 27/08/2022
# Modified: 15/09/2026

# Description:
# Continuously checks whether a given IP address or hostname is reachable.

# Usage:
# ./connection.sh

echo "Hello ${USER^}!"
read -r -p "Please enter the IP address or hostname to check: " target_ip

# Check if input is empty
if [[ -z "$target_ip" ]]; then
    echo "Error: No IP address or hostname was entered."
    exit 1
fi

echo
echo "Checking connectivity to: $target_ip"
echo "Press Ctrl+C to stop."
echo

while true; do
    if ping -q -c 2 -W 1 "$target_ip" > /dev/null 2>&1; then
        echo "$(date '+%H:%M:%S') - $target_ip is UP"
        break
    else
        echo "$(date '+%H:%M:%S') - $target_ip is DOWN. Retrying in 2 seconds..."
        sleep 2
    fi
done
