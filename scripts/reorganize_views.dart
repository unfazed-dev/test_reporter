#!/usr/bin/env dart

import 'dart:io';

/// Script to reorganize views into role-based folders
///
/// Before:
/// lib/ui/views/participant_dashboard/
/// lib/ui/views/participant_inbox/
///
/// After:
/// lib/ui/views/participant/dashboard/
/// lib/ui/views/participant/inbox/

void main() async {
  stdout.writeln('🗂️  Reorganizing Views into Role-Based Folders');
  stdout.writeln('=' * 60);
  stdout.writeln('');

  // Define the reorganization mapping
  final viewMapping = {
    // Participant views
    'participant': [
      'participant_dashboard',
      'participant_inbox',
      'participant_bookings',
      'participant_team',
      'participant_journal',
      'participant_profile',
      'participant_invoices',
      'participant_shop',
      'participant_account',
      'participant_requests',
      'participant_funds',
    ],
    // Provider views
    'provider': [
      'provider_dashboard',
      'provider_inbox',
      'provider_bookings',
      'provider_clients',
      'provider_journal',
      'provider_profile',
      'provider_invoices',
      'provider_shop',
      'provider_account',
      'provider_requests',
      'provider_funds',
      'provider_travel_book',
    ],
    // Admin views
    'admin': [
      'admin_dashboard',
      'admin_access',
      'admin_human_resources',
      'admin_finances',
      'admin_marketing',
      'admin_accounting',
    ],
    // Supporter views
    'supporter': [
      'supporter_dashboard',
      'supporter_participants',
      'supporter_providers',
      'supporter_invoices',
      'supporter_meetings',
      'supporter_inbox',
      'supporter_funds',
      'supporter_requests',
      'supporter_journal',
      'supporter_payments',
      'supporter_travel_book',
      'supporter_shop',
    ],
    // Account Manager views
    'account_manager': [
      'account_manager_dashboard',
      'account_manager_inbox',
      'account_manager_team',
      'account_manager_bookings',
    ],
    // Auth views
    'auth': [
      'auth_sign_up',
      'auth_sign_in',
    ],
    // Common/Shared views
    'common': [
      'main',
      'startup',
      'unknown',
      'settings',
      'onboarding',
    ],
  };

  int totalMoved = 0;

  // Step 1: Create role-based directories
  stdout.writeln('📁 Creating role-based directories...');
  for (final role in viewMapping.keys) {
    final roleDir = Directory('lib/ui/views/$role');
    if (!await roleDir.exists()) {
      await roleDir.create(recursive: true);
      stdout.writeln('✓ Created lib/ui/views/$role/');
    }
  }

  stdout.writeln('');
  stdout.writeln('📦 Moving view directories...');

  // Step 2: Move view directories
  for (final entry in viewMapping.entries) {
    final role = entry.key;
    final views = entry.value;

    for (final viewName in views) {
      final oldDir = Directory('lib/ui/views/$viewName');
      if (!await oldDir.exists()) {
        stdout.writeln('⚠ Skipping $viewName (not found)');
        continue;
      }

      // Extract the short name (remove role prefix)
      final shortName = viewName.replaceFirst('${role}_', '');
      final newDir = Directory('lib/ui/views/$role/$shortName');

      // Move directory
      await oldDir.rename(newDir.path);
      stdout.writeln('✓ Moved $viewName → $role/$shortName');
      totalMoved++;
    }
  }

  stdout.writeln('');
  stdout.writeln('🔄 Updating import paths in view files...');

  // Step 3: Update imports in moved files
  int importsUpdated = 0;
  for (final entry in viewMapping.entries) {
    final role = entry.key;
    final views = entry.value;

    for (final viewName in views) {
      final shortName = viewName.replaceFirst('${role}_', '');
      final viewDir = Directory('lib/ui/views/$role/$shortName');

      if (!await viewDir.exists()) continue;

      await for (final file in viewDir.list()) {
        if (file is File && file.path.endsWith('.dart')) {
          String content = await file.readAsString();
          final original = content;

          // Update imports from old path to new path
          content = content.replaceAll(
            "import 'package:kinly/ui/views/$viewName/",
            "import 'package:kinly/ui/views/$role/$shortName/",
          );

          if (content != original) {
            await file.writeAsString(content);
            importsUpdated++;
          }
        }
      }
    }
  }
  stdout.writeln('✓ Updated imports in $importsUpdated view files');

  stdout.writeln('');
  stdout.writeln('🧪 Updating test file paths and imports...');

  // Step 4: Update test files
  int testsUpdated = 0;
  for (final entry in viewMapping.entries) {
    final role = entry.key;
    final views = entry.value;

    for (final viewName in views) {
      final shortName = viewName.replaceFirst('${role}_', '');
      final testFile = File('test/viewmodels/${viewName}_viewmodel_test.dart');

      if (!await testFile.exists()) continue;

      String content = await testFile.readAsString();
      final original = content;

      // Update import path
      content = content.replaceAll(
        "import 'package:kinly/ui/views/$viewName/${viewName}_viewmodel.dart';",
        "import 'package:kinly/ui/views/$role/$shortName/${viewName}_viewmodel.dart';",
      );

      if (content != original) {
        await testFile.writeAsString(content);
        testsUpdated++;
      }
    }
  }
  stdout.writeln('✓ Updated $testsUpdated test files');

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Reorganization complete!');
  stdout.writeln('');
  stdout.writeln('Summary:');
  stdout.writeln('  • Moved $totalMoved view directories');
  stdout.writeln('  • Updated $importsUpdated import statements');
  stdout.writeln('  • Updated $testsUpdated test files');
  stdout.writeln('');
  stdout.writeln('📝 Next steps:');
  stdout.writeln('  1. Update lib/app/app.dart with new import paths');
  stdout.writeln('  2. Run: dart format .');
  stdout.writeln('  3. Run: flutter analyze');
  stdout.writeln('  4. Run: flutter test');
  stdout.writeln('');
  stdout.writeln('See scripts/NEW_VIEW_STRUCTURE.md for the complete mapping');
}
