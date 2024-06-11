#!/usr/bin/env bash

set -euo pipefail

# Install dotfiles.
ln -s $HOME/dotfiles/.gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles/.zshrc $HOME/.zshrc
ln -s $HOME/dotfiles/.tmux.conf $HOME/.config/tmux/tmux.conf

# Install nvim.
ln -s $HOME/dotfiles/nvim $HOME/.config/nvim
