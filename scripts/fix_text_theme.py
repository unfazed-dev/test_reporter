#!/usr/bin/env python3
"""
Fix textTheme usage in generated mobile view files.

Changes:
  theme.textTheme.headlineMedium
To:
  Theme.of(context).textTheme.headlineMedium

(ShadTextTheme doesn't have these properties, use Flutter's TextTheme instead)
"""

from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
VIEW_DIRS = [
    BASE_DIR / "lib" / "ui" / "views" / "participant",
    BASE_DIR / "lib" / "ui" / "views" / "provider",
]

def fix_mobile_files():
    """Fix theme.textTheme references in mobile view files"""
    count = 0

    for view_dir in VIEW_DIRS:
        for view_file in view_dir.rglob("*.mobile.dart"):
            content = view_file.read_text()
            original = content

            # Replace theme.textTheme with Theme.of(context).textTheme
            content = content.replace(
                "theme.textTheme.headlineMedium",
                "Theme.of(context).textTheme.headlineMedium"
            )
            content = content.replace(
                "theme.textTheme.bodyLarge",
                "Theme.of(context).textTheme.bodyLarge"
            )

            if content != original:
                view_file.write_text(content)
                print(f"✓ Fixed: {view_file.relative_to(BASE_DIR)}")
                count += 1

    return count

def main():
    print("🔧 Fixing textTheme usage in mobile views...\n")

    count = fix_mobile_files()

    print(f"\n✅ Fixed {count} files")

if __name__ == '__main__':
    main()
