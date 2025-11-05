/// Utilities for generating GitHub-flavored markdown checklists in reports.
///
/// Provides classes and helpers for creating actionable task lists that
/// developers can use to track fixes, improvements, and test coverage additions.
library;

/// Priority levels for checklist sections.
enum ChecklistPriority {
  /// 🔴 Critical - Must fix immediately (blocks releases)
  critical,

  /// 🟠 Important - Should fix soon (affects reliability)
  important,

  /// 🟡 Optional - Nice to have (enhancements)
  optional,
}

/// A single checklist item with optional sub-items, tips, and commands.
class ChecklistItem {
  /// Creates a checklist item.
  const ChecklistItem({
    required this.text,
    this.subItems = const [],
    this.tip,
    this.command,
  });

  /// The main text of the checklist item
  final String text;

  /// Optional nested sub-items
  final List<ChecklistItem> subItems;

  /// Optional tip/hint for completing this item (shown with 💡 emoji)
  final String? tip;

  /// Optional command to run (shown with backticks)
  final String? command;

  /// Converts this item to GitHub-flavored markdown format.
  ///
  /// [indent] controls the nesting level (0 = root, 1 = sub-item, etc.)
  String toMarkdown({int indent = 0}) {
    final buffer = StringBuffer();
    final prefix = '  ' * indent;

    // Main checkbox
    buffer.writeln('$prefix- [ ] $text');

    // Add tip if provided
    if (tip != null) {
      buffer.writeln('$prefix  - 💡 Tip: $tip');
    }

    // Add command if provided
    if (command != null) {
      buffer.writeln('$prefix  - Run: `$command`');
    }

    // Add sub-items recursively
    for (final subItem in subItems) {
      buffer.write(subItem.toMarkdown(indent: indent + 1));
    }

    return buffer.toString();
  }
}

/// A section of related checklist items with a title and optional priority.
class ChecklistSection {
  /// Creates a checklist section.
  const ChecklistSection({
    required this.title,
    required this.items,
    this.subtitle,
    this.priority,
  });

  /// The section title
  final String title;

  /// Optional subtitle/description
  final String? subtitle;

  /// The checklist items in this section
  final List<ChecklistItem> items;

  /// Optional priority level (adds emoji to title)
  final ChecklistPriority? priority;

  /// Converts this section to markdown format.
  String toMarkdown() {
    final buffer = StringBuffer();

    // Add title with priority emoji if specified
    if (priority != null) {
      final emoji = _priorityEmoji(priority!);
      buffer.writeln('### $emoji $title');
    } else {
      buffer.writeln('### $title');
    }

    // Add subtitle if provided
    if (subtitle != null) {
      buffer.writeln('*$subtitle*');
      buffer.writeln();
    }

    buffer.writeln();

    // Add all items
    for (final item in items) {
      buffer.write(item.toMarkdown());
    }

    return buffer.toString();
  }

  /// Gets the emoji for a priority level.
  String _priorityEmoji(ChecklistPriority priority) {
    switch (priority) {
      case ChecklistPriority.critical:
        return '🔴';
      case ChecklistPriority.important:
        return '🟠';
      case ChecklistPriority.optional:
        return '🟡';
    }
  }
}

/// A grouped test case from consecutive uncovered lines.
class TestCaseGroup {
  /// Creates a test case group.
  const TestCaseGroup({
    required this.lineRange,
    required this.description,
    this.suggestion,
  });

  /// The line range (e.g., "15-20" or "25")
  final String lineRange;

  /// Human-readable description of what to test
  final String description;

  /// Optional suggestion for how to test
  final String? suggestion;
}

/// Suggests the test file path for a given source file.
///
/// Converts:
/// - `lib/src/auth/service.dart` → `test/auth/service_test.dart`
/// - `lib/main.dart` → `test/main_test.dart`
String suggestTestFile(String sourceFile) {
  // Remove lib/ prefix
  var path = sourceFile;
  if (path.startsWith('lib/')) {
    path = path.substring(4);
  }

  // Remove src/ prefix if present
  if (path.startsWith('src/')) {
    path = path.substring(4);
  }

  // Ensure .dart extension
  if (!path.endsWith('.dart')) {
    path = '$path.dart';
  }

  // Remove _test.dart if already present (avoid double test suffix)
  if (path.endsWith('_test.dart')) {
    path = path.substring(0, path.length - 10);
  } else if (path.endsWith('.dart')) {
    // Remove .dart to add _test.dart
    path = path.substring(0, path.length - 5);
  }

  return 'test/$path\_test.dart';
}

/// Formats a human-readable description for a line range.
///
/// Detects common patterns like error handling, null checks, etc.
String formatLineRangeDescription(
  String file,
  List<int> lines, {
  String? codeSnippet,
}) {
  final lineRange = _formatLineRange(lines);

  // Detect patterns from code snippet if provided
  if (codeSnippet != null) {
    final lowerSnippet = codeSnippet.toLowerCase();

    // Check for null first (more specific than general error handling)
    if (lowerSnippet.contains('null')) {
      return 'Test $lineRange: Null validation';
    }

    if (lowerSnippet.contains('catch') ||
        lowerSnippet.contains('error') ||
        lowerSnippet.contains('exception')) {
      return 'Test $lineRange: Error handling';
    }

    if (lowerSnippet.contains('if') || lowerSnippet.contains('else')) {
      return 'Test $lineRange: Branch coverage';
    }
  }

  // Generic description
  if (lines.length == 1) {
    return 'Test line ${lines.first}';
  } else {
    return 'Test lines $lineRange';
  }
}

/// Formats a list of line numbers into a compact range string.
///
/// Examples:
/// - `[15]` → "15"
/// - `[15, 16, 17]` → "15-17"
/// - `[15, 16, 20, 21, 25]` → "15-16, 20-21, 25"
String _formatLineRange(List<int> lines) {
  if (lines.isEmpty) return '';
  if (lines.length == 1) return lines.first.toString();

  final sorted = List<int>.from(lines)..sort();
  final ranges = <String>[];
  var rangeStart = sorted.first;
  var rangeEnd = sorted.first;

  for (var i = 1; i < sorted.length; i++) {
    if (sorted[i] == rangeEnd + 1) {
      // Continue range
      rangeEnd = sorted[i];
    } else {
      // End current range, start new one
      if (rangeStart == rangeEnd) {
        ranges.add(rangeStart.toString());
      } else {
        ranges.add('$rangeStart-$rangeEnd');
      }
      rangeStart = sorted[i];
      rangeEnd = sorted[i];
    }
  }

  // Add final range
  if (rangeStart == rangeEnd) {
    ranges.add(rangeStart.toString());
  } else {
    ranges.add('$rangeStart-$rangeEnd');
  }

  return ranges.join(', ');
}

/// Groups consecutive line numbers into logical test cases.
///
/// Attempts to identify patterns and create meaningful test case descriptions.
List<TestCaseGroup> groupLinesIntoTestCases(String file, List<int> lines) {
  if (lines.isEmpty) return [];

  final testCases = <TestCaseGroup>[];
  final sorted = List<int>.from(lines)..sort();

  var groupStart = 0;
  for (var i = 0; i < sorted.length; i++) {
    // Check if this is the last line or if the next line is not consecutive
    if (i == sorted.length - 1 || sorted[i + 1] != sorted[i] + 1) {
      // Create a test case for this group
      final groupLines = sorted.sublist(groupStart, i + 1);
      final lineRange = _formatLineRange(groupLines);
      final description = 'Uncovered logic in lines $lineRange';

      testCases.add(
        TestCaseGroup(
          lineRange: lineRange,
          description: description,
        ),
      );

      groupStart = i + 1;
    }
  }

  return testCases;
}

/// Sorts checklist sections by priority (critical > important > optional).
///
/// Maintains original order for sections with the same priority.
List<ChecklistSection> prioritizeItems(List<ChecklistSection> sections) {
  if (sections.isEmpty) return [];

  // Create a copy to avoid modifying the original list
  final sorted = List<ChecklistSection>.from(sections);

  // Sort by priority
  sorted.sort((a, b) {
    // Null priorities go last
    if (a.priority == null && b.priority == null) return 0;
    if (a.priority == null) return 1;
    if (b.priority == null) return -1;

    // Compare priority indices (critical=0, important=1, optional=2)
    return a.priority!.index.compareTo(b.priority!.index);
  });

  return sorted;
}
