#!/usr/bin/env dart

import 'dart:io';

/// Script to fix all remaining analyzer issues:
/// 1. Rename files from account_manager_* to participant_manager_*
/// 2. Fix unused imports in test files
/// 3. Update any references to the old filenames

void main() async {
  stdout.writeln('🔧 Fixing All Analyzer Issues');
  stdout.writeln('=' * 60);
  stdout.writeln();

  int totalChanges = 0;

  // Step 1: Rename files
  stdout.writeln('📝 Step 1: Renaming account_manager_* files...');
  totalChanges += await renameFiles();

  // Step 2: Fix unused imports
  stdout.writeln('\n🧹 Step 2: Fixing unused imports in test files...');
  totalChanges += await fixUnusedImports();

  stdout.writeln();
  stdout.writeln('=' * 60);
  stdout.writeln('✅ All fixes complete!');
  stdout.writeln();
  stdout.writeln('Summary:');
  stdout.writeln('  • Total changes: $totalChanges');
  stdout.writeln();
  stdout.writeln('Next steps:');
  stdout.writeln(
      '  1. Run: dart run build_runner build --delete-conflicting-outputs');
  stdout.writeln('  2. Run: flutter analyze');
}

Future<int> renameFiles() async {
  int changes = 0;

  // Find all files with account_manager in the name
  final filesToRename = [
    // Views
    'lib/ui/views/participant_manager/inbox/account_manager_inbox_view.dart',
    'lib/ui/views/participant_manager/inbox/account_manager_inbox_view.mobile.dart',
    'lib/ui/views/participant_manager/inbox/account_manager_inbox_view.tablet.dart',
    'lib/ui/views/participant_manager/inbox/account_manager_inbox_view.desktop.dart',
    'lib/ui/views/participant_manager/inbox/account_manager_inbox_viewmodel.dart',

    'lib/ui/views/participant_manager/bookings/account_manager_bookings_view.dart',
    'lib/ui/views/participant_manager/bookings/account_manager_bookings_view.mobile.dart',
    'lib/ui/views/participant_manager/bookings/account_manager_bookings_view.tablet.dart',
    'lib/ui/views/participant_manager/bookings/account_manager_bookings_view.desktop.dart',
    'lib/ui/views/participant_manager/bookings/account_manager_bookings_viewmodel.dart',

    'lib/ui/views/participant_manager/dashboard/account_manager_dashboard_view.dart',
    'lib/ui/views/participant_manager/dashboard/account_manager_dashboard_view.mobile.dart',
    'lib/ui/views/participant_manager/dashboard/account_manager_dashboard_view.tablet.dart',
    'lib/ui/views/participant_manager/dashboard/account_manager_dashboard_view.desktop.dart',
    'lib/ui/views/participant_manager/dashboard/account_manager_dashboard_viewmodel.dart',

    'lib/ui/views/participant_manager/team/account_manager_team_view.dart',
    'lib/ui/views/participant_manager/team/account_manager_team_view.mobile.dart',
    'lib/ui/views/participant_manager/team/account_manager_team_view.tablet.dart',
    'lib/ui/views/participant_manager/team/account_manager_team_view.desktop.dart',
    'lib/ui/views/participant_manager/team/account_manager_team_viewmodel.dart',

    // Layouts
    'lib/ui/layouts/participant_manager_layout/account_manager_layout_view.dart',
    'lib/ui/layouts/participant_manager_layout/account_manager_layout_view.mobile.dart',
    'lib/ui/layouts/participant_manager_layout/account_manager_layout_view.tablet.dart',
    'lib/ui/layouts/participant_manager_layout/account_manager_layout_view.desktop.dart',
    'lib/ui/layouts/participant_manager_layout/account_manager_layout_viewmodel.dart',

    // Tests
    'test/viewmodels/account_manager_inbox_viewmodel_test.dart',
    'test/viewmodels/account_manager_bookings_viewmodel_test.dart',
    'test/viewmodels/account_manager_dashboard_viewmodel_test.dart',
    'test/viewmodels/account_manager_team_viewmodel_test.dart',
    'test/viewmodels/account_manager_layout_viewmodel_test.dart',
  ];

  for (final oldPath in filesToRename) {
    final file = File(oldPath);
    if (await file.exists()) {
      final newPath =
          oldPath.replaceAll('account_manager', 'participant_manager');
      await file.rename(newPath);
      stdout.writeln(
          '✓ Renamed ${oldPath.split('/').last} → ${newPath.split('/').last}');
      changes++;
    }
  }

  return changes;
}

Future<int> fixUnusedImports() async {
  int changes = 0;
  final testDir = Directory('test/viewmodels');

  if (!await testDir.exists()) return changes;

  await for (final entity in testDir.list()) {
    if (entity is File && entity.path.endsWith('_test.dart')) {
      String content = await entity.readAsString();
      final original = content;

      // Remove unused import: 'package:kinly/app/app.locator.dart'
      final lines = content.split('\n');
      final filteredLines = lines.where((line) {
        // Keep the line unless it's the unused import
        if (line.trim() == "import 'package:kinly/app/app.locator.dart';") {
          return false;
        }
        return true;
      }).toList();

      content = filteredLines.join('\n');

      if (content != original) {
        await entity.writeAsString(content);
        stdout.writeln(
            '✓ Fixed unused imports in ${entity.path.split('/').last}');
        changes++;
      }
    }
  }

  return changes;
}
