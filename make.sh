#!/usr/bin/env zsh
# make.sh - recreate test/ directory with latest design

set -e

log() { printf "%s\n" "$*" >&2; }
log_error() { printf "error: %s\n" "$1" >&2; }
log_done() { printf "✓ %s\n" "$1" >&2; }

# Validate we're in dotfiles repo
[[ -f "dotfiles" ]] || { log_error "Run from dotfiles repository root"; exit 1; }

# Remove old tests
[[ -d "tests" ]] && { log "Removing old tests/"; rm -rf tests; }

# Create structure
log "Creating test structure..."
mkdir -p tests/{util,dotfiles.test}

# Create test framework
cat > tests/util/runner.zsh << 'EOF'
#!/usr/bin/env zsh
# Test framework
TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0

test() {
  printf "  %s" "$1"; ((TESTS_RUN++))
  if eval "$2" &>/dev/null; then
    printf " ✓\n"; ((TESTS_PASSED++)); return 0
  else
    printf " ✗\n"; ((TESTS_FAILED++)); return 1
  fi
}

section() { printf "\n** %s **\n" "$1"; }
summary() {
  printf "\n** %s results **\n" "$1"
  printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 && $TESTS_RUN -gt 0 ]] && printf "  ✓ all passed\n" || printf "  ✗ %d failed\n" "$TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 ]]
}
reset() { TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; }

# Helpers
file() { [[ -f "$1" ]]; }
dir() { [[ -d "$1" ]]; }
executable() { [[ -x "$1" ]]; }
symlink() { [[ -L "$1" ]]; }
contains() { [[ "$(eval "$1" 2>/dev/null)" == *"$2"* ]]; }
succeeds() { eval "$1" &>/dev/null; }
fails() { ! eval "$1" &>/dev/null; }

ci_only() {
  if [[ -z "$IS_ENV_CI" ]]; then
    printf "\n** %s **\n" "$1"; printf "  skipped (CI only)\n"; return 1
  fi; return 0
}

setup_test_env() {
  export TEST_ROOT="/tmp/dotfiles-test-$(date +%s)"
  export FAKE_HOME="$TEST_ROOT/home"
  export FAKE_DOTFILES="$TEST_ROOT/.dotfiles"
  
  mkdir -p "$FAKE_HOME"/.config/nvim "$FAKE_HOME"/.ssh
  echo "# test .zshrc" > "$FAKE_HOME/.zshrc"
  echo "# test .gitconfig" > "$FAKE_HOME/.gitconfig"
  echo "set number" > "$FAKE_HOME/.config/nvim/init.vim"
  
  mkdir -p "$TEST_ROOT/workspace"
  cp -r "$(pwd)"/* "$TEST_ROOT/workspace/" 2>/dev/null || true
  cd "$TEST_ROOT/workspace"
  
  export HOME="$FAKE_HOME" DOTFILES_ROOT="$FAKE_DOTFILES" DOTFILES_HOME="$FAKE_DOTFILES/home"
  
  mkdir -p mock-bin
  cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init|add|commit|remote|pull|push) echo "mock: git $*"; exit 0 ;;
  rev-parse) echo "main"; exit 0 ;;
  diff) [[ "$2" == "--quiet" ]] && exit 1 || exit 0 ;;
  *) echo "mock: git $*"; exit 0 ;;
esac
MOCKEOF
  chmod +x mock-bin/git
  export PATH="$PWD/mock-bin:$PATH"
}

cleanup_test_env() {
  cd /; rm -rf "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME TEST_ROOT FAKE_HOME FAKE_DOTFILES
}
EOF

# Create main tests (safe locally)
cat > tests/main.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/util/runner.zsh"

printf "\n** dotfiles main tests **\n"

section "structure"
test "dotfiles executable exists" "file dotfiles"
test "install script exists" "file install.sh"
test "readme exists" "file README.md"
test "gitignore exists" "file .gitignore"
test "lib directory exists" "dir _lib"
test "home directory exists" "dir home"
test "tests directory exists" "dir tests"
test "github workflow exists" "file .github/workflows/test.yml"

section "permissions"
test "dotfiles is executable" "executable dotfiles"
test "install script is executable" "executable install.sh"

section "libraries"
test "loggers library exists" "file _lib/loggers.sh"
test "validation library exists" "file _lib/validation.sh"
test "init library exists" "file _lib/init.sh"
test "link library exists" "file _lib/link.sh"
test "unlink library exists" "file _lib/unlink.sh"
test "backup library exists" "file _lib/backup.sh"
test "restore library exists" "file _lib/restore.sh"

section "syntax"
test "dotfiles syntax valid" "succeeds 'zsh -n dotfiles'"
test "install script syntax valid" "succeeds 'zsh -n install.sh'"
test "library syntax valid" "succeeds 'for f in _lib/*.sh; do zsh -n \$f || exit 1; done'"

summary "main tests"
EOF

# Create CLI tests (CI only)
cat > tests/dotfiles.test/cli.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "cli command tests" || exit 0
setup_test_env

section "basic commands"
test "help command responds" "succeeds './dotfiles --help'"
test "version command responds" "succeeds './dotfiles --version'"
test "status command responds" "succeeds './dotfiles status'"

section "help content"
test "help contains usage" "contains './dotfiles --help' 'usage:'"
test "help contains commands" "contains './dotfiles --help' 'commands:'"

section "error handling"
test "rejects unknown commands" "fails './dotfiles nonexistent'"

cleanup_test_env
summary "cli tests"
EOF

cat > tests/dotfiles.test/init.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "init command tests" || exit 0
setup_test_env

section "init command"
test "creates git repository" "succeeds './dotfiles init' && dir '$FAKE_DOTFILES/.git'"
test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
test "fails when already exists" "fails './dotfiles init'"

cleanup_test_env
summary "init tests"
EOF

cat > tests/dotfiles.test/link.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "link command tests" || exit 0
setup_test_env
./dotfiles init &>/dev/null

section "link files"
test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"

cleanup_test_env
summary "link tests"
EOF

cat > tests/dotfiles.test/unlink.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "unlink command tests" || exit 0
setup_test_env
./dotfiles init &>/dev/null
./dotfiles link "$FAKE_HOME/.zshrc" &>/dev/null

section "unlink files"
test "unlinks managed file" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc' && file '\$FAKE_HOME/.zshrc' && ! symlink '\$FAKE_HOME/.zshrc'"
test "rejects non-managed files" "echo 'test' > '\$FAKE_HOME/regular' && fails './dotfiles unlink \$FAKE_HOME/regular'"

cleanup_test_env
summary "unlink tests"
EOF

cat > tests/dotfiles.test/backup.test.sh << 'EOF'
#!/usr/bin/env zsh
source "$(dirname "$0")/../util/runner.zsh"

ci_only "backup command tests" || exit 0
setup_test_env
./dotfiles init &>/dev/null

section "backup functionality"
test "handles no changes" "succeeds './dotfiles backup'"
test "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"

cleanup_test_env
summary "backup tests"
EOF

# Create test runner
cat > tests/run.test.sh << 'EOF'
#!/usr/bin/env zsh
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/util/runner.zsh"

printf "** dotfiles test suite **\n"

local total_tests=0 total_passed=0 total_failed=0
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
EOF

# Make executable
chmod +x tests/{*.sh,dotfiles.test/*.sh}

log_done "Test suite created" \
  "- Run locally: ./tests/run.test.sh" \
  "- Run in CI: IS_ENV_CI=1 ./tests/run.test.sh"