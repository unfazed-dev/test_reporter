#!/usr/bin/env python3
"""
Kinly Onboarding Widget Creation Script
Creates widget files with boilerplate code for Phase 5 implementation
"""

import os
from pathlib import Path
from typing import List, Dict

BASE_DIR = Path("/Users/unfazed-mac/Developer/apps/kinly")
LIB_DIR = BASE_DIR / "lib"
TEST_DIR = BASE_DIR / "test"

# Widget definitions
WIDGETS = {
    "onboarding_step_indicator": {
        "description": "Progress indicator showing current step and completion percentage",
        "path": "ui/widgets/onboarding",
        "test": True,
        "template": "stateless_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:shadcn_ui/shadcn_ui.dart",
        ],
    },
    "onboarding_navigation_bar": {
        "description": "Navigation controls (back/skip/next buttons)",
        "path": "ui/widgets/onboarding",
        "test": True,
        "template": "stateless_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:shadcn_ui/shadcn_ui.dart",
        ],
    },
    "questionnaire_field_renderer": {
        "description": "Router widget that renders appropriate field widget based on field type",
        "path": "ui/widgets/onboarding",
        "test": True,
        "template": "stateless_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:kinly/models/questionnaire_field.dart",
        ],
    },
    "text_field_widget": {
        "description": "Text input field for text/email/phone types",
        "path": "ui/widgets/onboarding/fields",
        "test": True,
        "template": "stateless_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:shadcn_ui/shadcn_ui.dart",
            "package:kinly/models/questionnaire_field.dart",
        ],
    },
    "single_choice_widget": {
        "description": "Radio button group for single choice fields",
        "path": "ui/widgets/onboarding/fields",
        "test": True,
        "template": "stateful_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:shadcn_ui/shadcn_ui.dart",
            "package:kinly/models/questionnaire_field.dart",
        ],
    },
    "legal_checkbox_widget": {
        "description": "Checkbox with document modal for legal acceptance",
        "path": "ui/widgets/onboarding/fields",
        "test": True,
        "template": "stateful_widget",
        "imports": [
            "package:flutter/material.dart",
            "package:shadcn_ui/shadcn_ui.dart",
        ],
    },
}


def to_class_name(snake_case: str) -> str:
    """Convert snake_case to PascalCase"""
    return "".join(word.capitalize() for word in snake_case.split("_"))


def create_stateless_widget(widget_name: str, description: str, imports: List[str]) -> str:
    """Generate stateless widget boilerplate"""
    class_name = to_class_name(widget_name)

    imports_str = "\n".join(imports)

    return f"""import 'package:flutter/material.dart';

/// {class_name}
///
/// {description}
class {class_name} extends StatelessWidget {{
  const {class_name}({{super.key}});

  @override
  Widget build(BuildContext context) {{
    // TODO: Implement {class_name}
    return const Placeholder();
  }}
}}
"""


def create_stateful_widget(widget_name: str, description: str, imports: List[str]) -> str:
    """Generate stateful widget boilerplate"""
    class_name = to_class_name(widget_name)

    imports_str = "\n".join(imports)

    return f"""import 'package:flutter/material.dart';

/// {class_name}
///
/// {description}
class {class_name} extends StatefulWidget {{
  const {class_name}({{super.key}});

  @override
  State<{class_name}> createState() => _{class_name}State();
}}

class _{class_name}State extends State<{class_name}> {{
  @override
  Widget build(BuildContext context) {{
    // TODO: Implement {class_name}
    return const Placeholder();
  }}
}}
"""


def create_widget_test(widget_name: str, description: str) -> str:
    """Generate widget test boilerplate"""
    class_name = to_class_name(widget_name)

    return f"""import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinly/ui/widgets/onboarding/{widget_name}.dart';

void main() {{
  group('{class_name} Tests', () {{
    testWidgets('should render without errors', (tester) async {{
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: {class_name}(),
          ),
        ),
      );

      // Assert
      expect(find.byType({class_name}), findsOneWidget);
    }});

    // TODO: Add more tests for {description}
  }});
}}
"""


def create_directory(path: Path):
    """Create directory if it doesn't exist"""
    path.mkdir(parents=True, exist_ok=True)
    print(f"📁 Created directory: {path.relative_to(BASE_DIR)}")


def create_file(path: Path, content: str):
    """Create file with content"""
    path.write_text(content)
    print(f"✅ Created file: {path.relative_to(BASE_DIR)}")


def main():
    print("🚀 Creating Onboarding Widgets for Phase 5...\n")

    created_files = []

    for widget_name, config in WIDGETS.items():
        print(f"\n📦 Creating {widget_name}...")

        # Create widget directory
        widget_dir = LIB_DIR / config["path"]
        create_directory(widget_dir)

        # Generate widget content
        if config["template"] == "stateless_widget":
            content = create_stateless_widget(
                widget_name,
                config["description"],
                config["imports"]
            )
        else:
            content = create_stateful_widget(
                widget_name,
                config["description"],
                config["imports"]
            )

        # Create widget file
        widget_file = widget_dir / f"{widget_name}.dart"
        create_file(widget_file, content)
        created_files.append(str(widget_file.relative_to(BASE_DIR)))

        # Create test file if needed
        if config["test"]:
            test_dir = TEST_DIR / "ui/widgets/onboarding"
            if "fields" in config["path"]:
                test_dir = TEST_DIR / "ui/widgets/onboarding/fields"

            create_directory(test_dir)

            test_content = create_widget_test(widget_name, config["description"])
            test_file = test_dir / f"{widget_name}_test.dart"
            create_file(test_file, test_content)
            created_files.append(str(test_file.relative_to(BASE_DIR)))

    print("\n" + "="*60)
    print("✅ Widget Creation Complete!")
    print("="*60)
    print(f"\n📊 Created {len(created_files)} files:")
    for file in created_files:
        print(f"   - {file}")

    print("\n📝 Next Steps:")
    print("   1. Implement widget logic following shadcn_ui design system")
    print("   2. Run: flutter analyze")
    print("   3. Run: flutter test")
    print("   4. Format: dart format lib/ test/")
    print("")


if __name__ == "__main__":
    main()
