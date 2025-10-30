/// Utility functions for the app
class Utils {
  /// Check if a number is even
  static bool isEven(int number) => number % 2 == 0;

  /// Check if a number is odd
  static bool isOdd(int number) => number % 2 != 0;

  /// Format a number with commas
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
