#!/usr/bin/env zsh
# unlink.sh - remove files from dotfiles management

# Domain functions
unlink_file() {
  local target_path="$1"
  local repo_path
  
  validate_safe_path "$target_path" || return 1
  
  # Check if it's a managed symlink
  if ! is_managed_symlink "$target_path"; then
    log_error "Not a managed symlink: $target_path" \
      "- Only dotfiles-managed symlinks can be unlinked"
    return 1
  fi
  
  repo_path="$(readlink "$target_path")" || {
    log_error "Failed to read symlink target"
    return 1
  }
  
  # Verify repo path is within dotfiles
  [[ "$repo_path" == "$DOTFILES_HOME"* ]] || {
    log_error "Symlink target is not within dotfiles repository"
    return 1
  }
  
  # Remove symlink
  rm "$target_path" || {
    log_error "Failed to remove symlink"
    return 1
  }
  
  # Move file back from repo
  mv "$repo_path" "$target_path" || {
    log_error "Failed to move file back from repository"
    return 1
  }
  
  # Remove from Git
  cd "$DOTFILES_ROOT" || return 1
  git rm --cached "${repo_path#$DOTFILES_ROOT/}" 2>/dev/null || true
  
  # Clean up empty directories
  local parent_dir="$(dirname "$repo_path")"
  while [[ "$parent_dir" != "$DOTFILES_HOME" && -d "$parent_dir" ]]; do
    rmdir "$parent_dir" 2>/dev/null || break
    parent_dir="$(dirname "$parent_dir")"
  done
  
  return 0
}

# Main unlink command
unlink_cmd() {
  local target_path="$1"
  
  [[ -z "$target_path" ]] && {
    log_error "Path argument required" \
      "- Usage: dotfiles unlink <path>" \
      "- Example: dotfiles unlink ~/.zshrc"
    exit 1
  }
  
  # Expand path
  target_path="${target_path/#\~/$HOME}"
  
  log "Unlinking: $target_path"
  
  unlink_file "$target_path" || exit 1
  
  log_done "Successfully unlinked: $target_path" \
    "- File is no longer managed by dotfiles" \
    "- Commit changes: dotfiles backup"
}
