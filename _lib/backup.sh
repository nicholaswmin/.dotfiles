#!/usr/bin/env zsh
# backup.sh - commit and push dotfiles changes

# Domain functions
check_git_status() {
  cd "$DOTFILES_ROOT" || return 1
  
  # Check if there are changes to commit
  if git diff --quiet && git diff --cached --quiet; then
    log "No changes to commit"
    return 1
  fi
  
  return 0
}

check_remote_configured() {
  cd "$DOTFILES_ROOT" || return 1
  
  git remote get-url origin &>/dev/null || {
    log_error "No remote origin configured" \
      "- Add remote: git remote add origin <your-repo-url>" \
      "- Example: git remote add origin git@github.com:username/dotfiles.git"
    return 1
  }
  
  return 0
}

commit_changes() {
  local message="$1"
  
  cd "$DOTFILES_ROOT" || return 1
  
  # Stage all changes
  git add . || {
    log_error "Failed to stage changes"
    return 1
  }
  
  # Commit with message
  git commit -m "$message" || {
    log_error "Failed to commit changes" \
      "- Check for conflicts: git status" \
      "- Resolve conflicts and try again"
    return 1
  }
  
  return 0
}

push_changes() {
  cd "$DOTFILES_ROOT" || return 1
  
  # Get current branch
  local branch="$(git rev-parse --abbrev-ref HEAD)"
  
  # Push to remote
  git push origin "$branch" || {
    log_error "Failed to push to remote" \
      "- Check network connectivity" \
      "- Verify repository access permissions" \
      "- Pull remote changes first: git pull origin $branch"
    return 1
  }
  
  return 0
}

# Main backup command
backup_cmd() {
  local message="${1:-"Update dotfiles $(date +'%Y-%m-%d %H:%M')"}"
  
  log "Backing up dotfiles..."
  
  # Check for changes
  check_git_status || {
    log_done "No changes to backup"
    return 0
  }
  
  # Verify remote is configured
  check_remote_configured || exit 1
  
  # Commit changes
  commit_changes "$message" || exit 1
  
  # Push to remote
  push_changes || exit 1
  
  log_done "Dotfiles backed up successfully" \
    "- Committed: $message" \
    "- Pushed to remote repository"
}
