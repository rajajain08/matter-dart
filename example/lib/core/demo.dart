import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

/// Pure function that populates a `Composite` with the demo's bodies/constraints.
typedef WorldBuilder = void Function(Composite world, math.Random rng);

/// Declarative description of a physics demo.
///
/// A `Demo` is data: it never references widgets, engines, or runners. The
/// presentation layer turns it into a live simulation via `DemoController`.
///
/// Builds read [WorldDimensions] while the controller holds an active
/// [WorldLayout] (narrow on mobile, wide on Flutter web).
class Demo {
  final String name;
  final String description;
  final WorldBuilder build;
  final EngineGravityOptions? gravity;
  final double? constraintIterations;
  final double? positionIterations;
  final double? velocityIterations;
  final bool enableSleeping;
  final IconData icon;
  final Color accent;

  const Demo({
    required this.name,
    required this.description,
    required this.build,
    required this.icon,
    required this.accent,
    this.gravity,
    this.constraintIterations,
    this.positionIterations,
    this.velocityIterations,
    this.enableSleeping = false,
  });
}
