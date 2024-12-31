#!/usr/bin/env bats

source .porcelain.bash

setup() {
  # temp. dir for testing
  export TEST_DIR=$(mktemp -d)
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "creates backup directory" {
  run backup "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -d "$TEST_DIR" ]
}

@test "backs up terminal.app profile" {
  run backup "$TEST_DIR"
  [ "$status" -eq 0 ]
  [ -f "$TEST_DIR/backup.terminal.plist" ]
}

@test "handles export failures" {
  # mock 'defaults' to simulate failure
  function defaults() { return 1; }

  run backup "$TEST_DIR"
  [ "$status" -gt 0 ]
  [[ "$output" == *"Failed"* ]]
}
