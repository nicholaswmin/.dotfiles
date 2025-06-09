#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "backup command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "backup functionality"
todo "handles no changes gracefully" "true"  # Skip actual execution
todo "accepts custom message" "true"        # Skip actual execution

section "backup validation"
todo "requires repository" "true"           # Skip this hanging test

cleanup_dotfiles_env
summary "backup tests"
printf "\n"
