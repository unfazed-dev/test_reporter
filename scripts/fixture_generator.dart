/// Generates test fixture projects for integration tests
///
/// Creates sample Dart and Flutter projects with various scenarios:
/// - Perfect coverage project (100% coverage)
/// - Failing tests project (intentional failures)
/// - Sample Flutter project (basic app structure)
/// - Sample Dart project (pure Dart package)

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  print('🏗️  Generating test fixture projects...\n');

  final fixturesDir = Directory('test/integration/fixtures');
  if (!await fixturesDir.exists()) {
    await fixturesDir.create(recursive: true);
  }

  await _generateSampleDartProject(fixturesDir);
  await _generateSampleFlutterProject(fixturesDir);
  await _generateFailingTestsProject(fixturesDir);
  await _generatePerfectCoverageProject(fixturesDir);

  print('\n✅ All fixture projects generated successfully!');
  print('   Location: ${fixturesDir.path}');
}

Future<void> _generateSampleDartProject(Directory fixturesDir) async {
  print('📦 Creating sample_dart_project...');

  final projectDir = Directory(p.join(fixturesDir.path, 'sample_dart_project'));
  await projectDir.create(recursive: true);

  // pubspec.yaml
  await _writeFile(
    projectDir,
    'pubspec.yaml',
    '''
name: sample_dart_project
version: 1.0.0
description: A sample Dart project for integration testing
environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.25.0
  lints: ^3.0.0
''',
  );

  // lib/calculator.dart
  await _writeFile(
    projectDir,
    'lib/calculator.dart',
    '''
/// A simple calculator for testing
class Calculator {
  /// Adds two numbers
  int add(int a, int b) => a + b;

  /// Subtracts b from a
  int subtract(int a, int b) => a - b;

  /// Multiplies two numbers
  int multiply(int a, int b) => a * b;

  /// Divides a by b
  double divide(int a, int b) {
    if (b == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return a / b;
  }
}
''',
  );

  // test/calculator_test.dart
  await _writeFile(
    projectDir,
    'test/calculator_test.dart',
    '''
import 'package:test/test.dart';
import '../lib/calculator.dart';

void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    test('adds two numbers correctly', () {
      expect(calculator.add(2, 3), equals(5));
      expect(calculator.add(-1, 1), equals(0));
    });

    test('subtracts two numbers correctly', () {
      expect(calculator.subtract(5, 3), equals(2));
      expect(calculator.subtract(1, 1), equals(0));
    });

    test('multiplies two numbers correctly', () {
      expect(calculator.multiply(3, 4), equals(12));
      expect(calculator.multiply(-2, 3), equals(-6));
    });

    test('divides two numbers correctly', () {
      expect(calculator.divide(10, 2), equals(5.0));
      expect(calculator.divide(7, 2), equals(3.5));
    });

    test('throws error when dividing by zero', () {
      expect(() => calculator.divide(5, 0), throwsArgumentError);
    });
  });
}
''',
  );

  // analysis_options.yaml
  await _writeFile(
    projectDir,
    'analysis_options.yaml',
    'include: package:lints/recommended.yaml\n',
  );

  print('  ✓ sample_dart_project created');
}

Future<void> _generateSampleFlutterProject(Directory fixturesDir) async {
  print('📱 Creating sample_flutter_project...');

  final projectDir =
      Directory(p.join(fixturesDir.path, 'sample_flutter_project'));
  await projectDir.create(recursive: true);

  // pubspec.yaml
  await _writeFile(
    projectDir,
    'pubspec.yaml',
    '''
name: sample_flutter_project
version: 1.0.0
description: A sample Flutter project for integration testing
environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.25.0
  flutter_lints: ^3.0.0
''',
  );

  // lib/counter.dart
  await _writeFile(
    projectDir,
    'lib/counter.dart',
    '''
/// A simple counter class
class Counter {
  Counter({this.initialValue = 0}) : _value = initialValue;

  final int initialValue;
  int _value;

  /// Get the current value
  int get value => _value;

  /// Increment the counter
  void increment() {
    _value++;
  }

  /// Decrement the counter
  void decrement() {
    _value--;
  }

  /// Reset to initial value
  void reset() {
    _value = initialValue;
  }
}
''',
  );

  // lib/utils.dart
  await _writeFile(
    projectDir,
    'lib/utils.dart',
    '''
/// Utility functions for the app
class Utils {
  /// Check if a number is even
  static bool isEven(int number) => number % 2 == 0;

  /// Check if a number is odd
  static bool isOdd(int number) => number % 2 != 0;

  /// Format a number with commas
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'),
          (Match m) => '\${m[1]},',
        );
  }
}
''',
  );

  // test/counter_test.dart
  await _writeFile(
    projectDir,
    'test/counter_test.dart',
    '''
import 'package:test/test.dart';
import '../lib/counter.dart';

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
''',
  );

  // test/utils_test.dart
  await _writeFile(
    projectDir,
    'test/utils_test.dart',
    '''
import 'package:test/test.dart';
import '../lib/utils.dart';

void main() {
  group('Utils', () {
    group('isEven', () {
      test('returns true for even numbers', () {
        expect(Utils.isEven(2), isTrue);
        expect(Utils.isEven(0), isTrue);
        expect(Utils.isEven(-4), isTrue);
      });

      test('returns false for odd numbers', () {
        expect(Utils.isEven(1), isFalse);
        expect(Utils.isEven(3), isFalse);
        expect(Utils.isEven(-5), isFalse);
      });
    });

    group('isOdd', () {
      test('returns true for odd numbers', () {
        expect(Utils.isOdd(1), isTrue);
        expect(Utils.isOdd(3), isTrue);
        expect(Utils.isOdd(-7), isTrue);
      });

      test('returns false for even numbers', () {
        expect(Utils.isOdd(2), isFalse);
        expect(Utils.isOdd(0), isFalse);
      });
    });

    group('formatNumber', () {
      test('formats large numbers with commas', () {
        expect(Utils.formatNumber(1000), equals('1,000'));
        expect(Utils.formatNumber(1000000), equals('1,000,000'));
      });

      test('does not format small numbers', () {
        expect(Utils.formatNumber(100), equals('100'));
        expect(Utils.formatNumber(10), equals('10'));
      });
    });
  });
}
''',
  );

  // analysis_options.yaml
  await _writeFile(
    projectDir,
    'analysis_options.yaml',
    'include: package:flutter_lints/flutter.yaml\n',
  );

  print('  ✓ sample_flutter_project created');
}

Future<void> _generateFailingTestsProject(Directory fixturesDir) async {
  print('❌ Creating failing_tests_project...');

  final projectDir =
      Directory(p.join(fixturesDir.path, 'failing_tests_project'));
  await projectDir.create(recursive: true);

  // pubspec.yaml
  await _writeFile(
    projectDir,
    'pubspec.yaml',
    '''
name: failing_tests_project
version: 1.0.0
description: A project with intentionally failing tests
environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.25.0
''',
  );

  // lib/buggy_code.dart
  await _writeFile(
    projectDir,
    'lib/buggy_code.dart',
    '''
/// Code with intentional bugs for testing
class BuggyCode {
  /// This has a bug - always returns wrong result
  int addBuggy(int a, int b) => a + b + 1; // Off by one

  /// This throws an unexpected error
  String greet(String? name) {
    return 'Hello, \$name!'; // Will fail if name is null
  }

  /// This has inconsistent behavior
  int randomResult(int input) {
    // Simulates flaky behavior
    return DateTime.now().millisecond > 500 ? input : -input;
  }
}
''',
  );

  // test/failing_test.dart
  await _writeFile(
    projectDir,
    'test/failing_test.dart',
    '''
import 'package:test/test.dart';
import '../lib/buggy_code.dart';

void main() {
  group('BuggyCode', () {
    late BuggyCode buggy;

    setUp(() {
      buggy = BuggyCode();
    });

    test('addition should work correctly (FAILS)', () {
      // This will fail due to the bug
      expect(buggy.addBuggy(2, 3), equals(5));
    });

    test('greeting should handle null (FAILS)', () {
      // This will fail with null error
      expect(buggy.greet(null), equals('Hello, null!'));
    });

    test('randomResult is flaky (FLAKY)', () {
      // This test is flaky and may pass or fail randomly
      expect(buggy.randomResult(10), equals(10));
    });

    test('this test passes', () {
      // At least one test should pass
      expect(true, isTrue);
    });
  });
}
''',
  );

  print('  ✓ failing_tests_project created');
}

Future<void> _generatePerfectCoverageProject(Directory fixturesDir) async {
  print('💯 Creating perfect_coverage_project...');

  final projectDir =
      Directory(p.join(fixturesDir.path, 'perfect_coverage_project'));
  await projectDir.create(recursive: true);

  // pubspec.yaml
  await _writeFile(
    projectDir,
    'pubspec.yaml',
    '''
name: perfect_coverage_project
version: 1.0.0
description: A project with 100% test coverage
environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  test: ^1.25.0
''',
  );

  // lib/perfect.dart
  await _writeFile(
    projectDir,
    'lib/perfect.dart',
    '''
/// A simple class with complete test coverage
class Perfect {
  /// Check if a number is positive
  bool isPositive(int number) => number > 0;

  /// Check if a number is negative
  bool isNegative(int number) => number < 0;

  /// Get absolute value
  int abs(int number) => number < 0 ? -number : number;
}
''',
  );

  // test/perfect_test.dart
  await _writeFile(
    projectDir,
    'test/perfect_test.dart',
    '''
import 'package:test/test.dart';
import '../lib/perfect.dart';

void main() {
  group('Perfect', () {
    late Perfect perfect;

    setUp(() {
      perfect = Perfect();
    });

    test('isPositive returns true for positive numbers', () {
      expect(perfect.isPositive(1), isTrue);
      expect(perfect.isPositive(100), isTrue);
    });

    test('isPositive returns false for negative numbers', () {
      expect(perfect.isPositive(-1), isFalse);
      expect(perfect.isPositive(0), isFalse);
    });

    test('isNegative returns true for negative numbers', () {
      expect(perfect.isNegative(-1), isTrue);
      expect(perfect.isNegative(-100), isTrue);
    });

    test('isNegative returns false for positive numbers', () {
      expect(perfect.isNegative(1), isFalse);
      expect(perfect.isNegative(0), isFalse);
    });

    test('abs returns absolute value', () {
      expect(perfect.abs(5), equals(5));
      expect(perfect.abs(-5), equals(5));
      expect(perfect.abs(0), equals(0));
    });
  });
}
''',
  );

  print('  ✓ perfect_coverage_project created');
}

Future<void> _writeFile(
    Directory projectDir, String path, String content) async {
  final file = File(p.join(projectDir.path, path));
  await file.parent.create(recursive: true);
  await file.writeAsString(content);
}
