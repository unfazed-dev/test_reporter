#!/usr/bin/env python3
"""
Fix stub test files by adding correct imports and uncommenting code.
"""

import re
from pathlib import Path
from typing import Optional, Tuple

BASE_DIR = Path(__file__).parent.parent
TEST_DIR = BASE_DIR / "test" / "viewmodels"

def camel_to_snake(name):
    """Convert CamelCase to snake_case"""
    return ''.join(['_' + c.lower() if c.isupper() else c for c in name]).lstrip('_')

def get_import_path_from_test_location(test_file: Path) -> Optional[Tuple[str, str]]:
    """Get import path based on test file location"""

    rel_path = test_file.relative_to(TEST_DIR)
    parts = list(rel_path.parts)

    if len(parts) < 2:
        return None

    # Remove the test filename
    parts = parts[:-1]

    # Build the import path
    # test/viewmodels/participant/shared/dashboard
    # -> lib/ui/views/participant/shared/dashboard

    viewmodel_dir = Path("lib/ui/views") / Path(*parts)

    # Get the viewmodel file name from test file name
    test_name = test_file.stem  # e.g., participant_shared_dashboard_viewmodel_test
    viewmodel_name = test_name.replace("_test", "")  # e.g., participant_shared_dashboard_viewmodel

    viewmodel_file = viewmodel_dir / f"{viewmodel_name}.dart"

    # Check if the viewmodel file exists
    full_path = BASE_DIR / viewmodel_file
    if not full_path.exists():
        return None

    # Convert to package import
    import_path = str(viewmodel_file).replace("lib/", "package:kinly/")

    # Extract class name from file name
    # participant_shared_dashboard_viewmodel -> ParticipantSharedDashboardViewModel
    class_name = ''.join(word.capitalize() for word in viewmodel_name.split('_'))

    return import_path, class_name

def fix_test_stub(test_file: Path) -> bool:
    """Fix a single test stub file"""

    result = get_import_path_from_test_location(test_file)
    if not result:
        return False

    import_path, class_name = result

    content = test_file.read_text()
    original = content

    # Add the correct import (uncommented)
    import_line = f"import '{import_path}';"

    # Replace the commented import placeholder
    content = re.sub(
        r"// Import your viewmodel\n// import 'package:kinly/path/to/\w+\.dart';",
        f"// Import ViewModel\n{import_line}",
        content
    )

    # Uncomment viewModel instantiation
    content = re.sub(
        r"      // viewModel = (\w+)\(\);",
        r"      viewModel = \1();",
        content
    )

    # Uncomment dispose
    content = re.sub(
        r"      // viewModel\.dispose\(\);",
        r"      viewModel.dispose();",
        content
    )

    if content != original:
        test_file.write_text(content)
        return True

    return False

def main():
    print("🔧 Fixing test stub files...\n")

    fixed_count = 0

    # Find all participant and provider test files
    for test_file in TEST_DIR.rglob("*_test.dart"):
        # Skip non-participant/provider tests
        rel_path = str(test_file.relative_to(TEST_DIR))
        if not (rel_path.startswith("participant") or rel_path.startswith("provider")):
            continue

        if fix_test_stub(test_file):
            print(f"✓ Fixed: {test_file.relative_to(TEST_DIR)}")
            fixed_count += 1

    print(f"\n✅ Fixed {fixed_count} test stub files")

if __name__ == '__main__':
    main()
