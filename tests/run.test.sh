#!/usr/bin/env zsh
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/util/runner.zsh"

printf "** dotfiles test suite **\n"

local total_tests=0 total_passed=0 total_failed=0 total_todo=0
local suite_results=()

# Main tests (always run)
reset
if source "$SCRIPT_DIR/main.test.sh"; then
  suite_results+=("main:✓")
else
  suite_results+=("main:✗")
fi
total_tests=$((total_tests + TESTS_RUN))
total_passed=$((total_passed + TESTS_PASSED))
total_failed=$((total_failed + TESTS_FAILED))
total_todo=$((total_todo + TESTS_TODO))

# CLI tests (CI only)
if [[ -n "$IS_ENV_CI" ]]; then
  for test_file in "$SCRIPT_DIR"/dotfiles.test/*.test.sh; do
    if [[ -f "$test_file" ]]; then
      local test_name="$(basename "$test_file" .test.sh)"
      reset
      if source "$test_file"; then
        suite_results+=("$test_name:✓")
      else
        suite_results+=("$test_name:✗")
      fi
      total_tests=$((total_tests + TESTS_RUN))
      total_passed=$((total_passed + TESTS_PASSED))
      total_failed=$((total_failed + TESTS_FAILED))
      total_todo=$((total_todo + TESTS_TODO))
    fi
  done
else
  printf "\n** dotfiles command tests **\n"
  printf "  skipped (CI only)\n\n"
fi

# Final summary
printf "** final results **\n"
printf "  total tests: %d | passed: %d | failed: %d" "$total_tests" "$total_passed" "$total_failed"
[[ $total_todo -gt 0 ]] && printf " | todo: %d" "$total_todo"
printf "\n"
printf "  suite results: "
for result in "${suite_results[@]}"; do
  printf "%s " "$result"
done
printf "\n"

if [[ $total_failed -eq 0 && $total_tests -gt 0 ]]; then
  printf "  ✓ all test suites passed"
  [[ $total_todo -gt 0 ]] && printf " (%d todo items)" "$total_todo"
  printf "\n"
  exit 0
else
  printf "  ✗ %d test(s) failed" "$total_failed"
  [[ $total_todo -gt 0 ]] && printf " (%d todo items)" "$total_todo"
  printf "\n"
  exit 1
fi
