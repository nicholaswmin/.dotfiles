
printf "** dotfiles test suite **\n"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test() {
  local name="$1" command="$2"
  ((TESTS_RUN++))
  
  local error_output
  error_output=$(eval "$command" 2>&1)
  local exit_code=$?
  
  if [[ $exit_code -eq 0 ]]; then
    printf "✓    %s\n" "$name"
    ((TESTS_PASSED++))
  else
    printf "✗    %s\n" "$name"
    printf "     Command: %s\n" "$command"
    printf "     Error: %s\n" "$error_output"
    printf "     Exit code: %d\n" "$exit_code"
    ((TESTS_FAILED++))
  fi
}

section() { printf "\n%s\n-----\n" "$1"; }

section "structure"
test "dotfiles executable exists" "[[ -x dotfiles ]]"
test "install script exists" "[[ -x install.sh ]]"
test "all libraries exist" "[[ -f _lib/loggers.sh && -f _lib/init.sh && -f _lib/link.sh ]]"

section "cli commands"
test "help command works" "./dotfiles --help"
test "version command works" "./dotfiles --version"
test "rejects unknown commands" "! ./dotfiles badcommand"

if [[ -n "$IS_ENV_CI" ]]; then
  section "command functionality"
  
  export TEST_HOME="/tmp/test-home-$$"
  export DOTFILES_ROOT="/tmp/test-dotfiles-$$" 
  export DOTFILES_HOME="$DOTFILES_ROOT/home"
  mkdir -p "$TEST_HOME" "$DOTFILES_ROOT"
  echo "test config" > "$TEST_HOME/.testrc"
  
  export PATH="/tmp/mock-git-$$:$PATH"
  mkdir -p "/tmp/mock-git-$$"
  cat > "/tmp/mock-git-$$/git" << 'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "/tmp/mock-git-$$/git"
  
  test "init creates repository"