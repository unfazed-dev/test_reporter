#!/bin/bash

echo "🔧 Fixing UI Test Imports"
echo "========================="

# Fix startup view tests
if [ -d "test/ui/views/startup" ]; then
  find test/ui/views/startup -name "*.dart" -type f | while read file; do
    sed -i '' "s|package:kinly/ui/views/startup/|package:kinly/ui/views/common/startup/|g" "$file"
    echo "✓ Fixed $file"
  done
fi

# Fix unknown view tests
if [ -d "test/ui/views/unknown" ]; then
  find test/ui/views/unknown -name "*.dart" -type f | while read file; do
    sed -i '' "s|package:kinly/ui/views/unknown/|package:kinly/ui/views/common/unknown/|g" "$file"
    echo "✓ Fixed $file"
  done
fi

echo ""
echo "✅ Done!"
echo ""
echo "Next: Run 'dart run build_runner build --delete-conflicting-outputs'"
