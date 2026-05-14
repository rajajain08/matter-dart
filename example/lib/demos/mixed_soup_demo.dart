import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo mixedSoupDemo = Demo(
  name: 'Mixed Soup',
  description: 'Every shape together — count scales on wide layouts',
  icon: Icons.bubble_chart_rounded,
  accent: const Color(0xFF06B6D4),
  build: _build,
);

void _build(Composite world, math.Random rng) {
  final int count = WorldDimensions.scaledBodyCount(40, max: 90);
  final bodies = <Body>[];
  for (int i = 0; i < count; i++) {
    final double x = WorldDimensions.innerLeft + 20 +
        rng.nextDouble() * (WorldDimensions.innerWidth - 40);
    final double y = WorldDimensions.innerTop + 20 +
        rng.nextDouble() * (WorldDimensions.innerHeight - 100);
    final double s = 12.0 + rng.nextDouble() * 18;

    final opts = BodyOptions(
      restitution: 0.4 + rng.nextDouble() * 0.3,
      friction: 0.1,
      frictionAir: 0.005,
      density: 0.0015,
    );

    final pick = rng.nextInt(4);
    final Body body;
    switch (pick) {
      case 0:
        body = Bodies.circle(x, y, s, opts);
        break;
      case 1:
        body = Bodies.rectangle(x, y, s * 1.6, s, opts);
        break;
      case 2:
        body = Bodies.polygon(x, y, 3 + rng.nextInt(5), s, opts);
        break;
      default:
        body = Bodies.trapezoid(x, y, s * 1.6, s, 0.3 + rng.nextDouble() * 0.3, opts);
        break;
    }
    body.setAngularVelocity((rng.nextDouble() - 0.5) * 0.6);
    body.setVelocity(Vector((rng.nextDouble() - 0.5) * 4, rng.nextDouble() * 2));
    bodies.add(body);
  }
  world.add(bodies.cast<MatterObject>());
}
