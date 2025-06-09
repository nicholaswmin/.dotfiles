#!/usr/bin/env zsh
echo "=== DOTFILES TESTS ==="

./dotfiles --help >/dev/null && echo "✓ help works"
./dotfiles --version >/dev/null && echo "✓ version works"

# Test link without moving around
TEST_ROOT="/tmp/dotfiles-test-$$"
mkdir -p "$TEST_ROOT"/{repo,home}
cp dotfiles "$TEST_ROOT/repo/"
cp -r _lib "$TEST_ROOT/repo/"
echo "test" > "$TEST_ROOT/home/.testrc"

DOTFILES_ROOT="$TEST_ROOT/repo" \
DOTFILES_HOME="$TEST_ROOT/repo/home" \
HOME="$TEST_ROOT/home" \
"$TEST_ROOT/repo/dotfiles" link "$TEST_ROOT/home/.testrc" >/dev/null 2>&1 && echo "✓ link works"

rm -rf "$TEST_ROOT"
echo "=== DONE ==="