#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/util/runner.zsh"

printf "** dotfiles test suite **\n"

# Run main tests only
source "$(dirname "$0")/main.test.sh"

# Skip everything else - just exit
printf "\n** final results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  printf "  all tests passed\n"
  exit 0
else
  printf "  %d failed\n" "$TESTS_FAILED"
  exit 1
fi