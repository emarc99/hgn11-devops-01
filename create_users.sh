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

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Check if input file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <user_list_file>"
    exit 1
fi

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

echo "User creation process completed." | tee -a "$LOG_FILE"

