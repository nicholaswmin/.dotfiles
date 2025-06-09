#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "cli command tests" || exit 0
setup_dotfiles_env

section "basic commands"
test "help command responds" "succeeds './dotfiles --help'"
test "version command responds" "succeeds './dotfiles --version'"

section "help content"
test "help contains usage" "contains './dotfiles --help' 'usage:'"
test "help contains commands" "contains './dotfiles --help' 'commands:'"

section "error handling"
test "rejects unknown commands" "fails './dotfiles nonexistent'"
test "requires repo for link" "fails './dotfiles link ~/.zshrc'"
test "requires repo for unlink" "fails './dotfiles unlink ~/.zshrc'"
test "requires repo for backup" "fails './dotfiles backup'"

cleanup_dotfiles_env
summary "cli tests"
printf "\n"
