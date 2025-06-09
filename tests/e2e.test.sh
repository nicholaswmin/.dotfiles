#!/bin/bash
echo "=== Dotfiles CLI End-to-End Tests ==="

echo "Running ./dotfiles --help..."
./dotfiles --help >/dev/null 2>&1 || { echo "--help failed"; exit 1; }

echo "Running ./dotfiles --version..."
./dotfiles --version >/dev/null 2>&1 || { echo "--version failed"; exit 1; }

echo "✓ All E2E tests passed!"
exit 0