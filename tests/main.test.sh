#!/bin/bash
# main.test.sh - Core functionality tests - SIMPLIFIED

set -e

echo "=== Dotfiles Generator Core Tests ==="
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

# Test 1: Basic file structure
run_test "Generated file structure"
if [[ -f "dotfiles" && -f "install.sh" && -f "README.md" && -d "_lib" && -d "home" && -d "tests" ]]; then
  test_pass "file structure"
else
  test_fail "file structure" "missing required files/directories"
fi

# Test 2: Library files
run_test "Library files exist"
missing_libs=()
for lib in loggers validation init link unlink backup restore; do
  [[ -f "_lib/$lib.sh" ]] || missing_libs+=("$lib.sh")
done

if [[ ${#missing_libs[@]} -eq 0 ]]; then
  test_pass "library files"
else
  test_fail "library files" "missing: ${missing_libs[*]}"
fi

# Test 3: Executable permissions
run_test "Executable permissions"
if [[ -x "dotfiles" && -x "install.sh" ]]; then
  test_pass "executable permissions"
else
  test_fail "executable permissions" "dotfiles or install.sh not executable"
fi

# Test 4: Basic CLI commands
run_test "CLI help system"
if ./dotfiles --help >/dev/null 2>&1 && ./dotfiles --version >/dev/null 2>&1; then
  test_pass "CLI commands"
else
  test_fail "CLI commands" "help or version failed"
fi

# Test 5: GitHub workflow
run_test "GitHub Actions workflow"
if [[ -f ".github/workflows/test.yml" ]]; then
  test_pass "GitHub workflow"
else
  test_fail "GitHub workflow" "workflow file missing"
fi

echo
echo "=== Results ==="
echo "Run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed!"
  exit 1
fi
