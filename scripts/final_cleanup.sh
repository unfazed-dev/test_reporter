#!/bin/bash

echo "🔧 Final Cleanup - Removing Unused Imports"
echo "=========================================="

# Find all test files with unused app.locator import
find test/viewmodels -name "*_test.dart" -type f | while read file; do
  if grep -q "import 'package:kinly/app/app.locator.dart';" "$file"; then
    # Check if locator is actually used
    if ! grep -q "locator\|registerServices" "$file"; then
      # Remove the import
      sed -i '' "/import 'package:kinly\/app\/app.locator.dart';/d" "$file"
      echo "✓ Fixed $file"
    fi
  fi
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Running final analyzer..."
flutter analyze --no-pub
