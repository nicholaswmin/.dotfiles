#!/usr/bin/env zsh
# tests/run.test.sh - ALL TESTS INLINE

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

printf "\n** dotfiles main tests **\n"

section "structure"
test "dotfiles executable exists" "[[ -f dotfiles ]]"
test "install script exists" "[[ -f install.sh ]]"
test "readme exists" "[[ -f README.md ]]"
test "gitignore exists" "[[ -f .gitignore ]]"
test "lib directory exists" "[[ -d _lib ]]"
test "home directory exists" "[[ -d home ]]"
test "tests directory exists" "[[ -d tests ]]"
test "github workflow exists" "[[ -f .github/workflows/test.yml ]]"

section "permissions"
test "dotfiles is executable" "[[ -x dotfiles ]]"
test "install script is executable" "[[ -x install.sh ]]"

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
test "library syntax valid" "for f in _lib/*.sh; do zsh -n \$f || exit 1; done"

printf "\n** results **\n"
printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  printf "  all tests passed\n"
  exit 0
else
  printf "  %d failed\n" "$TESTS_FAILED"
  exit 1
fi