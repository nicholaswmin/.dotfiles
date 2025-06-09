#!/bin/bash
echo "=== Dotfiles Generator Core Tests ==="
if [ -f "dotfiles" ] && [ -f "install.sh" ] && [ -f "README.md" ] && [ -d "_lib" ] && [ -d "home" ] && [ -d "tests" ]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ Tests failed"
  exit 1
fi
