import 'package:test/test.dart';
import 'package:test_reporter/test_analyzer.dart';

void main() {
  group('FormattingUtils', () {
    test('formatTimestamp should format correctly', () {
      final timestamp = DateTime(2025, 1, 28, 14, 30);
      final formatted = FormattingUtils.formatTimestamp(timestamp);
      expect(formatted, equals('1430_280125'));
    });

    test('formatDuration should format minutes and seconds', () {
      const duration = Duration(minutes: 2, seconds: 30);
      final formatted = FormattingUtils.formatDuration(duration);
      expect(formatted, equals('2m 30s'));
    });

    test('formatPercentage should format with decimals', () {
      final percentage = FormattingUtils.formatPercentage(85.67);
      expect(percentage, equals('85.7%'));
    });
  });

  group('PathUtils', () {
    test('extractPathName should extract meaningful name', () {
      const path = 'test/ui/widgets/onboarding';
      final name = PathUtils.extractPathName(path);
      expect(name, equals('ui_widgets_onboarding'));
    });

    test('normalizePath should normalize path', () {
      const path = 'test/ui/./widgets/../widgets';
      final normalized = PathUtils.normalizePath(path);
      expect(normalized, equals('test/ui/widgets'));
    });
  });
}
