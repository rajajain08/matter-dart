import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/geometry/vector.dart';

class Collision {
  final bool collided;
  final int axisNumber;
  final Body axisBody;
  final Body bodyA;
  final Body bodyB;
  final Body parentA;
  final Body parentB;
  final int depth;
  final Vector normal;
  final Vector tangent;
  final Vector penetration;
  final List<Vector> supports;
  final bool reused;

  Collision(this.collided, this.axisNumber, this.axisBody, this.bodyA, this.bodyB, this.parentA, this.parentB,
      this.depth, this.normal, this.tangent, this.penetration, this.supports, this.reused);
}
