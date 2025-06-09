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
