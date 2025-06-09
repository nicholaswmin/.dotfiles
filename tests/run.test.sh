#!/usr/bin/env zsh
# tests/run.test.sh - ACTUAL COMMAND TESTING

printf "** dotfiles test suite **\n"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test() {
  local name="$1" command="$2"
  ((TESTS_RUN++))
  if eval "$command" &>/dev/null; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    ((TESTS_FAILED++))
  fi
}

section() { printf "\n%s\n-----\n" "$1"; }

# File structure tests
section "structure"
test "dotfiles executable exists" "[[ -x dotfiles ]]"
test "install script exists" "[[ -x install.sh ]]"
test "all libraries exist" "[[ -f _lib/loggers.sh && -f _lib/init.sh && -f _lib/link.sh ]]"

# ACTUAL CLI COMMAND TESTS
section "cli commands"
test "help command works" "./dotfiles --help"
test "version command works" "./dotfiles --version"
test "rejects unknown commands" "! ./dotfiles badcommand"

# Skip CI-only tests if not in CI
if [[ -n "$IS_ENV_CI" ]]; then
  section "command functionality"
  
  # Setup test environment
  export TEST_HOME="/tmp/test-home-$$"
  export DOTFILES_ROOT="/tmp/test-dotfiles-$$"
  export DOTFILES_HOME="$DOTFILES_ROOT/home"
  mkdir -p "$TEST_HOME" "$DOTFILES_ROOT"
  echo "test config" > "$TEST_HOME/.testrc"
  
  # Mock git
  export PATH="/tmp/mock-git-$$:$PATH"
  mkdir -p "/tmp/mock-git-$$"
  echo '#!/bin/bash
case "$1" in
  init|add|commit|remote|push|pull) exit 0 ;;
  *) exit 0 ;;
esac' > "/tmp/mock-git-$$/git"
  chmod +x "/tmp/mock-git-$$/git"
  
  # Test commands
  test "init creates repository" "cd '$DOTFILES_ROOT' && '$PWD/dotfiles' init"
  test "link works with files" "cd '$DOTFILES_ROOT' && HOME='$TEST_HOME' '$PWD/dotfiles' link '$TEST_HOME/.testrc'"
  test "backup command runs" "cd '$DOTFILES_ROOT' && '$PWD/dotfiles' backup 'test commit'"
  
  # Cleanup
  rm -rf "$TEST_HOME" "$DOTFILES_ROOT" "/tmp/mock-git-$$"
  unset TEST_HOME DOTFILES_ROOT DOTFILES_HOME
else
  printf "\n** command functionality **\n"
  printf "  skipped (CI only)\n"
fi

printf "\n** results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1