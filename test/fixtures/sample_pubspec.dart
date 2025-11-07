/// Pubspec.yaml generator for testing
///
/// Generates realistic pubspec.yaml files for integration tests.

/// Generator for pubspec.yaml files
class SamplePubspec {
  /// Generate basic Dart package pubspec
  static String generateDartPackage({
    required String name,
    required String version,
    String? sdkVersion,
    String? description,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('name: $name');
    if (description != null) {
      buffer.writeln('description: $description');
    }
    buffer.writeln('version: $version');
    buffer.writeln();
    buffer.writeln('environment:');
    buffer.writeln('  sdk: "${sdkVersion ?? '>=3.0.0 <4.0.0'}"');
    buffer.writeln();
    buffer.writeln('dependencies:');
    buffer.writeln();
    buffer.writeln('dev_dependencies:');
    buffer.writeln('  test: ^1.24.0');

    return buffer.toString();
  }

  /// Generate Flutter package pubspec
  static String generateFlutterPackage({
    required String name,
    required String version,
    String? flutterVersion,
    String? description,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('name: $name');
    if (description != null) {
      buffer.writeln('description: $description');
    }
    buffer.writeln('version: $version');
    buffer.writeln();
    buffer.writeln('environment:');
    buffer.writeln('  sdk: "${flutterVersion ?? '>=3.0.0 <4.0.0'}"');
    buffer.writeln();
    buffer.writeln('dependencies:');
    buffer.writeln('  flutter:');
    buffer.writeln('    sdk: flutter');
    buffer.writeln();
    buffer.writeln('dev_dependencies:');
    buffer.writeln('  flutter_test:');
    buffer.writeln('    sdk: flutter');
    buffer.writeln('  test: ^1.24.0');
    buffer.writeln();
    buffer.writeln('flutter:');

    return buffer.toString();
  }

  /// Generate pubspec with custom dependencies
  static String generateWithDependencies({
    required String name,
    String? version,
    Map<String, String>? dependencies,
    Map<String, String>? devDependencies,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('name: $name');
    buffer.writeln('version: ${version ?? '1.0.0'}');
    buffer.writeln();
    buffer.writeln('environment:');
    buffer.writeln('  sdk: ">=3.0.0 <4.0.0"');
    buffer.writeln();

    if (dependencies != null && dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (final entry in dependencies.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln();
    }

    if (devDependencies != null && devDependencies.isNotEmpty) {
      buffer.writeln('dev_dependencies:');
      for (final entry in devDependencies.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
    }

    return buffer.toString();
  }

  /// Parse pubspec content (simple key-value extraction)
  static Map<String, dynamic> parse(String pubspecContent) {
    final result = <String, dynamic>{};

    for (final line in pubspecContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Simple key: value parsing (doesn't handle nested YAML)
      if (trimmed.contains(':') && !trimmed.startsWith(' ')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          if (value.isNotEmpty) {
            result[key] = value;
          }
        }
      }
    }

    return result;
  }
}
