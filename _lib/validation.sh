#!/usr/bin/env zsh
# validation.sh - input validation and safety checks

# Path safety validation
validate_safe_path() {
  local path="$1"
  local resolved
  
  [[ -z "$path" ]] && {
    log_error "Path cannot be empty"
    return 1
  }
  
  # Resolve path safely
  resolved="$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")" || {
    log_error "Cannot resolve path: $path"
    return 1
  }
  
  # Ensure path is within allowed boundaries
  case "$resolved" in
    "$HOME"*|"$DOTFILES_ROOT"*)
      return 0
      ;;
    *)
      log_error "Unsafe path detected: $path" \
        "- Paths must be within \$HOME or dotfiles repository"
      return 1
      ;;
  esac
}

# Git repository validation
validate_git_repo() {
  local repo_path="${1:-$PWD}"
  
  [[ -d "$repo_path/.git" ]] || {
    log_error "Not a Git repository: $repo_path"
    return 1
  }
  
  return 0
}

# File existence validation
validate_file_exists() {
  local file_path="$1"
  
  [[ -e "$file_path" ]] || {
    log_error "File does not exist: $file_path"
    return 1
  }
  
  return 0
}
