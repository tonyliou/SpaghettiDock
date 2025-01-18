#!/bin/bash

# Function to display the menu
display_menu() {
  echo "Select the Git credential helper configuration:"
  echo "1) Cache (default settings)"
  echo "2) Cache with timeout"
  echo "3) Store credentials"
  echo "4) Exit"
}

# Main script loop
while true; do
  display_menu
  read -p "Enter your choice (1-4): " choice

  case $choice in
    1)
      echo "Setting credential helper to cache (default settings)..."
      git config --global credential.helper cache
      echo "Configuration applied."
      ;;
    2)
      read -p "Enter timeout in seconds: " timeout
      if [[ $timeout =~ ^[0-9]+$ ]]; then
        echo "Setting credential helper to cache with timeout of $timeout seconds..."
        git config --global credential.helper "cache --timeout=$timeout"
        echo "Configuration applied."
      else
        echo "Invalid timeout value. Please enter a valid number."
      fi
      ;;
    3)
      echo "Setting credential helper to store credentials..."
      git config --global credential.helper store
      echo "Configuration applied."
      ;;
    4)
      echo "Exiting script. Goodbye!"
      exit 0
      ;;
    *)
      echo "Invalid choice. Please try again."
      ;;
  esac

done