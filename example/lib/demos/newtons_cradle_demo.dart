import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo newtonsCradleDemo = Demo(
  name: "Newton's Cradle",
  description: 'Hanging circles trade momentum',
  icon: Icons.swap_horiz_rounded,
  accent: const Color(0xFFEAB308),
  build: _build,
  constraintIterations: 8,
  positionIterations: 20,
  velocityIterations: 16,
);

const int _balls = 5;
const double _radius = 18;
const double _stringLen = 200;

void _build(Composite world, math.Random rng) {
  final double anchorY = WorldDimensions.wallThickness + 20;
  final double spacing = _radius * 2 + 0.5;
  final double startX = WorldDimensions.width / 2 - (_balls - 1) * spacing / 2;
  final double restY = anchorY + _stringLen;

  final List<Body> bodies = [];
  final List<Constraint> joints = [];

  // Maximum horizontal offset that keeps the lifted ball inside the left
  // wall while keeping the string taut.
  final double leftmostAnchorX = startX;
  final double maxOffset =
      leftmostAnchorX - WorldDimensions.innerLeft - _radius - 4;
  final double liftOffset = math.min(_stringLen - 1, maxOffset);
  final double liftSag =
      math.sqrt(_stringLen * _stringLen - liftOffset * liftOffset);

  for (int i = 0; i < _balls; i++) {
    final double x = startX + i * spacing;
    // Pull the leftmost ball aside along a taut string to start the swing.
    final double bx = (i == 0) ? x - liftOffset : x;
    final double by = (i == 0) ? anchorY + liftSag : restY;

    final ball = Bodies.circle(
      bx,
      by,
      _radius,
      BodyOptions(
        restitution: 1.0,
        friction: 0.0,
        frictionAir: 0.0,
        slop: 0.01,
        density: 0.02,
      ),
      maxSides: 64,
    );
    bodies.add(ball);

    joints.add(Constraint(
      pointA: Vector(x, anchorY),
      bodyB: ball,
      pointB: Vector(0, 0),
      stiffness: 1.0,
      damping: 0.02,
      length: _stringLen,
    ));
  }

  world.add(bodies.cast<MatterObject>());
  world.add(joints.cast<MatterObject>());
}
