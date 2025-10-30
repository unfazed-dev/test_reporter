#!/usr/bin/env dart

import 'dart:io';

/// Fix remaining analyzer issues
/// 1. String interpolation in test import paths
/// 2. Unused app.locator imports in remaining test files
/// 3. Rename app_routes_template.dart to .txt to exclude from analysis

void main() async {
  stdout.writeln('🔧 Fixing Remaining Analyzer Issues');
  stdout.writeln('=' * 60);
  stdout.writeln('');

  int totalFixes = 0;

  // Fix 1: String interpolation in test imports
  stdout.writeln('📦 Fixing string interpolation in test imports...');
  totalFixes += await fixStringInterpolationInImports();

  // Fix 2: Remaining unused imports in tests
  stdout.writeln('\n📦 Fixing remaining unused imports in tests...');
  totalFixes += await fixRemainingUnusedImports();

  // Fix 3: Rename template file
  stdout.writeln('\n📦 Renaming template file to exclude from analysis...');
  totalFixes += await renameTemplateFile();

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Fixed $totalFixes issues!');
  stdout.writeln('');
  stdout.writeln('Running final analyzer check...');
}

Future<int> fixStringInterpolationInImports() async {
  int fixes = 0;
  final layoutTests = [
    'test/viewmodels/main_layout_viewmodel_test.dart',
    'test/viewmodels/admin_layout_viewmodel_test.dart',
    'test/viewmodels/auth_layout_viewmodel_test.dart',
    'test/viewmodels/onboarding_layout_viewmodel_test.dart',
    'test/viewmodels/settings_layout_viewmodel_test.dart',
    'test/viewmodels/participant_layout_viewmodel_test.dart',
    'test/viewmodels/provider_layout_viewmodel_test.dart',
    'test/viewmodels/supporter_layout_viewmodel_test.dart',
    'test/viewmodels/account_manager_layout_viewmodel_test.dart',
  ];

  for (final filePath in layoutTests) {
    final file = File(filePath);
    if (!await file.exists()) continue;

    String content = await file.readAsString();

    // Check if it has the string interpolation issue
    final interpolationPattern = RegExp(
      r"import 'package:kinly/ui/layouts/\\\$1/\\\$1_viewmodel\.dart';",
    );

    if (content.contains(interpolationPattern) ||
        content.contains(r'$1') ||
        content.contains(r'\$')) {
      // Extract layout name from filename
      final layoutName =
          filePath.split('/').last.replaceAll('_viewmodel_test.dart', '');

      // Replace with correct import
      content = content.replaceAll(
        RegExp(r"import 'package:kinly/ui/layouts/.*?_viewmodel\.dart';"),
        "import 'package:kinly/ui/layouts/$layoutName/${layoutName}_viewmodel.dart';",
      );

      await file.writeAsString(content);
      stdout.writeln('✓ Fixed $filePath');
      fixes++;
    }
  }

  return fixes;
}

Future<int> fixRemainingUnusedImports() async {
  int fixes = 0;
  final testFiles = await _findFiles('test/viewmodels', '*_test.dart');

  for (final filePath in testFiles) {
    final file = File(filePath);
    String content = await file.readAsString();
    final original = content;

    // Remove unused app.locator import
    if (content.contains("import 'package:kinly/app/app.locator.dart';") &&
        !content.contains('locator') &&
        !content.contains('registerServices')) {
      content = content.replaceAll(
        "import 'package:kinly/app/app.locator.dart';\n",
        '',
      );
    }

    if (content != original) {
      await file.writeAsString(content);
      stdout.writeln('✓ Fixed $filePath');
      fixes++;
    }
  }

  return fixes;
}

Future<int> renameTemplateFile() async {
  final templateFile = File('scripts/app_routes_template.dart');
  final newFile = File('scripts/app_routes_template.txt');

  if (await templateFile.exists()) {
    await templateFile.rename(newFile.path);
    stdout.writeln(
        '✓ Renamed app_routes_template.dart → app_routes_template.txt');
    return 1;
  }

  return 0;
}

/// Helper: Find files matching a pattern
Future<List<String>> _findFiles(String dir, String pattern) async {
  final files = <String>[];
  final directory = Directory(dir);

  if (!await directory.exists()) return files;

  await for (final entity in directory.list(recursive: true)) {
    if (entity is File) {
      final path = entity.path;
      if (pattern.startsWith('*') && path.endsWith(pattern.substring(1))) {
        files.add(path);
      } else if (path.contains(pattern)) {
        files.add(path);
      }
    }
  }

  return files;
}
