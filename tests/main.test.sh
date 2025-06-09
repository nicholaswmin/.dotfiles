#!/usr/bin/env zsh
printf "PWD: %s\n" "$PWD"
ls -la
printf "\n"

if [[ -f dotfiles ]]; then
  printf "dotfiles exists\n"
  if [[ -x dotfiles ]]; then
    printf "dotfiles is executable\n"
    ./dotfiles --help 2>&1 | head -5
  else
    printf "dotfiles not executable\n"
    chmod +x dotfiles
  fi
else
  printf "dotfiles missing\n"
fi

exit 0