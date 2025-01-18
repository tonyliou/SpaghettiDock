#!/bin/bash

# Update package list
sudo apt update

# Install Vim
sudo apt install -y vim

# Check if installation was successful
if ! command -v vim &> /dev/null
then
    echo "Vim installation failed. Please check the error messages."
    exit 1
fi

# Set Vim configuration file
VIMRC=~/.vimrc
BACKUP_VIMRC=~/.vimrc.backup.$(date +%Y%m%d%H%M%S)

# Create backup mechanism
if [ -f "$VIMRC" ]; then
    echo "Existing .vimrc file found. Creating a backup at $BACKUP_VIMRC"
    cp "$VIMRC" "$BACKUP_VIMRC"
fi

cat <<EOL > $VIMRC
" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Enable auto-indentation
set autoindent
set smartindent

" Set indentation width
set tabstop=4
set shiftwidth=4
set expandtab

" Enable search highlighting
set hlsearch

" Incremental search
set incsearch

" Enable mouse support
set mouse=a

" Set color scheme
colorscheme desert

" Disable backup files
set nobackup
set nowritebackup
set noswapfile

" Show status line
set laststatus=2

" Set scroll offset
set scrolloff=8

" Enable autocomplete menu
set wildmenu

" Enable file type detection
filetype plugin on
filetype indent on
EOL

# Completion message
echo "Vim installation complete. Configuration has been set in $VIMRC."
echo "If you need to restore the previous configuration, overwrite $VIMRC with $BACKUP_VIMRC."