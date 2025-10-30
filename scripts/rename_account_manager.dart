#!/usr/bin/env dart

import 'dart:io';

/// Script to rename account_manager to participant_manager throughout the codebase
///
/// This ensures consistency with the UserRole enum which defines participantManager

void main() async {
  stdout.writeln('🔄 Renaming account_manager → participant_manager');
  stdout.writeln('=' * 60);
  stdout.writeln('');
  stdout.writeln('This will update:');
  stdout.writeln('  • View directories');
  stdout.writeln('  • Layout directories');
  stdout.writeln('  • All file contents (class names, imports, paths)');
  stdout.writeln('  • Test files');
  stdout.writeln('  • Route configurations');
  stdout.writeln('');

  int totalChanges = 0;

  // Step 1: Rename view directories
  stdout.writeln('📁 Step 1: Renaming view directories...');
  totalChanges += await renameViewDirectories();

  // Step 2: Rename layout directory
  stdout.writeln('\n📁 Step 2: Renaming layout directory...');
  totalChanges += await renameLayoutDirectory();

  // Step 3: Update file contents in renamed directories
  stdout.writeln('\n📝 Step 3: Updating file contents...');
  totalChanges += await updateFileContents();

  // Step 4: Update test files
  stdout.writeln('\n🧪 Step 4: Updating test files...');
  totalChanges += await updateTestFiles();

  // Step 5: Update app.dart
  stdout.writeln('\n⚙️  Step 5: Updating app.dart...');
  totalChanges += await updateAppDart();

  // Step 6: Update route template files
  stdout.writeln('\n📄 Step 6: Updating route template files...');
  totalChanges += await updateTemplateFiles();

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Rename complete!');
  stdout.writeln('');
  stdout.writeln('Summary:');
  stdout.writeln('  • Total changes: $totalChanges');
  stdout.writeln('');
  stdout.writeln('Next steps:');
  stdout.writeln(
      '  1. Run: dart run build_runner build --delete-conflicting-outputs');
  stdout.writeln('  2. Run: flutter analyze');
  stdout.writeln('  3. Run: flutter test');
}

Future<int> renameViewDirectories() async {
  int changes = 0;

  final oldDir = Directory('lib/ui/views/account_manager');
  final newDir = Directory('lib/ui/views/participant_manager');

  if (await oldDir.exists()) {
    await oldDir.rename(newDir.path);
    stdout.writeln(
        '✓ Renamed lib/ui/views/account_manager → participant_manager');
    changes++;
  }

  return changes;
}

Future<int> renameLayoutDirectory() async {
  int changes = 0;
  final oldDir = Directory('lib/ui/layouts/account_manager_layout');
  final newDir = Directory('lib/ui/layouts/participant_manager_layout');

  if (await oldDir.exists()) {
    await oldDir.rename(newDir.path);
    stdout.writeln(
        '✓ Renamed lib/ui/layouts/account_manager_layout → participant_manager_layout');
    changes++;
  }

  return changes;
}

Future<int> updateFileContents() async {
  int changes = 0;

  // Update files in participant_manager views
  final viewDir = Directory('lib/ui/views/participant_manager');
  if (await viewDir.exists()) {
    changes += await updateFilesInDirectory(viewDir);
  }

  // Update files in participant_manager_layout
  final layoutDir = Directory('lib/ui/layouts/participant_manager_layout');
  if (await layoutDir.exists()) {
    changes += await updateFilesInDirectory(layoutDir);
  }

  return changes;
}

Future<int> updateFilesInDirectory(Directory dir) async {
  int changes = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = await entity.readAsString();
      final original = content;

      // Replace class names and identifiers
      content = content.replaceAll('AccountManager', 'ParticipantManager');
      content = content.replaceAll('account_manager', 'participant_manager');
      content = content.replaceAll('account-manager', 'participant-manager');

      // Update import paths
      content = content.replaceAll(
        'lib/ui/views/account_manager/',
        'lib/ui/views/participant_manager/',
      );
      content = content.replaceAll(
        'lib/ui/layouts/account_manager_layout/',
        'lib/ui/layouts/participant_manager_layout/',
      );
      content = content.replaceAll(
        'package:kinly/ui/views/account_manager/',
        'package:kinly/ui/views/participant_manager/',
      );
      content = content.replaceAll(
        'package:kinly/ui/layouts/account_manager_layout/',
        'package:kinly/ui/layouts/participant_manager_layout/',
      );

      if (content != original) {
        await entity.writeAsString(content);
        stdout.writeln(
            '✓ Updated ${entity.path.split('/').sublist(entity.path.split('/').length - 3).join('/')}');
        changes++;
      }
    }
  }

  return changes;
}

Future<int> updateTestFiles() async {
  int changes = 0;
  final testDir = Directory('test/viewmodels');

  if (!await testDir.exists()) return changes;

  await for (final entity in testDir.list()) {
    if (entity is File && entity.path.contains('account_manager')) {
      String content = await entity.readAsString();
      final original = content;

      // Update import paths
      content = content.replaceAll(
        'package:kinly/ui/views/account_manager/',
        'package:kinly/ui/views/participant_manager/',
      );
      content = content.replaceAll(
        'package:kinly/ui/layouts/account_manager_layout/',
        'package:kinly/ui/layouts/participant_manager_layout/',
      );

      // Update class names
      content = content.replaceAll('AccountManager', 'ParticipantManager');
      content = content.replaceAll('account_manager', 'participant_manager');

      if (content != original) {
        await entity.writeAsString(content);
        stdout.writeln('✓ Updated ${entity.path.split('/').last}');
        changes++;
      }
    }
  }

  return changes;
}

Future<int> updateAppDart() async {
  int changes = 0;
  final appFile = File('lib/app/app.dart');

  if (!await appFile.exists()) return changes;

  String content = await appFile.readAsString();
  final original = content;

  // Update imports
  content = content.replaceAll(
    "import 'package:kinly/ui/layouts/account_manager_layout/account_manager_layout_view.dart';",
    "import 'package:kinly/ui/layouts/participant_manager_layout/participant_manager_layout_view.dart';",
  );
  content = content.replaceAll(
    "import 'package:kinly/ui/views/account_manager/",
    "import 'package:kinly/ui/views/participant_manager/",
  );

  // Update route references (class names stay as they rename with views)
  content = content.replaceAll(
      'AccountManagerLayoutView', 'ParticipantManagerLayoutView');
  content = content.replaceAll(
      'AccountManagerDashboardView', 'ParticipantManagerDashboardView');
  content = content.replaceAll(
      'AccountManagerInboxView', 'ParticipantManagerInboxView');
  content = content.replaceAll(
      'AccountManagerTeamView', 'ParticipantManagerTeamView');
  content = content.replaceAll(
      'AccountManagerBookingsView', 'ParticipantManagerBookingsView');

  // Update route paths
  content = content.replaceAll(
      "path: '/account-manager'", "path: '/participant-manager'");
  content = content.replaceAll(
      "path: '/account_manager'", "path: '/participant-manager'");

  if (content != original) {
    await appFile.writeAsString(content);
    stdout.writeln('✓ Updated lib/app/app.dart');
    changes++;
  }

  return changes;
}

Future<int> updateTemplateFiles() async {
  int changes = 0;

  // Update scripts/app_imports_updated.txt
  final importsFile = File('scripts/app_imports_updated.txt');
  if (await importsFile.exists()) {
    String content = await importsFile.readAsString();
    final original = content;

    content = content.replaceAll(
        'account_manager_layout', 'participant_manager_layout');
    content = content.replaceAll('account_manager/', 'participant_manager/');
    content = content.replaceAll('AccountManager', 'ParticipantManager');
    content = content.replaceAll('Account Manager', 'Participant Manager');

    if (content != original) {
      await importsFile.writeAsString(content);
      stdout.writeln('✓ Updated scripts/app_imports_updated.txt');
      changes++;
    }
  }

  // Update scripts/app_routes_template.txt
  final routesFile = File('scripts/app_routes_template.txt');
  if (await routesFile.exists()) {
    String content = await routesFile.readAsString();
    final original = content;

    content = content.replaceAll(
        'AccountManagerLayoutView', 'ParticipantManagerLayoutView');
    content = content.replaceAll(
        'AccountManagerDashboardView', 'ParticipantManagerDashboardView');
    content = content.replaceAll(
        'AccountManagerInboxView', 'ParticipantManagerInboxView');
    content = content.replaceAll(
        'AccountManagerTeamView', 'ParticipantManagerTeamView');
    content = content.replaceAll(
        'AccountManagerBookingsView', 'ParticipantManagerBookingsView');
    content = content.replaceAll(
        "path: '/account-manager'", "path: '/participant-manager'");
    content = content.replaceAll('account-manager', 'participant-manager');
    content = content.replaceAll('Account Manager', 'Participant Manager');

    if (content != original) {
      await routesFile.writeAsString(content);
      stdout.writeln('✓ Updated scripts/app_routes_template.txt');
      changes++;
    }
  }

  // Update NEW_VIEW_STRUCTURE.md
  final structureFile = File('scripts/NEW_VIEW_STRUCTURE.md');
  if (await structureFile.exists()) {
    String content = await structureFile.readAsString();
    final original = content;

    content = content.replaceAll('account_manager', 'participant_manager');
    content = content.replaceAll('AccountManager', 'ParticipantManager');
    content = content.replaceAll('Account Manager', 'Participant Manager');

    if (content != original) {
      await structureFile.writeAsString(content);
      stdout.writeln('✓ Updated scripts/NEW_VIEW_STRUCTURE.md');
      changes++;
    }
  }

  return changes;
}
