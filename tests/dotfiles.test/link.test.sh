#!/usr/bin/env zsh
# tests/dotfiles.test/link.test.sh - link command tests

source "$(dirname "$0")/../util/runner.zsh"

run_link_tests() {
  ci_only "link command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "link files"
  test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
  test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
  test "links directory" "succeeds './dotfiles link \$FAKE_HOME/.ssh' && symlink '\$FAKE_HOME/.ssh'"
  test "handles nested paths" "succeeds './dotfiles link \$FAKE_HOME/.config/nvim/init.vim' && symlink '\$FAKE_HOME/.config/nvim/init.vim'"
  
  section "link validation"
  test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"
  test "rejects paths outside home" "fails './dotfiles link /etc/hosts'"
  test "handles already linked" "succeeds './dotfiles link \$FAKE_HOME/.gitconfig' && succeeds './dotfiles link \$FAKE_HOME/.gitconfig'"
  
  section "link requirements"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles link \$FAKE_HOME/.zshrc'"
  test "requires path argument" "fails './dotfiles link'"
  
  cleanup_test_env
  summary "link tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_link_tests
