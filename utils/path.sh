#!/bin/sh

# This file contains utility functions for resolving script paths.

# get_script_dir: Determines the absolute, resolved path of the calling script's directory.
#
# Arguments:
#   $1: The path to the script itself (typically "$0" from the calling script).
#
# Returns:
#   Prints the absolute, canonical path to the script's directory to stdout.
#   It handles symlinks and various ways of invoking the script.
#   Prioritizes `readlink -f` (GNU coreutils) for best results, with fallbacks
#   for more portable POSIX shells.
#
get_script_dir() {
    local script_path="$1"
    local resolved_path=""
    local script_dir=""

    # Try readlink -f first for robust symlink resolution (GNU coreutils)
    if command -v readlink >/dev/null 2>&1; then
        resolved_path=$(readlink -f "$script_path" || echo "$script_path")
    else
        # Fallback for systems without readlink -f
        resolved_path="$script_path"
    fi

    # Get the directory name of the resolved path.
    script_dir=$(dirname "$resolved_path")

    # If script_dir is a relative path (e.g., if script was run as ./install.sh
    # from another directory), make it absolute using the current working directory.
    # Use 'pwd -P' to get the physical path, resolving any symlinks in the CWD itself.
    # The ( ... ) runs this in a subshell, so it doesn't change the main script's CWD.
    if [ "${script_dir#/}" = "$script_dir" ]; then # Check if path is relative (doesn't start with /)
        (cd "$script_dir" >/dev/null 2>&1 && pwd -P)
    else # Already absolute
        echo "$script_dir"
    fi
}
