#!/usr/bin/env bash
#
# This script installs Vim and configures a basic .vimrc with syntax highlighting 
# and the settings described in the instructions. It also backs up any existing
# ~/.vimrc by appending a timestamp.

# Backup existing .vimrc with timestamp
TIMESTAMP=$(date +'%Y%m%d%H%M%S')
if [ -f ~/.vimrc ]; then
    cp ~/.vimrc ~/.vimrc.$TIMESTAMP
    echo "Existing ~/.vimrc backed up as ~/.vimrc.$TIMESTAMP"
fi

# Update package information (optional, but recommended)
sudo apt-get update

# Install Vim
sudo apt-get install -y vim

# Create (or overwrite) the .vimrc file in the user's home directory
cat <<EOF > ~/.vimrc
" Enable syntax highlighting
syntax on

" Show line numbers
set nu

" Auto indent
set ai

" Highlight the current cursor line
set cursorline

" Background color setting for a light-themed terminal
" If your terminal is dark-themed, consider using: set bg=dark
set bg=light

" Set the width for a <Tab> character
set tabstop=4

" Set the indentation width
set shiftwidth=4

" Enable mouse support in all modes
set mouse=a

" Show the cursor position at the bottom-right
set ruler

" Enable backspace in insert mode
set backspace=2

" Add 'r' to format options to continue comments automatically
set formatoptions+=r

" Keep 100 lines of command history
set history=100

" Enable incremental search
set incsearch

" Key mappings for automatic bracket insertion
inoremap ( ()<Esc>i
inoremap " ""<Esc>i
inoremap ' ''<Esc>i
inoremap [ []<Esc>i
inoremap {<CR> {<CR>}<Esc>ko
inoremap {{ {}<Esc>i

" Convert tabs to spaces (expandtab), tabstop=4 determines how many spaces
set expandtab

" Enable indentation detection based on file type
filetype indent on

" Highlight line numbers
hi LineNr cterm=bold ctermfg=DarkGrey ctermbg=NONE

" Highlight the current cursor line number
hi CursorLineNr cterm=bold ctermfg=Green ctermbg=NONE
EOF

echo "Vim installation and configuration completed."
echo "Open a file with 'vim filename' to enjoy the new settings!"
