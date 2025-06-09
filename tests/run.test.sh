#!/usr/bin/env zsh
# tests/run.test.sh - main test runner

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/util/runner.zsh"

run_all_tests() {
  printf "** dotfiles test suite **\n"
  
  local total_tests=0 total_passed=0 total_failed=0
  local suite_results=()
  
  # Always run main tests (safe locally)
  printf "\n"
  if source "$SCRIPT_DIR/main.test.sh"; then
    suite_results+=("main:✓")
  else
    suite_results+=("main:✗")
  fi
  total_tests=$((total_tests + TESTS_RUN))
  total_passed=$((total_passed + TESTS_PASSED))
  total_failed=$((total_failed + TESTS_FAILED))
  
  # Run CLI tests (CI only)
  if [[ -n "$IS_ENV_CI" ]]; then
    for test_file in "$SCRIPT_DIR"/dotfiles.test/*.test.sh; do
      if [[ -f "$test_file" ]]; then
        local test_name="$(basename "$test_file" .test.sh)"
        reset
        printf "\n"
        if source "$test_file"; then
          suite_results+=("$test_name:✓")
        else
          suite_results+=("$test_name:✗")
        fi
        total_tests=$((total_tests + TESTS_RUN))
        total_passed=$((total_passed + TESTS_PASSED))
        total_failed=$((total_failed + TESTS_FAILED))
      fi
    done
  else
    printf "\n** dotfiles command tests **\n"
    printf "  skipped (CI only)\n"
  fi
  
  # Final summary
  printf "\n** final results **\n"
  printf "  total tests: %d | passed: %d | failed: %d\n" "$total_tests" "$total_passed" "$total_failed"
  
  printf "  suite results: "
  for result in "${suite_results[@]}"; do
    printf "%s " "$result"
  done
  printf "\n"
  
  if [[ $total_failed -eq 0 && $total_tests -gt 0 ]]; then
    printf "  ✓ all test suites passed\n"
    exit 0
  else
    printf "  ✗ %d test(s) failed\n" "$total_failed"
    exit 1
  fi
}

run_all_tests
