/// Extension methods for common types
extension DurationFormatting on Duration {
  /// Format duration as human-readable string
  String toHumanReadable() {
    if (inMinutes > 0) {
      return '${inMinutes}m ${inSeconds % 60}s';
    }
    return '${inSeconds}.${(inMilliseconds % 1000).toString().padLeft(3, '0')}s';
  }
}

extension DoubleFormatting on double {
  /// Format double as percentage with decimals
  String toPercentage({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }
}

extension ListChunking<T> on List<T> {
  /// Split list into chunks of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(skip(i).take(size).toList());
    }
    return chunks;
  }
}

extension ListUtils<T> on List<T> {
  /// Get first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;
}
