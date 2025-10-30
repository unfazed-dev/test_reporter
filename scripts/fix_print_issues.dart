#!/usr/bin/env dart

import 'dart:io';

/// Script to replace print() with stdout.writeln() in all script files

void main() async {
  stdout.writeln('🔧 Fixing print statements in scripts');
  stdout.writeln('=' * 60);

  final scriptsToFix = [
    'scripts/fix_all_analyzer_issues.dart',
    'scripts/fix_analyzer_issues.dart',
    'scripts/fix_locator_imports.dart',
    'scripts/fix_remaining_issues.dart',
    'scripts/generate_routes.dart',
    'scripts/rename_account_manager.dart',
    'scripts/reorganize_views.dart',
  ];

  int totalReplacements = 0;

  for (final scriptPath in scriptsToFix) {
    final file = File(scriptPath);
    if (!await file.exists()) continue;

    String content = await file.readAsString();
    final originalContent = content;

    // Ensure dart:io import exists
    if (!content.contains("import 'dart:io';")) {
      // Add after the shebang line if it exists
      if (content.startsWith('#!/usr/bin/env dart')) {
        content = content.replaceFirst(
          '#!/usr/bin/env dart\n',
          "#!/usr/bin/env dart\n\nimport 'dart:io';\n",
        );
      } else {
        content = "import 'dart:io';\n\n$content";
      }
    }

    // Replace print( with stdout.writeln(
    content = content.replaceAll('print(', 'stdout.writeln(');
    final afterCount = 'stdout.writeln('.allMatches(content).length;

    final replacements = afterCount -
        (originalContent.contains('stdout.writeln(')
            ? 'stdout.writeln('.allMatches(originalContent).length
            : 0);

    if (content != originalContent) {
      await file.writeAsString(content);
      stdout.writeln(
          '✓ Fixed ${scriptPath.split('/').last} ($replacements replacements)');
      totalReplacements += replacements;
    }
  }

  stdout.writeln();
  stdout.writeln('=' * 60);
  stdout.writeln('✅ Fixed $totalReplacements print statements');
}
