#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root!"
    exit 1
fi

echo "Updating the system and installing OpenSSH Server..."

# Update system packages
apt-get update -y && apt-get upgrade -y

# Install OpenSSH Server
apt-get install -y openssh-server

# Enable and start the SSH service
echo "Enabling and starting the SSH service..."
systemctl enable ssh
systemctl start ssh

# Modify sshd_config to allow root login
SSHD_CONFIG="/etc/ssh/sshd_config"

echo "Modifying SSH settings to allow root login and password authentication..."

# Allow root login
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
fi

# Enable password authentication
if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
fi

# Restart SSH service to apply the changes
echo "Restarting SSH service to apply changes..."
systemctl restart ssh

# Display SSH status
echo "SSH Server installation and configuration completed. SSH status is as follows:"
systemctl status ssh --no-pager

echo "You can now log in via SSH using the root account."