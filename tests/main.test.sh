#!/usr/bin/env zsh
echo "=== TESTING DOTFILES MANAGER ==="
./dotfiles init
./dotfiles link ~/.zshrc
./dotfiles backup "test"
echo "=== DONE ==="