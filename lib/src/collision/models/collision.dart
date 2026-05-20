import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/geometry/vector.dart';

class Collision {
  bool collided;
  int? axisNumber;
  Body? axisBody;
  Body bodyA;
  Body bodyB;
  Body? parentA;
  Body? parentB;
  double? depth;
  Vector? normal;
  Vector? tangent;
  Vector? penetration;
  List<Vector> supports;
  bool reused;

  Collision({
    this.collided = false,
    this.axisNumber,
    this.axisBody,
    required this.bodyA,
    required this.bodyB,
    this.parentA,
    this.parentB,
    this.depth,
    this.normal,
    this.tangent,
    this.penetration,
    this.supports = const <Vector>[],
    this.reused = false,
  });
}

class CollisionFilter {
  int group;
  int mask;
  int category;

  CollisionFilter({
    required this.group,
    required this.mask,
    required this.category,
  });
}
