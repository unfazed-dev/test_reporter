#!/usr/bin/env python3
"""
Script to generate test files for all Hub ViewModels
Creates basic ViewModel test structure following TDD best practices
"""

from pathlib import Path

def snake_to_pascal(snake_str):
    """Convert snake_case to PascalCase"""
    return ''.join(word.capitalize() for word in snake_str.split('_'))

def create_viewmodel_test_file(file_path, viewmodel_class_name, view_path):
    """Create basic ViewModel test file with Arrange-Act-Assert pattern"""
    content = f"""import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/app/app.locator.dart';
import 'package:kinly/{view_path}';

// TODO: When you need mocks, add them here:
// import 'package:mockito/annotations.dart';
// import 'package:mockito/mockito.dart';
//
// @GenerateMocks([RouterService, SomeOtherService])
// Then run: flutter pub run build_runner build --delete-conflicting-outputs

void main() {{
  late {viewmodel_class_name} viewModel;

  setUp(() {{
    // TODO: Register test dependencies when needed
    // Example:
    // mockRouterService = MockRouterService();
    // locator.registerSingleton<RouterService>(mockRouterService);

    viewModel = {viewmodel_class_name}();
  }});

  tearDown(() async {{
    await locator.reset();
  }});

  group('{viewmodel_class_name} -', () {{
    test('should be created successfully', () {{
      // Assert
      expect(viewModel, isA<{viewmodel_class_name}>());
    }});

    // TODO: Add tests for ViewModel methods
    // Follow TDD: Write test first, then implement
    // Use Arrange-Act-Assert pattern:
    //
    // test('methodName should do something when condition', () {{
    //   // Arrange - Set up test data and mocks
    //
    //   // Act - Call the method being tested
    //
    //   // Assert - Verify the expected outcome
    // }});
  }});
}}
"""
    file_path.write_text(content)

def main():
    print("🧪 Creating Hub ViewModel Test Files...")

    # Base paths
    lib_base = Path("lib/ui/views/hub")
    test_base = Path("test/viewmodels/hub")

    # Shared views (10)
    shared_views = [
        ("hub_inbox", "Hub Inbox"),
        ("hub_settings", "Hub Settings"),
        ("hub_payslips", "Hub Payslips"),
        ("hub_documents", "Hub Documents"),
        ("hub_calendar", "Hub Calendar"),
        ("hub_directory", "Hub Directory"),
        ("hub_announcements", "Hub Announcements"),
        ("hub_training", "Hub Training"),
        ("hub_time_off", "Hub Time Off"),
        ("hub_expenses", "Hub Expenses"),
    ]

    # Support Coordinator views (11)
    support_coordinator_views = [
        ("support_coordinator_dashboard", "Support Coordinator Dashboard"),
        ("support_coordinator_participants", "Support Coordinator Participants"),
        ("support_coordinator_providers", "Support Coordinator Providers"),
        ("support_coordinator_invoices", "Support Coordinator Invoices"),
        ("support_coordinator_meetings", "Support Coordinator Meetings"),
        ("support_coordinator_funds", "Support Coordinator Funds"),
        ("support_coordinator_requests", "Support Coordinator Requests"),
        ("support_coordinator_journal", "Support Coordinator Journal"),
        ("support_coordinator_payments", "Support Coordinator Payments"),
        ("support_coordinator_travel_book", "Support Coordinator Travel Book"),
        ("support_coordinator_shop", "Support Coordinator Shop"),
    ]

    # Admin views (6)
    admin_views = [
        ("hub_admin_dashboard", "Hub Admin Dashboard"),
        ("hub_admin_access", "Hub Admin Access"),
        ("hub_admin_human_resources", "Hub Admin Human Resources"),
        ("hub_admin_finances", "Hub Admin Finances"),
        ("hub_admin_marketing", "Hub Admin Marketing"),
        ("hub_admin_accounting", "Hub Admin Accounting"),
    ]

    # Other role dashboards (4)
    other_dashboards = [
        ("accountant_dashboard", "Accountant Dashboard"),
        ("hr_dashboard", "HR Dashboard"),
        ("marketing_dashboard", "Marketing Dashboard"),
        ("support_worker_dashboard", "Support Worker Dashboard"),
    ]

    # Hub Startup
    hub_startup = [("hub_startup", "Hub Startup")]

    created_count = 0

    # Create shared view tests
    print("Creating shared view tests...")
    shared_test_dir = test_base / "shared"
    for base_name, title in shared_views:
        viewmodel_class = snake_to_pascal(base_name) + "ViewModel"
        view_path = f"ui/views/hub/shared/{base_name.replace('hub_', '')}/{base_name}_viewmodel.dart"

        test_dir = shared_test_dir / base_name.replace('hub_', '')
        test_dir.mkdir(parents=True, exist_ok=True)

        test_file = test_dir / f"{base_name}_viewmodel_test.dart"
        create_viewmodel_test_file(test_file, viewmodel_class, view_path)
        created_count += 1

    # Create support coordinator tests
    print("Creating support coordinator view tests...")
    sc_test_dir = test_base / "support_coordinator"
    for base_name, title in support_coordinator_views:
        viewmodel_class = snake_to_pascal(base_name) + "ViewModel"
        view_name = base_name.replace('support_coordinator_', '')
        view_path = f"ui/views/hub/support_coordinator/{view_name}/{base_name}_viewmodel.dart"

        test_dir = sc_test_dir / view_name
        test_dir.mkdir(parents=True, exist_ok=True)

        test_file = test_dir / f"{base_name}_viewmodel_test.dart"
        create_viewmodel_test_file(test_file, viewmodel_class, view_path)
        created_count += 1

    # Create admin tests
    print("Creating admin view tests...")
    admin_test_dir = test_base / "admin"
    for base_name, title in admin_views:
        viewmodel_class = snake_to_pascal(base_name) + "ViewModel"
        view_name = base_name.replace('hub_admin_', '')
        view_path = f"ui/views/hub/admin/{view_name}/{base_name}_viewmodel.dart"

        test_dir = admin_test_dir / view_name
        test_dir.mkdir(parents=True, exist_ok=True)

        test_file = test_dir / f"{base_name}_viewmodel_test.dart"
        create_viewmodel_test_file(test_file, viewmodel_class, view_path)
        created_count += 1

    # Create other role dashboard tests
    print("Creating other role dashboard tests...")
    for base_name, title in other_dashboards:
        viewmodel_class = snake_to_pascal(base_name) + "ViewModel"

        if base_name == "accountant_dashboard":
            role_dir = "accountant"
        elif base_name == "hr_dashboard":
            role_dir = "hr"
        elif base_name == "marketing_dashboard":
            role_dir = "marketing"
        elif base_name == "support_worker_dashboard":
            role_dir = "support_worker"

        view_path = f"ui/views/hub/{role_dir}/dashboard/{base_name}_viewmodel.dart"

        test_dir = test_base / role_dir / "dashboard"
        test_dir.mkdir(parents=True, exist_ok=True)

        test_file = test_dir / f"{base_name}_viewmodel_test.dart"
        create_viewmodel_test_file(test_file, viewmodel_class, view_path)
        created_count += 1

    # Create hub startup test
    print("Creating hub startup test...")
    startup_test_dir = test_base / "startup"
    startup_test_dir.mkdir(parents=True, exist_ok=True)
    for base_name, title in hub_startup:
        viewmodel_class = snake_to_pascal(base_name) + "ViewModel"
        view_path = f"ui/views/hub/startup/{base_name}_viewmodel.dart"

        test_file = startup_test_dir / f"{base_name}_viewmodel_test.dart"
        create_viewmodel_test_file(test_file, viewmodel_class, view_path)
        created_count += 1

    print(f"✅ All test files created!\n")
    print(f"📊 Summary:")
    print(f"  - Total test files created: {created_count}")
    print(f"  - Shared view tests: 10")
    print(f"  - Support coordinator tests: 11")
    print(f"  - Admin tests: 6")
    print(f"  - Other role tests: 4")
    print(f"  - Hub startup test: 1")
    print(f"\n📝 Next steps:")
    print(f"1. Generate mock classes: flutter pub run build_runner build --delete-conflicting-outputs")
    print(f"2. Implement test cases following TDD (Red-Green-Refactor)")
    print(f"3. Run tests: flutter test test/viewmodels/hub/")
    print(f"4. Aim for 100% ViewModel coverage")

if __name__ == "__main__":
    main()
