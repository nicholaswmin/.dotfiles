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
