import 'package:test/test.dart';
import 'package:test_reporter/src/utils/checklist_utils.dart';

void main() {
  group('ChecklistItem', () {
    test('should format basic markdown checkbox', () {
      final item = ChecklistItem(text: 'Test lines 15-20: Null handling');

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ]'));
      expect(markdown, contains('Test lines 15-20: Null handling'));
    });

    test('should include tip with 💡 emoji when provided', () {
      final item = ChecklistItem(
        text: 'Test lines 15-20',
        tip: 'Test both null and invalid cases',
      );

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ] Test lines 15-20'));
      expect(markdown, contains('💡 Tip: Test both null and invalid cases'));
    });

    test('should include command with backticks when provided', () {
      final item = ChecklistItem(
        text: 'Fix failing test',
        command: 'flutter test test/auth_test.dart',
      );

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ] Fix failing test'));
      expect(markdown, contains('`flutter test test/auth_test.dart`'));
    });

    test('should include sub-items with proper indentation', () {
      final item = ChecklistItem(
        text: 'Fix test failure',
        subItems: [
          ChecklistItem(text: 'Identify root cause'),
          ChecklistItem(text: 'Apply fix'),
          ChecklistItem(text: 'Verify fix'),
        ],
      );

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ] Fix test failure'));
      expect(markdown, contains('  - [ ] Identify root cause'));
      expect(markdown, contains('  - [ ] Apply fix'));
      expect(markdown, contains('  - [ ] Verify fix'));
    });

    test('should support nested sub-items with increasing indentation', () {
      final item = ChecklistItem(
        text: 'Main task',
        subItems: [
          ChecklistItem(
            text: 'Sub-task 1',
            subItems: [
              ChecklistItem(text: 'Nested task'),
            ],
          ),
        ],
      );

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ] Main task'));
      expect(markdown, contains('  - [ ] Sub-task 1'));
      expect(markdown, contains('    - [ ] Nested task'));
    });

    test('should include both tip and command when provided', () {
      final item = ChecklistItem(
        text: 'Test error handling',
        tip: 'Mock network errors',
        command: 'flutter test test/api_test.dart',
      );

      final markdown = item.toMarkdown();

      expect(markdown, contains('- [ ] Test error handling'));
      expect(markdown, contains('💡 Tip: Mock network errors'));
      expect(markdown, contains('`flutter test test/api_test.dart`'));
    });

    test('should handle empty sub-items list', () {
      final item = ChecklistItem(
        text: 'Simple task',
        subItems: [],
      );

      final markdown = item.toMarkdown();

      expect(markdown, equals('- [ ] Simple task\n'));
    });
  });

  group('ChecklistSection', () {
    test('should format section with title and items', () {
      final section = ChecklistSection(
        title: '🔴 Priority 1: Fix Failing Tests',
        items: [
          ChecklistItem(text: 'Fix test 1'),
          ChecklistItem(text: 'Fix test 2'),
        ],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('### 🔴 Priority 1: Fix Failing Tests'));
      expect(markdown, contains('- [ ] Fix test 1'));
      expect(markdown, contains('- [ ] Fix test 2'));
    });

    test('should include subtitle when provided', () {
      final section = ChecklistSection(
        title: 'Critical Fixes',
        subtitle: 'These issues block releases - fix immediately',
        items: [
          ChecklistItem(text: 'Fix critical bug'),
        ],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('### Critical Fixes'));
      expect(
        markdown,
        contains('*These issues block releases - fix immediately*'),
      );
      expect(markdown, contains('- [ ] Fix critical bug'));
    });

    test('should support priority enum in title', () {
      final section = ChecklistSection(
        title: 'Fix Failures',
        priority: ChecklistPriority.critical,
        items: [
          ChecklistItem(text: 'Fix test'),
        ],
      );

      final markdown = section.toMarkdown();

      // Priority should add emoji to title
      expect(markdown, contains('🔴'));
      expect(markdown, contains('Fix Failures'));
    });

    test('should handle empty items list', () {
      final section = ChecklistSection(
        title: 'Empty Section',
        items: [],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('### Empty Section'));
      // Should still be valid markdown even with no items
      expect(markdown.trim(), isNotEmpty);
    });

    test('should render important priority with orange emoji', () {
      final section = ChecklistSection(
        title: 'Stability Issues',
        priority: ChecklistPriority.important,
        items: [
          ChecklistItem(text: 'Fix flaky test'),
        ],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('🟠'));
      expect(markdown, contains('Stability Issues'));
    });

    test('should render optional priority with yellow emoji', () {
      final section = ChecklistSection(
        title: 'Optimizations',
        priority: ChecklistPriority.optional,
        items: [
          ChecklistItem(text: 'Optimize slow test'),
        ],
      );

      final markdown = section.toMarkdown();

      expect(markdown, contains('🟡'));
      expect(markdown, contains('Optimizations'));
    });
  });

  group('Helper Functions', () {
    group('suggestTestFile', () {
      test('should infer test file from source file', () {
        final testFile = suggestTestFile('lib/src/auth/auth_service.dart');

        expect(testFile, equals('test/auth/auth_service_test.dart'));
      });

      test('should handle lib/src prefix correctly', () {
        final testFile = suggestTestFile('lib/src/utils/report_utils.dart');

        expect(testFile, equals('test/utils/report_utils_test.dart'));
      });

      test('should handle lib without src prefix', () {
        final testFile = suggestTestFile('lib/main.dart');

        expect(testFile, equals('test/main_test.dart'));
      });

      test('should handle already _test.dart files', () {
        final testFile = suggestTestFile('lib/src/auth/auth_service_test.dart');

        expect(testFile, equals('test/auth/auth_service_test.dart'));
      });

      test('should handle file without .dart extension', () {
        final testFile = suggestTestFile('lib/src/utils/constants');

        expect(testFile, equals('test/utils/constants_test.dart'));
      });
    });

    group('formatLineRangeDescription', () {
      test('should format single line description', () {
        final description = formatLineRangeDescription(
          'lib/src/auth/service.dart',
          [15],
        );

        expect(description, contains('line 15'));
        expect(description, isNotEmpty);
      });

      test('should format consecutive line range', () {
        final description = formatLineRangeDescription(
          'lib/src/auth/service.dart',
          [15, 16, 17, 18],
        );

        expect(description, contains('lines 15-18'));
      });

      test('should format multiple ranges', () {
        final description = formatLineRangeDescription(
          'lib/src/auth/service.dart',
          [15, 16, 20, 21, 25],
        );

        expect(description, anyOf([
          contains('15-16'),
          contains('20-21'),
          contains('25'),
        ]));
      });

      test('should detect error handling pattern', () {
        final description = formatLineRangeDescription(
          'lib/src/auth/service.dart',
          [15, 16],
          codeSnippet: 'catch (e) { handleError(e); }',
        );

        expect(
          description.toLowerCase(),
          anyOf([
            contains('error'),
            contains('exception'),
            contains('catch'),
          ]),
        );
      });

      test('should detect null check pattern', () {
        final description = formatLineRangeDescription(
          'lib/src/auth/service.dart',
          [10],
          codeSnippet: 'if (token == null) throw Exception();',
        );

        expect(
          description.toLowerCase(),
          anyOf([
            contains('null'),
            contains('validation'),
          ]),
        );
      });
    });

    group('groupLinesIntoTestCases', () {
      test('should group consecutive lines', () {
        final testCases = groupLinesIntoTestCases(
          'lib/src/auth/service.dart',
          [15, 16, 17, 20, 21],
        );

        expect(testCases.length, greaterThanOrEqualTo(2));
        expect(testCases.first.lineRange, anyOf(['15-17', '15-16-17']));
      });

      test('should handle single isolated lines', () {
        final testCases = groupLinesIntoTestCases(
          'lib/src/auth/service.dart',
          [15, 20, 25],
        );

        expect(testCases.length, equals(3));
      });

      test('should include descriptions for each group', () {
        final testCases = groupLinesIntoTestCases(
          'lib/src/auth/service.dart',
          [15, 16, 17],
        );

        expect(testCases.first.description, isNotEmpty);
      });

      test('should return empty list for empty input', () {
        final testCases = groupLinesIntoTestCases(
          'lib/src/auth/service.dart',
          [],
        );

        expect(testCases, isEmpty);
      });
    });

    group('prioritizeItems', () {
      test('should sort by severity: critical > important > optional', () {
        final items = [
          ChecklistSection(
            title: 'Optional',
            priority: ChecklistPriority.optional,
            items: [],
          ),
          ChecklistSection(
            title: 'Critical',
            priority: ChecklistPriority.critical,
            items: [],
          ),
          ChecklistSection(
            title: 'Important',
            priority: ChecklistPriority.important,
            items: [],
          ),
        ];

        final sorted = prioritizeItems(items);

        expect(sorted[0].priority, equals(ChecklistPriority.critical));
        expect(sorted[1].priority, equals(ChecklistPriority.important));
        expect(sorted[2].priority, equals(ChecklistPriority.optional));
      });

      test('should handle empty list', () {
        final sorted = prioritizeItems([]);

        expect(sorted, isEmpty);
      });

      test('should maintain order for same priority', () {
        final items = [
          ChecklistSection(
            title: 'First',
            priority: ChecklistPriority.critical,
            items: [],
          ),
          ChecklistSection(
            title: 'Second',
            priority: ChecklistPriority.critical,
            items: [],
          ),
        ];

        final sorted = prioritizeItems(items);

        expect(sorted[0].title, equals('First'));
        expect(sorted[1].title, equals('Second'));
      });
    });
  });

  group('Integration', () {
    test('should create complete checklist with all features', () {
      final sections = [
        ChecklistSection(
          title: 'Fix Failing Tests',
          priority: ChecklistPriority.critical,
          subtitle: 'These tests fail every time',
          items: [
            ChecklistItem(
              text: 'Fix auth_service_test.dart: "should validate token"',
              tip: 'Add null check for authToken',
              command: 'flutter test test/auth_service_test.dart',
              subItems: [
                ChecklistItem(text: 'Identify root cause'),
                ChecklistItem(text: 'Apply fix'),
                ChecklistItem(text: 'Verify fix'),
              ],
            ),
          ],
        ),
      ];

      final markdown = sections.map((s) => s.toMarkdown()).join('\n');

      expect(markdown, contains('🔴'));
      expect(markdown, contains('Fix Failing Tests'));
      expect(markdown, contains('*These tests fail every time*'));
      expect(markdown, contains('- [ ] Fix auth_service_test.dart'));
      expect(markdown, contains('💡 Tip: Add null check'));
      expect(markdown, contains('`flutter test'));
      expect(markdown, contains('  - [ ] Identify root cause'));
      expect(markdown, contains('  - [ ] Apply fix'));
      expect(markdown, contains('  - [ ] Verify fix'));
    });
  });
}
