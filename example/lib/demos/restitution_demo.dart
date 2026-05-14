import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo restitutionDemo = Demo(
  name: 'Restitution',
  description: 'Bounce coefficient ramps from 0 → 1',
  icon: Icons.sports_volleyball_rounded,
  accent: const Color(0xFFEF4444),
  build: _build,
);

void _build(Composite world, math.Random rng) {
  const int n = 6;
  const double size = 36;
  const double y = 80;
  final double spacing = WorldDimensions.innerWidth / n;
  final bodies = <Body>[];

  for (int i = 0; i < n; i++) {
    final double restitution = i / (n - 1);
    final double x = WorldDimensions.innerLeft + spacing * (i + 0.5);
    bodies.add(Bodies.rectangle(
      x,
      y,
      size,
      size,
      BodyOptions(restitution: restitution, frictionAir: 0.005, friction: 0.05),
    ));
  }
  world.add(bodies.cast<MatterObject>());
}
