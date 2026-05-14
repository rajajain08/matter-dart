import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo ballPitDemo = Demo(
  name: 'Ball Pit',
  description: 'Bouncy circles (fills the playfield on wide layouts)',
  icon: Icons.circle_rounded,
  accent: const Color(0xFFEC4899),
  build: _build,
);

const double _minR = 6;
const double _maxR = 12;

void _build(Composite world, math.Random rng) {
  final int count = WorldDimensions.scaledBodyCount(120, max: 220);
  final bodies = <Body>[];
  for (int i = 0; i < count; i++) {
    final double r = _minR + rng.nextDouble() * (_maxR - _minR);
    final double x = WorldDimensions.innerLeft + r +
        rng.nextDouble() * (WorldDimensions.innerWidth - 2 * r);
    final double y = WorldDimensions.innerTop + r +
        rng.nextDouble() * (WorldDimensions.innerHeight - 2 * r);
    bodies.add(Bodies.circle(
      x,
      y,
      r,
      BodyOptions(
        restitution: 0.7,
        friction: 0.05,
        frictionAir: 0.005,
        density: 0.001,
      ),
    ));
  }
  world.add(bodies.cast<MatterObject>());
}
