/// Custom matchers and assertions for integration tests
///
/// Provides domain-specific matchers for validating binary execution,
/// report generation, and file system operations.

// ignore_for_file: strict_raw_type

import 'dart:io';
import 'package:test/test.dart';
import 'real_execution_helper.dart';

/// Matcher for checking exit codes
Matcher exitedWithCode(int expectedCode) => _ExitCodeMatcher(expectedCode);

class _ExitCodeMatcher extends Matcher {
  _ExitCodeMatcher(this.expectedCode);

  final int expectedCode;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ExecutionResult) {
      return item.exitCode == expectedCode;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('exits with code $expectedCode');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is ExecutionResult) {
      return mismatchDescription.add('exited with code ${item.exitCode}');
    }
    return mismatchDescription.add('is not an ExecutionResult');
  }
}

/// Matcher for successful execution (exit code 0)
const Matcher succeeds = _SuccessMatcher();

class _SuccessMatcher extends Matcher {
  const _SuccessMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ExecutionResult) {
      return item.exitCode == 0;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('succeeds (exit code 0)');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is ExecutionResult) {
      return mismatchDescription.add('failed with exit code ${item.exitCode}');
    }
    return mismatchDescription.add('is not an ExecutionResult');
  }
}

/// Matcher for failed execution (non-zero exit code)
const Matcher fails = _FailureMatcher();

class _FailureMatcher extends Matcher {
  const _FailureMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ExecutionResult) {
      return item.exitCode != 0;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('fails (non-zero exit code)');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is ExecutionResult) {
      return mismatchDescription
          .add('succeeded with exit code ${item.exitCode}');
    }
    return mismatchDescription.add('is not an ExecutionResult');
  }
}

/// Matcher for checking if output contains a pattern
Matcher outputContains(Pattern pattern) => _OutputContainsMatcher(pattern);

class _OutputContainsMatcher extends Matcher {
  _OutputContainsMatcher(this.pattern);

  final Pattern pattern;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ExecutionResult) {
      final output = item.stdout + item.stderr;
      return output.contains(pattern);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('output contains "$pattern"');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is ExecutionResult) {
      return mismatchDescription.add('output does not contain "$pattern"');
    }
    return mismatchDescription.add('is not an ExecutionResult');
  }
}

/// Matcher for checking if a report file was generated
Matcher hasReportFile(String pattern) => _ReportFileMatcher(pattern);

class _ReportFileMatcher extends Matcher {
  _ReportFileMatcher(this.pattern);

  final String pattern;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Directory) {
      final files = item.listSync(recursive: true);
      return files.any((f) => f.path.contains(pattern));
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has report file matching "$pattern"');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Directory) {
      return mismatchDescription
          .add('does not have report file matching "$pattern"');
    }
    return mismatchDescription.add('is not a Directory');
  }
}

/// Matcher for valid markdown content
const Matcher hasValidMarkdown = _ValidMarkdownMatcher();

class _ValidMarkdownMatcher extends Matcher {
  const _ValidMarkdownMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is String) {
      // Basic markdown validation
      return item.contains('#') || // Headers
          item.contains('*') || // Lists or emphasis
          item.contains('-') || // Lists
          item.contains('|'); // Tables
    } else if (item is File) {
      final content = item.readAsStringSync();
      return content.contains('#') ||
          content.contains('*') ||
          content.contains('-') ||
          content.contains('|');
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has valid markdown content');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) =>
      mismatchDescription.add('does not have valid markdown syntax');
}

/// Matcher for embedded JSON in reports
const Matcher hasEmbeddedJson = _EmbeddedJsonMatcher();

class _EmbeddedJsonMatcher extends Matcher {
  const _EmbeddedJsonMatcher();

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is String) {
      return item.contains('```json') && item.contains('```');
    } else if (item is File) {
      final content = item.readAsStringSync();
      return content.contains('```json') && content.contains('```');
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has embedded JSON section');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) =>
      mismatchDescription.add('does not have embedded JSON section');
}

/// Matcher for execution duration
Matcher completesWithin(Duration duration) => _DurationMatcher(duration);

class _DurationMatcher extends Matcher {
  _DurationMatcher(this.maxDuration);

  final Duration maxDuration;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is ExecutionResult) {
      return item.duration <= maxDuration;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('completes within ${maxDuration.inSeconds}s');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is ExecutionResult) {
      return mismatchDescription.add('took ${item.duration.inSeconds}s');
    }
    return mismatchDescription.add('is not an ExecutionResult');
  }
}

/// Matcher for file count in directory
Matcher hasFileCount(int count) => _FileCountMatcher(count);

class _FileCountMatcher extends Matcher {
  _FileCountMatcher(this.expectedCount);

  final int expectedCount;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is Directory) {
      final files = item.listSync(recursive: true).whereType<File>().toList();
      matchState['actualCount'] = files.length;
      return files.length == expectedCount;
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has $expectedCount files');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is Directory) {
      final actualCount = matchState['actualCount'] ?? 0;
      return mismatchDescription.add('has $actualCount files');
    }
    return mismatchDescription.add('is not a Directory');
  }
}

/// Matcher for checking file extension
Matcher hasExtension(String extension) => _ExtensionMatcher(extension);

class _ExtensionMatcher extends Matcher {
  _ExtensionMatcher(this.extension);

  final String extension;

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is File) {
      return item.path.endsWith(extension);
    } else if (item is String) {
      return item.endsWith(extension);
    }
    return false;
  }

  @override
  Description describe(Description description) =>
      description.add('has extension "$extension"');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) =>
      mismatchDescription.add('does not have extension "$extension"');
}
