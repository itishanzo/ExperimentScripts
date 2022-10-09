#!/bin/bash

#Author: Hanzo
#Created: 31/7/22
#Modified: 9/10/22

#Description
#Lets users  keep their environment updated

#Usage
#update.sh

distro=/etc/os-release


if grep  -q "Ubuntu" $distro || grep -q "Debian" $distro; then
	sudo apt update && sudo apt -y upgrade
elif grep -q "CentOS" $distro || grep -q "rhel" $distro; then
	sudo yum update -y
else
	echo "Please update this script and add your Distro"
fi

if [ -f /var/run/reboot-required ]; then # This statement will reboot the system if it required after an update.
	reboot
fi
