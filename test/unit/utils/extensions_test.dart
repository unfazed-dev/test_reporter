import 'package:test/test.dart';
import 'package:test_reporter/src/utils/extensions.dart';

void main() {
  group('DurationFormatting Extension', () {
    group('toHumanReadable', () {
      test('should format duration less than 1 minute with milliseconds', () {
        const duration = Duration(seconds: 5, milliseconds: 250);
        expect(duration.toHumanReadable(), equals('5.250s'));
      });

      test('should format duration with exact seconds', () {
        const duration = Duration(seconds: 30);
        expect(duration.toHumanReadable(), equals('30.000s'));
      });

      test('should format duration with zero milliseconds padding', () {
        const duration = Duration(seconds: 10, milliseconds: 5);
        expect(duration.toHumanReadable(), equals('10.005s'));
      });

      test('should format duration of exactly 1 minute', () {
        const duration = Duration(minutes: 1);
        expect(duration.toHumanReadable(), equals('1m 0s'));
      });

      test('should format duration greater than 1 minute', () {
        const duration = Duration(minutes: 2, seconds: 30);
        expect(duration.toHumanReadable(), equals('2m 30s'));
      });

      test('should format duration with many minutes and seconds', () {
        const duration = Duration(minutes: 15, seconds: 45);
        expect(duration.toHumanReadable(), equals('15m 45s'));
      });

      test('should handle zero duration', () {
        const duration = Duration.zero;
        expect(duration.toHumanReadable(), equals('0.000s'));
      });

      test('should handle very small duration (milliseconds only)', () {
        const duration = Duration(milliseconds: 123);
        expect(duration.toHumanReadable(), equals('0.123s'));
      });

      test('should handle duration with minutes and remainder seconds', () {
        const duration = Duration(minutes: 1, seconds: 59);
        expect(duration.toHumanReadable(), equals('1m 59s'));
      });

      test('should format hours as minutes', () {
        const duration = Duration(hours: 1, minutes: 5, seconds: 30);
        expect(duration.toHumanReadable(), equals('65m 30s'));
      });

      test('should handle milliseconds that round to full second', () {
        const duration = Duration(seconds: 3, milliseconds: 999);
        expect(duration.toHumanReadable(), equals('3.999s'));
      });
    });
  });

  group('DoubleFormatting Extension', () {
    group('toPercentage', () {
      test('should format double as percentage with default 1 decimal', () {
        const value = 85.5;
        expect(value.toPercentage(), equals('85.5%'));
      });

      test('should format double with no decimals', () {
        const value = 90.0;
        expect(value.toPercentage(decimals: 0), equals('90%'));
      });

      test('should format double with 2 decimals', () {
        const value = 87.654;
        expect(value.toPercentage(decimals: 2), equals('87.65%'));
      });

      test('should format double with 3 decimals', () {
        const value = 99.999;
        expect(value.toPercentage(decimals: 3), equals('99.999%'));
      });

      test('should handle zero value', () {
        const value = 0.0;
        expect(value.toPercentage(), equals('0.0%'));
      });

      test('should handle 100 percent', () {
        const value = 100.0;
        expect(value.toPercentage(), equals('100.0%'));
      });

      test('should handle very small percentages', () {
        const value = 0.01;
        expect(value.toPercentage(decimals: 2), equals('0.01%'));
      });

      test('should handle very large percentages', () {
        const value = 999.99;
        expect(value.toPercentage(), equals('1000.0%'));
      });

      test('should round values correctly', () {
        const value = 85.456;
        expect(value.toPercentage(decimals: 1), equals('85.5%'));
      });

      test('should handle negative percentages', () {
        const value = -5.5;
        expect(value.toPercentage(), equals('-5.5%'));
      });

      test('should format with many decimals', () {
        const value = 87.123456789;
        expect(value.toPercentage(decimals: 5), equals('87.12346%'));
      });
    });
  });

  group('ListChunking Extension', () {
    group('chunk', () {
      test('should split list into chunks of specified size', () {
        final list = [1, 2, 3, 4, 5, 6];
        final chunks = list.chunk(2);

        expect(chunks, hasLength(3));
        expect(chunks[0], equals([1, 2]));
        expect(chunks[1], equals([3, 4]));
        expect(chunks[2], equals([5, 6]));
      });

      test('should handle list that does not divide evenly', () {
        final list = [1, 2, 3, 4, 5];
        final chunks = list.chunk(2);

        expect(chunks, hasLength(3));
        expect(chunks[0], equals([1, 2]));
        expect(chunks[1], equals([3, 4]));
        expect(chunks[2], equals([5])); // Last chunk with 1 element
      });

      test('should handle chunk size equal to list length', () {
        final list = [1, 2, 3];
        final chunks = list.chunk(3);

        expect(chunks, hasLength(1));
        expect(chunks[0], equals([1, 2, 3]));
      });

      test('should handle chunk size greater than list length', () {
        final list = [1, 2];
        final chunks = list.chunk(5);

        expect(chunks, hasLength(1));
        expect(chunks[0], equals([1, 2]));
      });

      test('should handle chunk size of 1', () {
        final list = [1, 2, 3];
        final chunks = list.chunk(1);

        expect(chunks, hasLength(3));
        expect(chunks[0], equals([1]));
        expect(chunks[1], equals([2]));
        expect(chunks[2], equals([3]));
      });

      test('should handle empty list', () {
        final list = <int>[];
        final chunks = list.chunk(2);

        expect(chunks, isEmpty);
      });

      test('should work with strings', () {
        final list = ['a', 'b', 'c', 'd'];
        final chunks = list.chunk(2);

        expect(chunks, hasLength(2));
        expect(chunks[0], equals(['a', 'b']));
        expect(chunks[1], equals(['c', 'd']));
      });

      test('should work with custom objects', () {
        final list = [
          {'id': 1},
          {'id': 2},
          {'id': 3}
        ];
        final chunks = list.chunk(2);

        expect(chunks, hasLength(2));
        expect(chunks[0], hasLength(2));
        expect(chunks[1], hasLength(1));
      });

      test('should handle large chunk sizes', () {
        final list = List.generate(100, (i) => i);
        final chunks = list.chunk(10);

        expect(chunks, hasLength(10));
        expect(chunks[0], hasLength(10));
        expect(chunks[9], hasLength(10));
      });
    });
  });

  group('ListUtils Extension', () {
    group('firstOrNull', () {
      test('should return first element of non-empty list', () {
        final list = [1, 2, 3];
        expect(list.firstOrNull, equals(1));
      });

      test('should return null for empty list', () {
        final list = <int>[];
        expect(list.firstOrNull, isNull);
      });

      test('should return first element of single-element list', () {
        final list = [42];
        expect(list.firstOrNull, equals(42));
      });

      test('should work with string lists', () {
        final list = ['first', 'second', 'third'];
        expect(list.firstOrNull, equals('first'));
      });

      test('should work with nullable types', () {
        final list = <int?>[null, 1, 2];
        expect(list.firstOrNull, isNull);
      });

      test('should return first even if it is falsy', () {
        final list = [0, 1, 2];
        expect(list.firstOrNull, equals(0));
      });

      test('should return first for large lists', () {
        final list = List.generate(1000, (i) => i);
        expect(list.firstOrNull, equals(0));
      });
    });

    group('lastOrNull', () {
      test('should return last element of non-empty list', () {
        final list = [1, 2, 3];
        expect(list.lastOrNull, equals(3));
      });

      test('should return null for empty list', () {
        final list = <int>[];
        expect(list.lastOrNull, isNull);
      });

      test('should return last element of single-element list', () {
        final list = [42];
        expect(list.lastOrNull, equals(42));
      });

      test('should work with string lists', () {
        final list = ['first', 'second', 'third'];
        expect(list.lastOrNull, equals('third'));
      });

      test('should work with nullable types', () {
        final list = <int?>[1, 2, null];
        expect(list.lastOrNull, isNull);
      });

      test('should return last even if it is falsy', () {
        final list = [1, 2, 0];
        expect(list.lastOrNull, equals(0));
      });

      test('should return last for large lists', () {
        final list = List.generate(1000, (i) => i);
        expect(list.lastOrNull, equals(999));
      });
    });

    group('firstOrNull and lastOrNull combined', () {
      test('should return same value for single-element list', () {
        final list = [99];
        expect(list.firstOrNull, equals(list.lastOrNull));
        expect(list.firstOrNull, equals(99));
      });

      test('should both return null for empty list', () {
        final list = <String>[];
        expect(list.firstOrNull, isNull);
        expect(list.lastOrNull, isNull);
      });

      test('should return different values for multi-element list', () {
        final list = [1, 2, 3, 4, 5];
        expect(list.firstOrNull, equals(1));
        expect(list.lastOrNull, equals(5));
        expect(list.firstOrNull, isNot(equals(list.lastOrNull)));
      });
    });
  });

  group('Extension Edge Cases', () {
    test('DurationFormatting handles negative durations', () {
      // Note: This tests current behavior - negative durations may format oddly
      const duration = Duration(seconds: -5);
      final result = duration.toHumanReadable();
      // Document what happens with negative durations
      expect(result, isNotEmpty);
    });

    test('DoubleFormatting handles infinity', () {
      const value = double.infinity;
      expect(value.toPercentage(), equals('Infinity%'));
    });

    test('DoubleFormatting handles NaN', () {
      const value = double.nan;
      expect(value.toPercentage(), equals('NaN%'));
    });

    test('ListChunking preserves type information', () {
      final list = [1, 2, 3];
      final chunks = list.chunk(2);

      expect(chunks, isA<List<List<int>>>());
      expect(chunks[0], isA<List<int>>());
    });

    test('ListUtils works with different types', () {
      final intList = [1, 2, 3];
      final stringList = ['a', 'b', 'c'];
      final boolList = [true, false];

      expect(intList.firstOrNull, isA<int>());
      expect(stringList.firstOrNull, isA<String>());
      expect(boolList.firstOrNull, isA<bool>());
    });
  });
}
