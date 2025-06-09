#!/usr/bin/env zsh
# tests/dotfiles.test/cli.test.sh - basic CLI tests

source "$(dirname "$0")/../util/runner.zsh"

run_cli_tests() {
  ci_only "cli command tests" || return 0
  
  setup_test_env
  
  section "basic commands"
  test "help command responds" "succeeds './dotfiles --help'"
  test "version command responds" "succeeds './dotfiles --version'"
  test "status command responds" "succeeds './dotfiles status'"
  
  section "help content"
  test "help contains usage" "contains './dotfiles --help' 'usage:'"
  test "help contains commands" "contains './dotfiles --help' 'commands:'"
  test "help contains examples" "contains './dotfiles --help' 'examples:'"
  
  section "version content"  
  test "version shows number" "contains './dotfiles --version' 'dotfiles v'"
  test "version shows platform" "contains './dotfiles --version' 'macOS'"
  
  section "error handling"
  test "rejects unknown commands" "fails './dotfiles nonexistent'"
  test "shows error for unknown commands" "contains './dotfiles badcmd 2>&1' 'error:'"
  test "empty command shows help" "succeeds './dotfiles' && contains './dotfiles 2>&1' 'usage:'"
  
  cleanup_test_env
  summary "cli tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_cli_tests
