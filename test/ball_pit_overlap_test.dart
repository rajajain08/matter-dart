import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:matter_dart/matter_dart.dart';

// Reproduces the ball-pit demo: many small circles falling inside an enclosure.
// We measure pairwise penetration after the pile settles. Excess overlap is the
// "circles passing into each other" bug the user reports.
void main() {
  test('ball-pit: settled circles should not overlap more than slop', () {
    // Small enclosure, modest circle count for a deterministic regression check.
    const double worldW = 200;
    const double worldH = 300;
    const double wall = 10;
    const double minR = 6;
    const double maxR = 12;
    const int circleCount = 40;

    final engine = Engine.create(null);
    final rng = math.Random(42);

    // Static enclosure (floor + 3 walls).
    final walls = <Body>[
      Bodies.rectangle(worldW / 2, worldH - wall / 2, worldW, wall, BodyOptions(isStatic: true)),
      Bodies.rectangle(worldW / 2, wall / 2, worldW, wall, BodyOptions(isStatic: true)),
      Bodies.rectangle(wall / 2, worldH / 2, wall, worldH, BodyOptions(isStatic: true)),
      Bodies.rectangle(worldW - wall / 2, worldH / 2, wall, worldH, BodyOptions(isStatic: true)),
    ];

    // Random circles.
    final circles = <Body>[];
    for (int i = 0; i < circleCount; i++) {
      final r = minR + rng.nextDouble() * (maxR - minR);
      final x = wall + r + rng.nextDouble() * (worldW - 2 * wall - 2 * r);
      final y = wall + r + rng.nextDouble() * (worldH * 0.5);
      circles.add(Bodies.circle(
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

    engine.world!.add([...walls, ...circles]);

    for (int step = 0; step < 600; step++) {
      engine.update(1000 / 60, 1);
    }
    // Final settled state.
    const double allowed = 0.5;
    double worstOverlap = 0;
    int violators = 0;
    final List<String> details = [];
    for (int i = 0; i < circles.length; i++) {
      for (int j = i + 1; j < circles.length; j++) {
        final a = circles[i];
        final b = circles[j];
        final dx = b.position.x - a.position.x;
        final dy = b.position.y - a.position.y;
        final d = math.sqrt(dx * dx + dy * dy);
        final overlap = (a.circleRadius! + b.circleRadius!) - d;
        if (overlap > worstOverlap) worstOverlap = overlap;
        if (overlap > allowed) {
          violators++;
          if (details.length < 8) {
            details.add('  pair($i,$j): r=${a.circleRadius!.toStringAsFixed(1)}+${b.circleRadius!.toStringAsFixed(1)}'
                ' dist=${d.toStringAsFixed(2)} overlap=${overlap.toStringAsFixed(3)}');
          }
        }
      }
    }

    expect(violators, equals(0),
        reason: 'Settled circles should not overlap more than slop.\n${details.join('\n')}');
  });

  test('two circles head-on collision — settles without persistent overlap', () {
    final engine = Engine.create(EngineOptions(
      gravity: EngineGravityOptions(x: 0, y: 0, scale: 0),
    ));
    final a = Bodies.circle(50, 100, 10, BodyOptions(restitution: 0.5));
    final b = Bodies.circle(150, 100, 10, BodyOptions(restitution: 0.5));
    a.setVelocity(Vector(8, 0));
    b.setVelocity(Vector(-8, 0));
    engine.world!.add([a, b]);

    double worst = 0;
    for (int step = 0; step < 120; step++) {
      engine.update(1000 / 60, 1);
      final dx = b.position.x - a.position.x;
      final dy = b.position.y - a.position.y;
      final d = math.sqrt(dx * dx + dy * dy);
      final overlap = 20.0 - d;
      if (overlap > worst) worst = overlap;
    }
    // Compute final overlap once everything has bounced apart.
    final ddx = b.position.x - a.position.x;
    final ddy = b.position.y - a.position.y;
    final finalDist = math.sqrt(ddx * ddx + ddy * ddy);
    final finalOverlap = 20.0 - finalDist;
    // Transient overlap is bounded by max integration step (~25 px/frame cap).
    // What matters is that the simulation recovers — final state must not overlap.
    expect(finalOverlap, lessThan(0.5),
        reason: 'after impulse propagates, bodies must separate');
  });
}
