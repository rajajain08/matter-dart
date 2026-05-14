import 'dart:math';

class MatterObject {
  final String type;

  MatterObject({required this.type});
}

class Common {
  static double clamp(double value, num min, num max) {
    if (value < min) return min.toDouble();
    if (value > max) return max.toDouble();
    return value;
  }

  /// -1 if negative, +1 if positive, 0 if zero
  static int sign(num value) {
    if (value < 0) return -1;
    if (value > 0) return 1;
    return 0;
  }

  /// Returns the random value from array
  static T chooseRandom<T>(List<T> array) {
    return array[Random().nextInt(array.length)];
  }
}

class ID {
  factory ID() => instance;
  ID._internal();
  static final ID instance = ID._internal();

  int _id = 0;
  int get nextID => _id++;
}
