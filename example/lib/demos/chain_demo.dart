import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo chainDemo = Demo(
  name: 'Chain',
  description: 'Constraint-linked rigid pendulum',
  icon: Icons.link_rounded,
  accent: const Color(0xFF8B5CF6),
  build: _build,
  constraintIterations: 6,
  positionIterations: 10,
);

const int _links = 18;
const double _linkW = 14;
const double _linkH = 24;
const double _gap = 2;

void _build(Composite world, math.Random rng) {
  final double anchorX = WorldDimensions.width / 2;
  final double anchorY = WorldDimensions.wallThickness + 10;

  final int group = Body.nextGroup(true);
  final List<Body> chain = _buildLinks(anchorX, anchorY, group);
  final List<Constraint> joints = _buildJoints(chain, anchorX, anchorY);

  world.add(chain.cast<MatterObject>());
  world.add(joints.cast<MatterObject>());
}

List<Body> _buildLinks(double anchorX, double anchorY, int group) {
  final filter = CollisionFilter(group: group, category: 0x0001, mask: 0xFFFFFFFF);
  return List.generate(_links, (i) {
    final double y = anchorY + (_linkH / 2) + i * (_linkH + _gap);
    return Bodies.rectangle(
      anchorX,
      y,
      _linkW,
      _linkH,
      BodyOptions(
        frictionAir: 0.05,
        density: 0.004,
        friction: 0.5,
        collisionFilter: filter,
      ),
    );
  });
}

List<Constraint> _buildJoints(List<Body> chain, double anchorX, double anchorY) {
  final out = <Constraint>[
    Constraint(
      pointA: Vector(anchorX, anchorY),
      bodyB: chain.first,
      pointB: Vector(0, -_linkH / 2),
      stiffness: 1.0,
      damping: 0.1,
      length: 0,
    ),
  ];
  for (int i = 0; i < chain.length - 1; i++) {
    out.add(Constraint(
      bodyA: chain[i],
      pointA: Vector(0, _linkH / 2),
      bodyB: chain[i + 1],
      pointB: Vector(0, -_linkH / 2),
      stiffness: 1.0,
      damping: 0.1,
      length: _gap.toDouble(),
    ));
  }
  return out;
}
