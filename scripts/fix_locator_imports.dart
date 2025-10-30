#!/usr/bin/env dart

import 'dart:io';

/// Script to add back locator import to test files that actually use it

void main() async {
  stdout.writeln('🔧 Fixing locator imports in test files');
  stdout.writeln('=' * 60);

  final filesToFix = [
    'test/viewmodels/auth_viewmodel_test.dart',
    'test/viewmodels/home_viewmodel_test.dart',
    'test/viewmodels/info_alert_dialog_model_test.dart',
    'test/viewmodels/notice_sheet_model_test.dart',
    'test/viewmodels/onboarding_viewmodel_test.dart',
    'test/viewmodels/otp_verification_viewmodel_test.dart',
    'test/viewmodels/role_selection_viewmodel_test.dart',
    'test/viewmodels/startup_viewmodel_test.dart',
    'test/viewmodels/unknown_viewmodel_test.dart',
  ];

  int fixed = 0;

  for (final filePath in filesToFix) {
    final file = File(filePath);
    if (await file.exists()) {
      String content = await file.readAsString();

      // Check if the file doesn't already have the import
      if (!content.contains("import 'package:kinly/app/app.locator.dart';")) {
        // Add the import after flutter_test import
        content = content.replaceFirst(
          "import 'package:flutter_test/flutter_test.dart';",
          "import 'package:flutter_test/flutter_test.dart';\nimport 'package:kinly/app/app.locator.dart';",
        );

        await file.writeAsString(content);
        stdout.writeln('✓ Added locator import to ${filePath.split('/').last}');
        fixed++;
      }
    }
  }

  stdout.writeln();
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Fixed $fixed files');
}
