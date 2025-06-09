#!/usr/bin/env zsh
# DO NOT use set -e - we need to capture test failures

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test environment
TEST_ROOT="/tmp/dotfiles-test-$$"
FAKE_HOME="$TEST_ROOT/home"
FAKE_REPO="$TEST_ROOT/.dotfiles"

test() {
  local name="$1" 
  local command="$2"
  ((TESTS_RUN++))
  
  # Run command and capture result
  local output
  local exit_code
  output=$(eval "$command" 2>&1) || exit_code=$?
  
  if [[ ${exit_code:-0} -eq 0 ]]; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    printf "     Command: %s\n" "$command"
    printf "     Output: %s\n" "$output"
    printf "     Exit: %d\n" "${exit_code:-0}"
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
  rm -rf "$TEST_ROOT" 2>/dev/null || true
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

printf "** dotfiles test suite **\n"
printf "PWD: %s\n" "$PWD"
printf "Contents:\n"
ls -la || true
printf "\n"

# Verify we're in the right place
if [[ ! -f ./dotfiles ]]; then
  printf "ERROR: Cannot find ./dotfiles - are we in the right directory?\n"
  printf "Looking for dotfiles in: %s\n" "$PWD"
  exit 1
fi

if [[ ! -x ./dotfiles ]]; then
  printf "ERROR: ./dotfiles exists but is not executable\n"
  chmod +x ./dotfiles || printf "Failed to make executable\n"
fi

if [[ -f ./install.sh && ! -x ./install.sh ]]; then
  chmod +x ./install.sh || printf "Failed to make install.sh executable\n"
fi

section "structure"
test "dotfiles executable exists" "[[ -x ./dotfiles ]]"
test "install script exists" "[[ -x ./install.sh ]]"
test "readme exists" "[[ -f ./README.md ]]"
test "gitignore exists" "[[ -f ./.gitignore ]]"
test "lib directory exists" "[[ -d ./_lib ]]"
test "home directory exists" "[[ -d ./home ]]"

section "libraries"
test "loggers library exists" "[[ -f ./_lib/loggers.sh ]]"
test "validation library exists" "[[ -f ./_lib/validation.sh ]]"
test "init library exists" "[[ -f ./_lib/init.sh ]]"
test "link library exists" "[[ -f ./_lib/link.sh ]]"
test "unlink library exists" "[[ -f ./_lib/unlink.sh ]]"
test "backup library exists" "[[ -f ./_lib/backup.sh ]]"
test "restore library exists" "[[ -f ./_lib/restore.sh ]]"

section "syntax"
test "dotfiles syntax valid" "zsh -n ./dotfiles"
test "install script syntax valid" "zsh -n ./install.sh"
test "loggers syntax valid" "zsh -n ./_lib/loggers.sh"
test "validation syntax valid" "zsh -n ./_lib/validation.sh"
test "init syntax valid" "zsh -n ./_lib/init.sh"
test "link syntax valid" "zsh -n ./_lib/link.sh"
test "unlink syntax valid" "zsh -n ./_lib/unlink.sh"
test "backup syntax valid" "zsh -n ./_lib/backup.sh"
test "restore syntax valid" "zsh -n ./_lib/restore.sh"

section "commands"
test "help command works" "./dotfiles --help >/dev/null 2>&1"
test "version command works" "./dotfiles --version >/dev/null 2>&1"
test "rejects unknown commands" "! ./dotfiles badcommand >/dev/null 2>&1"

section "integration (CI only)"
if [[ -n "${IS_ENV_CI}" ]]; then
  # Save original values
  local orig_home="$HOME"
  local orig_path="$PATH"
  
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
  
  # Restore environment
  export HOME="$orig_home"
  export PATH="$orig_path"
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
