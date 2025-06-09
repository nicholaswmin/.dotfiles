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
