#!/usr/bin/env zsh
# tests/util/runner.zsh - generic test framework

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TODO=0

# FIX: Replaced original test function with a version that has a built-in, dependency-free timeout.
test() {
  local name="$1" command="$2" timeout_duration="${3:-5}"
  local pid
  local exit_code=0

  [[ -n "$name" && -n "$command" ]] || {
    printf "ERROR: test() requires name and command\n" >&2
    return 1
  }

  ((TESTS_RUN++))

  eval "$command" &>/dev/null &
  pid=$!

  (
    sleep "$timeout_duration"
    if ps -p $pid > /dev/null; then
      kill -9 $pid 2>/dev/null
    fi
  ) &
  local watcher_pid=$!

  wait $pid 2>/dev/null
  exit_code=$?

  kill -9 $watcher_pid 2>/dev/null &>/dev/null

  if [[ $exit_code -eq 0 ]]; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
    return 0
  else
    printf "✗    %s\n" "$name"
    ((TESTS_FAILED++))
    return 1
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

# FIX: Replaced original succeeds function with a version that has a built-in, dependency-free timeout.
succeeds() {
  local command="$1"
  local pid
  local exit_code=0

  [[ -n "$command" ]] || return 1

  eval "$command" &>/dev/null &
  pid=$!

  ( sleep 5; if ps -p $pid > /dev/null; then kill -9 $pid 2>/dev/null; fi ) &
  local watcher_pid=$!

  wait $pid 2>/dev/null
  exit_code=$?

  kill -9 $watcher_pid 2>/dev/null &>/dev/null
  
  return $exit_code
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