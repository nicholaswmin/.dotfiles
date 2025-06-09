#!/usr/bin/env zsh
# tests/dotfiles.test/init.test.sh - init command tests

source "$(dirname "$0")/../util/runner.zsh"

run_init_tests() {
  ci_only "init command tests" || return 0
  
  setup_test_env
  
  section "init command"
  test "creates git repository" "succeeds './dotfiles init' && dir '$FAKE_DOTFILES/.git'"
  test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
  test "creates install script" "file '$FAKE_DOTFILES/install.sh'"
  test "fails when already exists" "fails './dotfiles init'"
  
  cleanup_test_env
  summary "init tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_init_tests
