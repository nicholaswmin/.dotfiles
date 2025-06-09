#!/usr/bin/env zsh
# e2e.test.sh - End-to-end CLI functionality tests

readonly TEST_NAME="Dotfiles CLI End-to-End Tests"
readonly TEST_ROOT="/tmp/dotfiles-e2e-$(date +%s)"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Test environment paths
readonly FAKE_HOME="$TEST_ROOT/home"
readonly FAKE_DOTFILES="$TEST_ROOT/.dotfiles"
readonly WORKSPACE="$TEST_ROOT/workspace"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Test Framework
# =============================================================================

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

# =============================================================================
# Environment Setup
# =============================================================================

setup_test_environment() {
  # Create isolated environment
  mkdir -p "$FAKE_HOME"/.config/{nvim,git}
  mkdir -p "$WORKSPACE"
  
  # Create fake config files
  echo "# Test .zshrc" > "$FAKE_HOME/.zshrc"
  echo "# Test .gitconfig" > "$FAKE_HOME/.gitconfig"
  echo "set number" > "$FAKE_HOME/.config/nvim/init.vim"
  mkdir -p "$FAKE_HOME/.ssh"
  echo "Host *" > "$FAKE_HOME/.ssh/config"
  
  # Copy generated dotfiles tool
  cp -r "$SCRIPT_DIR"/* "$WORKSPACE/"
  cd "$WORKSPACE"
  
  # Override environment for safe testing
  export HOME="$FAKE_HOME"
  export DOTFILES_ROOT="$FAKE_DOTFILES"
  export DOTFILES_HOME="$FAKE_DOTFILES/home"
  
  # Create mock commands for system integration
  mkdir -p mock-bin
  
  # Mock git - log operations but don't fail
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
  
  # Mock brew - just acknowledge commands
  cat > mock-bin/brew << 'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
  
  # Mock defaults - acknowledge macOS commands
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

# =============================================================================
# CLI Tests
# =============================================================================

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

test_link_directory() {
  test_start "dotfiles link (directory)"
  
  local test_dir="$FAKE_HOME/.ssh"
  local repo_dir="$FAKE_DOTFILES/home/.ssh"
  
  if ./dotfiles link "$test_dir" &>/dev/null; then
    if [[ -L "$test_dir" && -d "$repo_dir" && -f "$repo_dir/config" ]]; then
      test_pass
    else
      test_fail "directory link failed"
    fi
  else
    test_fail "link directory command failed"
  fi
}

test_unlink_file() {
  test_start "dotfiles unlink"
  
  # Link then unlink .gitconfig
  local test_file="$FAKE_HOME/.gitconfig"
  ./dotfiles link "$test_file" &>/dev/null
  
  if ./dotfiles unlink "$test_file" &>/dev/null; then
    if [[ -f "$test_file" && ! -L "$test_file" ]]; then
      test_pass
    else
      test_fail "file not restored properly"
    fi
  else
    test_fail "unlink command failed"
  fi
}

test_backup_no_remote() {
  test_start "dotfiles backup (no remote)"
  
  # Should handle gracefully when no remote configured
  if ./dotfiles backup "test" &>/dev/null; then
    test_fail "should fail without remote"
  else
    test_pass
  fi
}

test_error_handling() {
  test_start "error handling"
  
  # Test nonexistent file
  if ./dotfiles link "/nonexistent/file" &>/dev/null; then
    test_fail "should reject nonexistent files"
  elif ./dotfiles unknown-command &>/dev/null; then
    test_fail "should reject unknown commands"
  else
    test_pass
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

test_install_script() {
  test_start "install script execution"
  
  # Should run without errors in mocked environment
  if source ./install.sh &>/dev/null; then
    test_pass
  else
    test_fail "install script failed"
  fi
}

test_workflow_integration() {
  test_start "complete workflow"
  
  # Clean slate
  rm -rf "$FAKE_DOTFILES"
  
  # Full workflow: init → link → backup attempt
  if ./dotfiles init &>/dev/null &&
     ./dotfiles link "$FAKE_HOME/.config/nvim" &>/dev/null &&
     [[ -L "$FAKE_HOME/.config/nvim" ]]; then
    test_pass
  else
    test_fail "workflow integration failed"
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

run_all_tests() {
  printf "\n=== %s ===\n\n" "$TEST_NAME"
  
  setup_test_environment
  
  # Core CLI functionality
  test_init_command
  test_link_file
  test_link_directory
  test_unlink_file
  
  # System integration
  test_backup_no_remote
  test_error_handling
  test_help_system
  test_install_script
  
  # Workflow
  test_workflow_integration
  
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
