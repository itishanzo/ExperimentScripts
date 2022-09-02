#!/bin/bash

#Author: Hanzo
#Created: 2/9/22
#Modified: 2/9/22

#Descrition
#This script will help user(s) to crosscheck specific log Entry

#Usage
#findlog.sh

echo "Hello ${USER^}!, Please enter/paste the specific log entry to crosscheck with other logs"
read target_entry

cdir=$(pwd)
echo "This script is being run from this $cdir directory"
sleep 2
echo "Please wait creating a TEXT file of journal logs in '/tmp'"
journalctl -r > /tmp/journal_LOG.txt
echo
echo "Reading logs ....."
echo
sleep 2
if cat /tmp/journal_LOG.txt |  grep -i "$target_entry" | head; then # If you don't want to see the output then replace '| head' with '> /dev/null'
	echo "This entry exists"
else
	echo "This entry $target_entry does not exists"
fi
exit 0
