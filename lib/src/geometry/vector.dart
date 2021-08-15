import 'dart:math' as math;

/// Vectors are the basis of all the geometry related operations in the engine.
///
/// It is the object of the form `[x, y]`.
class Vector {
  double x;
  double y;

  Vector(this.x, this.y);

  double magnitude() {
    return math.sqrt((x * x) + (y * y));
  }

  double magnitudeSquared() {
    return (x * x) + (y * y);
  }

  Vector rotateVactor(num angle) {
    double cos = math.cos(angle);
    double sin = math.sin(angle);
    return Vector(x * cos - y * sin, x * sin + y * cos);
  }

  Vector rotateAbout(num angle, Vector point) {
    double cos = math.cos(angle);
    double sin = math.sin(angle);

    return Vector(
        point.x + ((x - point.x) * cos - (y - point.y) * sin), point.y + ((x - point.x) * sin + (y - point.y) * cos));
  }

  Vector normalise() {
    double mag = magnitude();
    if (mag == 0) return Vector(0, 0);
    return Vector(x / mag, y / mag);
  }

  static double dot(Vector a, Vector b) {
    return a.x * b.x + a.y * b.y;
  }

  static double cross(Vector a, Vector b) {
    return a.x * b.y - a.y * b.x;
  }

  static double cross3(Vector a, Vector b, Vector c) {
    return ((b.x - a.x) * (c.y - a.y)) - ((b.y - a.y) * (c.x - a.x));
  }

  static Vector add(Vector a, Vector b) {
    return Vector(a.x + b.x, a.y + b.y);
  }

  static Vector sub(Vector a, Vector b) {
    return Vector(a.x - b.x, a.y - b.y);
  }

  static Vector mult(Vector a, double scaler) {
    return Vector(a.x * scaler, a.y * scaler);
  }

  static Vector div(Vector a, double scaler) {
    return Vector(a.x / scaler, a.y / scaler);
  }

  static Vector perp(Vector a, [bool negate = false]) {
    double neg = negate == true ? -1 : 1;
    return Vector(neg * -a.y, neg * a.x);
  }

  static Vector neg(Vector a) {
    return Vector(-a.x, -a.y);
  }

  static double angle(Vector a, Vector b) {
    return math.atan2(b.y - a.y, b.x - a.x);
  }
}
