#!/usr/bin/env zsh
# tests/dotfiles.test/unlink.test.sh - unlink command tests

source "$(dirname "$0")/../util/runner.zsh"

run_unlink_tests() {
  ci_only "unlink command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "unlink files"
  # Setup: link a file first
  ./dotfiles link "$FAKE_HOME/.zshrc" &>/dev/null
  test "unlinks managed file" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc' && file '\$FAKE_HOME/.zshrc' && ! symlink '\$FAKE_HOME/.zshrc'"
  
  # Setup: link and unlink directory
  ./dotfiles link "$FAKE_HOME/.ssh" &>/dev/null
  test "unlinks managed directory" "succeeds './dotfiles unlink \$FAKE_HOME/.ssh' && dir '\$FAKE_HOME/.ssh' && ! symlink '\$FAKE_HOME/.ssh'"
  
  section "unlink validation"
  test "rejects non-managed files" "echo 'test' > '\$FAKE_HOME/regular' && fails './dotfiles unlink \$FAKE_HOME/regular'"
  test "rejects nonexistent paths" "fails './dotfiles unlink /nonexistent'"
  
  section "unlink requirements"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles unlink \$FAKE_HOME/.zshrc'"
  test "requires path argument" "fails './dotfiles unlink'"
  
  cleanup_test_env
  summary "unlink tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_unlink_tests
