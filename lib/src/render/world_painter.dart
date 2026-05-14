import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../body/body.dart';
import '../constraint/constraint.dart';
import '../geometry/vector.dart';

/// Paints a [Body] list using [WorldPainter] without wrapping [CustomPaint] yourself.
///
/// Forwards the same fields as [WorldPainter]; use [child], [size], and
/// [foregroundPainter] when you need [CustomPaint] behavior beyond the painter.
class WorldPaint extends StatelessWidget {
  const WorldPaint({
    super.key,
    required this.bodies,
    required this.worldWidth,
    required this.worldHeight,
    this.constraints = const <Constraint>[],
    this.highlightedBody,
    this.highlightColor = const Color(0xFFFFD166),
    this.defaultFillStyle = const Color(0xFF888888),
    this.defaultStrokeStyle = const Color(0xFFCCCCCC),
    this.constraintColor = const Color(0xFFFF5A3C),
    this.strokeWidth = 1.0,
    this.shouldAlwaysRepaint = true,
    this.child,
    this.size,
    this.foregroundPainter,
    this.isComplex = true,
    this.willChange = false,
  });

  final List<Body> bodies;
  final List<Constraint> constraints;
  final double worldWidth;
  final double worldHeight;
  final Body? highlightedBody;
  final Color highlightColor;
  final Color defaultFillStyle;
  final Color defaultStrokeStyle;
  final Color constraintColor;
  final double strokeWidth;
  final bool shouldAlwaysRepaint;
  final Widget? child;
  final Size? size;
  final CustomPainter? foregroundPainter;
  final bool isComplex;
  final bool willChange;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      painter: WorldPainter(
        bodies: bodies,
        worldWidth: worldWidth,
        worldHeight: worldHeight,
        constraints: constraints,
        highlightedBody: highlightedBody,
        highlightColor: highlightColor,
        defaultFillStyle: defaultFillStyle,
        defaultStrokeStyle: defaultStrokeStyle,
        constraintColor: constraintColor,
        strokeWidth: strokeWidth,
        shouldAlwaysRepaint: shouldAlwaysRepaint,
      ),
      foregroundPainter: foregroundPainter,
      isComplex: isComplex,
      willChange: willChange,
      child: child,
    );
    if (size != null) {
      return SizedBox.fromSize(size: size!, child: paint);
    }
    return paint;
  }
}

/// Opt-in debug renderer that draws a [Body] list onto a [Canvas].
///
/// Prefer [WorldPaint] in widget trees so you do not wrap [CustomPaint] yourself.
/// Use [WorldPainter] directly when you need a [CustomPainter] (e.g. combined
/// with [CustomPaint.foregroundPainter] or custom repaint behaviour).
///
/// World coordinates are scaled to fit the provided [size] using [worldWidth]
/// and [worldHeight]. Pass [constraints] to draw springs/pins. Use
/// [highlightedBody] to tint a specific body (e.g. a body being dragged).
///
/// Each body's [BodyRenderOptions] drive fill/stroke; supply fallback colors
/// via [defaultFillStyle] and [defaultStrokeStyle].
class WorldPainter extends CustomPainter {
  WorldPainter({
    required this.bodies,
    required this.worldWidth,
    required this.worldHeight,
    this.constraints = const <Constraint>[],
    this.highlightedBody,
    this.highlightColor = const Color(0xFFFFD166),
    this.defaultFillStyle = const Color(0xFF888888),
    this.defaultStrokeStyle = const Color(0xFFCCCCCC),
    this.constraintColor = const Color(0xFFFF5A3C),
    this.strokeWidth = 1.0,
    this.shouldAlwaysRepaint = true,
  });

  final List<Body> bodies;
  final List<Constraint> constraints;
  final double worldWidth;
  final double worldHeight;
  final Body? highlightedBody;
  final Color highlightColor;
  final Color defaultFillStyle;
  final Color defaultStrokeStyle;
  final Color constraintColor;
  final double strokeWidth;
  final bool shouldAlwaysRepaint;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / worldWidth;
    final scaleY = size.height / worldHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = defaultStrokeStyle;

    for (final body in bodies) {
      if (body.vertices.isEmpty) continue;

      final isHighlighted = highlightedBody != null && identical(body, highlightedBody);
      fillPaint.color = isHighlighted ? highlightColor : (body.render.fillStyle ?? defaultFillStyle);
      strokePaint.color = body.render.strokeStyle ?? defaultStrokeStyle;
      final lineWidth = body.render.lineWidth ?? strokeWidth;
      strokePaint.strokeWidth = lineWidth;

      // Draw true circles when the body declares a circleRadius — physics
      // still uses the polygon approximation under the hood.
      final r = body.circleRadius;
      if (r != null && r > 0) {
        final center = Offset(body.position.x, body.position.y);
        canvas.drawCircle(center, r, fillPaint);
        if (lineWidth > 0) canvas.drawCircle(center, r, strokePaint);
        // Orientation tick so rotation is visible.
        if (lineWidth > 0) {
          final tip = Offset(
            body.position.x + r * 0.9 * math.cos(body.angle),
            body.position.y + r * 0.9 * math.sin(body.angle),
          );
          canvas.drawLine(center, tip, strokePaint);
        }
        continue;
      }

      final path = Path()..moveTo(body.vertices.first.x, body.vertices.first.y);
      for (var i = 1; i < body.vertices.length; i++) {
        path.lineTo(body.vertices[i].x, body.vertices[i].y);
      }
      path.close();

      canvas.drawPath(path, fillPaint);
      if (lineWidth > 0) canvas.drawPath(path, strokePaint);
    }

    final constraintPaint = Paint()
      ..color = constraintColor
      ..strokeWidth = strokeWidth * 1.5;
    final anchorPaint = Paint()..color = constraintColor;

    for (final c in constraints) {
      final a = _worldPoint(c.pointA, c.bodyA, useBodyAngle: c.bodyA != null);
      final b = _worldPoint(c.pointB, c.bodyB, useBodyAngle: c.bodyB != null);
      if (a == null || b == null) continue;
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), constraintPaint);
      canvas.drawCircle(Offset(a.x, a.y), 3, anchorPaint);
      canvas.drawCircle(Offset(b.x, b.y), 3, anchorPaint);
    }

    canvas.restore();
  }

  Vector? _worldPoint(Vector? local, Body? body, {required bool useBodyAngle}) {
    if (local == null) return null;
    if (body == null) return local;
    final rotated = useBodyAngle ? local.rotateVactor(body.angle) : local;
    return Vector(body.position.x + rotated.x, body.position.y + rotated.y);
  }

  @override
  bool shouldRepaint(covariant WorldPainter old) =>
      shouldAlwaysRepaint ||
      old.bodies != bodies ||
      old.constraints != constraints ||
      old.highlightedBody != highlightedBody;
}
