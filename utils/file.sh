#!/bin/sh

# Shared utility functions for file operations.
# Assumes that 'utils/log.sh' has already been sourced.

# Moves a specified file or directory to the system Trash.
# Usage: trash "/path/to/item"
trash() {
  log "moving to Trash: $1"
  mv "$1" "$HOME/.Trash/"
}

# Creates a symbolic link from source to target in $HOME.
# Ensures target directory exists & handles existing files.
#
# Usage: homelink "/path/to/source" "/path/to/target"
homelink() {
  source_file="$1"
  target_file="$2"

  # If the target already exists, handle it.
  if [ -e "$target_file" ]; then
    # If it's already a symlink pointing to our dotfiles, we're done.
    if [ "$(readlink "$target_file")" = "$source_file" ]; then
      log "already linked: $target_file"
      return
    fi

    # It's a real file or a different symlink. Move it to the Trash.
    log_warn "found existing file: $target_file"
    trash "$target_file"
  fi

  # Ensure the parent directory of the target exists.
  mkdir -p "$(dirname "$target_file")"

  # Create the new symbolic link.
  log "linking: $target_file"
  ln -s "$source_file" "$target_file"
}
