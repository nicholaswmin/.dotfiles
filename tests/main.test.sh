#!/bin/bash
echo "=== Dotfiles Generator Core Tests ==="

echo "Checking if dotfiles exists..."
[ -f "dotfiles" ] || { echo "dotfiles missing"; exit 1; }

echo "Checking if install.sh exists..."
[ -f "install.sh" ] || { echo "install.sh missing"; exit 1; }

echo "Checking if README.md exists..."
[ -f "README.md" ] || { echo "README.md missing"; exit 1; }

echo "Checking if _lib directory exists..."
[ -d "_lib" ] || { echo "_lib directory missing"; exit 1; }

echo "Checking if home directory exists..."
[ -d "home" ] || { echo "home directory missing"; exit 1; }

echo "Checking if tests directory exists..."
[ -d "tests" ] || { echo "tests directory missing"; exit 1; }

echo "✓ All tests passed!"
exit 0