#!/usr/bin/env bats

source '.porcelain.bash'

# just 1, unavoidable mock
can_control_apps() { return 0; }

setup_file() {
  osascript -e 'tell application "Safari" to activate'
  osascript -e 'tell application "Reminders" to quit'
}

teardown_file() { osascript -e 'tell application "Safari" to quit'; }

# Test cases

@test "focus function succeeds for running app" {
  run focus "Safari"
  [ "$status" -eq 0 ]
}

@test "focus function fails if can_control_apps returns 1" {
  can_control_apps() {
    return 1
  }

  run focus "Safari"
  [ "$status" -eq 1 ]
}

@test "focus function fails if no argument is passed" {
  run focus ""
  [ "$status" -eq 1 ]
  echo $output | grep -e "app name"
}

@test "focus function fails if not_installed returns 1" {
  run focus "NonExistentApp"
  [ "$status" -eq 1 ]
  echo $output | grep -e "not installed"
}

@test "focus function fails if not_running returns 1" {
  run focus "Reminders"
  [ "$status" -eq 1 ]
  echo $output | grep -e "not installed"
}
