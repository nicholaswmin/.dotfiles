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
