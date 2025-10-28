import 'package:test/test.dart';
import 'package:test_analyzer/src/utils/formatting_utils.dart';

void main() {
  group('FormattingUtils', () {
    group('formatTimestamp', () {
      test('should format timestamp as HHMM_DDMMYY', () {
        final timestamp = DateTime(2025, 1, 28, 14, 30);
        final formatted = FormattingUtils.formatTimestamp(timestamp);
        expect(formatted, '1430_280125');
      });

      test('should pad single digits with zeros', () {
        final timestamp = DateTime(2025, 3, 5, 9, 7);
        final formatted = FormattingUtils.formatTimestamp(timestamp);
        expect(formatted, '0907_050325');
      });

      test('should handle midnight', () {
        final timestamp = DateTime(2025, 12, 31);
        final formatted = FormattingUtils.formatTimestamp(timestamp);
        expect(formatted, '0000_311225');
      });

      test('should handle end of day', () {
        final timestamp = DateTime(2025, 6, 15, 23, 59);
        final formatted = FormattingUtils.formatTimestamp(timestamp);
        expect(formatted, '2359_150625');
      });
    });

    group('formatDuration', () {
      test('should format duration with minutes and seconds', () {
        const duration = Duration(minutes: 2, seconds: 30);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '2m 30s');
      });

      test('should format duration with only minutes', () {
        const duration = Duration(minutes: 5);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '5m 0s');
      });

      test('should format duration with seconds only', () {
        const duration = Duration(seconds: 45);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '45.000s');
      });

      test('should format duration with milliseconds', () {
        const duration = Duration(seconds: 3, milliseconds: 123);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '3.123s');
      });

      test('should pad milliseconds to 3 digits', () {
        const duration = Duration(seconds: 2, milliseconds: 5);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '2.005s');
      });

      test('should handle zero duration', () {
        const duration = Duration.zero;
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '0.000s');
      });

      test('should handle very long durations', () {
        const duration = Duration(minutes: 120, seconds: 45);
        final formatted = FormattingUtils.formatDuration(duration);
        expect(formatted, '120m 45s');
      });
    });

    group('formatPercentage', () {
      test('should format with default 1 decimal', () {
        final percentage = FormattingUtils.formatPercentage(85.67);
        expect(percentage, '85.7%');
      });

      test('should format with 0 decimals', () {
        final percentage = FormattingUtils.formatPercentage(85.7, decimals: 0);
        expect(percentage, '86%');
      });

      test('should format with 2 decimals', () {
        final percentage = FormattingUtils.formatPercentage(85.678, decimals: 2);
        expect(percentage, '85.68%');
      });

      test('should handle 100%', () {
        final percentage = FormattingUtils.formatPercentage(100.0);
        expect(percentage, '100.0%');
      });

      test('should handle 0%', () {
        final percentage = FormattingUtils.formatPercentage(0.0);
        expect(percentage, '0.0%');
      });
    });

    group('truncate', () {
      test('should not truncate string shorter than maxLength', () {
        const str = 'Hello';
        final truncated = FormattingUtils.truncate(str, 10);
        expect(truncated, 'Hello');
      });

      test('should not truncate string equal to maxLength', () {
        const str = 'Hello';
        final truncated = FormattingUtils.truncate(str, 5);
        expect(truncated, 'Hello');
      });

      test('should truncate long string with ellipsis', () {
        const str = 'This is a very long string that needs truncation';
        final truncated = FormattingUtils.truncate(str, 20);
        expect(truncated, 'This is a very lo...');
        expect(truncated.length, 20);
      });

      test('should truncate to minimum length with ellipsis', () {
        const str = 'Hello World';
        final truncated = FormattingUtils.truncate(str, 8);
        expect(truncated, 'Hello...');
        expect(truncated.length, 8);
      });

      test('should handle empty string', () {
        const str = '';
        final truncated = FormattingUtils.truncate(str, 10);
        expect(truncated, '');
      });
    });

    group('generateBar', () {
      test('should generate full bar at 100%', () {
        final bar = FormattingUtils.generateBar(100.0, 10);
        expect(bar, '██████████');
        expect(bar.length, 10);
      });

      test('should generate empty bar at 0%', () {
        final bar = FormattingUtils.generateBar(0.0, 10);
        expect(bar, '░░░░░░░░░░');
        expect(bar.length, 10);
      });

      test('should generate half-filled bar at 50%', () {
        final bar = FormattingUtils.generateBar(50.0, 10);
        expect(bar, '█████░░░░░');
        expect(bar.length, 10);
      });

      test('should generate bar with custom characters', () {
        final bar = FormattingUtils.generateBar(
          60.0,
          10,
          filledChar: '#',
          emptyChar: '-',
        );
        expect(bar, '######----');
        expect(bar.length, 10);
      });

      test('should round to nearest filled character', () {
        final bar = FormattingUtils.generateBar(33.0, 10);
        // 33% of 10 = 3.3, rounds to 3
        expect(bar, '███░░░░░░░');
      });

      test('should handle small widths', () {
        final bar = FormattingUtils.generateBar(75.0, 4);
        expect(bar, '███░');
        expect(bar.length, 4);
      });

      test('should handle large widths', () {
        final bar = FormattingUtils.generateBar(25.0, 50);
        expect(bar.length, 50);
        expect(bar.substring(0, 13), '█████████████');
        expect(bar.substring(13), '░' * 37);
      });

      test('should handle edge case percentages', () {
        // 1% of 10 = 0.1, rounds to 0
        final bar1 = FormattingUtils.generateBar(1.0, 10);
        expect(bar1, '░░░░░░░░░░');

        // 99% of 10 = 9.9, rounds to 10
        final bar99 = FormattingUtils.generateBar(99.0, 10);
        expect(bar99, '██████████');

        // 10% of 10 = 1.0, exactly 1
        final bar10 = FormattingUtils.generateBar(10.0, 10);
        expect(bar10, '█░░░░░░░░░');
      });
    });
  });
}
