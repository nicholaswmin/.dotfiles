#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "backup command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "backup functionality"
test "handles no changes gracefully" "succeeds './dotfiles backup'"
test "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"

section "backup validation"
test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles backup'"

cleanup_dotfiles_env
summary "backup tests"
printf "\n"
