#!/usr/bin/env zsh
# main.test.sh - Core functionality tests for dotfiles generator with debug output

readonly TEST_NAME="Dotfiles Generator Core Tests"
readonly TEST_DIR="/tmp/dotfiles-test-$(date +%s)"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_start() {
  local test_name="$1"
  printf "Testing: %s... " "$test_name"
  ((TESTS_RUN++))
}

test_pass() {
  printf "✓ PASS\n"
  ((TESTS_PASSED++))
}

test_fail() {
  local reason="$1"
  printf "✗ FAIL"
  [[ -n "$reason" ]] && printf " ($reason)"
  printf "\n"
  ((TESTS_FAILED++))
}

setup_test_environment() {
  mkdir -p "$TEST_DIR" || {
    echo "ERROR: Failed to create test directory: $TEST_DIR"
    exit 1
  }
  
  cd "$TEST_DIR" || {
    echo "ERROR: Failed to change to test directory"
    exit 1
  }
  
  if [[ -f "$SCRIPT_DIR/../make.zsh" ]]; then
    cp "$SCRIPT_DIR/../make.zsh" . || {
      echo "ERROR: Failed to copy make.zsh"
      exit 1
    }
    chmod +x make.zsh
  else
    echo "ERROR: Cannot find make.zsh in parent directory"
    exit 1
  fi
}

cleanup_test_environment() {
  cd /
  rm -rf "$TEST_DIR"
}

test_generator_execution() {
  test_start "Generator execution"
  
  if ./make.zsh &>/dev/null; then
    test_pass
  else
    test_fail "Generator script failed"
  fi
}

test_file_structure() {
  test_start "Generated file structure"
  
  local required=(
    "dotfiles:file"
    "install.sh:file"
    "README.md:file"
    ".gitignore:file"
    "_lib:dir"
    "home:dir"
    "tests:dir"
    ".github:dir"
  )
  
  local missing=()
  
  for item in "${required[@]}"; do
    local path="${item%:*}"
    local type="${item#*:}"
    
    if [[ "$type" == "file" && ! -f "$path" ]]; then
      missing+=("$path")
    elif [[ "$type" == "dir" && ! -d "$path" ]]; then
      missing+=("$path")
    fi
  done
  
  if [[ ${#missing[@]} -eq 0 ]]; then
    test_pass
  else
    test_fail "Missing: ${missing[*]}"
  fi
}

test_library_files() {
  test_start "Library files"
  
  local libs=( loggers validation init link unlink backup restore )
  local missing=()
  
  for lib in "${libs[@]}"; do
    [[ -f "_lib/$lib.sh" ]] || missing+=("$lib.sh")
  done
  
  if [[ ${#missing[@]} -eq 0 ]]; then
    test_pass
  else
    test_fail "Missing: ${missing[*]}"
  fi
}

test_executable_permissions() {
  test_start "Executable permissions"
  
  if [[ -x "dotfiles" && -x "install.sh" ]]; then
    test_pass
  else
    test_fail "Missing execute permissions"
  fi
}

test_basic_commands() {
  test_start "Basic CLI commands"
  
  if ./dotfiles --help &>/dev/null && ./dotfiles --version &>/dev/null; then
    test_pass
  else
    test_fail "Help or version failed"
  fi
}

test_github_workflow() {
  test_start "GitHub Actions workflow"
  
  if [[ -f ".github/workflows/test.yml" ]]; then
    test_pass
  else
    test_fail "GitHub workflow missing"
  fi
}

run_all_tests() {
  printf "\n=== %s ===\n\n" "$TEST_NAME"
  
  setup_test_environment
  test_generator_execution
  test_file_structure
  test_library_files
  test_executable_permissions
  test_basic_commands
  test_github_workflow
  cleanup_test_environment
  
  printf "\n=== Results ===\n"
  printf "Run: %d | Passed: %d | Failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "✓ All tests passed!\n"
    exit 0
  else
    printf "✗ %d test(s) failed!\n" "$TESTS_FAILED"
    exit 1
  fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_all_tests
