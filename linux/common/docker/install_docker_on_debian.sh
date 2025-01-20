#!/bin/bash

# Function to display a menu
display_menu() {
  echo "Select an option:"
  echo "1) Uninstall conflicting packages"
  echo "2) Set up Docker repository"
  echo "3) Install Docker Engine"
  echo "4) Verify Docker installation"
  echo "5) Exit"
  echo -n "Enter your choice: "
}

# Function to uninstall conflicting packages
uninstall_conflicts() {
  echo "Uninstalling conflicting packages..."
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y "$pkg"
  done
  echo "Conflicting packages removed."
}

# Function to set up Docker repository
setup_repository() {
  echo "Setting up Docker repository..."
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  echo "Docker repository set up."
}

# Function to install Docker Engine
install_docker() {
  echo "Installing Docker Engine..."
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Docker Engine installed."
}

# Function to verify Docker installation
verify_installation() {
  echo "Verifying Docker installation..."
  sudo docker run hello-world
  echo "If you see a confirmation message, Docker is successfully installed."
}

# Main script logic
while true; do
  display_menu
  read choice
  case $choice in
    1)
      uninstall_conflicts
      ;;
    2)
      setup_repository
      ;;
    3)
      install_docker
      ;;
    4)
      verify_installation
      ;;
    5)
      echo "Exiting script. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac
done
