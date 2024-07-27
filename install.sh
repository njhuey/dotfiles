#!/usr/bin/env bash

set -euo pipefail

# Install dotfiles.
ln -s $HOME/.dotfiles/gitconfig $HOME/.config/git/config
ln -s $HOME/.dotfiles/zshrc $HOME/.zshrc
ln -s $HOME/.dotfiles/tmux.conf $HOME/.config/tmux/tmux.conf
ln -s $HOME/.dotfiles/kitty.conf $HOME/.config/kitty/kitty.conf

# Install nvim.
ln -s $HOME/.dotfiles/nvim $HOME/.config/nvim
