#!/bin/bash

# todo

# - still has rpoblem with breaking PS1 lines
# - shellcheck
# - test if reimplemented 
# - the following vars need implementation
BRANCH_MAXLEN=20
WORKDIR="Projects"

RED="$(tput setaf 1)"
GREEN="$(tput setaf 2)"
YELLOW="$(tput setaf 3)"
BLUE="$(tput setaf 4)"
MAGENTA="$(tput setaf 5)"
CYAN="$(tput setaf 6)"
RESET="$(tput setaf 7)"

is_git_dir () {
  echo $(git rev-parse --is-inside-work-tree 2> /dev/null)
}

get_path () {
  base=$(pwd) | xargs basename

  if [[ $(pwd)  == *"${base}"* ]]; then
    echo $(pwd) | sed "s/.*\(${WORKDIR}\)/\1/g" | sed -e "s/^${WORKDIR}\///" 
  else
   echo $(pwd)
  fi
}

to_script () {
  local result=()
  local script=("⁰" "¹" "²" "³" "⁴" "⁵" "⁶" "⁷" "⁸" "⁹")
  local splitd=($(echo $1|sed  's/\(.\)/\1 /g'))

  for t in ${splitd[@]}; do
    result+="${script[$t]}"
  done

  echo $result
}

branch_label () {
  local code=$? # must be 1st
  PS1="" # must be 2nd
  local arrow=">"

  local color="${GREEN}"
  local pathcolor="${RESET}"
  local pointer="${GREEN}${arrow}${RESET}"
  local errmsg=""
  local postfix=""

  if (($code > 0)); then
    color="${RED}"
    errmsg=" ${RED}􀡰 $code${RESET}"
    pointer="${RED}${arrow}${RESET}"
  fi
  
  if [[ $PWD == *"${WORKDIR}"* ]]; then
    local pathcolor="${MAGENTA}"
  fi

  if [ $(is_git_dir) ]; then
    local unsaved=$(git status --porcelain=v1 2>/dev/null | wc -l | xargs)
    local branch="($(git branch --show-current -q))"

    if (($unsaved > 0)); then
      color="${YELLOW}"
      postfix=$(to_script $unsaved)
    fi
  fi
  
  PS1+="◦ ${pathcolor}$(get_path)${RESET}${color}${branch}${postfix}${RESET}${errmsg}${pointer} "
}

PROMPT_COMMAND=branch_label
