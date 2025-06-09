#!/usr/bin/env zsh
# tests/run.test.sh - SIMPLE VERSION THAT WORKS

printf "** dotfiles test suite **\n"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test() {
  local name="$1" command="$2"
  ((TESTS_RUN++))
  if eval "$command" &>/dev/null; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    ((TESTS_FAILED++))
  fi
}

section() { printf "\n%s\n-----\n" "$1"; }

# Just run the basic tests inline
section "structure"
test "dotfiles executable exists" "[[ -f dotfiles ]]"
test "install script exists" "[[ -f install.sh ]]"
test "readme exists" "[[ -f README.md ]]"

printf "\n** results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1