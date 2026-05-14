import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo stressDemo = Demo(
  name: 'Stress',
  description: 'Many bodies — broadphase & solver load (scales on wide layouts)',
  icon: Icons.bolt_rounded,
  accent: const Color(0xFF10B981),
  build: _build,
);

void _build(Composite world, math.Random rng) {
  final int count = WorldDimensions.scaledBodyCount(120, max: 220);
  final bodies = <Body>[];
  for (int i = 0; i < count; i++) {
    final double size = 14.0 + rng.nextDouble() * 14;
    final double x = WorldDimensions.innerLeft + rng.nextDouble() * WorldDimensions.innerWidth;
    final double y = WorldDimensions.innerTop + rng.nextDouble() * (WorldDimensions.innerHeight - WorldDimensions.wallThickness);
    final Body b = Bodies.rectangle(x, y, size, size, BodyOptions(frictionAir: 0.02));
    b.setAngularVelocity((rng.nextDouble() - 0.5) * 1.0);
    bodies.add(b);
  }
  world.add(bodies.cast<MatterObject>());
}
