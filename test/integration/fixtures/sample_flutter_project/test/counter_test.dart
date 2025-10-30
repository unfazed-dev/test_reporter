import 'package:test/test.dart';
import 'package:sample_flutter_project/counter.dart';

void main() {
  group('Counter', () {
    test('starts at zero by default', () {
      final counter = Counter();
      expect(counter.value, equals(0));
    });

    test('starts at initial value', () {
      final counter = Counter(initialValue: 5);
      expect(counter.value, equals(5));
    });

    test('increments value', () {
      final counter = Counter();
      counter.increment();
      expect(counter.value, equals(1));
      counter.increment();
      expect(counter.value, equals(2));
    });

    test('decrements value', () {
      final counter = Counter(initialValue: 5);
      counter.decrement();
      expect(counter.value, equals(4));
    });

    test('resets to initial value', () {
      final counter = Counter(initialValue: 10);
      counter.increment();
      counter.increment();
      counter.reset();
      expect(counter.value, equals(10));
    });
  });
}
