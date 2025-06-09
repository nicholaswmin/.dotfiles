#!/usr/bin/env zsh
# e2e.test.sh - End-to-end CLI functionality tests

readonly TEST_NAME="Dotfiles CLI End-to-End Tests"
readonly TEST_ROOT="/tmp/dotfiles-e2e-$(date +%s)"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

readonly FAKE_HOME="$TEST_ROOT/home"
readonly FAKE_DOTFILES="$TEST_ROOT/.dotfiles"
readonly WORKSPACE="$TEST_ROOT/workspace"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_start() {
  printf "Testing: %s... " "$1"
  ((TESTS_RUN++))
}

test_pass() {
  printf "✓ PASS\n"
  ((TESTS_PASSED++))
}

test_fail() {
  printf "✗ FAIL (%s)\n" "$1"
  ((TESTS_FAILED++))
}

setup_test_environment() {
  mkdir -p "$FAKE_HOME"/.config/{nvim,git}
  mkdir -p "$WORKSPACE"
  
  echo "# Test .zshrc" > "$FAKE_HOME/.zshrc"
  echo "# Test .gitconfig" > "$FAKE_HOME/.gitconfig"
  echo "set number" > "$FAKE_HOME/.config/nvim/init.vim"
  mkdir -p "$FAKE_HOME/.ssh"
  echo "Host *" > "$FAKE_HOME/.ssh/config"
  
  # Check if we have the generated dotfiles structure
  if [[ ! -d "$SCRIPT_DIR/_lib" ]]; then
    printf "ERROR: Generated dotfiles not found. Current directory structure:\n" >&2
    ls -la "$SCRIPT_DIR/" >&2
    printf "Looking for _lib directory in: $SCRIPT_DIR\n" >&2
    exit 1
  fi
  
  cp -r "$SCRIPT_DIR"/* "$WORKSPACE/"
  cd "$WORKSPACE"
  
  export HOME="$FAKE_HOME"
  export DOTFILES_ROOT="$FAKE_DOTFILES"
  export DOTFILES_HOME="$FAKE_DOTFILES/home"
  
  mkdir -p mock-bin
  
  cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init) mkdir -p .git; exit 0 ;;
  add|commit) exit 0 ;;
  remote) exit 0 ;;
  rev-parse) echo "main"; exit 0 ;;
  clone) mkdir -p "$2"; cd "$2"; mkdir -p .git; exit 0 ;;
  pull|push) exit 0 ;;
  *) exit 0 ;;
esac
MOCKEOF
  
  cat > mock-bin/brew << 'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
  
  cat > mock-bin/defaults << 'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
  
  chmod +x mock-bin/*
  export PATH="$PWD/mock-bin:$PATH"
}

cleanup_test_environment() {
  cd /
  rm -rf "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

test_init_command() {
  test_start "dotfiles init"
  
  if ./dotfiles init &>/dev/null; then
    if [[ -d "$FAKE_DOTFILES/.git" && -d "$FAKE_DOTFILES/home" ]]; then
      test_pass
    else
      test_fail "missing .git or home directory"
    fi
  else
    test_fail "init command failed"
  fi
}

test_link_file() {
  test_start "dotfiles link (file)"
  
  local test_file="$FAKE_HOME/.zshrc"
  local repo_file="$FAKE_DOTFILES/home/.zshrc"
  
  if ./dotfiles link "$test_file" &>/dev/null; then
    if [[ -L "$test_file" && -f "$repo_file" ]]; then
      local target="$(readlink "$test_file")"
      if [[ "$target" == "$repo_file" ]]; then
        test_pass
      else
        test_fail "symlink points to wrong target"
      fi
    else
      test_fail "symlink or repo file missing"
    fi
  else
    test_fail "link command failed"
  fi
}

test_help_system() {
  test_start "help system"
  
  local help_output="$(./dotfiles --help 2>/dev/null)"
  local version_output="$(./dotfiles --version 2>/dev/null)"
  
  if [[ -n "$help_output" && -n "$version_output" ]]; then
    test_pass
  else
    test_fail "help or version output empty"
  fi
}

run_all_tests() {
  printf "\n=== %s ===\n\n" "$TEST_NAME"
  
  setup_test_environment
  
  test_init_command
  test_link_file
  test_help_system
  
  cleanup_test_environment
  
  printf "\n=== Results ===\n"
  printf "Run: %d | Passed: %d | Failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "✓ All E2E tests passed!\n"
    exit 0
  else
    printf "✗ %d E2E test(s) failed!\n" "$TESTS_FAILED"
    exit 1
  fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_all_tests
