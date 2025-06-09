#!/usr/bin/env zsh
# install.sh - macOS system setup

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib/loggers.sh"

log "Running macOS setup..."

[[ "$(uname -s)" == "Darwin" ]] || {
  log_error "This setup script requires macOS"
  exit 1
}

[[ -f "home/config/macos/set-defaults.sh" ]] && source "home/config/macos/set-defaults.sh"
[[ -f "home/config/macos/brew.sh" ]] && source "home/config/macos/brew.sh"

log_done "macOS setup completed" \
  "- Use 'dotfiles link' to manage configuration files"
