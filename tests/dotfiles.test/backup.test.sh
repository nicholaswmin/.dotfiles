#!/usr/bin/env zsh
# tests/dotfiles.test/backup.test.sh - backup command tests

source "$(dirname "$0")/../util/runner.zsh"

run_backup_tests() {
  ci_only "backup command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "backup functionality"
  test "handles no changes" "succeeds './dotfiles backup'"
  test "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"
  test "works with linked files" "./dotfiles link '\$FAKE_HOME/.zshrc' &>/dev/null && succeeds './dotfiles backup \"added zshrc\"'"
  
  section "backup validation"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles backup'"
  
  cleanup_test_env
  summary "backup tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_backup_tests
