#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "cli command tests" || exit 0
setup_test_env

section "basic commands"
test "help command responds" "succeeds './dotfiles --help'"
test "version command responds" "succeeds './dotfiles --version'"
test "status command responds" "succeeds './dotfiles status'"

section "help content"
test "help contains usage" "contains './dotfiles --help' 'usage:'"
test "help contains commands" "contains './dotfiles --help' 'commands:'"

section "error handling"
test "rejects unknown commands" "fails './dotfiles nonexistent'"

cleanup_test_env
summary "cli tests"
