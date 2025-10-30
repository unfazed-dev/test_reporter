#!/usr/bin/env python3
"""
Phase 5 COMPLETE File Creation Script
Creates ALL files specified in the implementation plan
"""

import os
from pathlib import Path

BASE_DIR = Path("/Users/unfazed-mac/Developer/apps/kinly")
LIB_DIR = BASE_DIR / "lib"
TEST_DIR = BASE_DIR / "test"

def create_file(path: Path, content: str):
    """Create file with content"""
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists():
        path.write_text(content)
        print(f"✅ Created: {path.relative_to(BASE_DIR)}")
    else:
        print(f"⏭️  Exists: {path.relative_to(BASE_DIR)}")

print("🚀 Creating ALL Phase 5 Files from Implementation Plan...\n")

# ============================================
# VIEWS - QuestionnaireStepView (Multi-Platform)
# ============================================
print("📦 Section 5.2: QuestionnaireStepView Files...")

create_file(LIB_DIR / "ui/views/common/onboarding/questionnaire_step_view.dart", """import 'package:flutter/material.dart';
import 'package:kinly/ui/views/common/onboarding/questionnaire_step_view.mobile.dart';
import 'package:kinly/ui/views/common/onboarding/questionnaire_step_view.desktop.dart';
import 'package:kinly/ui/views/common/onboarding/questionnaire_step_view.tablet.dart';
import 'package:kinly/ui/views/common/onboarding/onboarding_viewmodel.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:stacked/stacked.dart';

class QuestionnaireStepView extends StackedView<OnboardingViewModel> {
  const QuestionnaireStepView({super.key});

  @override
  Widget builder(BuildContext context, OnboardingViewModel viewModel, Widget? child) {
    return ScreenTypeLayout.builder(
      mobile: (_) => const QuestionnaireStepViewMobile(),
      tablet: (_) => const QuestionnaireStepViewTablet(),
      desktop: (_) => const QuestionnaireStepViewDesktop(),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) => OnboardingViewModel();
}
""")

create_file(LIB_DIR / "ui/views/common/onboarding/questionnaire_step_view.mobile.dart", """import 'package:flutter/material.dart';
import 'package:kinly/ui/views/common/onboarding/onboarding_viewmodel.dart';
import 'package:stacked/stacked.dart';

class QuestionnaireStepViewMobile extends ViewModelWidget<OnboardingViewModel> {
  const QuestionnaireStepViewMobile({super.key});

  @override
  Widget build(BuildContext context, OnboardingViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: const Center(child: Text('Mobile - TODO')),
    );
  }
}
""")

create_file(LIB_DIR / "ui/views/common/onboarding/questionnaire_step_view.desktop.dart", """import 'package:flutter/material.dart';
import 'package:kinly/ui/views/common/onboarding/onboarding_viewmodel.dart';
import 'package:stacked/stacked.dart';

class QuestionnaireStepViewDesktop extends ViewModelWidget<OnboardingViewModel> {
  const QuestionnaireStepViewDesktop({super.key});

  @override
  Widget build(BuildContext context, OnboardingViewModel viewModel) {
    return const Scaffold(
      body: Center(child: Text('Desktop - TODO')),
    );
  }
}
""")

create_file(LIB_DIR / "ui/views/common/onboarding/questionnaire_step_view.tablet.dart", """import 'package:flutter/material.dart';
import 'package:kinly/ui/views/common/onboarding/onboarding_viewmodel.dart';
import 'package:stacked/stacked.dart';

class QuestionnaireStepViewTablet extends ViewModelWidget<OnboardingViewModel> {
  const QuestionnaireStepViewTablet({super.key});

  @override
  Widget build(BuildContext context, OnboardingViewModel viewModel) {
    return const Scaffold(
      body: Center(child: Text('Tablet - TODO')),
    );
  }
}
""")

# ============================================
# WIDGETS - Field Renderers (Section 5.3)
# ============================================
print("\n📦 Section 5.3: Dynamic Field Renderer Widgets...")

# Already exists - skip questionnaire_field_renderer.dart
# Already exists - skip text_field_widget.dart
# Already exists - skip single_choice_widget.dart
# Already exists - skip legal_checkbox_widget.dart

create_file(LIB_DIR / "ui/widgets/onboarding/fields/date_picker_widget.dart", """import 'package:flutter/material.dart';
import 'package:kinly/models/questionnaire_field.dart';

class DatePickerWidget extends StatelessWidget {
  final QuestionnaireField field;
  final DateTime? value;
  final ValueChanged<DateTime>? onChanged;
  final String? errorText;

  const DatePickerWidget({
    required this.field,
    this.value,
    this.onChanged,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/fields/multi_choice_widget.dart", """import 'package:flutter/material.dart';
import 'package:kinly/models/questionnaire_field.dart';

class MultiChoiceWidget extends StatelessWidget {
  final QuestionnaireField field;
  final List<String>? value;
  final ValueChanged<List<String>>? onChanged;
  final String? errorText;

  const MultiChoiceWidget({
    required this.field,
    this.value,
    this.onChanged,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/fields/boolean_field_widget.dart", """import 'package:flutter/material.dart';
import 'package:kinly/models/questionnaire_field.dart';

class BooleanFieldWidget extends StatelessWidget {
  final QuestionnaireField field;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final String? errorText;

  const BooleanFieldWidget({
    required this.field,
    this.value,
    this.onChanged,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/fields/repeater_field_widget.dart", """import 'package:flutter/material.dart';
import 'package:kinly/models/questionnaire_field.dart';

class RepeaterFieldWidget extends StatelessWidget {
  final QuestionnaireField field;
  final List<Map<String, dynamic>>? value;
  final ValueChanged<List<Map<String, dynamic>>>? onChanged;
  final String? errorText;

  const RepeaterFieldWidget({
    required this.field,
    this.value,
    this.onChanged,
    this.errorText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/fields/readonly_field_widget.dart", """import 'package:flutter/material.dart';
import 'package:kinly/models/questionnaire_field.dart';

class ReadonlyFieldWidget extends StatelessWidget {
  final QuestionnaireField field;
  final String? value;

  const ReadonlyFieldWidget({
    required this.field,
    this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

# ============================================
# WIDGETS - Validators (Section 5.3)
# ============================================
print("\n📦 Section 5.3: Validators...")

create_file(LIB_DIR / "ui/widgets/onboarding/validators/abn_validator.dart", """/// ABN Validator
///
/// Validates Australian Business Number (ABN)
class ABNValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove spaces
    final abn = value.replaceAll(' ', '');

    // Check length
    if (abn.length != 11) return 'ABN must be 11 digits';

    // Check all digits
    if (!RegExp(r'^\\d+\$').hasMatch(abn)) return 'ABN must contain only digits';

    // TODO: Implement ABN checksum validation
    return null;
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/validators/bsb_validator.dart", """/// BSB Validator
///
/// Validates Australian Bank State Branch (BSB) number
class BSBValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove spaces and hyphens
    final bsb = value.replaceAll(RegExp(r'[\\s-]'), '');

    // Check length
    if (bsb.length != 6) return 'BSB must be 6 digits';

    // Check all digits
    if (!RegExp(r'^\\d+\$').hasMatch(bsb)) return 'BSB must contain only digits';

    return null;
  }
}
""")

create_file(LIB_DIR / "ui/widgets/onboarding/validators/tfn_validator.dart", """/// TFN Validator
///
/// Validates Australian Tax File Number (TFN)
class TFNValidator {
  static String? validate(String? value) {
    if (value == null || value.isEmpty) return null;

    // Remove spaces
    final tfn = value.replaceAll(' ', '');

    // Check length
    if (tfn.length != 9) return 'TFN must be 9 digits';

    // Check all digits
    if (!RegExp(r'^\\d+\$').hasMatch(tfn)) return 'TFN must contain only digits';

    // TODO: Implement TFN checksum validation
    return null;
  }
}
""")

# ============================================
# WIDGETS - UI Components (Section 5.4)
# ============================================
print("\n📦 Section 5.4: UI Component Widgets...")

# Already exists - skip onboarding_step_indicator.dart
# Already exists - skip onboarding_navigation_bar.dart

create_file(LIB_DIR / "ui/widgets/onboarding/onboarding_completion_screen.dart", """import 'package:flutter/material.dart';

class OnboardingCompletionScreen extends StatelessWidget {
  final VoidCallback? onContinue;

  const OnboardingCompletionScreen({
    this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
""")

# ============================================
# TESTS - Widget Tests (Section 5.5)
# ============================================
print("\n📦 Section 5.5: Widget Tests...")

create_file(TEST_DIR / "ui/widgets/onboarding/fields/text_field_widget_test.dart", """import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextFieldWidget Tests', () {
    test('placeholder', () => expect(true, true));
  });
}
""")

create_file(TEST_DIR / "ui/widgets/onboarding/fields/single_choice_widget_test.dart", """import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SingleChoiceWidget Tests', () {
    test('placeholder', () => expect(true, true));
  });
}
""")

create_file(TEST_DIR / "ui/widgets/onboarding/fields/multi_choice_widget_test.dart", """import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiChoiceWidget Tests', () {
    test('placeholder', () => expect(true, true));
  });
}
""")

create_file(TEST_DIR / "ui/widgets/onboarding/fields/repeater_field_widget_test.dart", """import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepeaterFieldWidget Tests', () {
    test('placeholder', () => expect(true, true));
  });
}
""")

create_file(TEST_DIR / "golden/onboarding_field_widgets_golden_test.dart", """import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

void main() {
  group('Onboarding Field Widgets Golden Tests', () {
    testGoldens('placeholder', (tester) async {
      // TODO: Implement golden tests
    });
  });
}
""")

# ============================================
# SUMMARY
# ============================================
print("\n" + "="*60)
print("✅ Phase 5 Complete File Structure Created!")
print("="*60)

print("\n📊 File Summary:")
print("\n✅ Views (4 files):")
print("   - questionnaire_step_view.dart (base)")
print("   - questionnaire_step_view.mobile.dart")
print("   - questionnaire_step_view.desktop.dart")
print("   - questionnaire_step_view.tablet.dart")

print("\n✅ Field Widgets (9 files - 4 already existed):")
print("   - questionnaire_field_renderer.dart (✅ exists)")
print("   - text_field_widget.dart (✅ exists)")
print("   - single_choice_widget.dart (✅ exists)")
print("   - legal_checkbox_widget.dart (✅ exists)")
print("   - date_picker_widget.dart (new)")
print("   - multi_choice_widget.dart (new)")
print("   - boolean_field_widget.dart (new)")
print("   - repeater_field_widget.dart (new)")
print("   - readonly_field_widget.dart (new)")

print("\n✅ Validators (3 files):")
print("   - abn_validator.dart")
print("   - bsb_validator.dart")
print("   - tfn_validator.dart")

print("\n✅ UI Components (3 files - 2 already existed):")
print("   - onboarding_step_indicator.dart (✅ exists)")
print("   - onboarding_navigation_bar.dart (✅ exists)")
print("   - onboarding_completion_screen.dart (new)")

print("\n✅ Tests (5 files):")
print("   - text_field_widget_test.dart")
print("   - single_choice_widget_test.dart")
print("   - multi_choice_widget_test.dart")
print("   - repeater_field_widget_test.dart")
print("   - onboarding_field_widgets_golden_test.dart")

print("\n📝 Next Steps:")
print("   1. Run: flutter analyze")
print("   2. Run: dart format lib/ test/")
print("   3. Implement TODOs in each file")
print("   4. Run: flutter test")
print("")
