#!/usr/bin/env zsh
# restore.sh - restore dotfiles from remote repository

prompt_for_remote() {
  printf "$(col cyan "Enter dotfiles repository URL:")\n" >&2
  printf "$(col dim "Example: git@github.com:username/dotfiles.git")\n" >&2
  printf "> "
  
  local remote_url
  read -r remote_url
  
  [[ -n "$remote_url" ]] || {
    log_error "Repository URL required"
    exit 1
  }
  
  echo "$remote_url"
}

clone_repository() {
  local remote_url="$1"
  
  log "Cloning dotfiles repository..."
  
  git clone "$remote_url" "$DOTFILES_ROOT" || {
    log_error "Failed to clone repository" \
      "- Check repository URL: $remote_url" \
      "- Verify network connectivity" \
      "- Check SSH key access (for SSH URLs)"
    return 1
  }
  
  return 0
}

pull_changes() {
  cd "$DOTFILES_ROOT" || return 1
  
  log "Pulling latest changes..."
  
  local branch="$(git rev-parse --abbrev-ref HEAD)"
  
  git pull origin "$branch" || {
    log_error "Failed to pull changes" \
      "- Check network connectivity" \
      "- Resolve any merge conflicts manually"
    return 1
  }
  
  return 0
}

restore_symlinks() {
  local restored=()
  
  log "Restoring symlinks..."
  
  find "$DOTFILES_HOME" -type f -o -type d 2>/dev/null | while read -r item; do
    [[ "$item" == "$DOTFILES_HOME" ]] && continue
    
    local target="$HOME/${item#$DOTFILES_HOME/}"
    local target_dir="$(dirname "$target")"
    
    [[ -d "$target_dir" ]] || mkdir -p "$target_dir"
    
    if [[ -e "$target" && ! -L "$target" ]]; then
      log_warn "Skipping existing file: $target"
      continue
    elif [[ -L "$target" ]]; then
      local existing_target="$(readlink "$target")"
      if [[ "$existing_target" == "$item" ]]; then
        continue
      else
        rm "$target"
      fi
    fi
    
    ln -s "$item" "$target" && {
      restored+=("$target")
    } || {
      log_warn "Failed to create symlink: $target"
    }
  done
  
  if [[ ${#restored[@]} -gt 0 ]]; then
    log "Restored ${#restored[@]} symlinks"
  fi
  
  return 0
}

run_install_script() {
  local install_script="$DOTFILES_ROOT/install.sh"
  
  if [[ -x "$install_script" ]]; then
    log "Running macOS setup script..."
    
    "$install_script" || {
      log_warn "Install script completed with errors" \
        "- Review output above for details" \
        "- Some system setup may be incomplete"
    }
  else
    log "No install script found, skipping system setup"
  fi
}

restore_cmd() {
  local remote_url="$1"
  
  if [[ -d "$DOTFILES_ROOT" ]]; then
    validate_git_repo "$DOTFILES_ROOT" || {
      log_error "Invalid dotfiles repository at $DOTFILES_ROOT" \
        "- Remove directory: rm -rf $DOTFILES_ROOT" \
        "- Run restore again with repository URL"
      exit 1
    }
    
    pull_changes || exit 1
  else
    [[ -n "$remote_url" ]] || remote_url="$(prompt_for_remote)"
    
    clone_repository "$remote_url" || exit 1
  fi
  
  restore_symlinks || exit 1
  
  run_install_script
  
  log_done "Dotfiles restored successfully" \
    "- Configuration files are now symlinked" \
    "- Use 'dotfiles link' to manage additional files"
}
