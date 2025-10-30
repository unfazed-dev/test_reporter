#!/usr/bin/env python3
"""
Fix incorrect imports in generated view files.

The script generator created imports like:
  import 'participant_manager_dashboard_view_viewmodel.dart';

Should be:
  import 'participant_manager_dashboard_viewmodel.dart';

Also fixes platform-specific file imports.
"""

import re
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
VIEW_DIRS = [
    BASE_DIR / "lib" / "ui" / "views" / "participant",
    BASE_DIR / "lib" / "ui" / "views" / "provider",
]

def fix_main_view_files():
    """Fix main *_view.dart files"""
    count = 0
    for view_dir in VIEW_DIRS:
        for view_file in view_dir.rglob("*_view.dart"):
            # Skip platform-specific files
            if any(x in view_file.name for x in ['.mobile.', '.desktop.', '.tablet.']):
                continue

            content = view_file.read_text()

            # Fix: participant_manager_dashboard_view_viewmodel.dart
            # To: participant_manager_dashboard_viewmodel.dart
            new_content = re.sub(
                r"import '([a-z_]+)_view_viewmodel\.dart';",
                r"import '\1_viewmodel.dart';",
                content
            )

            if new_content != content:
                view_file.write_text(new_content)
                print(f"✓ Fixed: {view_file.relative_to(BASE_DIR)}")
                count += 1

    return count

def fix_platform_view_files():
    """Fix .mobile/.desktop/.tablet files"""
    count = 0
    for view_dir in VIEW_DIRS:
        for pattern in ["*.mobile.dart", "*.desktop.dart", "*.tablet.dart"]:
            for view_file in view_dir.rglob(pattern):
                content = view_file.read_text()
                original = content

                # Fix viewmodel imports
                # From: import 'participantmanagerdashboard_viewmodel.dart';
                # To: import 'participant_manager_dashboard_viewmodel.dart';

                # Get the base name from the file
                # E.g., participant_manager_dashboard_view.mobile.dart
                # -> participant_manager_dashboard
                base_name = view_file.name.replace('.mobile.dart', '').replace('.desktop.dart', '').replace('.tablet.dart', '')
                if base_name.endswith('_view'):
                    base_name = base_name[:-5]  # Remove '_view'

                # Create correct imports
                viewmodel_import = f"import '{base_name}_viewmodel.dart';"
                mobile_import = f"import '{base_name}_view.mobile.dart';"

                # Fix viewmodel import (handle various incorrect patterns)
                content = re.sub(
                    r"import '[a-z]+_viewmodel\.dart';",
                    viewmodel_import,
                    content
                )

                # Fix mobile view import in desktop/tablet files
                if '.desktop.dart' in view_file.name or '.tablet.dart' in view_file.name:
                    content = re.sub(
                        r"import '[a-z]+_viewmobile\.dart';",
                        mobile_import,
                        content
                    )

                if content != original:
                    view_file.write_text(content)
                    print(f"✓ Fixed: {view_file.relative_to(BASE_DIR)}")
                    count += 1

    return count

def main():
    print("🔧 Fixing generated view imports...\n")

    main_count = fix_main_view_files()
    platform_count = fix_platform_view_files()

    total = main_count + platform_count
    print(f"\n✅ Fixed {total} files ({main_count} main views, {platform_count} platform views)")

if __name__ == '__main__':
    main()
