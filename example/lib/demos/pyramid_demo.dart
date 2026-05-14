import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo pyramidDemo = Demo(
  name: 'Pyramid',
  description: '10-row stack — friction & stacking demo',
  icon: Icons.change_history_rounded,
  accent: const Color(0xFF06B6D4),
  build: _build,
  positionIterations: 8,
  velocityIterations: 6,
);

void _build(Composite world, math.Random rng) {
  const int rows = 10;
  const double cellW = 30;
  const double cellH = 30;
  final double baseY = WorldDimensions.innerBottom - cellH / 2;
  final bodies = <Body>[];

  for (int row = 0; row < rows; row++) {
    final int count = rows - row;
    final double y = baseY - row * cellH;
    final double startX = WorldDimensions.width / 2 - (count - 1) * cellW / 2;
    for (int col = 0; col < count; col++) {
      final double x = startX + col * cellW;
      bodies.add(Bodies.rectangle(
        x,
        y,
        cellW,
        cellH,
        BodyOptions(
          friction: 0.8,
          frictionStatic: 1.0,
          frictionAir: 0.02,
        ),
      ));
    }
  }
  world.add(bodies.cast<MatterObject>());
}
