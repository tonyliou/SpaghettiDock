#!/bin/bash

# Function to install required packages
install_packages() {
    echo "Installing required packages..."
    sudo apt update && sudo apt install vim ack -y
    echo "Package installation complete."
}

# Function to install awesome_vimrc
install_awesome_vimrc() {
    echo "Installing awesome_vimrc..."
    git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
    sh ~/.vim_runtime/install_awesome_vimrc.sh

    echo "Checking for existing my_configs.vim..."
    if [ -f ~/.vim_runtime/my_configs.vim ]; then
        backup_file="~/.vim_runtime/my_configs_$(date +%Y%m%d%H%M%S).vim"
        mv ~/.vim_runtime/my_configs.vim "$backup_file"
        echo "Existing my_configs.vim backed up to $backup_file."
    fi

    echo "Adding custom configurations to my_configs.vim..."
    echo "set number" > ~/.vim_runtime/my_configs.vim

    echo "Installation of awesome_vimrc complete."
}

# Function to uninstall awesome_vimrc
uninstall_awesome_vimrc() {
    echo "Uninstalling awesome_vimrc..."
    if [ -d "~/.vim_runtime" ]; then
        rm -rf ~/.vim_runtime
        echo "Removed ~/.vim_runtime."
    else
        echo "~/.vim_runtime does not exist."
    fi

    if grep -q ".vim_runtime" ~/.vimrc; then
        sed -i '/.vim_runtime/d' ~/.vimrc
        echo "Removed references to .vim_runtime in ~/.vimrc."
    else
        echo "No references to .vim_runtime found in ~/.vimrc."
    fi

    echo "Uninstallation complete."
}

# Main menu
while true; do
    echo "Please select an option:"
    echo "1. Install required packages"
    echo "2. Install awesome_vimrc"
    echo "3. Uninstall awesome_vimrc"
    echo "4. Exit"
    read -rp "Enter your choice [1-4]: " choice

    case $choice in
        1)
            install_packages
            ;;
        2)
            install_awesome_vimrc
            ;;
        3)
            uninstall_awesome_vimrc
            ;;
        4)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, 3, or 4."
            ;;
    esac
    echo
done

