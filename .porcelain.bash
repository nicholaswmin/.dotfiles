#!/bin/bash

# Porcelain
# - stricly user-facing commands.
# - porcelain/plumbing naming convention explained here:
#   read: https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain
# 
source "$HOME/.dotfiles/.plumbing.bash"


# **
# focus a running, GUI-based MacOS app.
# - might require manually setting MacOS permissions.
#   Specific instructions will be printed if it fails.
#
#   usage: focus "<app name>"
# example: focus "Safari"
# **
focus () {
  not "$1" "app name" || return 1

  can_control_apps || return 1
  not_installed "$1" || return 1
  not_running "$1" || return 1

  osascript -e 'tell application "System Events" to tell process '"\"$1\"" \
            -e 'set frontmost to true' \
            -e 'end tell'

  if [ $? -ne 0 ]; then
    printdim "might require manually setting MacOS permissions."
    printdim "see: ${FUNCNAME}() docs at: $(basename "${BASH_SOURCE[0]}")"
    return 1
  fi

  return 0
}

# estimate file size in bytes
# - optionally if file was gzipped
# 
#   usage: bytecount "<filename>"
# example: bytecount foo.txt
#          bytecount foo.txt --gzip
bytecount() {
  not "$1" "filename" || return 1
  notfile "$1" || return 1

  if [ "$2" = "--gzip" ]; then
    byte_count=$(gzip --best -c "$1" | wc -c)
  else
    byte_count=$(wc -c <"$1")
  fi

  echo "$byte_count" | xargs
  return 0
}

# backup various non-symlinked settings 
#    usage: backup
#  example: backup
backup() {  
  backup_terminal_profile "${1:-"$HOME/.dotfiles/terminal"}"
  local status=$?
  
  printok "done, now commit and push..."

  return $status
}

# restore various non-symlinked settings 
# 
#   usage: restore
# example: restore
restore() {
  restore_terminal_profile "${1:-"$HOME/.dotfiles/terminal"}"
  local status=$?
  
  printok "restore completed. restart Terminal.app..."
  
  return $status
}

# apply changes in .bash_profile & .bash_rc
# - a missing .bash_rc will be logged but won't cause an error.
#   
#    usage: refresh
#  example: refresh
refresh() { 
  source "$HOME/.bash_profile"
  printdim "▸ sourced .bash_profile"

  [ -f "$HOME/.bash_rc" ] \
    && { source "$HOME/.bash_rc"; echo "- sourced .bash_rc"; } \
    || printdim "▸ skipped missing .bash_rc"

  printok "refreshed"
}

"$@"
