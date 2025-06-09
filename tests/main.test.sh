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
  mkdir -p "~/.dotfiles/home" || { printf "ERROR: Failed to create %s\n" "~/.dotfiles/home"; exit 1; }

  echo "test content for real home" > "~/.testrc"

  if [[ ! -d "~/.dotfiles/.git" ]]; then
    git init "~/.dotfiles" || { printf "ERROR: Failed to git init real repo in %s\n" "~/.dotfiles"; exit 1; }
  fi
  git config --global --add safe.directory "~/.dotfiles"

  git --git-dir="~/.dotfiles/.git" --work-tree="~/.dotfiles" add --all && \
  git --git-dir="~/.dotfiles/.git" --work-tree="~/.dotfiles" commit -m "Initial commit for test setup" --allow-empty || { printf "ERROR: Git setup in %s failed\n" "~/.dotfiles"; exit 1; }
}

printf "** dotfiles test suite **\n"
printf "Contents of current directory:\n"
ls -la || true
printf "\n"

if [[ ! -f "~/.dotfiles/dotfiles" ]]; then
  printf "ERROR: Cannot find ~/.dotfiles/dotfiles. Ensure your CI environment checks out the repository directly into ~/.dotfiles.\n"
  exit 1
fi

if [[ ! -x "~/.dotfiles/dotfiles" ]]; then
  printf "ERROR: ~/.dotfiles/dotfiles exists but is not executable\n"
  chmod +x "~/.dotfiles/dotfiles" || printf "Failed to make executable\n"
fi

if [[ -f "~/.dotfiles/install.sh" && ! -x "~/.dotfiles/install.sh" ]]; then
  chmod +x "~/.dotfiles/install.sh" || printf "Failed to make install.sh executable\n"
fi

section "structure"
test "dotfiles executable exists" "[[ -x ~/.dotfiles/dotfiles ]]"
test "install script exists" "[[ -x ~/.dotfiles/install.sh ]]"
test "readme exists" "[[ -f ~/.dotfiles/README.md ]]"
test "gitignore exists" "[[ -f ~/.dotfiles/.gitignore ]]"
test "lib directory exists" "[[ -d ~/.dotfiles/_lib ]]"
test "home directory exists" "[[ -d ~/.dotfiles/home ]]"

section "libraries"
test "loggers library exists" "[[ -f ~/.dotfiles/_lib/loggers.sh ]]"
test "validation library exists" "[[ -f ~/.dotfiles/_lib/validation.sh ]]"
test "init library exists" "[[ -f ~/.dotfiles/_lib/init.sh ]]"
test "link library exists" "[[ -f ~/.dotfiles/_lib/link.sh ]]"
test "unlink library exists" "[[ -f ~/.dotfiles/_lib/unlink.sh ]]"
test "backup library exists" "[[ -f ~/.dotfiles/_lib/backup.sh ]]"
test "restore library exists" "[[ -f ~/.dotfiles/_lib/restore.sh ]]"

section "syntax"
test "dotfiles syntax valid" "zsh -n ~/.dotfiles/dotfiles"
test "install script syntax valid" "zsh -n ~/.dotfiles/install.sh"
test "loggers syntax valid" "zsh -n ~/.dotfiles/_lib/loggers.sh"
test "validation syntax valid" "zsh -n ~/.dotfiles/_lib/validation.sh"
test "init syntax valid" "zsh -n ~/.dotfiles/_lib/init.sh"
test "link syntax valid" "zsh -n ~/.dotfiles/_lib/link.sh"
test "unlink syntax valid" "zsh -n ~/.dotfiles/_lib/unlink.sh"
test "backup syntax valid" "zsh -n ~/.dotfiles/_lib/backup.sh"
test "restore syntax valid" "zsh -n ~/.dotfiles/_lib/restore.sh"

section "commands"
test "help command works" "~/.dotfiles/dotfiles --help"
test "version command works" "~/.dotfiles/dotfiles --version"
test "rejects unknown commands" "! ~/.dotfiles/dotfiles badcommand"

section "integration (CI only)"
if [[ -n "${IS_ENV_CI}" ]]; then
  setup_test_env
  
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
