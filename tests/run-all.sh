#!/usr/bin/env zsh
# run-all.sh - Execute all test suites

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🧪 Running Dotfiles Test Suite"
echo "================================"

echo
echo "Running generator tests..."
"$SCRIPT_DIR/main.test.sh"
main_result=$?

echo
echo "Running CLI tests..."
"$SCRIPT_DIR/e2e.test.sh"
e2e_result=$?

echo
echo "📊 Final Results"
echo "================"
if [[ $main_result -eq 0 && $e2e_result -eq 0 ]]; then
  echo "✅ All test suites passed!"
  exit 0
else
  echo "❌ Some tests failed:"
  [[ $main_result -ne 0 ]] && echo "  - Generator tests failed"
  [[ $e2e_result -ne 0 ]] && echo "  - CLI tests failed"
  exit 1
fi
