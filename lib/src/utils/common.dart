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

class ID {
  factory ID() => instance;
  ID._internal();
  static final ID instance = ID._internal();

  int _id = 0;
  int get nextID => _id++;
}
