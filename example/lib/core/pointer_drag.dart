import 'package:flutter/widgets.dart';
import 'package:matter_dart/matter_dart.dart';

import 'world_dimensions.dart';

/// Translates pointer drag gestures into a temporary `Constraint` on the
/// nearest body. The constraint is added on drag start and removed on end.
///
/// Owns nothing else — the world it mutates is injected.
class PointerDrag {
  final Composite Function() worldGetter;
  final WorldLayout layout;

  PointerDrag({
    required this.worldGetter,
    required this.layout,
  });

  Constraint? _drag;
  Body? _body;

  Constraint? get current => _drag;
  Body? get draggedBody => _body;

  void onStart(Offset local, Size viewport) {
    final world = worldGetter();
    final p = _toWorld(local, viewport);
    final body = _bodyAt(world, p);
    if (body == null) return;

    final dx = p.x - body.position.x;
    final dy = p.y - body.position.y;
    final localOffset = Vector(dx, dy).rotateVactor(-body.angle);

    final c = Constraint(
      bodyB: body,
      pointA: Vector(p.x, p.y),
      pointB: localOffset,
      stiffness: 0.05,
      damping: 0.3,
      length: 0,
    );
    world.add([c]);
    _drag = c;
    _body = body;

    if (body.isSleeping) Sleeping.set(body, false);
  }

  void onUpdate(Offset local, Size viewport) {
    final drag = _drag;
    if (drag == null) return;
    final p = _toWorld(local, viewport);
    drag.pointA.x = p.x;
    drag.pointA.y = p.y;
    if (_body != null && _body!.isSleeping) {
      Sleeping.set(_body!, false);
    }
  }

  void onEnd() {
    final drag = _drag;
    if (drag == null) return;
    worldGetter().remove([drag]);
    _drag = null;
    _body = null;
  }

  Vector _toWorld(Offset local, Size viewport) {
    return Vector(
      local.dx * layout.width / viewport.width,
      local.dy * layout.height / viewport.height,
    );
  }

  Body? _bodyAt(Composite world, Vector point) {
    for (final body in world.allBodies()) {
      if (body.isStatic) continue;
      if (body.vertices.isEmpty) continue;
      if (body.bounds != null && !body.bounds!.contains(point)) continue;
      if (Vertices.contains(body.vertices, point)) return body;
    }
    return null;
  }
}
