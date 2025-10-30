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
