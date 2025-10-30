import 'package:test_reporter/test_analyzer.dart';

void main() {
  // Example usage of formatting utilities
  final timestamp = DateTime.now();
  print('Formatted timestamp: ${FormattingUtils.formatTimestamp(timestamp)}');

  // Example duration formatting
  const duration = Duration(minutes: 2, seconds: 30);
  print('Formatted duration: ${FormattingUtils.formatDuration(duration)}');

  // Example percentage formatting
  const coverage = 85.67;
  print('Formatted percentage: ${FormattingUtils.formatPercentage(coverage)}');

  // Example path extraction
  const path = 'test/ui/widgets/onboarding';
  print('Path name: ${PathUtils.extractPathName(path)}');
}
