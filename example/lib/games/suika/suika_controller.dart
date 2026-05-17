import 'dart:math' as math;

import 'package:matter_dart/matter_dart.dart';

import '../../core/walls.dart';
import '../../core/world_dimensions.dart';
import 'suika_tiers.dart';

typedef VoidCallback = void Function();

/// Runs the Suika game loop on top of matter_dart.
///
/// Owns the engine, walls, danger line and scoring. UI subscribes via [onTick].
class SuikaController {
  final VoidCallback onTick;
  final WorldLayout worldLayout;

  SuikaController({required this.onTick, required this.worldLayout});

  final Runner _runner = Runner();
  final math.Random _rng = math.Random();

  late Engine _engine;
  late Composite _world;

  int _score = 0;
  int _nextTier = 0;
  int _previewTier = 0;
  bool _gameOver = false;
  double _dropCooldown = 0;
  double _overTimer = 0;
  final Set<String> _merged = <String>{};
  final List<_PendingMerge> _pending = <_PendingMerge>[];
  final Map<int, int> _bodyTier = <int, int>{};
  // bodyId → accumulated contact time in seconds (for sustained-contact merging)
  final Map<String, double> _contactDwell = <String, double>{};

  static const double _dropCooldownSeconds = 0.35;
  static const double _gameOverGraceSeconds = 1.4;

  Engine get engine => _engine;
  List<Body> get bodies => _engine.world?.allBodies() ?? const <Body>[];
  List<Constraint> get constraints =>
      _engine.world?.allConstraints() ?? const <Constraint>[];
  int get bodyCount => bodies.length;
  int get score => _score;
  int get nextTier => _nextTier;
  int get previewTier => _previewTier;
  bool get gameOver => _gameOver;
  bool get canDrop => !_gameOver && _dropCooldown <= 0;
  Map<int, int> get bodyTierMap => _bodyTier;

  double get dangerLineY => WorldDimensions.innerTop + 70;

  void start() {
    WorldDimensions.bind(worldLayout);
    _build();
    _runner.run(_tick, engineTiming: EngineTimingOptions(timeScale: 1.0));
  }

  void dispose() {
    _runner.stop();
    WorldDimensions.resetBinding();
  }

  void restart() {
    _world.clear(false, true);
    _score = 0;
    _gameOver = false;
    _dropCooldown = 0;
    _overTimer = 0;
    _merged.clear();
    _pending.clear();
    _bodyTier.clear();
    _contactDwell.clear();
    _build();
  }

  /// Drops a fruit of the queued tier at horizontal screen position [worldX].
  /// Returns true when a fruit was spawned.
  bool drop(double worldX) {
    if (!canDrop) return false;
    final tier = _nextTier;
    final radius = tierAt(tier).radius;
    final clampedX = worldX.clamp(
      WorldDimensions.innerLeft + radius + 2,
      WorldDimensions.innerRight - radius - 2,
    );
    _spawnFruit(clampedX, WorldDimensions.innerTop + 24, tier);
    _nextTier = _previewTier;
    _previewTier = _rollPreview();
    _dropCooldown = _dropCooldownSeconds;
    return true;
  }

  // ---- internals ----------------------------------------------------------

  void _build() {
    _world = Composite.create(CompositeOptions(bodies: <Body>[]));
    Walls.addTo(_world);
    _engine = Engine.create(EngineOptions(
      world: _world,
      gravity: EngineGravityOptions(x: 0, y: 1, scale: 0.001),
      positionIterations: 10,
      velocityIterations: 8,
      enableSleeping: true,
    ));
    _engine.on('collisionStart', _onCollisionEvent);
    _engine.on('collisionActive', _onCollisionEvent);
    _engine.on('collisionEnd', _onCollisionEnd);
    _engine.on('afterUpdate', (_) => _afterUpdate());
    _nextTier = _rollPreview();
    _previewTier = _rollPreview();
  }

  int _rollPreview() => _rng.nextInt(kMaxDropTierIndex + 1);

  Body _spawnFruit(double x, double y, int tier) {
    final t = tierAt(tier);
    final body = Bodies.circle(
      x,
      y,
      t.radius,
      BodyOptions(
        restitution: 0.0,
        friction: 0.5,
        frictionAir: 0.018,
        density: 0.002,
        slop: 0.005,
        render: BodyRenderOptions()..fillStyle = t.color,
      ),
      maxSides: 28,
    );
    _bodyTier[body.id] = tier;
    _world.add(<MatterObject>[body]);
    return body;
  }

  // Required dwell time before merge fires (seconds). Small fruits merge quickly,
  // large ones need sustained contact so impulse doesn't separate them first.
  static double _dwellRequired(int tier) => tier < 3 ? 0.0 : 0.08;

  void _onCollisionEvent(Map<String, dynamic> event) {
    final dt = _engine.timing.lastDelta / 1000.0;
    final pairs = event['pairs'] as List<dynamic>? ?? const [];
    for (final raw in pairs) {
      final pair = raw as Pair;
      final a = pair.bodyA;
      final b = pair.bodyB;
      final ta = _bodyTier[a.id];
      final tb = _bodyTier[b.id];
      if (ta == null || tb == null) continue;
      if (ta != tb) continue;
      if (isMaxTier(ta)) continue;
      final aKey = 'b:${a.id}';
      final bKey = 'b:${b.id}';
      if (_merged.contains(aKey) || _merged.contains(bKey)) continue;
      final pairKey = pair.id;
      if (_merged.contains(pairKey)) continue;
      // Accumulate dwell time; fire merge once threshold met.
      final dwell = (_contactDwell[pairKey] ?? 0.0) + dt;
      if (dwell >= _dwellRequired(ta)) {
        _contactDwell.remove(pairKey);
        _merged
          ..add(pairKey)
          ..add(aKey)
          ..add(bKey);
        _pending.add(_PendingMerge(a: a, b: b, tier: ta));
      } else {
        _contactDwell[pairKey] = dwell;
      }
    }
  }

  void _onCollisionEnd(Map<String, dynamic> event) {
    final pairs = event['pairs'] as List<dynamic>? ?? const [];
    for (final raw in pairs) {
      _contactDwell.remove((raw as Pair).id);
    }
  }

  void _afterUpdate() {
    if (_pending.isNotEmpty) {
      for (final m in _pending) {
        final nextTier = m.tier + 1;
        final mx = (m.a.position.x + m.b.position.x) / 2;
        final my = (m.a.position.y + m.b.position.y) / 2;
        _bodyTier.remove(m.a.id);
        _bodyTier.remove(m.b.id);
        _world.remove(<MatterObject>[m.a, m.b]);
        final spawned = _spawnFruit(mx, my, nextTier);
        // Tiny upward nudge so chains look lively, not snappy.
        spawned.velocity = Vector(0, -0.4);
        _score += tierAt(nextTier).score;
      }
      _pending.clear();
      _merged.clear();
    }

    // Game-over: any non-fresh fruit resting above the danger line for too long.
    if (!_gameOver) {
      bool overLine = false;
      final line = dangerLineY;
      for (final body in bodies) {
        if (!_bodyTier.containsKey(body.id)) continue;
        final topY = body.position.y - (body.circleRadius ?? 0);
        if (topY < line && body.speed < 0.25) {
          overLine = true;
          break;
        }
      }
      if (overLine) {
        _overTimer += _engine.timing.lastDelta / 1000.0;
        if (_overTimer >= _gameOverGraceSeconds) {
          _gameOver = true;
        }
      } else {
        _overTimer = 0;
      }
    }
  }

  double _emaFps = 60;
  double get fps => _emaFps;

  void _tick(double dt, double correction) {
    if (!correction.isFinite) return;
    _engine.update(dt * 1000, correction);
    if (_dropCooldown > 0) {
      _dropCooldown = math.max(0, _dropCooldown - dt);
    }
    if (dt > 0) {
      final instant = 1.0 / dt;
      _emaFps = _emaFps * 0.9 + instant * 0.1;
    }
    onTick();
  }
}

class _PendingMerge {
  final Body a;
  final Body b;
  final int tier;
  _PendingMerge({required this.a, required this.b, required this.tier});
}
