#!/bin/bash

# Update the system package list
sudo apt update

# Install tmux
sudo apt install -y tmux

# Install bash-completion
sudo apt install -y bash-completion

# Download the tmux bash-completion script
wget https://raw.githubusercontent.com/imomaliev/tmux-bash-completion/master/completions/tmux

# Move the completion script to the bash-completion default directory
sudo mv tmux /etc/bash_completion.d/

# Restart bash to apply the new configuration
exec bash

# Display a success message
echo "tmux and bash-completion have been successfully installed."