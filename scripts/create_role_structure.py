#!/usr/bin/env python3

"""
Universal Role Structure Generation Script
Generates views, ViewModels, and tests based on role_structures.yaml
Usage: python3 scripts/create_role_structure.py [--role participant|provider] [--all]
"""

import os
import sys
import yaml
import argparse
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).parent
BASE_DIR = SCRIPT_DIR.parent
LIB_DIR = BASE_DIR / "lib"
TEST_DIR = BASE_DIR / "test"
CONFIG_FILE = SCRIPT_DIR / "role_structures.yaml"


def snake_to_pascal(snake_str):
    """Convert snake_case to PascalCase"""
    return ''.join(word.capitalize() for word in snake_str.split('_'))


def snake_to_title(snake_str):
    """Convert snake_case to Title Case"""
    return ' '.join(word.capitalize() for word in snake_str.split('_'))


def create_view_file(file_path, class_name, view_model_name):
    """Create main view file"""
    view_file = file_path.stem
    content = f"""import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';
import '{view_file}_viewmodel.dart';
import '{view_file}.mobile.dart';
import '{view_file}.tablet.dart';
import '{view_file}.desktop.dart';

class {class_name} extends StackedView<{view_model_name}> {{
  const {class_name}({{super.key}});

  @override
  Widget builder(
    BuildContext context,
    {view_model_name} viewModel,
    Widget? child,
  ) {{
    return ScreenTypeLayout.builder(
      mobile: (_) => const {class_name}Mobile(),
      tablet: (_) => const {class_name}Tablet(),
      desktop: (_) => const {class_name}Desktop(),
    );
  }}

  @override
  {view_model_name} viewModelBuilder(BuildContext context) => {view_model_name}();
}}
"""
    file_path.write_text(content)


def create_viewmodel_file(file_path, class_name):
    """Create viewmodel file"""
    content = f"""import 'package:stacked/stacked.dart';

class {class_name} extends BaseViewModel {{
  // TODO: Implement {class_name} logic
}}
"""
    file_path.write_text(content)


def create_mobile_view_file(file_path, class_name, view_model_name, title):
    """Create mobile view file"""
    viewmodel_file = view_model_name.lower().replace('viewmodel', '_viewmodel')
    content = f"""import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '{viewmodel_file}.dart';

class {class_name}Mobile extends ViewModelWidget<{view_model_name}> {{
  const {class_name}Mobile({{super.key}});

  @override
  Widget build(BuildContext context, {view_model_name} viewModel) {{
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('{title}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '{title}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }}
}}
"""
    file_path.write_text(content)


def create_platform_view_file(file_path, class_name, view_model_name, mobile_class):
    """Create tablet/desktop view file (delegates to mobile)"""
    viewmodel_file = view_model_name.lower().replace('viewmodel', '_viewmodel')
    mobile_file = mobile_class.lower().replace('view', '_view')
    content = f"""import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import '{viewmodel_file}.dart';
import '{mobile_file}.dart';

class {class_name} extends ViewModelWidget<{view_model_name}> {{
  const {class_name}({{super.key}});

  @override
  Widget build(BuildContext context, {view_model_name} viewModel) {{
    return const {mobile_class}();
  }}
}}
"""
    file_path.write_text(content)


def create_test_file(file_path, viewmodel_name):
    """Create test file"""
    content = f"""import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Import your viewmodel
// import 'package:kinly/path/to/{viewmodel_name.lower()}.dart';

void main() {{
  group('{viewmodel_name} Tests', () {{
    late {viewmodel_name} viewModel;

    setUp(() {{
      // viewModel = {viewmodel_name}();
    }});

    tearDown(() {{
      // viewModel.dispose();
    }});

    test('should initialize correctly', () {{
      // TODO: Implement test
      expect(true, true);
    }});

    // TODO: Add more tests for 100% coverage
  }});
}}
"""
    file_path.write_text(content)


def create_view_set(directory, base_name, title):
    """Create all view files for a directory"""
    directory.mkdir(parents=True, exist_ok=True)

    view_file = directory / f"{base_name}_view.dart"
    viewmodel_file = directory / f"{base_name}_viewmodel.dart"
    mobile_file = directory / f"{base_name}_view.mobile.dart"
    tablet_file = directory / f"{base_name}_view.tablet.dart"
    desktop_file = directory / f"{base_name}_view.desktop.dart"

    class_name = snake_to_pascal(base_name) + "View"
    viewmodel_name = snake_to_pascal(base_name) + "ViewModel"

    print(f"  📝 Creating {class_name}...")

    create_view_file(view_file, class_name, viewmodel_name)
    create_viewmodel_file(viewmodel_file, viewmodel_name)
    create_mobile_view_file(mobile_file, f"{class_name}Mobile", viewmodel_name, title)
    create_platform_view_file(tablet_file, f"{class_name}Tablet", viewmodel_name, f"{class_name}Mobile")
    create_platform_view_file(desktop_file, f"{class_name}Desktop", viewmodel_name, f"{class_name}Mobile")

    # Create test file
    test_file = TEST_DIR / "viewmodels" / f"{base_name}_viewmodel_test.dart"
    test_file.parent.mkdir(parents=True, exist_ok=True)
    create_test_file(test_file, viewmodel_name)


def generate_sub_roles(role, config, yaml_path, dir_path):
    """Recursively generate sub-role views"""
    sub_roles = config

    for sub_role, sub_config in sub_roles.items():
        print(f"📦 Creating {sub_role} views...")

        # Check if sub-role has startup
        if sub_config.get('startup_view', False):
            startup_dir = dir_path / sub_role / "startup"
            create_view_set(startup_dir, f"{role}_{sub_role}_startup", f"{sub_role.title()} Startup")

        # Generate shared views for this sub-role
        shared_views = sub_config.get('shared_views', [])
        for view in shared_views:
            view_name = view['name']
            view_title = view['title']
            shared_dir = dir_path / sub_role / "shared" / view_name
            create_view_set(shared_dir, f"{role}_{sub_role}_shared_{view_name}", view_title)

        # Generate views for this sub-role
        views = sub_config.get('views', [])
        for view in views:
            view_name = view['name']
            view_title = view['title']
            view_dir = dir_path / sub_role / view_name
            create_view_set(view_dir, f"{role}_{sub_role}_{view_name}", view_title)

        # Recursively process nested sub-roles
        nested_sub_roles = sub_config.get('sub_roles', {})
        if nested_sub_roles:
            generate_sub_roles(role, nested_sub_roles, f"{yaml_path}.{sub_role}.sub_roles", dir_path / sub_role)


def generate_role_structure(role, config):
    """Generate views for a role"""
    print(f"\n🔨 Generating {role} structure...")
    print("=" * 40)

    role_config = config[role]
    base_path = role_config['base_path']

    # Generate startup view if needed
    if role_config.get('startup_view', False):
        print("📦 Creating startup view...")
        startup_dir = LIB_DIR / "ui" / "views" / role / "startup"
        create_view_set(startup_dir, f"{role}_startup", f"{role.title()} Startup")

    # Generate shared views
    print("📦 Creating shared views...")
    for view in role_config.get('shared_views', []):
        view_name = view['name']
        view_title = view['title']
        shared_dir = LIB_DIR / "ui" / "views" / role / "shared" / view_name
        create_view_set(shared_dir, f"{role}_shared_{view_name}", view_title)

    # Generate sub-role views
    sub_roles = role_config.get('sub_roles', {})
    if sub_roles:
        generate_sub_roles(role, sub_roles, f"{role}.sub_roles", LIB_DIR / "ui" / "views" / role)


def main():
    parser = argparse.ArgumentParser(description='Generate role structure views')
    parser.add_argument('--role', choices=['participant', 'provider'], help='Specific role to generate')
    parser.add_argument('--all', action='store_true', help='Generate all roles')
    args = parser.parse_args()

    print("🚀 Universal Role Structure Generator")
    print("=" * 40)

    # Load config
    with open(CONFIG_FILE, 'r') as f:
        config = yaml.safe_load(f)

    # Generate structures
    if args.all:
        generate_role_structure('participant', config)
        generate_role_structure('provider', config)
    elif args.role:
        generate_role_structure(args.role, config)
    else:
        parser.print_help()
        sys.exit(1)

    print("\n✅ Generation complete!")
    print("\nNext steps:")
    print("1. Review generated files in lib/ui/views/")
    print("2. Implement ViewModels with business logic")
    print("3. Update app.dart with route definitions")
    print("4. Run: dart run build_runner build --delete-conflicting-outputs")
    print("5. Run: flutter test")
    print()


if __name__ == '__main__':
    main()
