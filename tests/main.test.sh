#!/usr/bin/env zsh
echo "=== DOTFILES TESTS ==="

./dotfiles --help >/dev/null && echo "✓ help works"
./dotfiles --version >/dev/null && echo "✓ version works"

echo "Testing link..."
TEST_HOME="/tmp/test-$$"
mkdir -p "$TEST_HOME"
echo "test" > "$TEST_HOME/.testrc"

echo "About to run link command..."
DOTFILES_ROOT="/tmp/repo-$$" \
DOTFILES_HOME="/tmp/repo-$$/home" \
HOME="$TEST_HOME" \
./dotfiles link "$TEST_HOME/.testrc"
echo "Link command finished"

rm -rf "$TEST_HOME" "/tmp/repo-$$"
echo "=== DONE ==="
