import 'package:test_analyzer/test_analyzer.dart';
import 'package:test/test.dart';

void main() {
  group('FormattingUtils', () {
    test('formatTimestamp should format correctly', () {
      final timestamp = DateTime(2025, 1, 28, 14, 30);
      final formatted = FormattingUtils.formatTimestamp(timestamp);
      expect(formatted, equals('1430_280125'));
    });

    test('formatDuration should format minutes and seconds', () {
      final duration = Duration(minutes: 2, seconds: 30);
      final formatted = FormattingUtils.formatDuration(duration);
      expect(formatted, equals('2m 30s'));
    });

    test('formatPercentage should format with decimals', () {
      final percentage = FormattingUtils.formatPercentage(85.67, decimals: 1);
      expect(percentage, equals('85.7%'));
    });
  });

  group('PathUtils', () {
    test('extractPathName should extract meaningful name', () {
      final path = 'test/ui/widgets/onboarding';
      final name = PathUtils.extractPathName(path);
      expect(name, equals('ui_widgets_onboarding'));
    });

    test('normalizePath should normalize path', () {
      final path = 'test/ui/./widgets/../widgets';
      final normalized = PathUtils.normalizePath(path);
      expect(normalized, equals('test/ui/widgets'));
    });
  });
}
