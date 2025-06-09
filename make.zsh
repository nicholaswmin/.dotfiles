#!/usr/bin/env zsh
# make.zsh - Complete macOS dotfiles system generator
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

# Source library functions
for lib_file in "$DOTFILES_ROOT"/_lib/*.sh; do
  [[ -f "$lib_file" ]] && source "$lib_file"
done

# Utility functions
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

# Color utility function
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

# Standard logging functions
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
EOF

  return 0
}

generate_init_command() {
  log "Generating init command..."
  
  cat > "_lib/init.sh" << 'EOF'
#!/usr/bin/env zsh
# init.sh - dotfiles repository initialization

# Initialize new dotfiles repository
init_cmd() {
  local remote_url="$1"
  
  # Check if dotfiles already exists
  if [[ -d "$DOTFILES_ROOT" ]]; then
    log_error "Dotfiles directory already exists: $DOTFILES_ROOT" \
      "- Remove existing directory: rm -rf $DOTFILES_ROOT" \
      "- Or use 'dotfiles restore' to sync existing repo"
    exit 1
  fi
  
  log "Initializing dotfiles repository..."
  
  # Create directory structure
  mkdir -p "$DOTFILES_ROOT"/{_lib,home/.config/macos,home/config/macos,tests} || {
    log_error "Failed to create directory structure"
    exit 1
  }
  
  # Copy current dotfiles tool to new repository
  cp -R "$PWD"/* "$DOTFILES_ROOT/" 2>/dev/null || {
    log_error "Failed to copy dotfiles tool"
    exit 1
  }
  
  # Initialize Git repository
  cd "$DOTFILES_ROOT" || exit 1
  git init || {
    log_error "Failed to initialize Git repository"
    exit 1
  }
  
  # Set default branch to main
  git checkout -b main 2>/dev/null || git branch -M main || {
    log_error "Failed to set default branch"
    exit 1
  }
  
  # Add remote if provided
  if [[ -n "$remote_url" ]]; then
    log "Adding remote origin: $remote_url"
    git remote add origin "$remote_url" || {
      log_error "Failed to add remote origin"
      exit 1
    }
  fi
  
  # Initial commit
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

# Utility functions
is_managed_symlink() {
  local path="$1"
  
  [[ -L "$path" ]] || return 1
  
  local target="$(readlink "$path")"
  [[ "$target" == "$DOTFILES_HOME"* ]]
}

calculate_repo_path() {
  local source_path="$1"
  local relative_path="${source_path#$HOME/}"
  
  # Handle paths that don't start with $HOME
  if [[ "$relative_path" == "$source_path" ]]; then
    log_error "Path must be within \$HOME: $source_path"
    return 1
  fi
  
  echo "$DOTFILES_HOME/$relative_path"
}

# Domain functions
link_file() {
  local source_path="$1"
  local repo_path
  
  validate_safe_path "$source_path" || return 1
  validate_file_exists "$source_path" || return 1
  
  repo_path="$(calculate_repo_path "$source_path")" || return 1
  
  # Check if already managed
  if is_managed_symlink "$source_path"; then
    log "Already managed: $source_path"
    return 0
  fi
  
  # Handle existing files in repo
  if [[ -e "$repo_path" ]]; then
    log_error "Target already exists in repository: $repo_path" \
      "- Remove existing file: rm -f \"$repo_path\"" \
      "- Or use different source path"
    return 1
  fi
  
  # Create parent directories
  mkdir -p "$(dirname "$repo_path")" || {
    log_error "Failed to create parent directory"
    return 1
  }
  
  # Handle conflicts in target location
  if [[ -e "$source_path" && ! -L "$source_path" ]]; then
    # Move original file to repo
    mv "$source_path" "$repo_path" || {
      log_error "Failed to move file to repository"
      return 1
    }
  elif [[ -L "$source_path" ]]; then
    # Handle existing symlink
    local existing_target="$(readlink "$source_path")"
    if [[ "$existing_target" != "$repo_path" ]]; then
      log_warn "Replacing existing symlink: $source_path → $existing_target"
      rm "$source_path" || {
        log_error "Failed to remove existing symlink"
        return 1
      }
      
      # Copy target of old symlink to repo
      if [[ -e "$existing_target" ]]; then
        cp -R "$existing_target" "$repo_path" || {
          log_error "Failed to copy symlink target"
          return 1
        }
      fi
    fi
  fi
  
  # Create symlink
  ln -s "$repo_path" "$source_path" || {
    log_error "Failed to create symlink"
    return 1
  }
  
  # Stage in Git
  cd "$DOTFILES_ROOT" || return 1
  git add "$repo_path" || {
    log_error "Failed to stage file in Git"
    return 1
  }
  
  return 0
}

# Main link command
link_cmd() {
  local source_path="$1"
  
  [[ -z "$source_path" ]] && {
    log_error "Path argument required" \
      "- Usage: dotfiles link <path>" \
      "- Example: dotfiles link ~/.zshrc"
    exit 1
  }
  
  # Expand path
  source_path="${source_path/#\~/$HOME}"
  
  log "Linking: $source_path"
  
  if [[ -d "$source_path" ]]; then
    # Handle directory
    log "Linking directory: $source_path"
    link_file "$source_path" || exit 1
  elif [[ -f "$source_path" ]]; then
    # Handle file
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
EOF

  return 0
}

generate_backup_command() {
  log "Generating backup command..."
  
  cat > "_lib/backup.sh" << 'EOF'
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
EOF

  return 0
}

generate_restore_command() {
  log "Generating restore command..."
  
  cat > "_lib/restore.sh" << 'EOF'
#!/usr/bin/env zsh
# restore.sh - restore dotfiles from remote repository

# Utility functions
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

# Domain functions
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
  
  # Get current branch
  local branch="$(git rev-parse --abbrev-ref HEAD)"
  
  # Pull latest changes
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
  
  # Find all files and directories in home/
  find "$DOTFILES_HOME" -type f -o -type d 2>/dev/null | while read -r item; do
    # Skip the home directory itself
    [[ "$item" == "$DOTFILES_HOME" ]] && continue
    
    # Calculate target path
    local target="$HOME/${item#$DOTFILES_HOME/}"
    local target_dir="$(dirname "$target")"
    
    # Create parent directory if needed
    [[ -d "$target_dir" ]] || mkdir -p "$target_dir"
    
    # Handle existing files
    if [[ -e "$target" && ! -L "$target" ]]; then
      # File exists and is not a symlink
      log_warn "Skipping existing file: $target"
      continue
    elif [[ -L "$target" ]]; then
      # Existing symlink - check if it points to our repo
      local existing_target="$(readlink "$target")"
      if [[ "$existing_target" == "$item" ]]; then
        # Already correctly linked
        continue
      else
        # Remove incorrect symlink
        rm "$target"
      fi
    fi
    
    # Create symlink
    ln -s "$item" "$target" && {
      restored+=("$target")
    } || {
      log_warn "Failed to create symlink: $target"
    }
  done
  
  # Report results
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

# Main restore command
restore_cmd() {
  local remote_url="$1"
  
  if [[ -d "$DOTFILES_ROOT" ]]; then
    # Existing repository - pull changes
    validate_git_repo "$DOTFILES_ROOT" || {
      log_error "Invalid dotfiles repository at $DOTFILES_ROOT" \
        "- Remove directory: rm -rf $DOTFILES_ROOT" \
        "- Run restore again with repository URL"
      exit 1
    }
    
    pull_changes || exit 1
  else
    # New setup - clone repository
    [[ -n "$remote_url" ]] || remote_url="$(prompt_for_remote)"
    
    clone_repository "$remote_url" || exit 1
  fi
  
  # Restore symlinks
  restore_symlinks || exit 1
  
  # Run install script
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

# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    log_error "Failed to install Homebrew"
    return 1
  }
  
  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# Update Homebrew
brew update || log_warn "Failed to update Homebrew"

# Essential CLI tools
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

# Development tools
brew install \
  node \
  python@3.11 \
  go \
  tmux \
  docker || log_warn "Some development tools failed to install"

# Essential apps
brew install --cask \
  1password \
  visual-studio-code \
  iterm2 \
  rectangle || log_warn "Some applications failed to install"

# Cleanup
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

# Source logging functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_lib/loggers.sh"

log "Running macOS setup..."

# Verify macOS
[[ "$(uname -s)" == "Darwin" ]] || {
  log_error "This setup script requires macOS"
  exit 1
}

# Run macOS configurations
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
# Test Suite Generation
# =============================================================================

generate_test_suite() {
  log "Generating comprehensive test suite..."
  
  # =============================================================================
  # Generate main.test.sh - Tests the generator itself
  # =============================================================================
  
  cat > "tests/main.test.sh" << 'EOF'
#!/usr/bin/env zsh
# main.test.sh - Core functionality tests for dotfiles generator

readonly TEST_NAME="Dotfiles Generator Core Tests"
readonly TEST_DIR="/tmp/dotfiles-test-$(date +%s)"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Test Utilities
# =============================================================================

test_start() {
  local test_name="$1"
  printf "Testing: %s... " "$test_name"
  ((TESTS_RUN++))
}

test_pass() {
  printf "✓ PASS\n"
  ((TESTS_PASSED++))
}

test_fail() {
  local reason="$1"
  printf "✗ FAIL"
  [[ -n "$reason" ]] && printf " ($reason)"
  printf "\n"
  ((TESTS_FAILED++))
}

# =============================================================================
# Setup and Cleanup
# =============================================================================

setup_test_environment() {
  mkdir -p "$TEST_DIR"
  cd "$TEST_DIR"
  
  # Copy the generator script (now called make.zsh)
  if [[ -f "$SCRIPT_DIR/../make.zsh" ]]; then
    cp "$SCRIPT_DIR/../make.zsh" . || {
      echo "ERROR: Failed to copy make.zsh"
      exit 1
    }
  else
    echo "ERROR: Cannot find make.zsh in parent directory"
    echo "Debug: Looking in: $SCRIPT_DIR/.."
    echo "Debug: Available files:"
    ls -la "$SCRIPT_DIR/.." || echo "Directory listing failed"
    exit 1
  fi
  
  chmod +x make.zsh
}

cleanup_test_environment() {
  cd /
  rm -rf "$TEST_DIR"
}

# =============================================================================
# Tests
# =============================================================================

test_generator_execution() {
  test_start "Generator execution"
  if ./make.zsh &>/dev/null; then
    test_pass
  else
    test_fail "Generator script failed"
  fi
}

test_file_structure() {
  test_start "Generated file structure"
  
  local required=(
    "dotfiles:file"
    "install.sh:file"
    "README.md:file"
    ".gitignore:file"
    "_lib:dir"
    "home:dir"
    "tests:dir"
    ".github:dir"
  )
  
  local missing=()
  for item in "${required[@]}"; do
    local path="${item%:*}"
    local type="${item#*:}"
    
    if [[ "$type" == "file" && ! -f "$path" ]]; then
      missing+=("$path")
    elif [[ "$type" == "dir" && ! -d "$path" ]]; then
      missing+=("$path")
    fi
  done
  
  if [[ ${#missing[@]} -eq 0 ]]; then
    test_pass
  else
    test_fail "Missing: ${missing[*]}"
  fi
}

test_library_files() {
  test_start "Library files"
  
  local libs=( loggers validation init link unlink backup restore )
  local missing=()
  
  for lib in "${libs[@]}"; do
    [[ -f "_lib/$lib.sh" ]] || missing+=("$lib.sh")
  done
  
  if [[ ${#missing[@]} -eq 0 ]]; then
    test_pass
  else
    test_fail "Missing: ${missing[*]}"
  fi
}

test_executable_permissions() {
  test_start "Executable permissions"
  
  if [[ -x "dotfiles" && -x "install.sh" ]]; then
    test_pass
  else
    test_fail "Missing execute permissions"
  fi
}

test_basic_commands() {
  test_start "Basic CLI commands"
  
  if ./dotfiles --help &>/dev/null && ./dotfiles --version &>/dev/null; then
    test_pass
  else
    test_fail "Help or version failed"
  fi
}

test_github_workflow() {
  test_start "GitHub Actions workflow"
  
  if [[ -f ".github/workflows/test.yml" ]]; then
    test_pass
  else
    test_fail "GitHub workflow missing"
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

run_all_tests() {
  printf "\n=== %s ===\n\n" "$TEST_NAME"
  
  setup_test_environment
  test_generator_execution
  test_file_structure
  test_library_files
  test_executable_permissions
  test_basic_commands
  test_github_workflow
  cleanup_test_environment
  
  printf "\n=== Results ===\n"
  printf "Run: %d | Passed: %d | Failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "✓ All tests passed!\n"
    exit 0
  else
    printf "✗ %d test(s) failed!\n" "$TESTS_FAILED"
    exit 1
  fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_all_tests
EOF

  # =============================================================================
  # Generate e2e.test.sh - Tests the CLI tool functionality
  # =============================================================================
  
  cat > "tests/e2e.test.sh" << 'EOF'
#!/usr/bin/env zsh
# e2e.test.sh - End-to-end CLI functionality tests

readonly TEST_NAME="Dotfiles CLI End-to-End Tests"
readonly TEST_ROOT="/tmp/dotfiles-e2e-$(date +%s)"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Test environment paths
readonly FAKE_HOME="$TEST_ROOT/home"
readonly FAKE_DOTFILES="$TEST_ROOT/.dotfiles"
readonly WORKSPACE="$TEST_ROOT/workspace"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# =============================================================================
# Test Framework
# =============================================================================

test_start() {
  printf "Testing: %s... " "$1"
  ((TESTS_RUN++))
}

test_pass() {
  printf "✓ PASS\n"
  ((TESTS_PASSED++))
}

test_fail() {
  printf "✗ FAIL (%s)\n" "$1"
  ((TESTS_FAILED++))
}

# =============================================================================
# Environment Setup
# =============================================================================

setup_test_environment() {
  # Create isolated environment
  mkdir -p "$FAKE_HOME"/.config/{nvim,git}
  mkdir -p "$WORKSPACE"
  
  # Create fake config files
  echo "# Test .zshrc" > "$FAKE_HOME/.zshrc"
  echo "# Test .gitconfig" > "$FAKE_HOME/.gitconfig"
  echo "set number" > "$FAKE_HOME/.config/nvim/init.vim"
  mkdir -p "$FAKE_HOME/.ssh"
  echo "Host *" > "$FAKE_HOME/.ssh/config"
  
  # Copy generated dotfiles tool - check if it exists first
  if [[ ! -d "$SCRIPT_DIR/_lib" ]]; then
    printf "ERROR: Generated dotfiles not found. Run generator first.\n" >&2
    exit 1
  fi
  
  cp -r "$SCRIPT_DIR"/* "$WORKSPACE/"
  cd "$WORKSPACE"
  
  # Override environment for safe testing
  export HOME="$FAKE_HOME"
  export DOTFILES_ROOT="$FAKE_DOTFILES"
  export DOTFILES_HOME="$FAKE_DOTFILES/home"
  
  # Create mock commands for system integration
  mkdir -p mock-bin
  
  # Mock git - log operations but don't fail
  cat > mock-bin/git << 'MOCKEOF'
#!/bin/bash
case "$1" in
  init) mkdir -p .git; exit 0 ;;
  add|commit) exit 0 ;;
  remote) exit 0 ;;
  rev-parse) echo "main"; exit 0 ;;
  clone) mkdir -p "$2"; cd "$2"; mkdir -p .git; exit 0 ;;
  pull|push) exit 0 ;;
  *) exit 0 ;;
esac
MOCKEOF
  
  # Mock brew - just acknowledge commands
  cat > mock-bin/brew << 'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
  
  # Mock defaults - acknowledge macOS commands
  cat > mock-bin/defaults << 'MOCKEOF'
#!/bin/bash
exit 0
MOCKEOF
  
  chmod +x mock-bin/*
  export PATH="$PWD/mock-bin:$PATH"
}

cleanup_test_environment() {
  cd /
  rm -rf "$TEST_ROOT"
  unset HOME DOTFILES_ROOT DOTFILES_HOME
}

# =============================================================================
# CLI Tests
# =============================================================================

test_init_command() {
  test_start "dotfiles init"
  
  if ./dotfiles init &>/dev/null; then
    if [[ -d "$FAKE_DOTFILES/.git" && -d "$FAKE_DOTFILES/home" ]]; then
      test_pass
    else
      test_fail "missing .git or home directory"
    fi
  else
    test_fail "init command failed"
  fi
}

test_link_file() {
  test_start "dotfiles link (file)"
  
  local test_file="$FAKE_HOME/.zshrc"
  local repo_file="$FAKE_DOTFILES/home/.zshrc"
  
  if ./dotfiles link "$test_file" &>/dev/null; then
    if [[ -L "$test_file" && -f "$repo_file" ]]; then
      local target="$(readlink "$test_file")"
      if [[ "$target" == "$repo_file" ]]; then
        test_pass
      else
        test_fail "symlink points to wrong target"
      fi
    else
      test_fail "symlink or repo file missing"
    fi
  else
    test_fail "link command failed"
  fi
}

test_link_directory() {
  test_start "dotfiles link (directory)"
  
  local test_dir="$FAKE_HOME/.ssh"
  local repo_dir="$FAKE_DOTFILES/home/.ssh"
  
  if ./dotfiles link "$test_dir" &>/dev/null; then
    if [[ -L "$test_dir" && -d "$repo_dir" && -f "$repo_dir/config" ]]; then
      test_pass
    else
      test_fail "directory link failed"
    fi
  else
    test_fail "link directory command failed"
  fi
}

test_unlink_file() {
  test_start "dotfiles unlink"
  
  # Link then unlink .gitconfig
  local test_file="$FAKE_HOME/.gitconfig"
  ./dotfiles link "$test_file" &>/dev/null
  
  if ./dotfiles unlink "$test_file" &>/dev/null; then
    if [[ -f "$test_file" && ! -L "$test_file" ]]; then
      test_pass
    else
      test_fail "file not restored properly"
    fi
  else
    test_fail "unlink command failed"
  fi
}

test_backup_no_remote() {
  test_start "dotfiles backup (no remote)"
  
  # Should handle gracefully when no remote configured
  if ./dotfiles backup "test" &>/dev/null; then
    test_fail "should fail without remote"
  else
    test_pass
  fi
}

test_error_handling() {
  test_start "error handling"
  
  # Test nonexistent file
  if ./dotfiles link "/nonexistent/file" &>/dev/null; then
    test_fail "should reject nonexistent files"
  elif ./dotfiles unknown-command &>/dev/null; then
    test_fail "should reject unknown commands"
  else
    test_pass
  fi
}

test_help_system() {
  test_start "help system"
  
  local help_output="$(./dotfiles --help 2>/dev/null)"
  local version_output="$(./dotfiles --version 2>/dev/null)"
  
  if [[ -n "$help_output" && -n "$version_output" ]]; then
    test_pass
  else
    test_fail "help or version output empty"
  fi
}

test_install_script() {
  test_start "install script execution"
  
  # Should run without errors in mocked environment
  if source ./install.sh &>/dev/null; then
    test_pass
  else
    test_fail "install script failed"
  fi
}

test_workflow_integration() {
  test_start "complete workflow"
  
  # Clean slate
  rm -rf "$FAKE_DOTFILES"
  
  # Full workflow: init → link → backup attempt
  if ./dotfiles init &>/dev/null &&
     ./dotfiles link "$FAKE_HOME/.config/nvim" &>/dev/null &&
     [[ -L "$FAKE_HOME/.config/nvim" ]]; then
    test_pass
  else
    test_fail "workflow integration failed"
  fi
}

# =============================================================================
# Main Execution
# =============================================================================

run_all_tests() {
  printf "\n=== %s ===\n\n" "$TEST_NAME"
  
  setup_test_environment
  
  # Core CLI functionality
  test_init_command
  test_link_file
  test_link_directory
  test_unlink_file
  
  # System integration
  test_backup_no_remote
  test_error_handling
  test_help_system
  test_install_script
  
  # Workflow
  test_workflow_integration
  
  cleanup_test_environment
  
  printf "\n=== Results ===\n"
  printf "Run: %d | Passed: %d | Failed: %d\n" "$TESTS_RUN" "$TESTS_PASSED" "$TESTS_FAILED"
  
  if [[ $TESTS_FAILED -eq 0 ]]; then
    printf "✓ All E2E tests passed!\n"
    exit 0
  else
    printf "✗ %d E2E test(s) failed!\n" "$TESTS_FAILED"
    exit 1
  fi
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && run_all_tests
EOF

  # =============================================================================
  # Generate test runner script
  # =============================================================================
  
  cat > "tests/run-all.sh" << 'EOF'
#!/usr/bin/env zsh
# run-all.sh - Execute all test suites

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🧪 Running Dotfiles Test Suite"
echo "================================"

# Run generator tests
echo
"$SCRIPT_DIR/main.test.sh"
main_result=$?

# Run CLI tests  
echo
"$SCRIPT_DIR/e2e.test.sh"
e2e_result=$?

# Summary
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
  # Disable analytics and telemetry
  HOMEBREW_NO_ANALYTICS: 1
  HOMEBREW_NO_AUTO_UPDATE: 1

jobs:
  test:
    name: Test on macOS
    runs-on: macos-latest
    
    steps:
    - name: Checkout repository
      uses: actions/checkout@v4
      
    - name: Set up environment
      run: |
        # Ensure we have the latest Xcode command line tools
        xcode-select --install || true
        
        # Set up zsh as default shell for consistency
        export SHELL=/bin/zsh
        
    - name: Validate generator script
      run: |
        # Check syntax
        zsh -n make.zsh
        
        # Make executable
        chmod +x make.zsh
        
        echo "✓ Generator script validation passed"
        
    - name: Run generator
      run: |
        # Run generator in clean directory
        ./make.zsh
        
        echo "✓ Generator execution completed"
        
    - name: Run test suite
      run: |
        # Execute all tests
        ./tests/run-all.sh
        
    - name: Validate generated structure
      run: |
        # Verify critical files exist
        test -f dotfiles || (echo "❌ Main executable missing" && exit 1)
        test -f install.sh || (echo "❌ Install script missing" && exit 1)
        test -f README.md || (echo "❌ Documentation missing" && exit 1)
        test -d _lib || (echo "❌ Library directory missing" && exit 1)
        test -d tests || (echo "❌ Tests directory missing" && exit 1)
        
        # Verify executables
        test -x dotfiles || (echo "❌ Main executable not executable" && exit 1)
        test -x install.sh || (echo "❌ Install script not executable" && exit 1)
        
        echo "✓ Generated structure validation passed"
        
    - name: Test CLI help system
      run: |
        # Test basic CLI functionality
        ./dotfiles --help >/dev/null || (echo "❌ Help command failed" && exit 1)
        ./dotfiles --version >/dev/null || (echo "❌ Version command failed" && exit 1)
        
        echo "✓ CLI help system validation passed"
        
    - name: Test error handling
      run: |
        # Test that invalid commands fail appropriately
        if ./dotfiles invalid-command >/dev/null 2>&1; then
          echo "❌ Should reject invalid commands"
          exit 1
        fi
        
        echo "✓ Error handling validation passed"
        
    - name: Performance check
      run: |
        # Ensure tests complete within reasonable time
        timeout 60s ./tests/run-all.sh || (echo "❌ Tests took too long" && exit 1)
        
        echo "✓ Performance check passed"
        
    - name: Generate test report
      if: always()
      run: |
        echo "## Test Report" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        
        if [ -f tests/main.test.sh ] && [ -f tests/e2e.test.sh ]; then
          echo "✅ Test suite generated successfully" >> $GITHUB_STEP_SUMMARY
          echo "✅ Main tests: Available" >> $GITHUB_STEP_SUMMARY  
          echo "✅ E2E tests: Available" >> $GITHUB_STEP_SUMMARY
        else
          echo "❌ Test suite generation failed" >> $GITHUB_STEP_SUMMARY
        fi
        
        if [ -f dotfiles ] && [ -x dotfiles ]; then
          echo "✅ CLI tool: Generated and executable" >> $GITHUB_STEP_SUMMARY
        else
          echo "❌ CLI tool: Generation failed" >> $GITHUB_STEP_SUMMARY
        fi
        
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Generated Files:**" >> $GITHUB_STEP_SUMMARY
        echo '```' >> $GITHUB_STEP_SUMMARY
        find . -type f -name "*.sh" -o -name "dotfiles" -o -name "*.md" -o -name "*.yml" | sort >> $GITHUB_STEP_SUMMARY
        echo '```' >> $GITHUB_STEP_SUMMARY
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
  # Parse arguments
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
  # validate_macos || exit 1
  # validate_cleanup_safety || exit 1
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
  
  # Final instructions
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