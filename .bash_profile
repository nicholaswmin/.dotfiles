#!/bin/bash

### bootstrap 

# load .profile & any .bashrc
if [ -r ~/.profile ]; then . ~/.profile; fi
case "$-" in *i*) if [ -r ~/.bashrc ]; then . ~/.bashrc; fi;; esac

# custom

# git autompletions
if [ -f ~/.dotfiles/.git-completion.bash ]; then
  . ~/.dotfiles/.git-completion.bash
fi

# gh completions 
eval "$(gh completion -s bash)"

# utility functions
source ~/.dotfiles/.ps1.bash
source ~/.dotfiles/.porcelain.bash


### env. vars

# make that warning shut the fuck up for a second
# export BASH_SILENCE_DEPRECATION_WARNING=1
# Set zed as .git editor for rebase/amends etc..
export EDITOR="zed --wait"

### alias

# homes
alias home="cd $HOME"
alias Home="cd $HOME"
alias HOME="cd $HOME"
alias hOMe="cd $HOME"

# work projects
alias projects="cd /Users/nicholaswmin/Projects"
alias Projects="cd /Users/nicholaswmin/Projects"
alias pRojects="cd /Users/nicholaswmin/Projects"

# start a local HTTP server on localhost:8080
# e.g: "serve" or "serve dist/"
alias serve="npx -y serve -p 8080 --no-port-switching"
