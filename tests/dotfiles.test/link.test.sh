#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "link command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "link files"
test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"
test "handles already managed files" "succeeds './dotfiles link \$FAKE_HOME/.zshrc'"

section "link directories"
test "links directory" "succeeds './dotfiles link \$FAKE_HOME/.ssh' && symlink '\$FAKE_HOME/.ssh'"
test "preserves directory contents" "file '\$FAKE_DOTFILES/home/.ssh/config'"

cleanup_dotfiles_env
summary "link tests"
printf "\n"
