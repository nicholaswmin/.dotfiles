#!/usr/bin/env zsh
# DO NOT use set -e - we need to capture test failures

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test() {
  local name="$1"
  local command="$2"
  ((TESTS_RUN++))
  
  local output
  local exit_code
  output=$(eval "$command" 2>&1)
  exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    printf "     Command: %s\n" "$command"
    printf "     Output: %s\n" "$output"
    printf "     Exit: %d\n" "$exit_code"
  fi
}

section() {
  printf "\n%s\n-----\n" "$1"
}

setup_test_env() {
  if [[ ! -x "./dotfiles" ]]; then
    chmod +x "./dotfiles" || { printf "ERROR: Failed to make ./dotfiles executable for init command\n"; exit 1; }
  fi

  export DOTFILES_ROOT="$HOME/.dotfiles"
  export DOTFILES_HOME="$HOME/.dotfiles/home"

  ./dotfiles init || { printf "ERROR: 'dotfiles init' command failed\n"; exit 1; }
  
  echo "test content for real home" > "~/.testrc"
}

printf "** dotfiles test suite **\n"
printf "Contents of current directory (repository checkout):\n"
ls -la || true
printf "\n"

if [[ ! -x "./dotfiles" ]]; then
  printf "ERROR: ./dotfiles exists but is not executable\n"
  chmod +x "./dotfiles" || printf "Failed to make executable\n"
fi

if [[ -f "./install.sh" && ! -x "./install.sh" ]]; then
  chmod +x "./install.sh" || printf "Failed to make install.sh executable\n"
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
test "help command works" "./dotfiles --help"
test "version command works" "./dotfiles --version"
test "rejects unknown commands" "! ./dotfiles badcommand"

section "integration (CI only)"
if [[ -n "${IS_ENV_CI}" ]]; then
  printf "     (running integration tests - this involves initializing dotfiles to ~/.dotfiles)\n"
  setup_test_env
  
  test "dotfiles executable is installed" "[[ -x ~/.dotfiles/dotfiles ]]"
  test "link file creates symlink" "~/.dotfiles/dotfiles link ~/.testrc && [[ -L ~/.testrc ]]"
  test "linked file exists in repo" "[[ -f ~/.dotfiles/home/.testrc ]]"
  test "symlink points to repo" "[[ \"$(readlink ~/.testrc)\" == \"~/.dotfiles/home/.testrc\" ]]"
  
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
