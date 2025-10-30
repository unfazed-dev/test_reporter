#!/usr/bin/env python3
"""
Reorganize test files to match source folder structure.

Source structure:
  lib/ui/views/participant/shared/dashboard/
  lib/ui/views/participant/manager/dashboard/
  lib/ui/views/provider/shared/dashboard/
  lib/ui/views/provider/company/admin/dashboard/

Target test structure:
  test/viewmodels/participant/shared/dashboard/
  test/viewmodels/participant/manager/dashboard/
  test/viewmodels/provider/shared/dashboard/
  test/viewmodels/provider/company/admin/dashboard/
"""

import shutil
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
TEST_DIR = BASE_DIR / "test" / "viewmodels"
SRC_DIR = BASE_DIR / "lib" / "ui" / "views"

def get_target_path(test_file: Path) -> Path:
    """Determine target path based on source file structure"""
    filename = test_file.name

    # Participant shared views
    if filename.startswith("participant_shared_"):
        view_name = filename.replace("participant_shared_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "participant" / "shared" / view_name / filename

    # Participant manager views
    if filename.startswith("participant_manager_") and not filename.startswith("participant_manager_layout"):
        view_name = filename.replace("participant_manager_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "participant" / "manager" / view_name / filename

    # Participant startup
    if filename == "participant_startup_viewmodel_test.dart":
        return TEST_DIR / "participant" / "startup" / filename

    # Provider shared views
    if filename.startswith("provider_shared_"):
        view_name = filename.replace("provider_shared_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "shared" / view_name / filename

    # Provider independent
    if filename.startswith("provider_independent_"):
        view_name = filename.replace("provider_independent_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "independent" / view_name / filename

    # Provider startup
    if filename == "provider_startup_viewmodel_test.dart":
        return TEST_DIR / "provider" / "startup" / filename

    # Provider company startup
    if filename == "provider_company_startup_viewmodel_test.dart":
        return TEST_DIR / "provider" / "company" / "startup" / filename

    # Provider company shared views
    if filename.startswith("provider_company_shared_"):
        view_name = filename.replace("provider_company_shared_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "company" / "shared" / view_name / filename

    # Provider admin views
    if filename.startswith("provider_admin_"):
        view_name = filename.replace("provider_admin_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "company" / "admin" / view_name / filename

    # Provider employee views
    if filename.startswith("provider_employee_"):
        view_name = filename.replace("provider_employee_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "company" / "employee" / view_name / filename

    # Provider coordinator views
    if filename.startswith("provider_coordinator_"):
        view_name = filename.replace("provider_coordinator_", "").replace("_viewmodel_test.dart", "")
        return TEST_DIR / "provider" / "company" / "coordinator" / view_name / filename

    # No match - keep in current location
    return None

def reorganize_tests():
    """Move test files to match source structure"""
    moved_count = 0
    kept_count = 0

    # Get all test files in the root test/viewmodels directory
    test_files = [f for f in TEST_DIR.iterdir() if f.is_file() and f.suffix == ".dart"]

    for test_file in test_files:
        target_path = get_target_path(test_file)

        if target_path and target_path != test_file:
            # Create target directory
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # Move file
            shutil.move(str(test_file), str(target_path))
            print(f"✓ Moved: {test_file.name} -> {target_path.relative_to(TEST_DIR)}")
            moved_count += 1
        else:
            # Keep in current location
            kept_count += 1

    return moved_count, kept_count

def remove_old_directories():
    """Remove old test directories that don't match the new structure"""
    old_dirs = [
        TEST_DIR / "participant_manager",
    ]

    removed = 0
    for old_dir in old_dirs:
        if old_dir.exists():
            print(f"⚠ Removing old directory: {old_dir.relative_to(BASE_DIR)}")
            shutil.rmtree(old_dir)
            removed += 1

    return removed

def main():
    print("🔧 Reorganizing test files to match source structure...\n")

    moved, kept = reorganize_tests()
    removed = remove_old_directories()

    print(f"\n✅ Reorganization complete!")
    print(f"   Moved: {moved} files")
    print(f"   Kept: {kept} files (non-participant/provider)")
    print(f"   Removed: {removed} old directories")

if __name__ == '__main__':
    main()
