#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "link command tests" || exit 0
setup_test_env
./dotfiles init &>/dev/null

section "link files"
test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"

cleanup_test_env
summary "link tests"
