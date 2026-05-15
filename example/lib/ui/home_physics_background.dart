import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

/// Live physics scene behind the home grid.
///
/// - Auto-spawns shapes from the top every ~1.4s up to [maxBodies].
/// - Periodically nudges random bodies for organic motion.
/// - Bodies share a low-opacity accent palette and rounded shapes.
/// - Exposes [spawnAt] for external triggers (e.g. a FAB).
class HomePhysicsBackground extends StatefulWidget {
  const HomePhysicsBackground({
    Key? key,
    this.controller,
    this.cardRects,
    this.maxBodies = 22,
  }) : super(key: key);

  final HomePhysicsController? controller;
  final CardRectRegistry? cardRects;
  final int maxBodies;

  @override
  State<HomePhysicsBackground> createState() => _HomePhysicsBackgroundState();
}

/// Tracks the global rects of interactive widgets (cards) that must always
/// win pointer events over the physics layer painted above them.
class CardRectRegistry {
  final Map<int, Rect> _rects = <int, Rect>{};

  void update(int id, Rect rect) {
    _rects[id] = rect;
  }

  void remove(int id) {
    _rects.remove(id);
  }

  bool contains(Offset globalPosition) {
    for (final r in _rects.values) {
      if (r.contains(globalPosition)) return true;
    }
    return false;
  }
}

/// External handle so widgets above can spawn / kick shapes.
class HomePhysicsController {
  _HomePhysicsBackgroundState? _state;
  void _attach(_HomePhysicsBackgroundState s) => _state = s;
  void _detach(_HomePhysicsBackgroundState s) {
    if (_state == s) _state = null;
  }

  void spawnBurst({int count = 6}) => _state?._spawnBurst(count);
  void kickRandom() => _state?._kickRandom();
}

class _HomePhysicsBackgroundState extends State<HomePhysicsBackground>
    with TickerProviderStateMixin {
  final Runner _runner = Runner();
  final math.Random _rng = math.Random(11);
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  Engine? _engine;
  Composite? _world;
  Size? _lastSize;
  DateTime _lastSpawn = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastKick = DateTime.fromMillisecondsSinceEpoch(0);

  static const _palette = <Color>[
    Color(0xFF60A5FA),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _runner.run(
      (dt, correction) {
        if (!correction.isFinite) return;
        _engine?.update(dt * 1000, correction);
        _autoBehaviors();
        if (mounted) _tick.value++;
      },
      engineTiming: EngineTimingOptions(timeScale: 1.0),
    );
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _runner.stop();
    _tick.dispose();
    super.dispose();
  }

  void _rebuildWorld(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;

    final world = Composite.create(CompositeOptions(bodies: <Body>[]));
    _addWalls(world, size);
    _seedInitial(world, size);

    _world = world;
    _engine = Engine.create(EngineOptions(
      world: world,
      gravity: EngineGravityOptions(x: 0, y: 1, scale: 0.0005),
    ));
  }

  void _addWalls(Composite world, Size size) {
    const t = 200.0;
    world.add(<MatterObject>[
      Bodies.rectangle(size.width / 2, size.height + t / 2, size.width + t, t, BodyOptions(isStatic: true)),
      Bodies.rectangle(-t / 2, size.height / 2, t, size.height * 3, BodyOptions(isStatic: true)),
      Bodies.rectangle(size.width + t / 2, size.height / 2, t, size.height * 3, BodyOptions(isStatic: true)),
    ]);
  }

  void _seedInitial(Composite world, Size size) {
    for (int i = 0; i < 8; i++) {
      final body = _makeShape(size, dropFromTop: false);
      world.add([body]);
    }
  }

  Body _makeShape(Size size, {bool dropFromTop = true}) {
    final s = 22.0 + _rng.nextDouble() * 34;
    final x = 40 + _rng.nextDouble() * math.max(1.0, size.width - 80);
    final y = dropFromTop
        ? -40 - _rng.nextDouble() * 40
        : 80 + _rng.nextDouble() * math.max(1.0, size.height * 0.5);
    final color = _palette[_rng.nextInt(_palette.length)];
    final isTrap = _rng.nextBool();

    final opts = BodyOptions(
      restitution: 0.55 + _rng.nextDouble() * 0.2,
      frictionAir: 0.01,
      friction: 0.1,
      density: 0.001,
      render: BodyRenderOptions()
        ..fillStyle = color.withValues(alpha: 0.14)
        ..strokeStyle = color.withValues(alpha: 0.45)
        ..lineWidth = 1.2,
    );
    final body = isTrap
        ? Bodies.trapezoid(x, y, s, s, 0.3, opts)
        : Bodies.rectangle(x, y, s, s * (0.7 + _rng.nextDouble() * 0.6), opts);
    body.setAngularVelocity((_rng.nextDouble() - 0.5) * 0.5);
    body.setVelocity(Vector((_rng.nextDouble() - 0.5) * 3, _rng.nextDouble() * 2));
    return body;
  }

  void _autoBehaviors() {
    final world = _world;
    final size = _lastSize;
    if (world == null || size == null) return;
    final now = DateTime.now();

    // Auto spawn
    final dynamicBodies = world.allBodies().where((b) => !b.isStatic).toList(growable: false);
    if (dynamicBodies.length < widget.maxBodies &&
        now.difference(_lastSpawn).inMilliseconds > 1400) {
      _lastSpawn = now;
      world.add([_makeShape(size)]);
    }

    // Cap bodies — remove oldest off-screen
    if (dynamicBodies.length > widget.maxBodies) {
      for (final b in dynamicBodies) {
        if (b.position.y > size.height + 100) {
          world.remove([b]);
          break;
        }
      }
    }

    // Periodic gentle kick
    if (now.difference(_lastKick).inMilliseconds > 2800 && dynamicBodies.isNotEmpty) {
      _lastKick = now;
      final victim = dynamicBodies[_rng.nextInt(dynamicBodies.length)];
      victim.applyForce(
        victim.position,
        Vector(
          (_rng.nextDouble() - 0.5) * 0.04,
          -(0.02 + _rng.nextDouble() * 0.03),
        ),
      );
    }
  }

  void _spawnBurst(int count) {
    final world = _world;
    final size = _lastSize;
    if (world == null || size == null) return;
    for (int i = 0; i < count; i++) {
      world.add([_makeShape(size)]);
    }
  }

  void _kickRandom() {
    final world = _world;
    if (world == null) return;
    final bodies = world.allBodies().where((b) => !b.isStatic).toList(growable: false);
    if (bodies.isEmpty) return;
    final b = bodies[_rng.nextInt(bodies.length)];
    b.applyForce(b.position, Vector((_rng.nextDouble() - 0.5) * 0.12, -0.12));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _rebuildWorld(size);
        return IgnorePointer(
          child: ValueListenableBuilder<int>(
            valueListenable: _tick,
            builder: (_, __, ___) {
              final bodies = _engine?.world?.allBodies() ?? const <Body>[];
              return WorldPaint(
                bodies: bodies,
                worldWidth: size.width,
                worldHeight: size.height,
                strokeWidth: 1,
                size: size,
              );
            },
          ),
        );
      },
    );
  }
}

