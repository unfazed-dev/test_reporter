/// Shared formatting utilities for test analyzer tools
class FormattingUtils {
  /// Format timestamp as HHMM_DDMMYY for filenames
  static String formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}'
        '${timestamp.minute.toString().padLeft(2, '0')}_'
        '${timestamp.day.toString().padLeft(2, '0')}'
        '${timestamp.month.toString().padLeft(2, '0')}'
        '${timestamp.year.toString().substring(2)}';
  }

  /// Format duration in human-readable format
  static String formatDuration(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
  }

  /// Format percentage with specified decimals
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Truncate string to max length with ellipsis
  static String truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength - 3)}...';
  }

  /// Generate visual bar for progress/percentage display
  static String generateBar(
    double percentage,
    int width, {
    String filledChar = '█',
    String emptyChar = '░',
  }) {
    final filled = (percentage / 100 * width).round();
    final empty = width - filled;
    return filledChar * filled + emptyChar * empty;
  }
}
