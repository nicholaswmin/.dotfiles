#!/usr/bin/env zsh
set -e

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test environment
TEST_ROOT="/tmp/dotfiles-test-$$"
FAKE_HOME="$TEST_ROOT/home"
FAKE_REPO="$TEST_ROOT/.dotfiles"

test() {
  local name="$1" command="$2"
  ((TESTS_RUN++))
  
  local output
  output=$(eval "$command" 2>&1)
  local exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    printf "     Command: %s\n" "$command"
    printf "     Output: %s\n" "$output"
    printf "     Exit: %d\n" "$exit_code"
    ((TESTS_FAILED++))
  fi
}

section() {
  printf "\n%s\n-----\n" "$1"
}

setup_test_env() {
  # Create test directories
  mkdir -p "$FAKE_HOME/.config"
  mkdir -p "$FAKE_REPO/home/.config"
  mkdir -p "$FAKE_REPO/.git"  # Fake git repo
  
  # Create test files
  echo "test content" > "$FAKE_HOME/.testrc"
  echo "git config" > "$FAKE_HOME/.gitconfig"
  
  # Set environment
  export HOME="$FAKE_HOME"
  export DOTFILES_ROOT="$FAKE_REPO"
  export DOTFILES_HOME="$FAKE_REPO/home"
}

cleanup_test_env() {
  rm -rf "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

printf "** dotfiles test suite **\n"

section "structure"
test "dotfiles executable exists" "[[ -x dotfiles ]]"
test "install script exists" "[[ -x install.sh ]]"
test "readme exists" "[[ -f README.md ]]"
test "gitignore exists" "[[ -f .gitignore ]]"
test "lib directory exists" "[[ -d _lib ]]"
test "home directory exists" "[[ -d home ]]"

section "libraries"
test "loggers library exists" "[[ -f _lib/loggers.sh ]]"
test "validation library exists" "[[ -f _lib/validation.sh ]]"
test "init library exists" "[[ -f _lib/init.sh ]]"
test "link library exists" "[[ -f _lib/link.sh ]]"
test "unlink library exists" "[[ -f _lib/unlink.sh ]]"
test "backup library exists" "[[ -f _lib/backup.sh ]]"
test "restore library exists" "[[ -f _lib/restore.sh ]]"

section "syntax"
test "dotfiles syntax valid" "zsh -n dotfiles"
test "install script syntax valid" "zsh -n install.sh"
test "all libraries syntax valid" "for f in _lib/*.sh; do zsh -n \"\$f\"; done"

section "commands"
test "help command works" "./dotfiles --help >/dev/null"
test "version command works" "./dotfiles --version >/dev/null"
test "rejects unknown commands" "! ./dotfiles badcommand 2>/dev/null"

section "integration (CI only)"
if [[ -n "${IS_ENV_CI}" ]]; then
  setup_test_env
  
  # Mock git for safe testing
  mkdir -p "$TEST_ROOT/mock-bin"
  cat > "$TEST_ROOT/mock-bin/git" << 'GITEOF'
#!/bin/bash
case "$1" in
  add|rm) exit 0 ;;
  init) mkdir -p .git; exit 0 ;;
  *) exit 0 ;;
esac
GITEOF
  chmod +x "$TEST_ROOT/mock-bin/git"
  export PATH="$TEST_ROOT/mock-bin:$PATH"
  
  test "link file creates symlink" "./dotfiles link $FAKE_HOME/.testrc >/dev/null 2>&1 && [[ -L $FAKE_HOME/.testrc ]]"
  test "linked file exists in repo" "[[ -f $FAKE_REPO/home/.testrc ]]"
  test "symlink points to repo" "[[ \"\$(readlink $FAKE_HOME/.testrc)\" == \"$FAKE_REPO/home/.testrc\" ]]"
  
  cleanup_test_env
else
  printf "     (skipping - set IS_ENV_CI=true to run)\n"
fi

printf "\n** results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  printf "  ✓ all tests passed\n"
  exit 0
else
  printf "  ✗ %d tests failed\n" "$TESTS_FAILED"
  exit 1
fi
