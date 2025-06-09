#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "backup command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "backup functionality (TODO)"
todo "handles no changes" "succeeds './dotfiles backup'"
todo "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"
todo "works with linked files" "./dotfiles link '\$FAKE_HOME/.zshrc' &>/dev/null && succeeds './dotfiles backup \"added zshrc\"'"

section "backup validation"
test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles backup'"

cleanup_dotfiles_env
summary "backup tests"
printf "\n"
