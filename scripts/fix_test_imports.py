#!/usr/bin/env python3
"""
Fix test file imports to point to correct ViewModel paths.

Old import: import 'package:kinly/ui/views/participant_shared_dashboard_viewmodel.dart';
New import: import 'package:kinly/ui/views/participant/shared/dashboard/participant_shared_dashboard_viewmodel.dart';
"""

import re
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
TEST_DIR = BASE_DIR / "test" / "viewmodels"

def get_viewmodel_import_path(viewmodel_class_name: str) -> str:
    """Get the correct import path for a ViewModel class"""

    # Participant shared
    if viewmodel_class_name.startswith("ParticipantShared") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ParticipantShared(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/participant/shared/{view_name}/participant_shared_{view_name}_viewmodel.dart"

    # Participant manager
    if viewmodel_class_name.startswith("ParticipantManager") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ParticipantManager(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/participant/manager/{view_name}/participant_manager_{view_name}_viewmodel.dart"

    # Participant startup
    if viewmodel_class_name == "ParticipantStartupViewModel":
        return "package:kinly/ui/views/participant/startup/participant_startup_viewmodel.dart"

    # Provider shared
    if viewmodel_class_name.startswith("ProviderShared") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderShared(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/shared/{view_name}/provider_shared_{view_name}_viewmodel.dart"

    # Provider independent
    if viewmodel_class_name.startswith("ProviderIndependent") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderIndependent(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/independent/{view_name}/provider_independent_{view_name}_viewmodel.dart"

    # Provider startup
    if viewmodel_class_name == "ProviderStartupViewModel":
        return "package:kinly/ui/views/provider/startup/provider_startup_viewmodel.dart"

    # Provider company startup
    if viewmodel_class_name == "ProviderCompanyStartupViewModel":
        return "package:kinly/ui/views/provider/company/startup/provider_company_startup_viewmodel.dart"

    # Provider company shared
    if viewmodel_class_name.startswith("ProviderCompanyShared") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderCompanyShared(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/company/shared/{view_name}/provider_company_shared_{view_name}_viewmodel.dart"

    # Provider admin
    if viewmodel_class_name.startswith("ProviderAdmin") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderAdmin(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/company/admin/{view_name}/provider_admin_{view_name}_viewmodel.dart"

    # Provider employee
    if viewmodel_class_name.startswith("ProviderEmployee") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderEmployee(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/company/employee/{view_name}/provider_employee_{view_name}_viewmodel.dart"

    # Provider coordinator
    if viewmodel_class_name.startswith("ProviderCoordinator") and viewmodel_class_name.endswith("ViewModel"):
        view_name = re.sub(r'ProviderCoordinator(.+)ViewModel', r'\1', viewmodel_class_name)
        view_name = ''.join(['_' + c.lower() if c.isupper() else c for c in view_name]).lstrip('_')
        return f"package:kinly/ui/views/provider/company/coordinator/{view_name}/provider_coordinator_{view_name}_viewmodel.dart"

    return None

def fix_test_file_imports():
    """Fix imports in all test files"""
    fixed_count = 0

    # Find all test files
    for test_file in TEST_DIR.rglob("*_test.dart"):
        content = test_file.read_text()
        original = content

        # Find ViewModel class name in the test file
        # Pattern: final viewModel = SomeViewModel();
        match = re.search(r'final viewModel = (\w+ViewModel)\(\);', content)

        if match:
            viewmodel_class = match.group(1)
            correct_import = get_viewmodel_import_path(viewmodel_class)

            if correct_import:
                # Replace the import statement
                # Look for any import of the ViewModel
                old_import_pattern = rf"import 'package:kinly/[^']+{viewmodel_class.lower()}\.dart';"

                if re.search(old_import_pattern, content):
                    content = re.sub(
                        old_import_pattern,
                        f"import '{correct_import}';",
                        content
                    )

                if content != original:
                    test_file.write_text(content)
                    print(f"✓ Fixed: {test_file.relative_to(TEST_DIR)}")
                    fixed_count += 1

    return fixed_count

def main():
    print("🔧 Fixing test file imports...\n")

    count = fix_test_file_imports()

    print(f"\n✅ Fixed {count} test files")

if __name__ == '__main__':
    main()
