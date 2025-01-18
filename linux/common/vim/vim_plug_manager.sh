#!/bin/bash

# Function to install vim-plug
install_vim_plug() {
    if command -v nvim >/dev/null 2>&1; then
        echo "Detected Neovim."
        PLUG_PATH="${HOME}/.config/nvim/autoload/plug.vim"
        CONFIG_DIR="${HOME}/.config/nvim"
    elif command -v vim >/dev/null 2>&1; then
        echo "Detected Vim."
        PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
        CONFIG_DIR="${HOME}/.vim"
    else
        echo "Neither Vim nor Neovim is installed. Please install one first."
        exit 1
    fi

    # Ensure the directory exists
    mkdir -p "$(dirname "${PLUG_PATH}")"

    # Download vim-plug
    echo "Installing vim-plug to ${PLUG_PATH}..."
    curl -fLo "${PLUG_PATH}" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    if [ $? -eq 0 ]; then
        echo "vim-plug installed successfully!"
    else
        echo "Failed to install vim-plug. Please check your internet connection or try again."
        exit 1
    fi

    # Suggest adding basic configuration
    if [ "$CONFIG_DIR" == "${HOME}/.config/nvim" ]; then
        INIT_FILE="${CONFIG_DIR}/init.vim"
    else
        INIT_FILE="${HOME}/.vimrc"
    fi

    if [ ! -f "$INIT_FILE" ]; then
        echo "Creating ${INIT_FILE}..."
        touch "$INIT_FILE"
    fi

    echo
    echo "To start using vim-plug, add the following lines to your ${INIT_FILE}:"
    echo
    cat <<EOF
call plug#begin('${CONFIG_DIR}/plugged')

" Add your plugins here, for example:
" Plug 'preservim/nerdtree'
" Plug 'junegunn/fzf', { 'do': './install --all' }
" Plug 'tpope/vim-commentary'

call plug#end()
EOF

    echo
    echo "Run :PlugInstall in Vim/Neovim after editing ${INIT_FILE} to install plugins."
}

# Function to remove vim-plug
remove_vim_plug() {
    if command -v nvim >/dev/null 2>&1; then
        echo "Detected Neovim."
        PLUG_PATH="${HOME}/.config/nvim/autoload/plug.vim"
        CONFIG_DIR="${HOME}/.config/nvim"
    elif command -v vim >/dev/null 2>&1; then
        echo "Detected Vim."
        PLUG_PATH="${HOME}/.vim/autoload/plug.vim"
        CONFIG_DIR="${HOME}/.vim"
    else
        echo "Neither Vim nor Neovim is installed. Nothing to remove."
        exit 1
    fi

    # Remove vim-plug file
    if [ -f "$PLUG_PATH" ]; then
        echo "Removing vim-plug from ${PLUG_PATH}..."
        rm -f "$PLUG_PATH"
        echo "vim-plug removed successfully."
    else
        echo "vim-plug is not installed in ${PLUG_PATH}. Nothing to remove."
    fi

    # Suggest cleaning up configuration directory
    echo "If you no longer need plugins, you may also remove the ${CONFIG_DIR}/plugged directory manually."
}

# Main menu
echo "What would you like to do?"
echo "1) Install vim-plug"
echo "2) Remove vim-plug"
echo "3) Exit"
read -rp "Enter your choice [1-3]: " choice

case $choice in
    1)
        install_vim_plug
        ;;
    2)
        remove_vim_plug
        ;;
    3)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
