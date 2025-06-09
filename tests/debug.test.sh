test() {
  local name="$1" command="$2"
  
  # Add a debug message to see what's being run
  echo "DEBUG: Evaluating command -> [ $command ]"

  ((TESTS_RUN++))

  # Run the command directly and check its exit status
  if eval "$command"; then
      printf "✓    %s\n" "$name"
      ((TESTS_PASSED++))
      return 0
  else
      printf "✗    %s\n" "$name"
      ((TESTS_FAILED++))
      return 1
  fi
}