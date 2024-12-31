#!/usr/bin/env bats

source '.porcelain.bash'

# Mock the 'not' function for testing purposes
not() {
  return 0
}

# Mock the 'notfile' function for testing purposes
notfile() {
  [ -f "$1" ]
}

setup() {
  test_dir=$(mktemp -d)
}

teardown() {
  rm -rf "$test_dir"
}

@test "bytecount plain file" {
  local test_file="$test_dir/testfile.txt"
  echo "Hello, World!" > "$test_file"
  local expected_byte_count=$(wc -c < "$test_file" | xargs)
  run bytecount "$test_file"
  [ "$status" -eq 0 ]
  [ "$output" -eq "$expected_byte_count" ]
}

@test "bytecount gzip file" {
  local test_file="$test_dir/testfile.txt"
  echo "Hello, World!" > "$test_file"
  local expected_byte_count=$(gzip --best -c "$test_file" | wc -c | xargs)
  run bytecount "$test_file" --gzip
  [ "$status" -eq 0 ]
  [ "$output" -eq "$expected_byte_count" ]
}

@test "bytecount empty file" {
  local test_file="$test_dir/emptyfile.txt"
  touch "$test_file"
  local expected_byte_count=$(wc -c < "$test_file" | xargs)
  run bytecount "$test_file"
  [ "$status" -eq 0 ]
  [ "$output" -eq "$expected_byte_count" ]
}

@test "bytecount nonexistent file" {
  local test_file="$test_dir/nonexistentfile.txt"
  run bytecount "$test_file"
  [ "$status" -ne 0 ]
}
