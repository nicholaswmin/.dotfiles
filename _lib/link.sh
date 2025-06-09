#!/usr/bin/env zsh
# link.sh - file and directory linking

is_managed_symlink() {
  local path="$1"
  
  [[ -L "$path" ]] || return 1
  
  local target="$(readlink "$path")"
  [[ "$target" == "$DOTFILES_HOME"* ]]
}

calculate_repo_path() {
  local source_path="$1"
  local relative_path="${source_path#$HOME/}"
  
  if [[ "$relative_path" == "$source_path" ]]; then
    log_error "Path must be within \$HOME: $source_path"
    return 1
  fi
  
  echo "$DOTFILES_HOME/$relative_path"
}

link_file() {
  local source_path="$1"
  local repo_path
  
  validate_safe_path "$source_path" || return 1
  validate_file_exists "$source_path" || return 1
  
  repo_path="$(calculate_repo_path "$source_path")" || return 1
  
  if is_managed_symlink "$source_path"; then
    log "Already managed: $source_path"
    return 0
  fi
  
  if [[ -e "$repo_path" ]]; then
    log_error "Target already exists in repository: $repo_path" \
      "- Remove existing file: rm -f \"$repo_path\"" \
      "- Or use different source path"
    return 1
  fi
  
  mkdir -p "$(dirname "$repo_path")" || {
    log_error "Failed to create parent directory"
    return 1
  }
  
  if [[ -e "$source_path" && ! -L "$source_path" ]]; then
    mv "$source_path" "$repo_path" || {
      log_error "Failed to move file to repository"
      return 1
    }
  elif [[ -L "$source_path" ]]; then
    local existing_target="$(readlink "$source_path")"
    if [[ "$existing_target" != "$repo_path" ]]; then
      log_warn "Replacing existing symlink: $source_path → $existing_target"
      rm "$source_path" || {
        log_error "Failed to remove existing symlink"
        return 1
      }
      
      if [[ -e "$existing_target" ]]; then
        cp -R "$existing_target" "$repo_path" || {
          log_error "Failed to copy symlink target"
          return 1
        }
      fi
    fi
  fi
  
  ln -s "$repo_path" "$source_path" || {
    log_error "Failed to create symlink"
    return 1
  }
  
  cd "$DOTFILES_ROOT" || return 1
  git add "$repo_path" || {
    log_error "Failed to stage file in Git"
    return 1
  }
  
  return 0
}

link_cmd() {
  local source_path="$1"
  
  [[ -z "$source_path" ]] && {
    log_error "Path argument required" \
      "- Usage: dotfiles link <path>" \
      "- Example: dotfiles link ~/.zshrc"
    exit 1
  }
  
  source_path="${source_path/#\~/$HOME}"
  
  log "Linking: $source_path"
  
  if [[ -d "$source_path" ]]; then
    log "Linking directory: $source_path"
    link_file "$source_path" || exit 1
  elif [[ -f "$source_path" ]]; then
    link_file "$source_path" || exit 1
  else
    log_error "Path does not exist: $source_path"
    exit 1
  fi
  
  log_done "Successfully linked: $source_path" \
    "- File is now managed in: $DOTFILES_ROOT" \
    "- Commit changes: dotfiles backup"
}
