# ExperimentScripts

A collection of practical Bash scripts for Linux system administration, troubleshooting, networking, backups, and system maintenance.

The repository contains small utilities designed to simplify common Linux tasks and make frequently used operations easier to run from the terminal.

## Scripts
Script	Purpose
backup_script.sh	Creates a compressed backup of the user's home directory
connection.sh	Continuously checks whether an IP address or hostname is reachable
findlog.sh	Searches and troubleshoots systemd journal logs
update.sh	Updates supported Linux distributions and checks whether a reboot is required
run-scripts-from-anywhere.txt	Instructions for adding the scripts directory to $PATH

## Requirements

Most scripts require:

Linux

Bash

Standard Linux command-line utilities

findlog.sh

findlog.sh requires:

Bash 4+

systemd

journalctl

grep

The script is intended for systems that use systemd and the systemd journal.

## Installation

Clone the repository:

git clone https://github.com/itishanzo/ExperimentScripts.git
cd ExperimentScripts


Make the scripts executable:

chmod +x *.sh


You can then run the scripts from the repository directory.

Scripts
1. backup_script.sh

Creates a compressed .tar.gz archive of the current user's home directory.

Usage
./backup_script.sh /path/to/backup/directory

Example
./backup_script.sh /mnt/backup


The destination directory must:

Already exist

Be writable by the current user

A timestamped backup file is created in the following format:

backup-DD-MM-YYYY_HH-MM-SS.tar.gz


For example:

backup-15-09-2026_07-30-45.tar.gz


The script also displays the resulting backup size.

How It Works

The backup is created using:

tar -czf


The contents of $HOME are archived without requiring the script to know the username or home-directory path in advance.

2. connection.sh

A simple connectivity-checking utility that repeatedly tests whether an IP address or hostname is reachable.

Usage
./connection.sh


The script prompts for an IP address or hostname:

Please enter the IP address or hostname to check:

Example
Please enter the IP address or hostname to check: 8.8.8.8


It uses ping to test connectivity.

If the target is unreachable, the script waits two seconds and tries again:

12:30:01 - 8.8.8.8 is DOWN. Retrying in 2 seconds...


When connectivity is detected:

12:30:05 - 8.8.8.8 is UP


Press Ctrl+C to stop the script while it is retrying.

3. findlog.sh

findlog.sh is the most feature-rich utility in this repository.

It is a read-only systemd journal troubleshooting and log-search tool.

Features

It supports:

Literal text searching

Extended regular expressions

Case-sensitive and case-insensitive searches

Time-based filtering

systemd service/unit filtering

Boot filtering

Priority filtering

PID filtering

UID filtering

Identifier filtering

Facility filtering

Kernel logs

System journal

User journal

Live/follow mode

Boot listing

Journal disk-usage information

Journal verification

Result limits

Before/after context

UTC timestamps

Full journal fields

JSON output

Quiet mode

Basic Usage

Run without arguments for an interactive search:

./findlog.sh


Search for a specific message:

./findlog.sh "connection refused"


Search recent errors:

./findlog.sh --since "1 hour ago" --priority err


Search SSH errors:

./findlog.sh --unit sshd --priority err "failed"


Search today's Nginx errors:

./findlog.sh --since today --unit nginx --priority err


Search logs from the previous boot:

./findlog.sh --boot previous "error"


Search kernel errors:

./findlog.sh --kernel --priority err


Search messages from a specific process:

./findlog.sh --pid 1234 "error"


Limit the number of matching entries:

./findlog.sh --lines 50 "timeout"


Show surrounding journal entries:

./findlog.sh --context 3 "connection refused"


Follow matching SSH failures in real time:

./findlog.sh --unit sshd --follow "failed"


Use an extended regular expression:

./findlog.sh --regex "failed.*connection"


Perform a case-sensitive search:

./findlog.sh --case-sensitive "Connection refused"


List available boots:

./findlog.sh --list-boots


Display journal disk usage:

./findlog.sh --disk-usage


Verify journal files:

./findlog.sh --verify


Output matching entries as JSON:

./findlog.sh --json "error"

Search Behavior

By default, searches are:

Case-insensitive

Literal/fixed-string searches

Limited to 20 matching entries

Displayed with no surrounding context

Regular expressions can be enabled with:

-E


or:

--regex


Case-sensitive searching can be enabled with:

-c


or:

--case-sensitive

Security Characteristics

findlog.sh is designed to be read-only.

It does not:

Execute commands from log contents

Use eval

Modify system configuration

Delete journal logs

Vacuum journal logs

Change permissions

Make network connections

Collect credentials

The script invokes journalctl for journal operations and uses grep for filtering.

Exit Status
Code	Meaning
0	Match found / operation successful
1	No matching entry found
2	Invalid argument or input
3	journalctl operation failed
4	Search operation failed
127	Required command not found
4. update.sh

Updates supported Linux distributions and checks whether the system requires a reboot.

Usage
./update.sh


The script reads /etc/os-release to determine the Linux distribution.

Supported Distribution Families

Ubuntu

Debian

RHEL

CentOS

Fedora

Rocky Linux

AlmaLinux

Debian / Ubuntu

The script runs:

sudo apt update
sudo apt upgrade -y

RHEL / CentOS / Fedora / Rocky / AlmaLinux

If dnf is available:

sudo dnf upgrade -y


Otherwise, if yum is available:

sudo yum update -y

Reboot Detection

After updating, the script checks:

/var/run/reboot-required


If a reboot is required, you are asked whether you want to reboot immediately.

Example:

A reboot is required to complete the updates.
Do you want to reboot now? [y/N]:


Answering y or Y initiates:

sudo systemctl reboot

## Running Scripts From Anywhere

If you frequently use these utilities, you can add the repository directory to your $PATH.

First, open your profile:

nano ~/.profile


Add:

export PATH="$PATH:$HOME/ExperimentScripts"


If your repository is stored somewhere else, replace the path accordingly.

Save the file and reload it:

source ~/.profile


Verify the path:

echo $PATH


You should now be able to execute the scripts from any directory:

backup_script.sh /mnt/backup

connection.sh

findlog.sh "error"

update.sh


If a script does not execute, make sure it has executable permissions:

chmod +x /path/to/ExperimentScripts/your-script.sh


For more details, see run-scripts-from-anywhere.txt.

Examples
Create a Home Directory Backup
backup_script.sh /mnt/backup

Check Whether a Server Is Reachable
connection.sh


Then enter:

192.168.1.1

Find Recent System Errors
findlog.sh --since "1 hour ago" --priority err "error"

Monitor SSH Failures
findlog.sh --unit sshd --follow "failed"

Check the Previous Boot for Errors
findlog.sh --boot previous "error"

Update the System
update.sh

## Safety Notes

These scripts perform operations that can affect the system, so review them before running them on production machines.

In particular:

backup_script.sh reads and archives the contents of your home directory.

update.sh installs system package updates using sudo.

update.sh can reboot the system if you explicitly confirm the reboot prompt.

findlog.sh is designed to be read-only.

connection.sh uses ping to test network reachability.

Tip: Always make sure your backup destination has sufficient free disk space before creating a backup.

## Contributing

This repository contains personal Linux/Bash utilities and experiments.

If you want to improve a script:

Fork the repository.

Create a feature branch.

Make your changes.

Test the script on a supported Linux environment.

Submit a pull request.

When modifying scripts, preserve safe shell practices and avoid introducing unnecessary privileged operations.

## License

This project is licensed under the MIT License.

You are free to:

Use the software

Copy the software

Modify the software

Merge the software

Publish the software

Distribute the software

Sublicense the software

Sell copies of the software

Subject to the terms and conditions of the MIT License.

See the LICENSE file for the complete license text.

## Author
Hanzo

GitHub: @itishanzo

Repository: ExperimentScripts
