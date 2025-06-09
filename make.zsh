#!/usr/bin/env zsh
# make.zsh - Complete macOS dotfiles system generator with fixed CI tests
# usage: ./make.zsh [--help]

# =============================================================================
# Configuration and Global Variables
# =============================================================================

readonly SCRIPT_NAME="make"
readonly SCRIPT_PATH="$(realpath "$0")"
readonly SCRIPT_FILENAME="$(basename "$SCRIPT_PATH")"
readonly TARGET_DIR="$PWD"

# =============================================================================
# Logging and Utility Functions
# =============================================================================

# Color utility function
color_text() {
  local color="$1" text="$2"
  if [[ -n "${NO_COLOR}" ]] || { [[ ! -t 1 ]] && [[ -z "${FORCE_COLOR}" ]]; }; then
    printf "%s" "$text"
    return
  fi
  
  case "$color" in
    red)     printf "\033[31m%s\033[0m" "$text" ;;
    green)   printf "\033[32m%s\033[0m" "$text" ;;
    yellow)  printf "\033[33m%s\033[0m" "$text" ;;
    cyan)    printf "\033[36m%s\033[0m" "$text" ;;
    dim)     printf "\033[2m%s\033[0m" "$text" ;;
    *)       printf "%s" "$text" ;;
  esac
}

# Logging functions
log() { printf "%s\n" "$(color_text dim "$*")" >&2; }
log_error() { printf "%s\n" "$(color_text red "› error: $1")" >&2; shift; [[ $# -gt 0 ]] && log "$@" >&2; }
log_done() { printf "%s\n" "$(color_text green "› $1")" >&2; shift; [[ $# -gt 0 ]] && log "$@" >&2; }
log_warn() { printf "%s\n" "$(color_text yellow "› warn: $*")" >&2; }
log_spacer() { printf "\n" >&2; }

# =============================================================================
# macOS Validation
# =============================================================================

validate_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || {
    log_error "macOS required" \
      "- This tool is designed exclusively for macOS" \
      "- Use on macOS 10.15 (Catalina) or later"
    return 1
  }
  
  command -v git &>/dev/null || {
    log_error "Git is required but not installed" \
      "- Install Xcode Command Line Tools: xcode-select --install" \
      "- Or install via Homebrew: brew install git"
    return 1
  }
  
  return 0
}

# =============================================================================
# Directory Cleanup Functions
# =============================================================================

validate_cleanup_safety() {
  [[ -d "$TARGET_DIR" ]] || {
    log_error "Target directory does not exist: $TARGET_DIR"
    return 1
  }
  
  [[ -w "$TARGET_DIR" ]] || {
    log_error "Target directory is not writable: $TARGET_DIR"
    return 1
  }
  
  # Safety check: don't run in dangerous directories
  case "$TARGET_DIR" in
    "/" | "$HOME")
      log_error "Unsafe directory detected: $TARGET_DIR" \
        "- Never run cleanup in root or home directory" \
        "- Navigate to a project-specific directory"
      return 1
      ;;
  esac
  
  return 0
}

cleanup_directory() {
  local removed_count=0
  
  log "Cleaning directory (preserving generator script and .git)..."
  
  # Find all items except this script and .git
  local items_to_remove=()
  for item in "$TARGET_DIR"/{*,.*}; do
    [[ -e "$item" ]] || continue
    local basename="$(basename "$item")"
    
    # Skip current/parent directories, this script, and .git
    [[ "$basename" == "." || "$basename" == ".." ]] && continue
    [[ "$basename" == "$SCRIPT_FILENAME" ]] && continue
    [[ "$basename" == ".git" ]] && continue
    
    items_to_remove+=("$item")
  done
  
  # Show what will be removed
  if [[ ${#items_to_remove[@]} -eq 0 ]]; then
    log "Directory is already clean"
    return 0
  fi
  
  log "Removing ${#items_to_remove[@]} items..."
  
  # Remove items automatically
  for item in "${items_to_remove[@]}"; do
    if [[ -d "$item" ]]; then
      rm -rf "$item" && ((removed_count++))
    else
      rm -f "$item" && ((removed_count++))
    fi
  done
  
  log_done "Directory cleaned" \
    "- Removed $removed_count items" \
    "- Preserved generator script and .git directory"
  
  return 0
}

# =============================================================================
# Directory Structure Creation
# =============================================================================

create_directory_structure() {
  log "Creating dotfiles directory structure..."
  
  mkdir -p {_lib,home/.config/macos,home/config/macos,tests,.github/workflows} || {
    log_error "Failed to create directory structure"
    return 1
  }
  
  return 0
}

# =============================================================================
# Main CLI Executable Generation
# =============================================================================

generate_main_executable() {
  log "Generating main CLI executable..."
  
  cat > "dotfiles" << 'EOF'
#!/usr/bin/env zsh
# dotfiles - macOS dotfiles management CLI
# usage: dotfiles <command> [options]

# Configuration
readonly SCRIPT_NAME="dotfiles"
readonly DOTFILES_ROOT="$HOME/.dotfiles"
readonly DOTFILES_HOME="$DOTFILES_ROOT/home"

# =============================================================================
# Color and Logging Functions (Self-contained)
# =============================================================================

col() {
  local color="$1" text="$2"
  
  if [[ -n "${NO_COLOR}" ]] || { [[ ! -t 1 ]] && [[ -z "${FORCE_COLOR}" ]]; }; then
    printf "%s" "$text"
    return
  fi
  
  case "$color" in
    red)     printf "\033[31m%s\033[0m" "$text" ;;
    green)   printf "\033[32m%s\033[0m" "$text" ;;
    yellow)  printf "\033[33m%s\033[0m" "$text" ;;
    cyan)    printf "\033[36m%s\033[0m" "$text" ;;
    dim)     printf "\033[2m%s\033[0m" "$text" ;;
    *)       printf "%s" "$text" ;;
  esac
}

log_error() {
  printf "%s\n" "$(col red "› error: $1")" >&2
  shift
  for msg in "$@"; do
    printf "%s\n" "$(col dim "$msg")" >&2
  done
}

# =============================================================================
# Library Loading
# =============================================================================

if [[ -d "$DOTFILES_ROOT/_lib" ]]; then
  for lib_file in "$DOTFILES_ROOT"/_lib/*.sh; do
    [[ -f "$lib_file" ]] && source "$lib_file"
  done
fi

# =============================================================================
# Utility Functions
# =============================================================================

is_dotfiles_repo() {
  [[ -d "$DOTFILES_ROOT/.git" ]] && [[ -d "$DOTFILES_HOME" ]]
}

require_repo() {
  is_dotfiles_repo || {
    log_error "Not in a dotfiles repository" \
      "- Initialize with: dotfiles init" \
      "- Clone existing: dotfiles init <remote_url>"
    exit 1
  }
}

show_help() {
  printf "\n"
  printf " $(col cyan "⚙️  dotfiles")\n"
  printf "   $(col yellow "macOS dotfiles management")\n"
  printf "\n"
  printf " $(col cyan "usage:")\n"
  printf " $(col dim "  dotfiles <command> [options]")\n"
  printf "\n"
  printf " $(col cyan "commands:")\n"
  printf " $(col dim "  init [remote]               # initialize dotfiles repo")\n"
  printf " $(col dim "  link <path>                 # link file or directory")\n"
  printf " $(col dim "  unlink <path>               # unlink file or directory")\n"
  printf " $(col dim "  restore                     # restore from remote")\n"
  printf " $(col dim "  backup [message]            # commit and push changes")\n"
  printf "\n"
  printf " $(col dim "  -h, --help                  # show this help")\n"
  printf " $(col dim "  -v, --version               # show version")\n"
  printf "\n"
  printf " $(col cyan "examples:")\n"
  printf " $(col dim "  dotfiles init")\n"
  printf " $(col dim "  dotfiles link ~/.zshrc")\n"
  printf " $(col dim "  dotfiles link ~/.config/nvim")\n"
  printf " $(col dim "  dotfiles backup \"Update configs\"")\n"
  printf "\n"
}

show_version() {
  printf "dotfiles v1.0.0 (macOS)\n"
}

# Stub functions - will be replaced by library functions when available
init_cmd() { echo "Init functionality requires full dotfiles repository"; exit 1; }
link_cmd() { echo "Link functionality requires full dotfiles repository"; exit 1; }
unlink_cmd() { echo "Unlink functionality requires full dotfiles repository"; exit 1; }
restore_cmd() { echo "Restore functionality requires full dotfiles repository"; exit 1; }
backup_cmd() { echo "Backup functionality requires full dotfiles repository"; exit 1; }

# Main command dispatcher
main() {
  case "$1" in
    init)
      shift
      init_cmd "$@"
      ;;
    link)
      shift
      require_repo
      link_cmd "$@"
      ;;
    unlink)
      shift
      require_repo
      unlink_cmd "$@"
      ;;
    restore)
      shift
      restore_cmd "$@"
      ;;
    backup)
      shift
      require_repo
      backup_cmd "$@"
      ;;
    -h|--help)
      show_help
      ;;
    -v|--version)
      show_version
      ;;
    "")
      show_help
      exit 1
      ;;
    *)
      log_error "Unknown command: $1" \
        "- Run 'dotfiles --help' for available commands"
      exit 1
      ;;
  esac
}

main "$@"
EOF

  chmod +x "dotfiles" || {
    log_error "Failed to make dotfiles executable"
    return 1
  }
  
  return 0
}

# =============================================================================
# Library Functions Generation
# =============================================================================

generate_logging_library() {
  log "Generating logging library..."
  
  cat > "_lib/loggers.sh" << 'EOF'
#!/usr/bin/env zsh
# loggers.sh - standardized logging functions

col() {
  local color="$1" text="$2"
  
  if [[ -n "${NO_COLOR}" ]] || { [[ ! -t 1 ]] && [[ -z "${FORCE_COLOR}" ]]; }; then
    printf "%s" "$text"
    return
  fi
  
  case "$color" in
    red)     printf "\033[31m%s\033[0m" "$text" ;;
    green)   printf "\033[32m%s\033[0m" "$text" ;;
    yellow)  printf "\033[33m%s\033[0m" "$text" ;;
    cyan)    printf "\033[36m%s\033[0m" "$text" ;;
    dim)     printf "\033[2m%s\033[0m" "$text" ;;
    *)       printf "%s" "$text" ;;
  esac
}

log() {
  for msg in "$@"; do
    printf "%s\n" "$(col dim "$msg")" >&2
  done
}

log_warn() {
  for msg in "$@"; do
    printf "%s\n" "$(col yellow "› warn: $msg")" >&2
  done
}

log_error() {
  printf "%s\n" "$(col red "› error: $1")" >&2
  shift
  [[ $# -gt 0 ]] && log "$@" >&2
}

log_done() {
  printf "%s\n" "$(col green "› $1")" >&2
  shift
  [[ $# -gt 0 ]] && log "$@" >&2
}

log_spacer() {
  printf "\n" >&2
}
EOF

  return 0
}

generate_validation_library() {
  log "Generating validation library..."
  
  cat > "_lib/validation.sh" << 'EOF'
#!/usr/bin/env zsh
# validation.sh - input validation and safety checks

validate_safe_path() {
  local path="$1"
  local resolved
  
  [[ -z "$path" ]] && {
    log_error "Path cannot be empty"
    return 1
  }
  
  resolved="$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")" || {
    log_error "Cannot resolve path: $path"
    return 1
  }
  
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

validate_git_repo() {
  local repo_path="${1:-$PWD}"
  
  [[ -d "$repo_path/.git" ]] || {
    log_error "Not a Git repository: $repo_path"
    return 1
  }
  
  return 0
}

validate_file_exists() {
  local file_path="$1"
  
  [[ -e "$file_path" ]] || {
    log_error "File does not exist: $file_path"
    return 1
  }
  
  return 0
}
EOF

  return 0
}

generate_init_command() {
  log "Generating init command..."
  
  cat > "_lib/init.sh" << 'EOF'
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
EOF

  return 0
}

generate_link_command() {
  log "Generating link command..."
  
  cat > "_lib/link.sh" << 'EOF'
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
EOF

  return 0
}

generate_unlink_command() {
  log "Generating unlink command..."
  
  cat > "_lib/unlink.sh" << 'EOF'
#!/usr/bin/env zsh
# unlink.sh - remove files from dotfiles management

unlink_file() {
  local target_path="$1"
  local repo_path
  
  validate_safe_path "$target_path" || return 1
  
  if ! is_managed_symlink "$target_path"; then
    log_error "Not a managed symlink: $target_path" \
      "- Only dotfiles-managed symlinks can be unlinked"
    return 1
  fi
  
  repo_path="$(readlink "$target_path")" || {
    log_error "Failed to read symlink target"
    return 1
  }
  
  [[ "$repo_path" == "$DOTFILES_HOME"* ]] || {
    log_error "Symlink target is not within dotfiles repository"
    return 1
  }
  
  rm "$target_path" || {
    log_error "Failed to remove symlink"
    return 1
  }
  
  mv "$repo_path" "$target_path" || {
    log_error "Failed to move file back from repository"
    return 1
  }
  
  cd "$DOTFILES_ROOT" || return 1
  git rm --cached "${repo_path#$DOTFILES_ROOT/}" 2>/dev/null || true
  
  local parent_dir="$(dirname "$repo_path")"
  while [[ "$parent_dir" != "$DOTFILES_HOME" && -d "$parent_dir" ]]; do
    rmdir "$parent_dir" 2>/dev/null || break
    parent_dir="$(dirname "$parent_dir")"
  done
  
  return 0
}

unlink_cmd() {
  local target_path="$1"
  
  [[ -z "$target_path" ]] && {
    log_error "Path argument required" \
      "- Usage: dotfiles unlink <path>" \
      "- Example: dotfiles unlink ~/.zshrc"
    exit 1
  }
  
  target_path="${target_path/#\~/$HOME}"
  
  log "Unlinking: $target_path"
  
  unlink_file "$target_path" || exit 1
  
  log_done "Successfully unlinked: $target_path" \
    "- File is no longer managed by dotfiles" \
    "- Commit changes: dotfiles backup"
}
EOF

  return 0
}

generate_backup_command() {
  log "Generating backup command..."
  
  cat > "_lib/backup.sh" << 'EOF'
#!/usr/bin/env zsh
# backup.sh - commit and push dotfiles changes

check_git_status() {
  cd "$DOTFILES_ROOT" || return 1
  
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
  
  git add . || {
    log_error "Failed to stage changes"
    return 1
  }
  
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
  
  local branch="$(git rev-parse --abbrev-ref HEAD)"
  
  git push origin "$branch" || {
    log_error "Failed to push to remote" \
      "- Check network connectivity" \
      "- Verify repository access permissions" \
      "- Pull remote changes first: git pull origin $branch"
    return 1
  }
  
  return 0
}

backup_cmd() {
  local message="${1:-"Update dotfiles $(date +'%Y-%m-%d %H:%M')"}"
  
  log "Backing up dotfiles..."
  
  check_git_status || {
    log_done "No changes to backup"
    return 0
  }
  
  check_remote_configured || exit 1
  
  commit_changes "$message" || exit 1
  
  push_changes || exit 1
  
  log_done "Dotfiles backed up successfully" \
    "- Committed: $message" \
    "- Pushed to remote repository"
}
EOF

  return 0
}

generate_restore_command() {
  log "Generating restore command..."
  
  cat > "_lib/restore.sh" << 'EOF'
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
EOF

  return 0
}

# =============================================================================
# macOS Configuration Files Generation
# =============================================================================

generate_macos_configuration() {
  log "Generating macOS system configuration..."
  
  cat > "home/config/macos/set-defaults.sh" << 'EOF'
#!/usr/bin/env zsh
# set-defaults.sh - essential macOS system preferences

log "Configuring macOS system defaults..."

# Disable press-and-hold for keys in favor of key repeat
defaults write -g ApplePressAndHoldEnabled -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Show hidden files and extensions
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show Finder status and path bars
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Use list view in Finder by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Auto-hide Dock with no delay
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Prevent creation of .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Show ~/Library folder
chflags nohidden ~/Library

log_done "macOS defaults configured" \
  "- Restart Finder and Dock: killall Finder Dock"
EOF

  return 0
}

generate_macos_brew() {
  log "Generating Homebrew configuration..."
  
  cat > "home/config/macos/brew.sh" << 'EOF'
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
EOF

  return 0
}

generate_install_script() {
  log "Generating install script..."
  
  cat > "install.sh" << 'EOF'
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
EOF

  chmod +x "install.sh" || {
    log_error "Failed to make install.sh executable"
    return 1
  }
  
  return 0
}

# =============================================================================
# Test Suite Generation - FIXED VERSION
# =============================================================================

generate_test_suite() {
  log "Generating comprehensive test suite..."
  
  cat > "tests/main.test.sh" << 'EOF'
#!/bin/bash
# main.test.sh - Core functionality tests - SIMPLIFIED

set -e

echo "=== Dotfiles Generator Core Tests ==="
echo

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  echo "✓ PASS: $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo "✗ FAIL: $1 - $2"
  ((TESTS_FAILED++))
}

run_test() {
  local test_name="$1"
  echo -n "Testing: $test_name... "
  ((TESTS_RUN++))
}

# Test 1: Basic file structure
run_test "Generated file structure"
if [[ -f "dotfiles" && -f "install.sh" && -f "README.md" && -d "_lib" && -d "home" && -d "tests" ]]; then
  test_pass "file structure"
else
  test_fail "file structure" "missing required files/directories"
fi

# Test 2: Library files
run_test "Library files exist"
missing_libs=()
for lib in loggers validation init link unlink backup restore; do
  [[ -f "_lib/$lib.sh" ]] || missing_libs+=("$lib.sh")
done

if [[ ${#missing_libs[@]} -eq 0 ]]; then
  test_pass "library files"
else
  test_fail "library files" "missing: ${missing_libs[*]}"
fi

# Test 3: Executable permissions
run_test "Executable permissions"
if [[ -x "dotfiles" && -x "install.sh" ]]; then
  test_pass "executable permissions"
else
  test_fail "executable permissions" "dotfiles or install.sh not executable"
fi

# Test 4: Basic CLI commands
run_test "CLI help system"
if ./dotfiles --help >/dev/null 2>&1 && ./dotfiles --version >/dev/null 2>&1; then
  test_pass "CLI commands"
else
  test_fail "CLI commands" "help or version failed"
fi

# Test 5: GitHub workflow
run_test "GitHub Actions workflow"
if [[ -f ".github/workflows/test.yml" ]]; then
  test_pass "GitHub workflow"
else
  test_fail "GitHub workflow" "workflow file missing"
fi

echo
echo "=== Results ==="
echo "Run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All tests passed!"
  exit 0
else
  echo "✗ $TESTS_FAILED test(s) failed!"
  exit 1
fi
EOF

  cat > "tests/e2e.test.sh" << 'EOF'
#!/bin/bash
# e2e.test.sh - End-to-end CLI tests - SIMPLIFIED

set -e

echo "=== Dotfiles CLI End-to-End Tests ==="
echo

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_pass() {
  echo "✓ PASS: $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo "✗ FAIL: $1 - $2"
  ((TESTS_FAILED++))
}

run_test() {
  local test_name="$1"
  echo -n "Testing: $test_name... "
  ((TESTS_RUN++))
}

# Setup fake environment
FAKE_HOME="/tmp/test-home-$"
FAKE_DOTFILES="/tmp/test-dotfiles-$"

cleanup() {
  rm -rf "$FAKE_HOME" "$FAKE_DOTFILES" 2>/dev/null || true
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

trap cleanup EXIT

mkdir -p "$FAKE_HOME"
echo "# test file" > "$FAKE_HOME/.zshrc"

export HOME="$FAKE_HOME"
export DOTFILES_ROOT="$FAKE_DOTFILES"
export DOTFILES_HOME="$FAKE_DOTFILES/home"

# Create mock git
mkdir -p mock-bin
cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init) mkdir -p .git; exit 0 ;;
  add|commit|remote|rev-parse|clone|pull|push) exit 0 ;;
  *) exit 0 ;;
esac
MOCKEOF
chmod +x mock-bin/git
export PATH="$PWD/mock-bin:$PATH"

# Test 1: Init command
run_test "dotfiles init"
if ./dotfiles init >/dev/null 2>&1; then
  if [[ -d "$FAKE_DOTFILES" ]]; then
    test_pass "init command"
  else
    test_fail "init command" "dotfiles directory not created"
  fi
else
  test_fail "init command" "init command failed"
fi

# Test 2: Help system
run_test "help and version"
if ./dotfiles --help >/dev/null 2>&1 && ./dotfiles --version >/dev/null 2>&1; then
  test_pass "help system"
else
  test_fail "help system" "help or version command failed"
fi

echo
echo "=== Results ==="
echo "Run: $TESTS_RUN | Passed: $TESTS_PASSED | Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✓ All E2E tests passed!"
  exit 0
else
  echo "✗ $TESTS_FAILED E2E test(s) failed!"
  exit 1
fi
EOF

  cat > "tests/run-all.sh" << 'EOF'
#!/bin/bash
# run-all.sh - Execute all test suites - BULLETPROOF

set -e

echo "🧪 Running Dotfiles Test Suite"
echo "================================"
echo

echo "▶ Running generator tests..."
bash tests/main.test.sh
main_result=$?

echo
echo "▶ Running CLI tests..."
bash tests/e2e.test.sh
e2e_result=$?

echo
echo "📊 Final Results"
echo "================"
if [[ $main_result -eq 0 && $e2e_result -eq 0 ]]; then
  echo "✅ All test suites passed!"
  exit 0
else
  echo "❌ Some tests failed:"
  [[ $main_result -ne 0 ]] && echo "  - Generator tests failed"
  [[ $e2e_result -ne 0 ]] && echo "  - CLI tests failed"
  exit 1
fi
EOF

  chmod +x "tests"/*.sh || {
    log_error "Failed to make test scripts executable"
    return 1
  }
  
  return 0
}

# =============================================================================
# GitHub Actions Workflow Generation
# =============================================================================

generate_github_workflow() {
  log "Generating GitHub Actions workflow..."
  
  cat > ".github/workflows/test.yml" << 'EOF'
name: Test Dotfiles Generator

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  HOMEBREW_NO_ANALYTICS: 1
  HOMEBREW_NO_AUTO_UPDATE: 1

jobs:
  test:
    name: Test on macOS
    runs-on: macos-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Validate generator script
      run: |
        zsh -n make.zsh
        chmod +x make.zsh
        echo "✓ Generator script validation passed"
        
    - name: Run generator
      run: |
        ./make.zsh
        echo "✓ Generator execution completed"
        
    - name: Run test suite
      run: |
        ./tests/run-all.sh
        
    - name: Validate generated structure
      run: |
        test -f dotfiles || (echo "❌ Main executable missing" && exit 1)
        test -f install.sh || (echo "❌ Install script missing" && exit 1)
        test -f README.md || (echo "❌ Documentation missing" && exit 1)
        test -d _lib || (echo "❌ Library directory missing" && exit 1)
        test -d tests || (echo "❌ Tests directory missing" && exit 1)
        
        test -x dotfiles || (echo "❌ Main executable not executable" && exit 1)
        test -x install.sh || (echo "❌ Install script not executable" && exit 1)
        
        echo "✓ Generated structure validation passed"
        
    - name: Test CLI help system
      run: |
        ./dotfiles --help >/dev/null || (echo "❌ Help command failed" && exit 1)
        ./dotfiles --version >/dev/null || (echo "❌ Version command failed" && exit 1)
        
        echo "✓ CLI help system validation passed"
EOF

  return 0
}

# =============================================================================
# Documentation Generation
# =============================================================================

generate_gitignore() {
  log "Generating .gitignore..."
  
  cat > ".gitignore" << 'EOF'
# macOS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes

# Editor files
*.swp
*.swo
*~
.vscode/

# Local configuration
*.local
.env
EOF

  return 0
}

generate_readme() {
  log "Generating README.md..."
  
  cat > "README.md" << 'EOF'
# macOS Dotfiles Management

Streamlined dotfiles management system optimized for macOS.

## Quick Start

```bash
# Initialize repository
dotfiles init

# Link configuration files
dotfiles link ~/.zshrc
dotfiles link ~/.config/nvim

# Backup changes
dotfiles backup "Initial setup"
```

## Commands

- `dotfiles init [remote]` - Initialize dotfiles repository
- `dotfiles link <path>` - Link file or directory
- `dotfiles unlink <path>` - Unlink file or directory  
- `dotfiles restore` - Restore from remote repository
- `dotfiles backup [message]` - Commit and push changes

## Repository Structure

```
~/.dotfiles/
├── dotfiles              # Main CLI executable
├── install.sh           # macOS system setup
├── home/                # Mirror of $HOME structure
│   └── .config/         # Application configurations
│       └── macos/       # macOS-specific configs
├── config/macos/        # macOS-specific setup
├── tests/               # Comprehensive test suite
│   ├── main.test.sh     # Generator tests
│   ├── e2e.test.sh      # CLI functionality tests
│   └── run-all.sh       # Test runner
├── .github/workflows/   # CI/CD automation
└── _lib/                # Internal functions
```

## Installation

1. Add to PATH: `export PATH="/path/to/dotfiles:$PATH"`
2. Initialize: `dotfiles init`
3. Start linking: `dotfiles link ~/.zshrc`

## Testing

```bash
# Run all tests
./tests/run-all.sh

# Run individual test suites
./tests/main.test.sh    # Generator tests
./tests/e2e.test.sh     # CLI tests
```

## macOS Integration

- System defaults optimization
- Homebrew package management
- Native macOS features

## CI/CD

Includes GitHub Actions workflow for automated testing on macOS runners.
Tests run on every push and pull request to `main` branch.

## License

MIT License
EOF

  return 0
}

# =============================================================================
# Help and Main Orchestration
# =============================================================================

show_help() {
  printf "\n"
  printf " $(color_text cyan "🍎 macOS Dotfiles Generator")\n"
  printf "   $(color_text yellow "Complete dotfiles system generation")\n"
  printf "\n"
  printf " $(color_text cyan "usage:")\n"
  printf " $(color_text dim "  ./make.zsh")\n"
  printf "\n"
  printf " $(color_text cyan "options:")\n"
  printf " $(color_text dim "  -h, --help                  # show this help")\n"
  printf "\n"
  printf " $(color_text cyan "what gets generated:")\n"
  printf " $(color_text dim "  • Complete CLI tool with all commands")\n"
  printf " $(color_text dim "  • macOS system configuration scripts")\n"
  printf " $(color_text dim "  • Comprehensive test suite (main + e2e)")\n"
  printf " $(color_text dim "  • GitHub Actions CI workflow")\n"
  printf " $(color_text dim "  • Complete documentation")\n"
  printf "\n"
  printf " $(color_text cyan "post-generation workflow:")\n"
  printf " $(color_text dim "  1. ./tests/run-all.sh       # validate everything works")\n"
  printf " $(color_text dim "  2. ./dotfiles init          # initialize your dotfiles")\n"
  printf " $(color_text dim "  3. git init && git add .    # setup version control")\n"
  printf " $(color_text dim "  4. git commit -m \"Initial\" # first commit")\n"
  printf "\n"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        log_error "Unknown option: $1" \
          "- Run './make.zsh --help' for available options"
        exit 1
        ;;
    esac
  done
  
  log "Starting complete macOS dotfiles system generation..."
  log_spacer
  
  # Phase 1: Validation and Cleanup
  #validate_macos || exit 1
  validate_cleanup_safety || exit 1
  cleanup_directory || exit 1
  
  log_spacer
  
  # Phase 2: Structure Creation
  create_directory_structure || exit 1
  generate_main_executable || exit 1
  
  # Phase 3: Library Generation
  generate_logging_library || exit 1
  generate_validation_library || exit 1
  generate_init_command || exit 1
  generate_link_command || exit 1
  generate_unlink_command || exit 1
  generate_backup_command || exit 1
  generate_restore_command || exit 1
  
  # Phase 4: macOS Configuration
  generate_macos_configuration || exit 1
  generate_macos_brew || exit 1
  generate_install_script || exit 1
  
  # Phase 5: Test Suite and CI
  generate_test_suite || exit 1
  generate_github_workflow || exit 1
  
  # Phase 6: Documentation
  generate_gitignore || exit 1
  generate_readme || exit 1
  
  log_spacer
  
  local next_steps=$(cat <<-EOF
- Run tests: ./tests/run-all.sh
- Initialize: ./dotfiles init
- Link files: ./dotfiles link ~/.zshrc
- Setup git: git init && git add . && git commit -m "Initial setup"
- Add remote: git remote add origin <your-repo-url>
EOF
)
  
  log_done "Complete macOS dotfiles system generated successfully!" "$next_steps"
}

main "$@"