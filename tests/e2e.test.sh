#!/bin/bash
echo "=== Dotfiles CLI End-to-End Tests ==="
if ./dotfiles --help >/dev/null 2>&1 && ./dotfiles --version >/dev/null 2>&1; then
  echo "✓ All E2E tests passed!"
  exit 0
else
  echo "✗ E2E tests failed"
  exit 1
fi
