#!/bin/bash

# File paths
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Create log and password files if they don't exist
touch $LOG_FILE
mkdir -p /var/secure
touch $PASSWORD_FILE
chmod 600 $PASSWORD_FILE

# Log function
log_action() {
    echo "$(date): $1" >> $LOG_FILE
}

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Function to create user and group
create_user_and_groups() {
    local user=$1
    local groups=$2

    # Check if the user already exists
    if id -u $user >/dev/null 2>&1; then
        log_action "User $user already exists."
        return 1
    fi

    # Create user with home directory
    useradd -m $user
    if [[ $? -ne 0 ]]; then
        log_action "Failed to create user $user."
        return 1
    fi

    # Create a personal group for the user
    groupadd $user
    if [[ $? -ne 0 ]]; then
        log_action "Failed to create group $user."
        return 1
    fi

    # Add user to their own group
    usermod -aG $user $user

    # Add user to additional groups
    IFS=',' read -ra ADDR <<< "$groups"
    for group in "${ADDR[@]}"; do
        group=$(echo $group | xargs) # Trim whitespace
        if ! getent group $group > /dev/null; then
            groupadd $group
        fi
        usermod -aG $group $user
    done

    # Generate and set a random password
    password=$(generate_password)
    echo "$user:$password" | chpasswd
    if [[ $? -ne 0 ]]; then
        log_action "Failed to set password for user $user."
        return 1
    fi

    # Save the password to the secure file
    echo "$user,$password" >> $PASSWORD_FILE

    # Log success
    log_action "Successfully created user $user with groups $groups and home directory."
}

# Read the input file
input_file=$1
if [[ ! -f $input_file ]]; then
    echo "Input file not found!"
    log_action "Input file $input_file not found."
    exit 1
fi

while IFS=';' read -r user groups; do
    user=$(echo $user | xargs) # Trim whitespace
    groups=$(echo $groups | xargs) # Trim whitespace
    create_user_and_groups "$user" "$groups"
done < $1
