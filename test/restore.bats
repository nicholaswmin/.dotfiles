#!/usr/bin/env bats

source .porcelain.bash

@test "restores terminal.app profile" {
  skip "avoid messing up local profiles"
}


@test "handles import failures" {
  # mock 'defaults' to simulate failure
  function defaults() { return 1; }

  run restore "$TEST_DIR"
  [ "$status" -gt 0 ]
  [[ "$output" == *"Failed"* ]]
}