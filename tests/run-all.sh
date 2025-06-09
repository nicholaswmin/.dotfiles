#!/bin/bash
echo "🧪 Running Dotfiles Test Suite"
echo "================================"
echo "▶ Running generator tests..."
bash tests/main.test.sh
main_result=$?

echo "▶ Running CLI tests..."
bash tests/e2e.test.sh
e2e_result=$?

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
