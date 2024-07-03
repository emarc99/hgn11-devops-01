# hgn11-devops-01
## Automating User and Group Creation in Linux with a Bash Script

As a SysOps engineer, managing users and groups efficiently is critical, especially in environments with frequent onboarding of new developers. As part of my journey in the HNG Internship program, I had the opportunity to tackle a practical and challenging DevOps task: writing a bash script to automate the creation of users and their associated groups. This script was designed to read a text file containing usernames and groups, create the users and groups as specified, set up home directories with appropriate permissions, generate random passwords, and log all actions. Here’s a step-by-step breakdown of how I approached and solved this problem.

## Script Overview

The create_users.sh script is designed to read a text file containing usernames and group names, create the necessary users and groups, set up home directories, generate random passwords, and log all actions.

## Requirements:

Reading a text file: Each line in the file contains a username and a list of groups, separated by a semicolon (;). Groups are comma-separated.
Creating users and groups: Each user must have a personal group with the same name as the username. The user can belong to multiple groups.
Setting up home directories: Ensuring each user has a home directory with appropriate permissions.
Generating random passwords: Assigning each user a random password.
Logging actions: Logging all actions to /var/log/user_management.log.
Storing passwords securely: Storing generated passwords in /var/secure/user_passwords.csv.

## Implementation:

Log and Password Files: The script starts by ensuring the log file and password file exist and have the correct permissions.
Logging Function: A function (log_action) logs actions with timestamps.
Password Generation: A function (generate_password) generates a random password using openssl.
User and Group Creation: The create_user_and_groups function handles creating the user, personal group, additional groups, setting the password, and logging these actions

## Run/Test the script

`sudo bash create_users.sh users.txt`

For those interested in joining a vibrant community and gaining hands-on experience, check out the [HNG Internship](https://hng.tech/internship). If you're looking to hire talented developers, visit [HNG Hire](https://hng.tech/hire).
