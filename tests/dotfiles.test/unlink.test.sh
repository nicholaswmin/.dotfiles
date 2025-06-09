#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "unlink command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null
./dotfiles link "$FAKE_HOME/.zshrc" &>/dev/null

section "unlink files"
test "unlinks managed file" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc' && file '\$FAKE_HOME/.zshrc' && ! symlink '\$FAKE_HOME/.zshrc'"
test "rejects non-managed files" "echo 'test' > '\$FAKE_HOME/regular' && fails './dotfiles unlink \$FAKE_HOME/regular'"
test "cleans up empty directories" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc'"

cleanup_dotfiles_env
summary "unlink tests"
printf "\n"
