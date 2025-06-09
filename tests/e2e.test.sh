#!/bin/bash
# e2e.test.sh - End-to-end CLI tests - SIMPLIFIED

set -e

echo "=== Dotfiles CLI End-to-End Tests ==="
echo

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  echo "✓ PASS: $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo "✗ FAIL: $1 - $2"
  ((TESTS_FAILED++))
}

run_test() {
  local test_name="$1"
  echo -n "Testing: $test_name... "
  ((TESTS_RUN++))
}

# Setup fake environment
FAKE_HOME="/tmp/test-home-$"
FAKE_DOTFILES="/tmp/test-dotfiles-$"

cleanup() {
  rm -rf "$FAKE_HOME" "$FAKE_DOTFILES" 2>/dev/null || true
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

trap cleanup EXIT

mkdir -p "$FAKE_HOME"
echo "# test file" > "$FAKE_HOME/.zshrc"

export HOME="$FAKE_HOME"
export DOTFILES_ROOT="$FAKE_DOTFILES"
export DOTFILES_HOME="$FAKE_DOTFILES/home"

# Create mock git
mkdir -p mock-bin
cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init) mkdir -p .git; exit 0 ;;
  add|commit|remote|rev-parse|clone|pull|push) exit 0 ;;
  *) exit 0 ;;
esac
MOCKEOF
chmod +x mock-bin/git
export PATH="$PWD/mock-bin:$PATH"

# Test 1: Init command
run_test "dotfiles init"
if ./dotfiles init >/dev/null 2>&1; then
  if [[ -d "$FAKE_DOTFILES" ]]; then
    test_pass "init command"
  else
    test_fail "init command" "dotfiles directory not created"
  fi
else
  test_fail "init command" "init command failed"
fi

# Test 2: Help system
run_test "help and version"
if ./dotfiles --help >/dev/null 2>&1 && ./dotfiles --version >/dev/null 2>&1; then
  test_pass "help system"
else
  test_fail "help system" "help or version command failed"
fi

echo
echo "=== Results ==="
echo "Run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All E2E tests passed!"
  exit 0
else
  echo "✗ $TESTS_FAILED E2E test(s) failed!"
  exit 1
fi
