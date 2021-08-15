class Common {
  static clamp(double value, min, max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// -1 if negative, +1 if 0 or positive
  static int sign(num value) {
    return value < 0 ? -1 : 1;
  }
}
