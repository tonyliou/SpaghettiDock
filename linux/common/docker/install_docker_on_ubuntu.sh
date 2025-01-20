#!/bin/bash

echo "==============================="
echo "Docker Installation Script"
echo "==============================="
echo "Please choose an option:"
echo "1) Uninstall old versions of Docker"
echo "2) Install Docker Engine (using Docker's official apt repository)"
echo "3) Install Docker Engine (using convenience script)"
echo "4) Uninstall Docker Engine"
echo "5) Exit script"
read -p "Enter your choice (1-5): " option

case $option in
1)
    echo "Uninstalling old versions of Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove -y $pkg
    done
    echo "Old versions of Docker have been removed."
    ;;
2)
    echo "Installing Docker Engine (using apt repository)..."
    echo "Updating system packages..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    echo "Adding Docker's official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo "Adding Docker repository..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "Installing Docker Engine..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Verifying Docker installation..."
    sudo docker run hello-world
    ;;
3)
    echo "Installing Docker Engine (using convenience script)..."
    echo "Downloading and running the Docker installation script..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    echo "Verifying Docker installation..."
    sudo docker run hello-world
    ;;
4)
    echo "Uninstalling Docker Engine..."
    sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

    echo "Cleaning up Docker data..."
    sudo rm -rf /var/lib/docker
    sudo rm -rf /var/lib/containerd

    echo "Removing source lists and keys..."
    sudo rm /etc/apt/sources.list.d/docker.list
    sudo rm /etc/apt/keyrings/docker.asc

    echo "Docker has been successfully uninstalled."
    ;;
5)
    echo "Exiting script."
    exit 0
    ;;
*)
    echo "Invalid option. Please rerun the script and select a valid option."
    ;;
esac
