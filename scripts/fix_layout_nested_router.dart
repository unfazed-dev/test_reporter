#!/usr/bin/env dart

import 'dart:io';

/// Script to fix all layout files to use NestedRouter() instead of placeholder text

void main() async {
  stdout.writeln('🔧 Fixing layout files to use NestedRouter()');
  stdout.writeln('=' * 60);

  int totalFixed = 0;

  // Find all layout view files (mobile, tablet, desktop)
  final layoutsDir = Directory('lib/ui/layouts');

  await for (final entity in layoutsDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      // Skip viewmodel files
      if (entity.path.contains('viewmodel')) continue;
      // Skip base view files (we only update platform-specific ones)
      if (!entity.path.contains('.mobile.dart') &&
          !entity.path.contains('.tablet.dart') &&
          !entity.path.contains('.desktop.dart')) {
        continue;
      }

      String content = await entity.readAsString();
      final original = content;

      // Check if it has the placeholder text
      if (content.contains('Nested routes will appear here')) {
        // Replace the entire Scaffold body with NestedRouter()
        content = content.replaceAllMapped(
          RegExp(
            r'return const Scaffold\([\s\S]*?\);[\s\n]*}',
            multiLine: true,
          ),
          (match) =>
              'return const Scaffold(\n      body: NestedRouter(),\n    );\n  }',
        );

        // Ensure stacked import exists for NestedRouter
        if (!content.contains("import 'package:stacked/stacked.dart';")) {
          // Add after the viewmodel import
          content = content.replaceFirstMapped(
            RegExp(r"import 'package:kinly/ui/layouts/.*?_viewmodel\.dart';"),
            (match) =>
                "${match.group(0)}\nimport 'package:stacked/stacked.dart';",
          );
        }

        if (content != original) {
          await entity.writeAsString(content);
          stdout.writeln(
              '✓ Fixed ${entity.path.split('/').sublist(entity.path.split('/').length - 3).join('/')}');
          totalFixed++;
        }
      }
    }
  }

  stdout.writeln('');
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Fixed $totalFixed layout files');
  stdout.writeln('');
  stdout
      .writeln('All layouts now use NestedRouter() for child route rendering');
}
