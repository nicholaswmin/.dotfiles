#!/usr/bin/env zsh
echo "=== DOTFILES TESTS ==="

./dotfiles --help >/dev/null && echo "✓ help works"
./dotfiles --version >/dev/null && echo "✓ version works"

# Test link
TEST_HOME="/tmp/test-$$"
mkdir -p "$TEST_HOME"
echo "test" > "$TEST_HOME/.testrc"

DOTFILES_ROOT="/tmp/repo-$$" \
DOTFILES_HOME="/tmp/repo-$$/home" \
HOME="$TEST_HOME" \
./dotfiles link "$TEST_HOME/.testrc" >/dev/null 2>&1 && echo "✓ link works"

rm -rf "$TEST_HOME" "/tmp/repo-$$"
echo "=== DONE ==="
