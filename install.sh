#!/usr/bin/env bash

set -euo pipefail

# Install dotfiles.
ln -s $HOME/dotfiles/.gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles/.zshrc $HOME/.zshrc

# Install nvim.
ln -s $HOME/dotfiles/nvim $HOME/.config/nvim
