#!/usr/bin/env zsh
# tests/util/dotfiles.zsh - dotfiles-specific test helpers

# Error handling
set -e

# Environment setup
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
  diff) case "$2" in --quiet|--cached) exit 1 ;; *) echo "mock diff"; exit 0 ;; esac ;;
  clone) mkdir -p "$2"; cd "$2"; mkdir -p .git; exit 0 ;;
  get-url) exit 1 ;;  # simulate no remote configured
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
