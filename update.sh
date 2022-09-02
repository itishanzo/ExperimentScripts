#!/bin/bash

#Author: Hanzo
#Created: 31/7/22
#Modified: 31/7/22

#Description
#Lets users  keep their environment updated

#Usage
#update.sh


sudo apt -y update 
sudo apt -y upgrade

if [ -f /var/run/reboot-required ]; then
	reboot
fi
