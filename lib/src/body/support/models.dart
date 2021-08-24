import 'dart:ui';

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/composite.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/constraint/constraint.dart';
import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// Options for [Body] model.
class BodyOptions {
  List<Body>? parts;
  double? angle;
  List<Vertex>? vertices;
  Vector? position;
  Vector? force;
  double? torque;
  Vector? positionImpulse;
  BodyConstraintImpulse? constraintImpulse;
  int? totalContacts;
  double? speed;
  double? angularSpeed;
  Vector? velocity;
  double? angularVelocity;
  bool? isSensor;
  bool? isStatic;
  bool? isSleeping;
  double? motion;
  int? sleepThreshold;
  double? density;
  double? restitution;
  double? friction;
  double? frictionStatic;
  double? frictionAir;
  CollisionFilter? collisionFilter;
  double? slop;
  double? timescale;
  BodyRenderOptions? render;
  Bounds? bounds;
  ChamferOptions? chamfer;
  double? circleRadius;
  Vector? positionPrev;
  double? anglePrev;
  Body? parent;
  List<Vector>? axes;
  double? area;
  double? mass;
  double? inverseMass;
  double? inertia;
  double? inverseInertia;
  int? sleepCounter;
  Region? region;
  Vector? centre;

  BodyOptions({
    this.parts,
    this.angle,
    this.vertices,
    this.position,
    this.force,
    this.torque,
    this.positionImpulse,
    this.constraintImpulse,
    this.totalContacts,
    this.speed,
    this.angularSpeed,
    this.velocity,
    this.angularVelocity,
    this.isSensor,
    this.isStatic,
    this.isSleeping,
    this.motion,
    this.sleepThreshold,
    this.density,
    this.restitution,
    this.friction,
    this.frictionStatic,
    this.frictionAir,
    this.collisionFilter,
    this.slop,
    this.timescale,
    this.render,
    this.bounds,
    this.chamfer,
    this.circleRadius,
    this.positionPrev,
    this.anglePrev,
    this.parent,
    this.axes,
    this.area,
    this.mass,
    this.inverseMass,
    this.inertia,
    this.inverseInertia,
    this.sleepCounter,
    this.region,
    this.centre,
  });
}

/// Creates a region for the body.
class Region {
  late final String id;
  final int startCol;
  final int endCol;
  final int startRow;
  final int endRow;

  Region({
    required this.startCol,
    required this.endCol,
    required this.startRow,
    required this.endRow,
  }) {
    id = '$startCol,$endCol,$startRow,$endRow';
  }
}

/// Defines constraint impulse for body.
class BodyConstraintImpulse extends Vector {
  double angle;
  BodyConstraintImpulse({double x = 0, double y = 0, this.angle = 0}) : super(x, y);
}

/// Defines body rendering properties.
class BodyRenderOptions {
  bool visible = true;
  double opacity = 1.0;
  Color? fillStyle;
  Color? strokeStyle;
  double? lineWidth;
  BodyRenderOptionsSprite sprite = BodyRenderOptionsSprite();
}

class BodyRenderOptionsSprite {
  String? texture;
  double xScale = 1;
  double yScale = 1;
  double xOffset = 0;
  double yOffset = 0;
}

class ChamferOptions {
  List<double>? radius;
  double? quality;
  double? qualityMin;
  double? qualityMax;
}

class CompositeOptions {
  int? id;
  String? label;
  Composite? parent;
  bool? isModified;
  List<Body>? bodies;
  List<Composite>? composites;
  List<Constraint>? constraints;

  CompositeOptions({
    this.id,
    this.label,
    this.parent,
    this.isModified,
    this.bodies,
    this.composites,
    this.constraints,
  });
}
