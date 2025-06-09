#!/usr/bin/env zsh
echo "PWD: $PWD"
echo "Starting link test..."
mkdir -p /tmp/testfile
echo "test" > /tmp/testfile/.test
./dotfiles link /tmp/testfile/.test
echo "Link finished"