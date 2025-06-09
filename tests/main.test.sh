#!/usr/bin/env zsh
echo "=== TESTING IN CI ==="
# Override the library path to current directory
export DOTFILES_ROOT="$PWD"
export DOTFILES_HOME="$PWD/home"

./dotfiles --help
./dotfiles --version
./dotfiles init
echo "=== DONE ==="