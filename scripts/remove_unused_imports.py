#!/usr/bin/env python3
"""
Remove unused mockito imports from test stub files.
"""

from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
TEST_DIR = BASE_DIR / "test" / "viewmodels"

def remove_unused_imports():
    """Remove unused mockito imports from test files"""
    fixed_count = 0

    for test_file in TEST_DIR.rglob("*_test.dart"):
        content = test_file.read_text()
        original = content

        # Remove unused mockito import
        if "import 'package:mockito/mockito.dart';" in content:
            # Check if mockito is actually used
            if "Mock" not in content or content.count("Mock") == 1:  # Only in import
                content = content.replace("import 'package:mockito/mockito.dart';\n", "")

        if content != original:
            test_file.write_text(content)
            print(f"✓ Removed unused import: {test_file.relative_to(TEST_DIR)}")
            fixed_count += 1

    return fixed_count

def main():
    print("🔧 Removing unused imports from test files...\n")

    count = remove_unused_imports()

    print(f"\n✅ Fixed {count} test files")

if __name__ == '__main__':
    main()
