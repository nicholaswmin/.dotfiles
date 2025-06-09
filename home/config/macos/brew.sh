#!/usr/bin/env zsh
# brew.sh - Homebrew package management

log "Setting up Homebrew and essential packages..."

if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    log_error "Failed to install Homebrew"
    return 1
  }
  
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

brew update || log_warn "Failed to update Homebrew"

brew install \
  git \
  zsh \
  curl \
  wget \
  tree \
  jq \
  ripgrep \
  fd \
  bat \
  exa \
  neovim || log_warn "Some CLI tools failed to install"

brew install \
  node \
  python@3.11 \
  go \
  tmux \
  docker || log_warn "Some development tools failed to install"

brew install --cask \
  1password \
  visual-studio-code \
  iterm2 \
  rectangle || log_warn "Some applications failed to install"

brew cleanup

log_done "Homebrew setup completed"
