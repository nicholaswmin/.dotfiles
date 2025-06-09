#!/bin/bash
echo "=== Dotfiles CLI End-to-End Tests ==="

if [[ -z "$IS_ENV_CI" ]]; then
  echo "e2e tests only run on CI to avoid mangling your HOME/PATH. Skipping..." >&2
else
  echo "Running ./dotfiles --help..."
  ./dotfiles --help >/dev/null 2>&1 || { echo "--help failed"; exit 1; }

  echo "Running ./dotfiles --version..."
  ./dotfiles --version >/dev/null 2>&1 || { echo "--version failed"; exit 1; }

  echo "✓ All E2E tests passed!"
fi

exit 0