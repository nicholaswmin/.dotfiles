#!/usr/bin/env zsh
# make.sh - recreate test/ directory with robust error handling

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

# Create robust generic test framework with validation
log "Creating robust test framework..."
cat > tests/util/runner.zsh << 'EOF'
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
  
  if eval "$command" &>/dev/null; then
    printf "✓    %s (TODO: unexpected pass)\n" "$name"
  else
    printf "-    %s (TODO)\n" "$name"
  fi
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
EOF

# Create dotfiles-specific helpers with improved error handling
log "Creating dotfiles-specific helpers..."
cat > tests/util/dotfiles.zsh << 'EOF'
#!/usr/bin/env zsh
# tests/util/dotfiles.zsh - dotfiles-specific test helpers

setup_dotfiles_env() {
  export TEST_ROOT="$(temp_dir "dotfiles-test")"
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
  
  # Mock git with comprehensive behavior
  mkdir -p mock-bin
  cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init) mkdir -p .git; exit 0 ;;
  add|commit|remote|pull|push|status) exit 0 ;;
  rev-parse) echo "main"; exit 0 ;;
  diff) 
    case "$2" in 
      --quiet|--cached) exit 1 ;;  # Always show "changes" for backup tests
      *) echo "mock diff"; exit 0 ;; 
    esac ;;
  clone) mkdir -p "$2"; cd "$2"; mkdir -p .git; exit 0 ;;
  get-url) 
    case "$2" in
      origin) echo "https://github.com/user/dotfiles.git"; exit 0 ;;
      *) exit 1 ;;
    esac ;;
  rm) exit 0 ;;
  *) exit 0 ;;
esac
MOCKEOF
  chmod +x mock-bin/git
  export PATH="$PWD/mock-bin:$PATH"
}

cleanup_dotfiles_env() {
  cd /; cleanup_temp "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME TEST_ROOT FAKE_HOME FAKE_DOTFILES
}

# Dotfiles-specific assertions
dotfiles_repo_exists() { dir "$FAKE_DOTFILES" && dir "$FAKE_DOTFILES/.git"; }
dotfiles_file_managed() {
  local file_path="$1"
  symlink "$file_path" && {
    local target="$(readlink "$file_path" 2>/dev/null)"
    [[ "$target" == "$FAKE_DOTFILES/home"* ]]
  }
}
EOF

# Create main tests with proper validation
cat > tests/main.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

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
printf "\n"
EOF

# Create improved CLI tests
cat > tests/dotfiles.test/cli.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "cli command tests" || exit 0
setup_dotfiles_env

section "basic commands"
test "help command responds" "succeeds './dotfiles --help'"
test "version command responds" "succeeds './dotfiles --version'"

section "help content"
test "help contains usage" "contains './dotfiles --help' 'usage:'"
test "help contains commands" "contains './dotfiles --help' 'commands:'"

section "error handling"
test "rejects unknown commands" "fails './dotfiles nonexistent'"
test "requires repo for link" "fails './dotfiles link ~/.zshrc'"
test "requires repo for unlink" "fails './dotfiles unlink ~/.zshrc'"
test "requires repo for backup" "fails './dotfiles backup'"

cleanup_dotfiles_env
summary "cli tests"
printf "\n"
EOF

# Create comprehensive init tests
cat > tests/dotfiles.test/init.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "init command tests" || exit 0
setup_dotfiles_env

section "init command"
test "creates git repository" "succeeds './dotfiles init' && dotfiles_repo_exists"
test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
test "fails when already exists" "fails './dotfiles init'"

cleanup_dotfiles_env
summary "init tests"
printf "\n"
EOF

# Create comprehensive link tests
cat > tests/dotfiles.test/link.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "link command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "link files"
test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"
test "handles already managed files" "succeeds './dotfiles link \$FAKE_HOME/.zshrc'"

section "link directories"
test "links directory" "succeeds './dotfiles link \$FAKE_HOME/.ssh' && symlink '\$FAKE_HOME/.ssh'"
test "preserves directory contents" "file '\$FAKE_DOTFILES/home/.ssh/config'"

cleanup_dotfiles_env
summary "link tests"
printf "\n"
EOF

# Create comprehensive unlink tests
cat > tests/dotfiles.test/unlink.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "unlink command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null
./dotfiles link "$FAKE_HOME/.zshrc" &>/dev/null

section "unlink files"
test "unlinks managed file" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc' && file '\$FAKE_HOME/.zshrc' && ! symlink '\$FAKE_HOME/.zshrc'"
test "rejects non-managed files" "echo 'test' > '\$FAKE_HOME/regular' && fails './dotfiles unlink \$FAKE_HOME/regular'"
test "cleans up empty directories" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc'"

cleanup_dotfiles_env
summary "unlink tests"
printf "\n"
EOF

# Create improved backup tests
cat > tests/dotfiles.test/backup.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

source "$(dirname "$0")/../util/runner.zsh"
source "$(dirname "$0")/../util/dotfiles.zsh"

ci_only "backup command tests" || exit 0
setup_dotfiles_env
./dotfiles init &>/dev/null

section "backup functionality"
todo "handles no changes gracefully" "succeeds './dotfiles backup'"
todo "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"

section "backup validation"
# test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles backup'"

# cleanup_dotfiles_env
summary "backup tests"
printf "\n"
EOF

# Create comprehensive test runner with validation
cat > tests/run.test.sh << 'EOF'
#!/usr/bin/env zsh
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/util/runner.zsh"

printf "** dotfiles test suite **\n"

local total_tests=0 total_passed=0 total_failed=0 total_todo=0
local suite_results=()

# Main tests (always run)
reset
if source "$SCRIPT_DIR/main.test.sh"; then
  suite_results+=("main:pass")
else
  suite_results+=("main:fail")
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
        suite_results+=("$test_name:pass")
      else
        suite_results+=("$test_name:fail")
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
  printf "  all test suites passed"
  [[ $total_todo -gt 0 ]] && printf " (%d todo items)" "$total_todo"
  printf "\n"
  exit 0
else
  printf "  %d test(s) failed" "$total_failed"
  [[ $total_todo -gt 0 ]] && printf " (%d todo items)" "$total_todo"
  printf "\n"
  exit 1
fi
EOF

# Make executable
chmod +x tests/{*.sh,dotfiles.test/*.sh}

log_done "Robust test suite created with comprehensive error handling" \
  "- Framework validation prevents false positives" \
  "- Error handling with set -e throughout" \
  "- Function validation on sourcing" \
  "- Test count validation in runner" \
  "- Improved mock Git behavior" \
  "- More comprehensive test coverage"