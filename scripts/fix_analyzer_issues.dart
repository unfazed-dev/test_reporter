#!/usr/bin/env dart

import 'dart:io';

/// Script to fix all analyzer issues in the generated files
///
/// Fixes:
/// 1. RouterView issues in layouts (replace with placeholder)
/// 2. Unused imports (stacked_annotations, app.locator, mockito)
/// 3. Unnecessary override methods in viewmodels
/// 4. Const constructor opportunities
/// 5. Wrong import paths in test files

void main() async {
  stdout.writeln('🔧 Fixing Analyzer Issues');
  stdout.writeln('=' * 60);
  stdout.writeln('');

  int totalFixes = 0;

  // Fix 1: Layout RouterView issues
  stdout.writeln('📦 Fixing RouterView issues in layouts...');
  totalFixes += await fixLayoutRouterViewIssues();

  // Fix 2: Unused imports in layout files
  stdout.writeln('\n📦 Fixing unused imports in layouts...');
  totalFixes += await fixUnusedImportsInLayouts();

  // Fix 3: Unused imports in viewmodels
  stdout.writeln('\n📦 Fixing unused imports in viewmodels...');
  totalFixes += await fixUnusedImportsInViewModels();

  // Fix 4: Unused imports in tests
  stdout.writeln('\n📦 Fixing unused imports in tests...');
  totalFixes += await fixUnusedImportsInTests();

  // Fix 5: Unnecessary overrides in viewmodels
  stdout.writeln('\n📦 Removing unnecessary dispose overrides...');
  totalFixes += await removeUnnecessaryOverrides();

  // Fix 6: Wrong import paths in layout viewmodel tests
  stdout.writeln('\n📦 Fixing import paths in layout tests...');
  totalFixes += await fixLayoutTestImports();

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Fixed $totalFixes issues!');
  stdout.writeln('');
  stdout.writeln('Next steps:');
  stdout.writeln('1. Run: dart format .');
  stdout.writeln('2. Run: flutter analyze');
  stdout.writeln('3. Verify all critical errors are resolved');
}

/// Fix RouterView issues in layout files
Future<int> fixLayoutRouterViewIssues() async {
  int fixes = 0;
  final layoutDirs = [
    'lib/ui/layouts/main_layout',
    'lib/ui/layouts/admin_layout',
    'lib/ui/layouts/auth_layout',
    'lib/ui/layouts/onboarding_layout',
    'lib/ui/layouts/settings_layout',
    'lib/ui/layouts/participant_layout',
    'lib/ui/layouts/provider_layout',
    'lib/ui/layouts/supporter_layout',
    'lib/ui/layouts/account_manager_layout',
  ];

  for (final layoutDir in layoutDirs) {
    final platformFiles = [
      '$layoutDir/${_getDirName(layoutDir)}_view.mobile.dart',
      '$layoutDir/${_getDirName(layoutDir)}_view.tablet.dart',
      '$layoutDir/${_getDirName(layoutDir)}_view.desktop.dart',
    ];

    for (final filePath in platformFiles) {
      final file = File(filePath);
      if (!await file.exists()) continue;

      String content = await file.readAsString();
      final original = content;

      // Replace RouterView with placeholder
      content = content.replaceAll(
        RegExp(r'const Expanded\(\s*child: RouterView\(\),\s*\)'),
        '''Expanded(
                child: Center(
                  child: Text(
                    'Nested routes will appear here after app.dart is configured',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              )''',
      );

      if (content != original) {
        await file.writeAsString(content);
        stdout.writeln('✓ Fixed $filePath');
        fixes++;
      }
    }
  }

  return fixes;
}

/// Fix unused imports in layout files
Future<int> fixUnusedImportsInLayouts() async {
  int fixes = 0;
  final layoutDirs = [
    'lib/ui/layouts/main_layout',
    'lib/ui/layouts/admin_layout',
    'lib/ui/layouts/auth_layout',
    'lib/ui/layouts/onboarding_layout',
    'lib/ui/layouts/settings_layout',
    'lib/ui/layouts/participant_layout',
    'lib/ui/layouts/provider_layout',
    'lib/ui/layouts/supporter_layout',
    'lib/ui/layouts/account_manager_layout',
  ];

  for (final layoutDir in layoutDirs) {
    final platformFiles = [
      '$layoutDir/${_getDirName(layoutDir)}_view.mobile.dart',
      '$layoutDir/${_getDirName(layoutDir)}_view.tablet.dart',
      '$layoutDir/${_getDirName(layoutDir)}_view.desktop.dart',
    ];

    for (final filePath in platformFiles) {
      final file = File(filePath);
      if (!await file.exists()) continue;

      String content = await file.readAsString();
      final original = content;

      // Remove unused stacked_annotations import
      content = content.replaceAll(
        "import 'package:stacked/stacked_annotations.dart';\n",
        '',
      );

      if (content != original) {
        await file.writeAsString(content);
        stdout.writeln('✓ Fixed $filePath');
        fixes++;
      }
    }
  }

  return fixes;
}

/// Fix unused imports in viewmodel files
Future<int> fixUnusedImportsInViewModels() async {
  int fixes = 0;
  final viewModelFiles = await _findFiles('lib/ui', '*_viewmodel.dart');

  for (final filePath in viewModelFiles) {
    final file = File(filePath);
    String content = await file.readAsString();
    final original = content;

    // Check if app.locator is imported but not used
    if (content.contains("import 'package:kinly/app/app.locator.dart';") &&
        !content.contains('locator<')) {
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

/// Fix unused imports in test files
Future<int> fixUnusedImportsInTests() async {
  int fixes = 0;
  final testFiles = await _findFiles('test/viewmodels', '*_test.dart');

  for (final filePath in testFiles) {
    final file = File(filePath);
    String content = await file.readAsString();
    final original = content;

    // Remove unused mockito import
    if (content.contains("import 'package:mockito/mockito.dart';") &&
        !content.contains('Mock') &&
        !content.contains('when(') &&
        !content.contains('verify(')) {
      content = content.replaceAll(
        "import 'package:mockito/mockito.dart';\n",
        '',
      );
    }

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

/// Remove unnecessary dispose overrides
Future<int> removeUnnecessaryOverrides() async {
  int fixes = 0;
  final viewModelFiles = await _findFiles('lib/ui', '*_viewmodel.dart');

  for (final filePath in viewModelFiles) {
    final file = File(filePath);
    String content = await file.readAsString();
    final original = content;

    // Remove unnecessary dispose override that only calls super.dispose()
    content = content.replaceAll(
      RegExp(
        r'  @override\s+void dispose\(\) \{\s+super\.dispose\(\);\s+\}\s*',
        multiLine: true,
      ),
      '',
    );

    // Also remove if it's the last method with extra newlines
    content = content.replaceAll(
      RegExp(
        r'\s+@override\s+void dispose\(\) \{\s+super\.dispose\(\);\s+\}\s*\}',
        multiLine: true,
      ),
      '\n}',
    );

    if (content != original) {
      await file.writeAsString(content);
      stdout.writeln('✓ Fixed $filePath');
      fixes++;
    }
  }

  return fixes;
}

/// Fix import paths in layout viewmodel test files
Future<int> fixLayoutTestImports() async {
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
    final original = content;

    // Fix import path: views/xxx_layout should be layouts/xxx_layout
    content = content.replaceAll(
      RegExp(
          r"import 'package:kinly/ui/views/(\w+_layout)/\1_viewmodel\.dart';"),
      "import 'package:kinly/ui/layouts/\$1/\$1_viewmodel.dart';",
    );

    if (content != original) {
      await file.writeAsString(content);
      stdout.writeln('✓ Fixed $filePath');
      fixes++;
    }
  }

  return fixes;
}

/// Helper: Get directory name from path
String _getDirName(String path) {
  return path.split('/').last;
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
