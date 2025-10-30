#!/usr/bin/env python3
"""
Script to reorganize test files into subdirectories matching the lib structure
Moves participant, provider, and participant_manager tests into organized folders
"""

from pathlib import Path
import shutil

def main():
    print("📁 Reorganizing test/viewmodels directory...")

    test_base = Path("test/viewmodels")

    # Create subdirectories
    participant_dir = test_base / "participant"
    provider_dir = test_base / "provider"
    participant_manager_dir = test_base / "participant_manager"

    participant_dir.mkdir(exist_ok=True)
    provider_dir.mkdir(exist_ok=True)
    participant_manager_dir.mkdir(exist_ok=True)

    moved_count = 0

    # Get all test files in the root
    test_files = list(test_base.glob("*.dart"))

    for test_file in test_files:
        file_name = test_file.name

        # Skip mock files
        if ".mocks.dart" in file_name:
            continue

        # Participant Manager files (check this first since it contains "participant")
        if file_name.startswith("participant_manager_"):
            # Extract the view name (e.g., "dashboard" from "participant_manager_dashboard_viewmodel_test.dart")
            view_name = file_name.replace("participant_manager_", "").replace("_viewmodel_test.dart", "").replace("_layout_viewmodel_test.dart", "")

            # Create subdirectory for the view
            if view_name == "layout":
                dest_dir = participant_manager_dir
            else:
                dest_dir = participant_manager_dir / view_name
                dest_dir.mkdir(exist_ok=True)

            dest_file = dest_dir / file_name
            print(f"  Moving {file_name} -> participant_manager/{view_name if view_name != 'layout' else ''}")
            shutil.move(str(test_file), str(dest_file))
            moved_count += 1

        # Participant files
        elif file_name.startswith("participant_"):
            # Extract the view name
            view_name = file_name.replace("participant_", "").replace("_viewmodel_test.dart", "").replace("_layout_viewmodel_test.dart", "")

            # Create subdirectory for the view
            if view_name == "layout":
                dest_dir = participant_dir
            else:
                dest_dir = participant_dir / view_name
                dest_dir.mkdir(exist_ok=True)

            dest_file = dest_dir / file_name
            print(f"  Moving {file_name} -> participant/{view_name if view_name != 'layout' else ''}")
            shutil.move(str(test_file), str(dest_file))
            moved_count += 1

        # Provider files
        elif file_name.startswith("provider_"):
            # Extract the view name
            view_name = file_name.replace("provider_", "").replace("_viewmodel_test.dart", "").replace("_layout_viewmodel_test.dart", "")

            # Create subdirectory for the view
            if view_name == "layout":
                dest_dir = provider_dir
            else:
                dest_dir = provider_dir / view_name
                dest_dir.mkdir(exist_ok=True)

            dest_file = dest_dir / file_name
            print(f"  Moving {file_name} -> provider/{view_name if view_name != 'layout' else ''}")
            shutil.move(str(test_file), str(dest_file))
            moved_count += 1

    print(f"\n✅ Reorganization complete!")
    print(f"\n📊 Summary:")
    print(f"  - Total files moved: {moved_count}")
    print(f"  - Participant tests: {len(list(participant_dir.rglob('*.dart')))}")
    print(f"  - Provider tests: {len(list(provider_dir.rglob('*.dart')))}")
    print(f"  - Participant Manager tests: {len(list(participant_manager_dir.rglob('*.dart')))}")

    print(f"\n📁 New structure:")
    print(f"  test/viewmodels/")
    print(f"    ├── participant/")
    for subdir in sorted(participant_dir.iterdir()):
        if subdir.is_dir():
            print(f"    │   ├── {subdir.name}/")
        elif subdir.suffix == ".dart":
            print(f"    │   └── {subdir.name}")
    print(f"    ├── provider/")
    for subdir in sorted(provider_dir.iterdir()):
        if subdir.is_dir():
            print(f"    │   ├── {subdir.name}/")
        elif subdir.suffix == ".dart":
            print(f"    │   └── {subdir.name}")
    print(f"    ├── participant_manager/")
    for subdir in sorted(participant_manager_dir.iterdir()):
        if subdir.is_dir():
            print(f"    │   ├── {subdir.name}/")
        elif subdir.suffix == ".dart":
            print(f"    │   └── {subdir.name}")
    print(f"    └── hub/")

if __name__ == "__main__":
    main()
