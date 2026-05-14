import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo plinkoDemo = Demo(
  name: 'Plinko',
  description: 'Circles scatter through a peg grid',
  icon: Icons.grain_rounded,
  accent: const Color(0xFF10B981),
  build: _build,
);

const int _rows = 8;
const double _pegRadius = 7;
const double _ballRadius = 6;
const int _ballCount = 18;

void _build(Composite world, math.Random rng) {
  final bodies = <Body>[];

  final double spacingX = WorldDimensions.innerWidth / 8;
  final double spacingY = 50;
  final double topY = WorldDimensions.innerTop + 110;

  for (int row = 0; row < _rows; row++) {
    final bool offset = row.isOdd;
    final int pegsInRow = offset ? 7 : 8;
    final double rowStart = WorldDimensions.innerLeft +
        spacingX * (offset ? 1.0 : 0.5);
    final double y = topY + row * spacingY;
    for (int i = 0; i < pegsInRow; i++) {
      final double x = rowStart + i * spacingX;
      bodies.add(Bodies.circle(
        x,
        y,
        _pegRadius,
        BodyOptions(
          isStatic: true,
          restitution: 0.6,
          friction: 0.0,
        ),
        maxSides: 24,
      ));
    }
  }

  // Stack balls vertically above the pegs, fully inside the world so they
  // don't get pinned against the ceiling.
  final double stackTop = WorldDimensions.innerTop + 16;
  for (int i = 0; i < _ballCount; i++) {
    final double x = WorldDimensions.width / 2 +
        (rng.nextDouble() - 0.5) * (spacingX * 0.5);
    final double y = stackTop + i * (_ballRadius * 2 + 2);
    if (y > topY - _pegRadius - _ballRadius) break;
    bodies.add(Bodies.circle(
      x,
      y,
      _ballRadius,
      BodyOptions(
        restitution: 0.55,
        friction: 0.0,
        frictionAir: 0.005,
        density: 0.002,
        slop: 0.02,
      ),
      maxSides: 24,
    ));
  }

  world.add(bodies.cast<MatterObject>());
}
