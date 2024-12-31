#!/bin/bash

# Plumbing
# stricly non-user-facing commands, helplers listed here are called by scripts


# Get ANSI color code from shell theme. 
# Respects NO_COLOR convention: https://no-color.org/
# 
#   usage: color "<color code 1..8>"
# example: color 3
color() { [ -z "$NO_COLOR" ] && tput setaf "$1" || echo ""; }

# print error message to stderr
# 
#   usage: printerr "<message>"
# example: printerr "File not found"
printerr() {
  local color=$(color "1")
  local reset=$(color "7")
  
  echo -e "\n${color}$1${reset}\n">&1
}

# print dim/muted message to stderr
# 
# - for ancillary logging of failed operations or "how to fix" instructions. 
#   For logging non-fatal issues that are expected to occur at times.
# - use sparingly and be concise when used. Dont clutter every command with
#   pointless how-to-fix instructions.
#   Can also be (very sparingly!) used for logging failed sub-steps of
#   successful operations, if relevant failed action was expected to fail
#   at times in a non-fatal manner.
#
#   usage: printdim "<message>"
# example: printdim "skipped file bar.txt because its missing"
printdim() {
  local color=$(color "8")
  local reset=$(color "7")
  
  echo -e "${color}$1${reset}" >&1
}

# print success message to stdout
# 
#   usage: printok "<message>"
# example: printok "file updated!"
printok() {
  local color=$(color "2")
  local reset=$(color "7")
  
  echo -e "${color}$1${reset}" >&1
}

# test func. parameter, echo custom message if missing
# 
#   usage: not <parameter> "<parameter name>" 
# example: not "$1" "filename" || return 1
not() {
  local error=$(color "1")
  local reset=$(color "7")

  if [ -z "$1" ]; then
    printerr "${error}missing parameter: $2${reset}"
    return 1
  fi
}

# test if filename refers to actual file
# 
#   usage: notfile <parameter> "<parameter name>"
# example: notfile "$1" "filename" || return 1
notfile() {
  if [ ! -f "$1" ]; then
    printerr "file '$1' does not exist/or is not a regular file"
    return 1
  fi

  return 0
}

# test if application is currently running
# 
#   usage: not_running "<application-name>"
# example: not_running "Safari" || return 1
not_running() {
  not_installed "$1" || return 1

  if pgrep -x "$1" > /dev/null; then
    return 0
  fi

  printerr "app: '$1' is not currently running"
  return 1
}

# test if application is installed as MacOS native app.
# 
#   usage: not_installed "<application-name>"
# example: not_installed "Google Chrome" || return 1
not_installed() {
  if [ -d "/Applications/$1.app" ]; then
    return 0
  fi

  printerr "app: '$1' is not installed as a MacOS application"

  return 1
}

# test if shell can control other MacOS apps
# 
#   usage: can_control_apps
# example: can_control_apps || return 1
can_control_apps() {
  osascript -e 'tell application "System Events" to get the name of every process' > /dev/null 2>&1
  if [ $? -eq 0 ]; then return 0; fi

  printerr "cannot use System Events to command other apps."
  print_permissions_instructions

  return 1
}

# print manual MacOS permissions instructions 
# - tested on Apple M2 MacOS Sonoma 14.4.1, bundled Safari & others.
# 
#   usage: print_permissions_instructions
# example: print_permissions_instructions
print_permissions_instructions() {
  apple_docs_url="https://developer.apple.com/documentation"

  printdim "Open: MacOS Settings > Privacy & Security"
  printdim ""
  printdim "▸ For *each* of tabs: Automation, Accessibility, Developer Tools"
  printdim "▸ Add <terminal> to allowed list,"
  printdim "     where <terminal> is name of your shell, e.g. Terminal.app"
  printdim ""
  printdim "▸ permissions are set just *once* but must be done manually."
  printdim "▸ ensure you understand all security implications if proceeding."
  printdim "▸ more info: $apple_docs_url/uikit/protecting-the-user-s-privacy"
}


# Export Terminal.app settings (theme, shell settings etc)
# 
#  usage: backup_terminal_profile "<output-directory>"
# example: backup_terminal_profile "$HOME/.dotfiles/terminal"
backup_terminal_profile() {
  not "$1" "output directory" || return 1

  OUTPUT_DIR="${1}"
  OUTPUT_FILE="backup.terminal"

  # Create the output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"
  defaults export com.apple.Terminal "$OUTPUT_DIR/$OUTPUT_FILE.plist"
  
  if [ $? -gt 0 ]; then
    printerr "Failed to backup Terminal.app profile"
    return 1 
  fi

  printdim "Terminal profile exported to $OUTPUT_DIR/$OUTPUT_FILE.plist"
  return 0
}


# Import Terminal.app settings (theme, shell settings etc)
# 
# usage: restore_terminal_profile "<input-directory>"
# example: restore_terminal_profile "$HOME/.dotfiles/terminal"
restore_terminal_profile() {
  not "$1" "input directory" || return 1

  INPUT_DIR="${1}"
  INPUT_FILE="backup.terminal"
  defaults import com.apple.Terminal "$INPUT_DIR/$INPUT_FILE.plist"
  
  if [ $? -gt 0 ]; then
    printerr "Failed to restore Terminal.app profile"
    return 1
  fi
  
  printdim "Terminal.app profile restored from $INPUT_DIR/$INPUT_FILE.plist"
  return 0
}
