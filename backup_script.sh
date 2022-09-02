#!/bin/bash

#Author: Hanzo
#Date Created: 7/7/22
#Last Modified: 8/7/22

#Description
#This script will assist us in backing up the $HOME directory

#Usage
#backup_script.sh

echo "Hello, ${USER^}!"
echo "I will now backup your home directory, $HOME"
sleep 2
cdir=$(pwd)
echo "You are running this script from $cdir"
sleep 2
echo "As a result, backup will be saved in $cdir." 
tar -cf $cdir/backup-"$(date +%d-%m-%Y_%H-%M-%S)".tar $HOME/* 2>/dev/null
sleep 2 
echo "Backup has been saved successfully."
exit 0
