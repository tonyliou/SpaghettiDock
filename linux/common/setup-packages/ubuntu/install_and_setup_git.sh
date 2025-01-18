#!/bin/bash

# Update and install Git on Ubuntu
sudo apt update && sudo apt install -y git

# Configure Git aliases

# Alias for 'git checkout'
git config --global alias.co checkout

# Alias for 'git branch'
git config --global alias.br branch

# Alias for 'git status'
git config --global alias.st status

# Alias for a simple one-line log
# This shows a condensed log with commit hashes and messages
git config --global alias.l "log --oneline --graph"

# Alias for a detailed log with a graphical representation
# Includes commit hash, author, time ago, and message
git config --global alias.ls 'log --graph --pretty=format:"%h <%an> %ar %s"'

# Alias for a colorful log
# Visualizes tree structure, authors, and additional information with colors
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Alias for cleaning all submodules
# Resets all submodules to their original state and cleans untracked files
git config --global alias.subreset '!git submodule sync --recursive && git submodule foreach --recursive "git reset --hard && git clean -dfx && git restore . && git submodule sync --recursive && git submodule update --init --recursive"'

# Alias for a full reset of the main repository and all submodules
# Resets the main repository and all submodules to their original state
git config --global alias.fullreset '!git reset --hard && git clean -dfx && git restore . && git submodule sync --recursive && git submodule foreach --recursive "git reset --hard && git clean -dfx && git restore ." && git submodule update --init --recursive'