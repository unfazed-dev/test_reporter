#!/bin/bash

# Kinly Route Generator Script
# Generates all views, viewmodels, and layouts based on the defined route structure

set -e

echo "🚀 Kinly Route Generator"
echo "=========================================="
echo ""

# Check if Dart is available
if ! command -v dart &> /dev/null; then
    echo "❌ Error: Dart is not installed or not in PATH"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

echo "📍 Working directory: $PROJECT_ROOT"
echo ""

# Run the generator
echo "🏗️  Generating views and viewmodels..."
echo ""
dart run scripts/generate_routes.dart

echo ""
echo "=========================================="
echo "✅ Generation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Review generated files in lib/ui/views/ and lib/ui/layouts/"
echo "   2. Update lib/app/app.dart with the route definitions"
echo "   3. Run: dart run build_runner build --delete-conflicting-outputs"
echo "   4. Run: flutter test"
echo ""
echo "💡 Tip: You can customize the templates in scripts/generate_routes.dart"
echo ""
