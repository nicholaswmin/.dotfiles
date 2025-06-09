#!/usr/bin/env zsh
# setup-tests.zsh - recreate test structure with latest design

set -e

readonly SCRIPT_NAME="setup-tests"
readonly TESTS_DIR="tests"

# =============================================================================
# Logging Functions
# =============================================================================

col() {
  local color="$1" text="$2"
  case "$color" in
    red)     printf "\033[31m%s\033[0m" "$text" ;;
    green)   printf "\033[32m%s\033[0m" "$text" ;;
    yellow)  printf "\033[33m%s\033[0m" "$text" ;;
    cyan)    printf "\033[36m%s\033[0m" "$text" ;;
    dim)     printf "\033[2m%s\033[0m" "$text" ;;
    *)       printf "%s" "$text" ;;
  esac
}

log() {
  for msg in "$@"; do
    printf "%s\n" "$(col dim "$msg")" >&2
  done
}

log_error() {
  printf "%s\n" "$(col red "› error: $1")" >&2
  shift
  [[ $# -gt 0 ]] && log "$@" >&2
}

log_done() {
  printf "%s\n" "$(col green "› $1")" >&2
  shift
  [[ $# -gt 0 ]] && log "$@" >&2
}

# =============================================================================
# Validation Functions
# =============================================================================

validate_environment() {
  [[ "$(uname -s)" == "Darwin" ]] || {
    log_error "macOS required" \
      "- This script is designed for macOS dotfiles setup"
    return 1
  }
  
  [[ -f "dotfiles" ]] || {
    log_error "Not in dotfiles repository" \
      "- Run this script from the dotfiles repository root" \
      "- Ensure 'dotfiles' executable exists"
    return 1
  }
  
  return 0
}

# =============================================================================
# Directory Management
# =============================================================================

remove_old_tests() {
  if [[ -d "$TESTS_DIR" ]]; then
    log "Removing existing tests directory..."
    rm -rf "$TESTS_DIR" || {
      log_error "Failed to remove existing tests directory"
      return 1
    }
  fi
  
  return 0
}

create_directory_structure() {
  log "Creating test directory structure..."
  
  mkdir -p "$TESTS_DIR"/{util,dotfiles.test} || {
    log_error "Failed to create directory structure"
    return 1
  }
  
  return 0
}

# =============================================================================
# Test File Generation
# =============================================================================

create_test_framework() {
  log "Creating test framework..."
  
  cat > "$TESTS_DIR/util/runner.zsh" << 'EOF'
#!/usr/bin/env zsh
# tests/util/runner.zsh - simple test framework

# Test state
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Core functions
test() {
  local name="$1"
  local command="$2"
  
  printf "  %s" "$name"
  ((TESTS_RUN++))
  
  if eval "$command" &>/dev/null; then
    printf " ✓\n"
    ((TESTS_PASSED++))
    return 0
  else
    printf " ✗\n"
    ((TESTS_FAILED++))
    return 1
  fi
}

section() { printf "\n** %s **\n" "$1"; }

summary() {
  local suite="$1"
  printf "\n** %s results **\n" "$suite"
  printf "  tests: %d | passed: %d | failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 && $TESTS_RUN -gt 0 ]] && printf "  ✓ all passed\n" || printf "  ✗ %d failed\n" "$TESTS_FAILED"
  [[ $TESTS_FAILED -eq 0 ]]
}

reset() { TESTS_RUN=0; TESTS_PASSED=0; TESTS_FAILED=0; }

# Test helpers
file() { [[ -f "$1" ]]; }
dir() { [[ -d "$1" ]]; }
executable() { [[ -x "$1" ]]; }
symlink() { [[ -L "$1" ]]; }
contains() { [[ "$(eval "$1" 2>/dev/null)" == *"$2"* ]]; }
succeeds() { eval "$1" &>/dev/null; }
fails() { ! eval "$1" &>/dev/null; }

# CI detection
ci_only() {
  if [[ -z "$IS_ENV_CI" ]]; then
    printf "\n** %s **\n" "$1"
    printf "  skipped (CI only)\n"
    return 1
  fi
  return 0
}

# Test environment setup
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
  
  export HOME="$FAKE_HOME"
  export DOTFILES_ROOT="$FAKE_DOTFILES"
  export DOTFILES_HOME="$FAKE_DOTFILES/home"
  
  # Mock git
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
  cd /
  rm -rf "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME TEST_ROOT FAKE_HOME FAKE_DOTFILES
}
EOF

  return 0
}

create_main_tests() {
  log "Creating main tests..."
  
  cat > "$TESTS_DIR/main.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/main.test.sh - structure tests (safe to run locally)

source "$(dirname "$0")/util/runner.zsh"

run_main_tests() {
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
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_main_tests
EOF

  chmod +x "$TESTS_DIR/main.test.sh" || return 1
  return 0
}

create_cli_tests() {
  log "Creating CLI tests..."
  
  cat > "$TESTS_DIR/dotfiles.test/cli.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/dotfiles.test/cli.test.sh - basic CLI tests

source "$(dirname "$0")/../util/runner.zsh"

run_cli_tests() {
  ci_only "cli command tests" || return 0
  
  setup_test_env
  
  section "basic commands"
  test "help command responds" "succeeds './dotfiles --help'"
  test "version command responds" "succeeds './dotfiles --version'"
  test "status command responds" "succeeds './dotfiles status'"
  
  section "help content"
  test "help contains usage" "contains './dotfiles --help' 'usage:'"
  test "help contains commands" "contains './dotfiles --help' 'commands:'"
  test "help contains examples" "contains './dotfiles --help' 'examples:'"
  
  section "version content"  
  test "version shows number" "contains './dotfiles --version' 'dotfiles v'"
  test "version shows platform" "contains './dotfiles --version' 'macOS'"
  
  section "error handling"
  test "rejects unknown commands" "fails './dotfiles nonexistent'"
  test "shows error for unknown commands" "contains './dotfiles badcmd 2>&1' 'error:'"
  test "empty command shows help" "succeeds './dotfiles' && contains './dotfiles 2>&1' 'usage:'"
  
  cleanup_test_env
  summary "cli tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_cli_tests
EOF

  chmod +x "$TESTS_DIR/dotfiles.test/cli.test.sh" || return 1
  return 0
}

create_init_tests() {
  log "Creating init tests..."
  
  cat > "$TESTS_DIR/dotfiles.test/init.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/dotfiles.test/init.test.sh - init command tests

source "$(dirname "$0")/../util/runner.zsh"

run_init_tests() {
  ci_only "init command tests" || return 0
  
  setup_test_env
  
  section "init command"
  test "creates git repository" "succeeds './dotfiles init' && dir '$FAKE_DOTFILES/.git'"
  test "creates directory structure" "dir '$FAKE_DOTFILES/home' && dir '$FAKE_DOTFILES/_lib'"
  test "creates install script" "file '$FAKE_DOTFILES/install.sh'"
  test "fails when already exists" "fails './dotfiles init'"
  
  cleanup_test_env
  summary "init tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_init_tests
EOF

  chmod +x "$TESTS_DIR/dotfiles.test/init.test.sh" || return 1
  return 0
}

create_link_tests() {
  log "Creating link tests..."
  
  cat > "$TESTS_DIR/dotfiles.test/link.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/dotfiles.test/link.test.sh - link command tests

source "$(dirname "$0")/../util/runner.zsh"

run_link_tests() {
  ci_only "link command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "link files"
  test "links single file" "succeeds './dotfiles link \$FAKE_HOME/.zshrc' && symlink '\$FAKE_HOME/.zshrc'"
  test "creates repo file" "file '\$FAKE_DOTFILES/home/.zshrc'"
  test "links directory" "succeeds './dotfiles link \$FAKE_HOME/.ssh' && symlink '\$FAKE_HOME/.ssh'"
  test "handles nested paths" "succeeds './dotfiles link \$FAKE_HOME/.config/nvim/init.vim' && symlink '\$FAKE_HOME/.config/nvim/init.vim'"
  
  section "link validation"
  test "rejects nonexistent files" "fails './dotfiles link /nonexistent'"
  test "rejects paths outside home" "fails './dotfiles link /etc/hosts'"
  test "handles already linked" "succeeds './dotfiles link \$FAKE_HOME/.gitconfig' && succeeds './dotfiles link \$FAKE_HOME/.gitconfig'"
  
  section "link requirements"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles link \$FAKE_HOME/.zshrc'"
  test "requires path argument" "fails './dotfiles link'"
  
  cleanup_test_env
  summary "link tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_link_tests
EOF

  chmod +x "$TESTS_DIR/dotfiles.test/link.test.sh" || return 1
  return 0
}

create_unlink_tests() {
  log "Creating unlink tests..."
  
  cat > "$TESTS_DIR/dotfiles.test/unlink.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/dotfiles.test/unlink.test.sh - unlink command tests

source "$(dirname "$0")/../util/runner.zsh"

run_unlink_tests() {
  ci_only "unlink command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "unlink files"
  # Setup: link a file first
  ./dotfiles link "$FAKE_HOME/.zshrc" &>/dev/null
  test "unlinks managed file" "succeeds './dotfiles unlink \$FAKE_HOME/.zshrc' && file '\$FAKE_HOME/.zshrc' && ! symlink '\$FAKE_HOME/.zshrc'"
  
  # Setup: link and unlink directory
  ./dotfiles link "$FAKE_HOME/.ssh" &>/dev/null
  test "unlinks managed directory" "succeeds './dotfiles unlink \$FAKE_HOME/.ssh' && dir '\$FAKE_HOME/.ssh' && ! symlink '\$FAKE_HOME/.ssh'"
  
  section "unlink validation"
  test "rejects non-managed files" "echo 'test' > '\$FAKE_HOME/regular' && fails './dotfiles unlink \$FAKE_HOME/regular'"
  test "rejects nonexistent paths" "fails './dotfiles unlink /nonexistent'"
  
  section "unlink requirements"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles unlink \$FAKE_HOME/.zshrc'"
  test "requires path argument" "fails './dotfiles unlink'"
  
  cleanup_test_env
  summary "unlink tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_unlink_tests
EOF

  chmod +x "$TESTS_DIR/dotfiles.test/unlink.test.sh" || return 1
  return 0
}

create_backup_tests() {
  log "Creating backup tests..."
  
  cat > "$TESTS_DIR/dotfiles.test/backup.test.sh" << 'EOF'
#!/usr/bin/env zsh
# tests/dotfiles.test/backup.test.sh - backup command tests

source "$(dirname "$0")/../util/runner.zsh"

run_backup_tests() {
  ci_only "backup command tests" || return 0
  
  setup_test_env
  ./dotfiles init &>/dev/null
  
  section "backup functionality"
  test "handles no changes" "succeeds './dotfiles backup'"
  test "accepts custom message" "succeeds './dotfiles backup \"custom message\"'"
  test "works with linked files" "./dotfiles link '\$FAKE_HOME/.zshrc' &>/dev/null && succeeds './dotfiles backup \"added zshrc\"'"
  
  section "backup validation"
  test "requires repository" "rm -rf '\$FAKE_DOTFILES' && fails './dotfiles backup'"
  
  cleanup_test_env
  summary "backup tests"
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_backup_tests
EOF

  chmod +x "$TESTS_DIR/dotfiles.test/backup.test.sh" || return 1
  return 0
}

create_test_runner() {
  log "Creating test runner..."
  
  cat > "$TESTS_DIR/run.test.sh" << 'EOF'
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
EOF

  chmod +x "$TESTS_DIR/run.test.sh" || return 1
  return 0
}

# =============================================================================
# Main Orchestration
# =============================================================================

main() {
  log "Setting up dotfiles test suite..."
  
 # validate_environment || exit 1
  remove_old_tests || exit 1
  create_directory_structure || exit 1
  
  create_test_framework || exit 1
  create_main_tests || exit 1
  create_cli_tests || exit 1
  create_init_tests || exit 1
  create_link_tests || exit 1
  create_unlink_tests || exit 1
  create_backup_tests || exit 1
  create_test_runner || exit 1
  
  log_done "Test suite setup completed" \
    "- Run locally: ./tests/run.test.sh" \
    "- Run in CI: IS_ENV_CI=1 ./tests/run.test.sh" \
    "- Structure: tests/{main.test.sh,dotfiles.test/*.test.sh}"
}

main "$@"