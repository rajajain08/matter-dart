import 'dart:math' as math;

import 'package:matter_dart/matter_dart.dart';

import 'demo.dart';
import 'walls.dart';
import 'world_dimensions.dart';

/// Owns the physics simulation lifecycle for a single `Demo`.
///
/// Responsible for:
///   - building the world and engine from a `Demo` spec
///   - driving the game loop via `Runner`
///   - resetting the world when requested
///
/// Knows nothing about widgets — the presentation layer subscribes via
/// `onTick` and reads state through the exposed getters.
class DemoController {
  final Demo demo;
  final VoidCallback onTick;
  final int seed;
  final WorldLayout worldLayout;

  DemoController({
    required this.demo,
    required this.onTick,
    this.seed = 42,
    this.worldLayout = WorldLayout.mobile,
  });

  final Runner _runner = Runner();
  late math.Random _rng;
  late Engine _engine;
  late Composite _world;

  Engine get engine => _engine;
  Composite get world => _world;

  List<Body> get bodies => _engine.world?.allBodies() ?? const <Body>[];
  List<Constraint> get constraints =>
      _engine.world?.allConstraints() ?? const <Constraint>[];
  int get bodyCount => bodies.length;

  void start() {
    WorldDimensions.bind(worldLayout);
    _rng = math.Random(seed);
    _build();
    _runner.run(
      _tick,
      engineTiming: EngineTimingOptions(timeScale: 1.0),
    );
  }

  void reset() {
    _world.clear(false, true);
    _rng = math.Random(seed);
    _build();
  }

  void dispose() {
    _runner.stop();
    WorldDimensions.resetBinding();
  }

  void _build() {
    _world = Composite.create(CompositeOptions(bodies: <Body>[]));
    Walls.addTo(_world);
    demo.build(_world, _rng);
    _engine = Engine.create(EngineOptions(
      world: _world,
      gravity: demo.gravity ?? EngineGravityOptions(x: 0, y: 1, scale: 0.001),
      constraintIterations: demo.constraintIterations,
      positionIterations: demo.positionIterations,
      velocityIterations: demo.velocityIterations,
      enableSleeping: demo.enableSleeping,
    ));
  }

  double _emaFps = 60;
  double get fps => _emaFps;

  void _tick(double dt, double correction) {
    if (!correction.isFinite) return;
    _engine.update(dt * 1000, correction);
    if (dt > 0) {
      final instant = 1.0 / dt;
      _emaFps = _emaFps * 0.9 + instant * 0.1;
    }
    onTick();
  }
}

typedef VoidCallback = void Function();
