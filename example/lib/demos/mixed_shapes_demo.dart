import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo mixedShapesDemo = Demo(
  name: 'Mixed Shapes',
  description: 'Pyramid stack with falling projectiles',
  icon: Icons.category_rounded,
  accent: const Color(0xFFF59E0B),
  build: _build,
);

void _build(Composite world, math.Random rng) {
  const int rows = 6;
  const double cellW = 40;
  const double cellH = 40;
  final double baseY = WorldDimensions.innerBottom - cellH / 2;
  final bodies = <Body>[];

  for (int row = 0; row < rows; row++) {
    final int count = rows - row;
    final double y = baseY - row * cellH;
    final double startX = WorldDimensions.width / 2 - (count - 1) * cellW / 2;
    for (int col = 0; col < count; col++) {
      final double x = startX + col * cellW;
      final bool useTrap = (row + col) % 3 == 0;
      if (useTrap) {
        bodies.add(Bodies.trapezoid(x, y, cellW, cellH, 0.3, BodyOptions(frictionAir: 0.02)));
      } else {
        bodies.add(Bodies.rectangle(x, y, cellW - 2, cellH - 2, BodyOptions(frictionAir: 0.02)));
      }
    }
  }

  for (int i = 0; i < 4; i++) {
    final double size = 20.0 + rng.nextDouble() * 25;
    final double x = WorldDimensions.innerLeft + rng.nextDouble() * WorldDimensions.innerWidth;
    final Body b = Bodies.rectangle(x, 60, size, size, BodyOptions(frictionAir: 0.02));
    b.setAngularVelocity((rng.nextDouble() - 0.5) * 1.2);
    b.setVelocity(Vector((rng.nextDouble() - 0.5) * 16, 8));
    bodies.add(b);
  }

  world.add(bodies.cast<MatterObject>());
}
