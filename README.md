# hgn11-devops-01
# Creating and Managing Linux Users with a Bash Script

As a SysOps engineer, managing user accounts and permissions efficiently is crucial, especially in a dynamic environment with many new developers. In this guide, I'll walk you through a Bash script designed to automate the creation of users and groups, set up home directories, generate random passwords, and log all actions. This script ensures consistency, security, and ease of management. Let's dive in!

## Requirements:

Before we begin, ensure you have the following:

A Linux machine (preferably Ubuntu)
Sudo privileges to run administrative commands
OpenSSL installed for secure password generation

## The Script: `create_users.sh`

This script reads a text file containing usernames and their associated groups, creates the users and groups as specified, sets up home directories, generates random passwords, and logs all actions.

## Script Breakdown

### 1. Setting Up Directories and Permissions
This section ensures the necessary directories and files exist, and sets the appropriate permissions to ensure security.

```bash
#!/bin/bash

# Paths for log and password files
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# Ensure the /var/secure directory exists
sudo mkdir -p /var/secure
sudo chmod 700 /var/secure

# Create or clear log and password files
> "$LOG_FILE" || { echo "Failed to create log file at $LOG_FILE"; exit 1; }
> "$PASSWORD_FILE" || { echo "Failed to create password file at $PASSWORD_FILE"; exit 1; }
sudo chmod 600 "$PASSWORD_FILE"
```

+ LOG_FILE and PASSWORD_FILE: Defines the paths for the log file and the password file.
+ Directory Creation: Ensures the /var/secure directory exists and sets its permissions to be readable only by the root user.
+ File Creation/Clearing: Ensures the log and password files are created or cleared, and sets their permissions.

### 2. Function to Generate Random Passwords
This function uses OpenSSL to generate secure random passwords.

```bash
# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}
```
+ generate_password: A simple function that generates a random password using OpenSSL. The password is 12 characters long and encoded in base64 for security.

### 3. Checking for Input File
This section ensures that an input file is provided as an argument to the script.

```bash
# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <user_list_file>"
    exit 1
fi
}
```

+ Input File Check: Checks if the input file is provided as an argument. If not, it displays usage instructions and exits.

### 4. Reading and Processing the Input File
This section reads the input file line by line, processes each line to create users and groups, sets up home directories, and assigns passwords.
```bash
# Read the input file line by line
while IFS=';' read -r username groups; do
    # Trim whitespace
    username=$(echo "$username" | xargs)
    groups=$(echo "$groups" | xargs)

    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists. Skipping..." | tee -a "$LOG_FILE"
        continue
    fi

    # Create personal group with the same name as the user
    if ! getent group "$username" &>/dev/null; then
        if ! sudo groupadd "$username"; then
            echo "Failed to create group $username." | tee -a "$LOG_FILE"
            continue
        fi
        echo "Group $username created." | tee -a "$LOG_FILE"
    fi

    # Create the user with the personal group
    if ! sudo useradd -m -g "$username" -s /bin/bash "$username"; then
        echo "Failed to create user $username." | tee -a "$LOG_FILE"
        continue
    fi
    echo "User $username created with home directory." | tee -a "$LOG_FILE"

    # Add user to additional groups
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
        group=$(echo "$group" | xargs)
        if ! getent group "$group" &>/dev/null; then
            if ! sudo groupadd "$group"; then
                echo "Failed to create group $group." | tee -a "$LOG_FILE"
                continue
            fi
            echo "Group $group created." | tee -a "$LOG_FILE"
        fi
        if ! sudo usermod -aG "$group" "$username"; then
            echo "Failed to add user $username to group $group." | tee -a "$LOG_FILE"
            continue
        fi
        echo "User $username added to group $group." | tee -a "$LOG_FILE"
    done

    # Set up home directory permissions
    sudo chmod 700 "/home/$username"
    sudo chown "$username:$username" "/home/$username"

    # Generate a random password and set it for the user
    password=$(generate_password)
    echo "$username:$password" | sudo chpasswd
    if [ $? -ne 0 ]; then
        echo "Failed to set password for user $username." | tee -a "$LOG_FILE"
        continue
    fi

    # Log the password securely
    echo "$username,$password" | sudo tee -a "$PASSWORD_FILE" > /dev/null
    echo "Password for user $username set." | tee -a "$LOG_FILE"

done < "$1"
```
+ Reading the File: Reads each line of the input file, trimming any extra whitespace.
+ User Existence Check: Checks if the user already exists. If so, it logs this and skips to the next line.
+ Personal Group Creation: Creates a personal group with the same name as the user, if it doesn't already exist.
+ User Creation: Creates the user, assigns the personal group, and sets up the home directory.
+ Additional Groups: Adds the user to any additional groups specified in the input file.
+ Home Directory Permissions: Sets the appropriate permissions for the home directory.
+ Password Generation and Assignment: Generates a random password and assigns it to the user.
+ Secure Logging: Logs the username and password to a secure file.

### 5. Completion Message
This section logs the completion of the user creation process

```bash
echo "User creation process completed." | tee -a "$LOG_FILE"
```
+ Completion Log: Logs a message indicating that the user creation process is complete.

## Run/Test the script

1. Save the Script

Save the script as `create_users.sh`.

2. Make the Script Executable

```bash
chmod +x create_users.sh
```

3. Prepare the Input File

Create a text file (e.g., user_list.txt) with the following format:

```kotlin
light; sudo,dev,www-data
idimma; sudo
mayowa; dev,www-data
```

4. Run the Script

Run the script with sudo to ensure it has the necessary permissions:

```bash
sudo ./create_users.sh users.txt
```

# Technical Insights and Learning
This script simplifies the task of managing users and groups on a Linux system. By automating user creation and password management, it ensures consistency and security. Each step of the script is designed to handle common issues, such as existing users or groups, and logs all actions for easy auditing.

 ## Links to HNG Internship:
For those interested in joining a vibrant community and gaining hands-on experience, check out the [HNG Internship](https://hng.tech/internship). If you're looking to hire talented developers, visit [HNG Hire](https://hng.tech/hire).
