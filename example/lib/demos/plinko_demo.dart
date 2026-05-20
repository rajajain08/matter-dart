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
const int _ballCount = 50;

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
          restitution: 0.85,
          friction: 0.0,
        ),
        maxSides: 24,
      ));
    }
  }

  // Cluster balls in a tight grid above the pegs. Single-column stacking
  // can't fit 50 balls in the available headroom, so we fan out into a
  // multi-column block centred on the playfield. A small jitter on each
  // slot prevents perfectly symmetric initial conditions (which would
  // collapse into a deterministic spine through the peg grid).
  final double stackTop = WorldDimensions.innerTop + 16;
  final double bottomLimit = topY - _pegRadius - _ballRadius * 2;
  final double pitch = _ballRadius * 2 + 1; // gap so balls don't spawn touching.
  final double clusterWidth = WorldDimensions.innerWidth * 0.6;
  final int cols = math.max(1, (clusterWidth / pitch).floor());
  final double clusterLeft = WorldDimensions.width / 2 - (cols - 1) * pitch / 2;
  for (int i = 0; i < _ballCount; i++) {
    final int row = i ~/ cols;
    final int col = i % cols;
    final double y = stackTop + row * pitch;
    if (y > bottomLimit) break;
    final double jitterX = (rng.nextDouble() - 0.5) * (pitch * 0.4);
    final double jitterY = (rng.nextDouble() - 0.5) * (pitch * 0.2);
    bodies.add(Bodies.circle(
      clusterLeft + col * pitch + jitterX,
      y + jitterY,
      _ballRadius,
      BodyOptions(
        restitution: 0.75,
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
