#!/usr/bin/env zsh
set -e

# Enable command tracing
set -x

source "$(dirname "$0")/util/runner.zsh"
source "$(dirname "$0")/util/dotfiles.zsh"

ci_only "Debug hanging test" || exit 0
setup_dotfiles_env

# Verify the environment before running the test
echo "---- DEBUGGING INFO ----"
echo "Current PATH: $PATH"
echo "which git: $(which git)"
echo "------------------------"

# This is the test known to hang from your other files
# It runs the 'backup' command without having run 'init' first
test "requires repo for backup" "fails './dotfiles backup'"

cleanup_dotfiles_env
summary "debug test"