#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "init command tests" || exit 0
setup_test_env

section "init command"
test "creates git repository" "succeeds './dotfiles init' && dir '$FAKE_DOTFILES/.git'"
test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
test "fails when already exists" "fails './dotfiles init'"

cleanup_test_env
summary "init tests"
