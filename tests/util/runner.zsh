#!/usr/bin/env zsh
# tests/util/runner.zsh - generic test framework
#
# Usage: source this file then use test functions
#
# Basic test structure:
#   source "$(dirname "$0")/util/runner.zsh"
#   
#   section "file validation"
#   test "config file exists" "file ~/.config/app.conf"
#   test "binary is executable" "executable /usr/bin/app"
#   
#   section "command behavior"
#   test "help command works" "succeeds 'app --help'"
#   test "invalid flag fails" "fails 'app --badarg'"
#   
#   summary "my tests"

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TODO=0

test() {
  local name="$1" command="$2" timeout="${3:-5}"
  
  [[ -n "$name" && -n "$command" ]] || {
    printf "ERROR: test() requires name and command\n" >&2
    return 1
  }
  
  ((TESTS_RUN++))
  
  if command -v timeout >/dev/null 2>&1; then
    if timeout "$timeout" zsh -c "$command" &>/dev/null; then
      printf "✓    %s\n" "$name"
      ((TESTS_PASSED++))
      return 0
    else
      printf "✗    %s\n" "$name"
      ((TESTS_FAILED++))
      return 1
    fi
  else
    if eval "$command" &>/dev/null; then
      printf "✓    %s\n" "$name"
      ((TESTS_PASSED++))
      return 0
    else
      printf "✗    %s\n" "$name"
      ((TESTS_FAILED++))
      return 1
    fi
  fi
}

todo() {
  local name="$1" command="$2"
  
  [[ -n "$name" && -n "$command" ]] || {
    printf "ERROR: todo() requires name and command\n" >&2
    return 1
  }
  
  ((TESTS_RUN++))
  ((TESTS_TODO++))
  
  # Don't execute command for TODO items - just mark as todo
  printf "-    %s (TODO)\n" "$name"
}

section() { 
  [[ -n "$1" ]] || {
    printf "ERROR: section() requires name\n" >&2
    return 1
  }
  printf "\n%s\n-----\n" "$1"
}

summary() {
  local suite="$1"
  [[ -n "$suite" ]] || {
    printf "ERROR: summary() requires suite name\n" >&2
    return 1
  }
  
  printf "\n** %s results **\n" "$suite"
  printf "  tests: %d | passed: %d | failed: %d" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  [[ $TESTS_TODO -gt 0 ]] && printf " | todo: %d" "$TESTS_TODO"
  printf "\n"
  
  if [[ $TESTS_FAILED -eq 0 && $TESTS_RUN -gt 0 ]]; then
    printf "  all passed"
    [[ $TESTS_TODO -gt 0 ]] && printf " (%d todo)" "$TESTS_TODO"
    printf "\n"
  else
    printf "  %d failed" "$TESTS_FAILED"
    [[ $TESTS_TODO -gt 0 ]] && printf " (%d todo)" "$TESTS_TODO"
    printf "\n"
  fi
  
  [[ $TESTS_FAILED -eq 0 ]]
}

reset() { 
  TESTS_RUN=0
  TESTS_PASSED=0
  TESTS_FAILED=0
  TESTS_TODO=0
}

file() { [[ -f "$1" ]]; }
dir() { [[ -d "$1" ]]; }
executable() { [[ -x "$1" ]]; }
symlink() { [[ -L "$1" ]]; }
readable() { [[ -r "$1" ]]; }
writable() { [[ -w "$1" ]]; }

contains() { 
  local command="$1" expected_text="$2"
  [[ -n "$command" && -n "$expected_text" ]] || return 1
  local output="$(eval "$command" 2>/dev/null)"
  [[ "$output" == *"$expected_text"* ]]
}

succeeds() { 
  local command="$1"
  [[ -n "$command" ]] || return 1
  if command -v timeout >/dev/null 2>&1; then
    timeout 5 eval "$command" &>/dev/null
  else
    eval "$command" &>/dev/null
  fi
}

fails() { 
  [[ -n "$1" ]] || return 1
  ! succeeds "$1"
}

ci_only() {
  local test_name="$1"
  [[ -n "$test_name" ]] || {
    printf "ERROR: ci_only() requires test name\n" >&2
    return 1
  }
  
  if [[ -z "$IS_ENV_CI" ]]; then
    printf "\n** %s **\n" "$test_name"
    printf "  skipped (CI only)\n\n"
    return 1
  fi
  return 0
}

temp_dir() {
  local prefix="${1:-test}"
  if command -v mktemp >/dev/null 2>&1; then
    mktemp -d -t "${prefix}-XXXXXX"
  else
    local temp_dir="/tmp/${prefix}-$(date +%s)-$$"
    mkdir -p "$temp_dir"
    echo "$temp_dir"
  fi
}

cleanup_temp() {
  local temp_dir="$1"
  [[ -n "$temp_dir" && -d "$temp_dir" ]] && rm -rf "$temp_dir"
}
