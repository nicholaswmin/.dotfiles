#!/usr/bin/env zsh
# init.sh - dotfiles repository initialization

init_cmd() {
  local remote_url="$1"
  
  if [[ -d "$DOTFILES_ROOT" ]]; then
    log_error "Dotfiles directory already exists: $DOTFILES_ROOT" \
      "- Remove existing directory: rm -rf $DOTFILES_ROOT" \
      "- Or use 'dotfiles restore' to sync existing repo"
    exit 1
  fi
  
  log "Initializing dotfiles repository..."
  
  mkdir -p "$DOTFILES_ROOT"/{_lib,home/.config/macos,home/config/macos,tests} || {
    log_error "Failed to create directory structure"
    exit 1
  }
  
  cp -R "$PWD"/* "$DOTFILES_ROOT/" 2>/dev/null || {
    log_error "Failed to copy dotfiles tool"
    exit 1
  }
  
  cd "$DOTFILES_ROOT" || exit 1
  git init || {
    log_error "Failed to initialize Git repository"
    exit 1
  }
  
  git checkout -b main 2>/dev/null || git branch -M main || {
    log_error "Failed to set default branch"
    exit 1
  }
  
  if [[ -n "$remote_url" ]]; then
    log "Adding remote origin: $remote_url"
    git remote add origin "$remote_url" || {
      log_error "Failed to add remote origin"
      exit 1
    }
  fi
  
  git add . || {
    log_error "Failed to stage initial files"
    exit 1
  }
  
  git commit -m "Initial dotfiles setup" || {
    log_error "Failed to create initial commit"
    exit 1
  }
  
  local next_steps=""
  if [[ -n "$remote_url" ]]; then
    next_steps="- Push to remote: git push -u origin main"$'\n'"- Start linking files: dotfiles link ~/.zshrc"
  else
    next_steps="- Add remote: git remote add origin <your-repo-url>"$'\n'"- Start linking files: dotfiles link ~/.zshrc"
  fi
  
  log_done "Dotfiles repository initialized at $DOTFILES_ROOT" "$next_steps"
}
