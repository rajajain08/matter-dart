class Common {
  static clamp(double value, min, max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
