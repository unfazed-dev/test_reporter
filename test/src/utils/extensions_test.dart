import 'package:test/test.dart';
import 'package:test_analyzer/src/utils/extensions.dart';

void main() {
  group('DurationFormatting', () {
    group('toHumanReadable', () {
      test('should format duration with minutes and seconds', () {
        const duration = Duration(minutes: 2, seconds: 30);
        expect(duration.toHumanReadable(), '2m 30s');
      });

      test('should format duration with only minutes', () {
        const duration = Duration(minutes: 5);
        expect(duration.toHumanReadable(), '5m 0s');
      });

      test('should format duration with seconds only', () {
        const duration = Duration(seconds: 45);
        expect(duration.toHumanReadable(), '45.000s');
      });

      test('should format duration with milliseconds', () {
        const duration = Duration(seconds: 5, milliseconds: 123);
        expect(duration.toHumanReadable(), '5.123s');
      });

      test('should pad milliseconds to 3 digits', () {
        const duration = Duration(seconds: 3, milliseconds: 5);
        expect(duration.toHumanReadable(), '3.005s');
      });

      test('should handle zero duration', () {
        const duration = Duration.zero;
        expect(duration.toHumanReadable(), '0.000s');
      });

      test('should handle very large durations', () {
        const duration = Duration(minutes: 120, seconds: 45);
        expect(duration.toHumanReadable(), '120m 45s');
      });
    });
  });

  group('DoubleFormatting', () {
    group('toPercentage', () {
      test('should format double as percentage with default 1 decimal', () {
        expect(85.5.toPercentage(), '85.5%');
      });

      test('should format double with 0 decimals', () {
        expect(85.7.toPercentage(decimals: 0), '86%');
      });

      test('should format double with 2 decimals', () {
        expect(85.555.toPercentage(decimals: 2), '85.56%');
      });

      test('should handle 100%', () {
        expect(100.0.toPercentage(), '100.0%');
      });

      test('should handle 0%', () {
        expect(0.0.toPercentage(), '0.0%');
      });

      test('should handle negative percentages', () {
        expect((-5.5).toPercentage(), '-5.5%');
      });

      test('should handle very small numbers', () {
        expect(0.001.toPercentage(decimals: 3), '0.001%');
      });
    });
  });

  group('ListChunking', () {
    group('chunk', () {
      test('should split list into chunks of specified size', () {
        final list = [1, 2, 3, 4, 5, 6, 7, 8, 9];
        final chunks = list.chunk(3);

        expect(chunks.length, 3);
        expect(chunks[0], [1, 2, 3]);
        expect(chunks[1], [4, 5, 6]);
        expect(chunks[2], [7, 8, 9]);
      });

      test('should handle list not perfectly divisible by chunk size', () {
        final list = [1, 2, 3, 4, 5, 6, 7];
        final chunks = list.chunk(3);

        expect(chunks.length, 3);
        expect(chunks[0], [1, 2, 3]);
        expect(chunks[1], [4, 5, 6]);
        expect(chunks[2], [7]);
      });

      test('should handle empty list', () {
        final list = <int>[];
        final chunks = list.chunk(3);

        expect(chunks.isEmpty, isTrue);
      });

      test('should handle chunk size larger than list', () {
        final list = [1, 2, 3];
        final chunks = list.chunk(5);

        expect(chunks.length, 1);
        expect(chunks[0], [1, 2, 3]);
      });

      test('should handle chunk size of 1', () {
        final list = [1, 2, 3];
        final chunks = list.chunk(1);

        expect(chunks.length, 3);
        expect(chunks[0], [1]);
        expect(chunks[1], [2]);
        expect(chunks[2], [3]);
      });

      test('should work with strings', () {
        final list = ['a', 'b', 'c', 'd', 'e'];
        final chunks = list.chunk(2);

        expect(chunks.length, 3);
        expect(chunks[0], ['a', 'b']);
        expect(chunks[1], ['c', 'd']);
        expect(chunks[2], ['e']);
      });
    });
  });

  group('ListUtils', () {
    group('firstOrNull', () {
      test('should return first element when list is not empty', () {
        final list = [1, 2, 3];
        expect(list.firstOrNull, 1);
      });

      test('should return null when list is empty', () {
        final list = <int>[];
        expect(list.firstOrNull, isNull);
      });

      test('should work with single element list', () {
        final list = [42];
        expect(list.firstOrNull, 42);
      });
    });

    group('lastOrNull', () {
      test('should return last element when list is not empty', () {
        final list = [1, 2, 3];
        expect(list.lastOrNull, 3);
      });

      test('should return null when list is empty', () {
        final list = <int>[];
        expect(list.lastOrNull, isNull);
      });

      test('should work with single element list', () {
        final list = [42];
        expect(list.lastOrNull, 42);
      });
    });
  });
}
