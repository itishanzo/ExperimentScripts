#!/bin/bash

#Author: Hanzo
#Created: 27/8/22
#Modified: 27/8/22


#Description
#This script will run a while loop to check entered IP whether is it Up or Down 

#Usage
#connection.sh

echo "Hello ${USER^}, Please enter the IP Address to check whether system is Up or Down"
read target_ip

while true
do
	if ping -q -c 2 -W 1 $target_ip > /dev/null; then
		echo "${USER^}! This IP is up now"
		break
	else
		echo "$target_ip is currently down"
	fi
done
