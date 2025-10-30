#!/usr/bin/env python3
"""
Fix duplicate platform suffixes in class names.

The script generated class names like:
  ParticipantManagerDashboardViewMobileMobile
  ParticipantManagerDashboardViewDesktopDesktop
  ParticipantManagerDashboardViewTabletTablet

Should be:
  ParticipantManagerDashboardViewMobile
  ParticipantManagerDashboardViewDesktop
  ParticipantManagerDashboardViewTablet
"""

import re
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
VIEW_DIRS = [
    BASE_DIR / "lib" / "ui" / "views" / "participant",
    BASE_DIR / "lib" / "ui" / "views" / "provider",
]

def fix_platform_files():
    """Fix platform-specific view files"""
    count = 0

    for view_dir in VIEW_DIRS:
        for pattern in ["*.mobile.dart", "*.desktop.dart", "*.tablet.dart"]:
            for view_file in view_dir.rglob(pattern):
                content = view_file.read_text()
                original = content

                # Fix class names
                # ParticipantManagerDashboardViewMobileMobile -> ParticipantManagerDashboardViewMobile
                content = re.sub(r'(\w+ViewMobile)Mobile\b', r'\1', content)
                content = re.sub(r'(\w+ViewDesktop)Desktop\b', r'\1', content)
                content = re.sub(r'(\w+ViewTablet)Tablet\b', r'\1', content)

                if content != original:
                    view_file.write_text(content)
                    print(f"✓ Fixed: {view_file.relative_to(BASE_DIR)}")
                    count += 1

    return count

def main():
    print("🔧 Fixing duplicate platform suffixes in class names...\n")

    count = fix_platform_files()

    print(f"\n✅ Fixed {count} files")

if __name__ == '__main__':
    main()
