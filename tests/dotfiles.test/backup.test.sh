#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "backup command tests" || exit 0
setup_test_env
./dotfiles init &>/dev/null

section "backup functionality"
test "handles no changes" "succeeds './dotfiles backup'"
test "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"

cleanup_test_env
summary "backup tests"
