#!/usr/bin/env zsh
# cleanup-tests.sh - Delete junk and create proper test

set -e

# Delete the entire tests folder
echo "Deleting tests folder..."
rm -rf tests

# Create new tests directory
echo "Creating new tests directory..."
mkdir -p tests

# Create proper main.test.sh
echo "Creating tests/main.test.sh..."
cat > tests/main.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

section "commands"
test "help command works" "./dotfiles --help"
test "version command works" "./dotfiles --version"
test "rejects unknown commands" "! ./dotfiles badcommand"

printf "\n** results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  printf "  all tests passed\n"
  exit 0
else
  printf "  %d tests failed\n" "$TESTS_FAILED"
  exit 1
fi
EOF

chmod +x tests/main.test.sh

echo "✓ Cleaned up tests and created tests/main.test.sh"
echo "✓ Run with: ./tests/main.test.sh"