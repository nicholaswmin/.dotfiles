#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "init command tests" || exit 0
setup_dotfiles_env

section "init command"
test "creates git repository" "succeeds './dotfiles init' && dotfiles_repo_exists"
test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
test "fails when already exists" "fails './dotfiles init'"

cleanup_dotfiles_env
summary "init tests"
printf "\n"
