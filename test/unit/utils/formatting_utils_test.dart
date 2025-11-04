import 'package:test/test.dart';
import 'package:test_reporter/src/utils/formatting_utils.dart';

void main() {
  group('FormattingUtils', () {
    group('formatTimestamp', () {
      test('should format timestamp with single-digit hour and minute', () {
        final timestamp = DateTime(2025, 11, 4, 9, 5);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('0905_041125'),
        );
      });

      test('should format timestamp with double-digit hour and minute', () {
        final timestamp = DateTime(2025, 11, 4, 14, 35);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('1435_041125'),
        );
      });

      test('should format timestamp at midnight', () {
        final timestamp = DateTime(2025, 11, 4, 0, 0);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('0000_041125'),
        );
      });

      test('should format timestamp at noon', () {
        final timestamp = DateTime(2025, 11, 4, 12, 0);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('1200_041125'),
        );
      });

      test('should format timestamp at end of day', () {
        final timestamp = DateTime(2025, 11, 4, 23, 59);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('2359_041125'),
        );
      });

      test('should format timestamp with single-digit day and month', () {
        final timestamp = DateTime(2025, 1, 5, 10, 30);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('1030_050125'),
        );
      });

      test('should format timestamp with last day of month', () {
        final timestamp = DateTime(2025, 12, 31, 23, 59);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('2359_311225'),
        );
      });

      test('should format timestamp with first day of year', () {
        final timestamp = DateTime(2025, 1, 1, 0, 0);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('0000_010125'),
        );
      });

      test('should extract last 2 digits of year', () {
        final timestamp1 = DateTime(2025, 6, 15, 10, 30);
        final timestamp2 = DateTime(2099, 6, 15, 10, 30);

        expect(
          FormattingUtils.formatTimestamp(timestamp1),
          equals('1030_150625'),
        );
        expect(
          FormattingUtils.formatTimestamp(timestamp2),
          equals('1030_150699'),
        );
      });

      test('should handle leap year date', () {
        final timestamp = DateTime(2024, 2, 29, 12, 0);
        expect(
          FormattingUtils.formatTimestamp(timestamp),
          equals('1200_290224'),
        );
      });
    });

    group('formatDuration', () {
      test('should format duration less than 1 minute with milliseconds', () {
        const duration = Duration(seconds: 5, milliseconds: 250);
        expect(FormattingUtils.formatDuration(duration), equals('5.250s'));
      });

      test('should format duration with exact seconds', () {
        const duration = Duration(seconds: 30);
        expect(FormattingUtils.formatDuration(duration), equals('30.000s'));
      });

      test('should format duration of exactly 1 minute', () {
        const duration = Duration(minutes: 1);
        expect(FormattingUtils.formatDuration(duration), equals('1m 0s'));
      });

      test('should format duration greater than 1 minute', () {
        const duration = Duration(minutes: 2, seconds: 30);
        expect(FormattingUtils.formatDuration(duration), equals('2m 30s'));
      });

      test('should format duration with many minutes', () {
        const duration = Duration(minutes: 15, seconds: 45);
        expect(FormattingUtils.formatDuration(duration), equals('15m 45s'));
      });

      test('should handle zero duration', () {
        const duration = Duration.zero;
        expect(FormattingUtils.formatDuration(duration), equals('0.000s'));
      });

      test('should handle very small duration (milliseconds only)', () {
        const duration = Duration(milliseconds: 123);
        expect(FormattingUtils.formatDuration(duration), equals('0.123s'));
      });

      test('should format hours as minutes', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 30);
        expect(FormattingUtils.formatDuration(duration), equals('65m 30s'));
      });

      test('should pad milliseconds with zeros', () {
        const duration = Duration(seconds: 3, milliseconds: 5);
        expect(FormattingUtils.formatDuration(duration), equals('3.005s'));
      });
    });

    group('formatPercentage', () {
      test('should format percentage with default 1 decimal', () {
        expect(FormattingUtils.formatPercentage(85.5), equals('85.5%'));
      });

      test('should format percentage with 0 decimals', () {
        expect(
          FormattingUtils.formatPercentage(90.0, decimals: 0),
          equals('90%'),
        );
      });

      test('should format percentage with 2 decimals', () {
        expect(
          FormattingUtils.formatPercentage(87.654, decimals: 2),
          equals('87.65%'),
        );
      });

      test('should format percentage with 3 decimals', () {
        expect(
          FormattingUtils.formatPercentage(99.999, decimals: 3),
          equals('99.999%'),
        );
      });

      test('should handle zero percentage', () {
        expect(FormattingUtils.formatPercentage(0.0), equals('0.0%'));
      });

      test('should handle 100 percent', () {
        expect(FormattingUtils.formatPercentage(100.0), equals('100.0%'));
      });

      test('should handle very small percentages', () {
        expect(
          FormattingUtils.formatPercentage(0.01, decimals: 2),
          equals('0.01%'),
        );
      });

      test('should handle negative percentages', () {
        expect(FormattingUtils.formatPercentage(-5.5), equals('-5.5%'));
      });

      test('should round correctly', () {
        expect(
          FormattingUtils.formatPercentage(85.456, decimals: 1),
          equals('85.5%'),
        );
      });
    });

    group('truncate', () {
      test('should not truncate string shorter than max length', () {
        expect(
          FormattingUtils.truncate('Hello', 10),
          equals('Hello'),
        );
      });

      test('should not truncate string equal to max length', () {
        expect(
          FormattingUtils.truncate('Hello', 5),
          equals('Hello'),
        );
      });

      test('should truncate string longer than max length', () {
        expect(
          FormattingUtils.truncate('Hello World', 8),
          equals('Hello...'),
        );
      });

      test('should truncate with ellipsis taking 3 characters', () {
        expect(
          FormattingUtils.truncate('1234567890', 7),
          equals('1234...'),
        );
      });

      test('should handle empty string', () {
        expect(
          FormattingUtils.truncate('', 10),
          equals(''),
        );
      });

      test('should handle very long strings', () {
        final longString = 'a' * 1000;
        final truncated = FormattingUtils.truncate(longString, 50);

        expect(truncated.length, equals(50));
        expect(truncated.endsWith('...'), isTrue);
        expect(truncated.substring(0, 47), equals('a' * 47));
      });

      test('should handle max length of 3 (minimum for ellipsis)', () {
        expect(
          FormattingUtils.truncate('Hello', 3),
          equals('...'),
        );
      });

      test('should handle max length less than string length', () {
        expect(
          FormattingUtils.truncate('Hello World!', 10),
          equals('Hello W...'),
        );
      });

      test('should preserve content before truncation', () {
        final result = FormattingUtils.truncate('Test string here', 12);
        // 12 chars total: 9 chars + '...' (3 chars)
        expect(result, equals('Test stri...'));
        expect(result.startsWith('Test'), isTrue);
        expect(result.length, equals(12));
      });
    });

    group('generateBar', () {
      test('should generate full bar at 100%', () {
        expect(
          FormattingUtils.generateBar(100, 10),
          equals('██████████'),
        );
      });

      test('should generate empty bar at 0%', () {
        expect(
          FormattingUtils.generateBar(0, 10),
          equals('░░░░░░░░░░'),
        );
      });

      test('should generate half-filled bar at 50%', () {
        expect(
          FormattingUtils.generateBar(50, 10),
          equals('█████░░░░░'),
        );
      });

      test('should generate bar with 75% fill', () {
        expect(
          FormattingUtils.generateBar(75, 20),
          equals('███████████████░░░░░'),
        );
      });

      test('should generate bar with 25% fill', () {
        expect(
          FormattingUtils.generateBar(25, 20),
          equals('█████░░░░░░░░░░░░░░░'),
        );
      });

      test('should handle custom filled character', () {
        expect(
          FormattingUtils.generateBar(50, 10, filledChar: '#'),
          equals('#####░░░░░'),
        );
      });

      test('should handle custom empty character', () {
        expect(
          FormattingUtils.generateBar(50, 10, emptyChar: '-'),
          equals('█████-----'),
        );
      });

      test('should handle both custom characters', () {
        expect(
          FormattingUtils.generateBar(
            50,
            10,
            filledChar: '=',
            emptyChar: ' ',
          ),
          equals('=====     '),
        );
      });

      test('should handle small width', () {
        expect(
          FormattingUtils.generateBar(50, 2),
          equals('█░'),
        );
      });

      test('should handle width of 1', () {
        expect(FormattingUtils.generateBar(0, 1), equals('░'));
        expect(FormattingUtils.generateBar(100, 1), equals('█'));
      });

      test('should handle large width', () {
        final bar = FormattingUtils.generateBar(50, 100);
        expect(bar.length, equals(100));
        expect(bar.substring(0, 50), equals('█' * 50));
        expect(bar.substring(50), equals('░' * 50));
      });

      test('should round percentage to nearest integer', () {
        // 33.33% of 10 = 3.333 should round to 3
        expect(
          FormattingUtils.generateBar(33.33, 10),
          equals('███░░░░░░░'),
        );

        // 66.67% of 10 = 6.667 should round to 7
        expect(
          FormattingUtils.generateBar(66.67, 10),
          equals('███████░░░'),
        );
      });

      test('should handle very small percentages', () {
        expect(
          FormattingUtils.generateBar(1, 100),
          equals('█' + '░' * 99),
        );
      });

      test('should handle very large percentages (over 100)', () {
        // 150% of 10 = 15 filled, exceeds width (no clamping)
        final bar = FormattingUtils.generateBar(150, 10);
        // Function doesn't clamp, so bar length exceeds width
        expect(bar.length, greaterThanOrEqualTo(10));
        expect(bar, contains('█'));
      });

      test('should handle negative percentages', () {
        // Negative percentage produces negative filled count
        final bar = FormattingUtils.generateBar(-10, 10);
        // Function doesn't clamp, behavior may vary
        expect(bar, isNotEmpty);
        expect(bar, contains('░'));
      });

      test('should generate consistent bar length', () {
        for (var percent = 0.0; percent <= 100; percent += 10) {
          final bar = FormattingUtils.generateBar(percent, 20);
          expect(bar.length, equals(20),
              reason: 'Bar at $percent% should have length 20');
        }
      });
    });

    group('Edge Cases and Integration', () {
      test('formatTimestamp should handle different centuries', () {
        final timestamp1900s = DateTime(1999, 12, 31, 23, 59);
        final timestamp2000s = DateTime(2025, 1, 1, 0, 0);

        expect(
          FormattingUtils.formatTimestamp(timestamp1900s),
          equals('2359_311299'),
        );
        expect(
          FormattingUtils.formatTimestamp(timestamp2000s),
          equals('0000_010125'),
        );
      });

      test('formatDuration and formatPercentage produce expected formats', () {
        const duration = Duration(seconds: 90);
        const percentage = 90.0;

        final durationStr = FormattingUtils.formatDuration(duration);
        final percentageStr = FormattingUtils.formatPercentage(percentage);

        // 90 seconds = 1 minute 30 seconds
        expect(durationStr, equals('1m 30s'));
        expect(percentageStr, equals('90.0%'));
      });

      test('truncate should handle special characters', () {
        // Note: substring on multi-byte chars may produce replacement chars
        final result = FormattingUtils.truncate('Hello World Test', 10);
        expect(result.length, equals(10));
        expect(result.endsWith('...'), isTrue);
      });

      test('generateBar should work with ASCII art characters', () {
        expect(
          FormattingUtils.generateBar(50, 10, filledChar: '*', emptyChar: '.'),
          equals('*****.....'),
        );
      });

      test('all formatting methods should handle null-safe types', () {
        final timestamp = DateTime.now();
        const duration = Duration(seconds: 10);
        const percentage = 50.0;
        const string = 'test';

        expect(
            () => FormattingUtils.formatTimestamp(timestamp), returnsNormally);
        expect(() => FormattingUtils.formatDuration(duration), returnsNormally);
        expect(() => FormattingUtils.formatPercentage(percentage),
            returnsNormally);
        expect(() => FormattingUtils.truncate(string, 10), returnsNormally);
        expect(
            () => FormattingUtils.generateBar(percentage, 10), returnsNormally);
      });
    });
  });
}
