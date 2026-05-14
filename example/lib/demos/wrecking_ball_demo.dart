import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/world_dimensions.dart';

final Demo wreckingBallDemo = Demo(
  name: 'Wrecking Ball',
  description: 'Heavy circle swings into a stack',
  icon: Icons.sports_baseball_rounded,
  accent: const Color(0xFFEF4444),
  build: _build,
  constraintIterations: 6,
  positionIterations: 10,
);

const double _ballRadius = 24;
const double _ropeLen = 260;
const int _stackRows = 5;
const int _stackCols = 4;
const double _brickW = 32;
const double _brickH = 22;

void _build(Composite world, math.Random rng) {
  final bodies = <Body>[];
  final joints = <Constraint>[];

  // Stack centered horizontally at the bottom.
  final double stackWidth = _stackCols * _brickW;
  final double stackLeft = (WorldDimensions.width - stackWidth) / 2;
  final double baseY = WorldDimensions.innerBottom - _brickH / 2;
  for (int row = 0; row < _stackRows; row++) {
    for (int col = 0; col < _stackCols; col++) {
      final double x = stackLeft + col * _brickW + _brickW / 2;
      final double y = baseY - row * _brickH;
      bodies.add(Bodies.rectangle(
        x,
        y,
        _brickW - 1,
        _brickH - 1,
        BodyOptions(
          friction: 0.6,
          frictionAir: 0.01,
          density: 0.0015,
        ),
      ));
    }
  }

  // Anchor centered, positioned so the resting ball lands at brick mid-height.
  final double anchorX = WorldDimensions.width / 2;
  final double brickMidY = baseY - (_stackRows / 2) * _brickH;
  final double anchorY = brickMidY - _ropeLen;

  // Lift the ball sideways as far as the wall allows so it builds momentum
  // before swinging into the centered stack. Keeps rope taut by computing the
  // matching vertical drop for the chosen horizontal offset.
  final double maxOffset = anchorX - WorldDimensions.innerLeft - _ballRadius - 6;
  final double offset = math.min(_ropeLen - 1, maxOffset);
  final double sag = math.sqrt(_ropeLen * _ropeLen - offset * offset);
  final double ballX = anchorX - offset;
  final double ballY = anchorY + sag;

  final ball = Bodies.circle(
    ballX,
    ballY,
    _ballRadius,
    BodyOptions(
      density: 0.06,
      restitution: 0.15,
      friction: 0.4,
      frictionAir: 0.002,
    ),
  );
  bodies.add(ball);

  joints.add(Constraint(
    pointA: Vector(anchorX, anchorY),
    bodyB: ball,
    pointB: Vector(0, 0),
    stiffness: 0.95,
    damping: 0.02,
    length: _ropeLen,
  ));

  world.add(bodies.cast<MatterObject>());
  world.add(joints.cast<MatterObject>());
}
