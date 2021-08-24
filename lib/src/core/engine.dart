import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/composite.dart';
import 'package:matter_dart/src/body/support/models.dart';
import 'package:matter_dart/src/collision/detector.dart';
import 'package:matter_dart/src/collision/grid.dart';
import 'package:matter_dart/src/collision/pairs.dart';
import 'package:matter_dart/src/collision/resolver.dart';
import 'package:matter_dart/src/constraint/constraint.dart';
import 'package:matter_dart/src/core/sleeping.dart';
import 'package:matter_dart/src/geometry/vector.dart';

class Engine {
  // Specifies the number of position iterations to perform each update.
  double positionIterations = 6;

  // Specifies the number of velocity iterations to perform each update.
  double velocityIterations = 4;

  // Specifies the number of constraint iterations to perform each update.
  double constraintIterations = 2;

  // Specifies whether the engine should allow sleeping via the `Matter.Sleeping` module.
  bool enableSleeping = false;
  //TODO
  List<dynamic> events = [];

  Grid? grid;
  Grid? broadphase;
  // The gravity to apply on all bodies in `engine.world`.
  EngineGravityOptions gravity = EngineGravityOptions(x: 0, y: 1, scale: 0.001);

  // Specifies timescale property to apply slow-motion or fast-motion effect on engine.
  EngineTimingOptions timing = EngineTimingOptions(timeScale: 1);

  Composite? world;

  late Pairs pairs;

  Engine({
    this.positionIterations = 6,
    this.velocityIterations = 4,
    this.constraintIterations = 2,
    this.enableSleeping = false,
    EngineGravityOptions? gravity,
    EngineTimingOptions? timing,
    this.world,
  }) {
    // this.gravity = gravity ?? EngineGravityOptions(x: 0, y: 1, scale: 0.001);
    // this.timing = timing ?? EngineTimingOptions(timeScale: 1);
    // this.pairs = Pairs.create();
  }

  factory Engine.create(EngineOptions? options) {
    options = options ?? EngineOptions();
    Engine engine = Engine();

    engine.gravity = EngineGravityOptions(x: 0, y: 1, scale: 0.001);
    _merge(engine, options);
    engine.world = engine.world ?? Composite.create(CompositeOptions(label: 'World'));
    engine.grid = options.grid ?? options.broadphase;
    engine.pairs = Pairs.create();

    // temporary back compatibility
    engine.broadphase = engine.grid;
    return engine;
  }
  void update(double? delta, double? correction) {
    DateTime startDateTime = DateTime.now();
    delta = delta ?? 1000 / 60;
    correction = correction ?? 1;
    List<GridPair> gridPairs;
    int i;
    timing.timestamp = delta * timing.timeScale;
    timing.lastDelta = delta * timing.timeScale;

    //TODO create event and triggger
    //
    //
    List<Body> allBodies = this.world?.allBodies() ?? [];
    List<Constraint>? allConstraints = this.world?.allConstraints();
    if (this.enableSleeping && allBodies != null) {
      Sleeping.update(allBodies, timing.timeScale);
    }
    // applies gravity to all bodies
    _bodiesApplyGravity(allBodies);

    // update all body position and rotation by integration
    _bodiesUpdate(allBodies, delta, timing.timeScale, correction);

    // update all constraints (first pass)
    Constraint.preSolveAll(allBodies);

    if (world?.isModified ?? false) {
      grid?.clear();
    }

    // update the grid buckets based on current bodies
    grid?.update(allBodies, this, world?.isModified ?? false);
    gridPairs = grid?.pairsList ?? [];

    // clear all composite modified flags
    if (world?.isModified ?? false) {
      world?.setModified(false, false, true);
    }

    // narrowphase pass: find actual collisions, then create or update collision pairs
    var collisions = Detector.collisions(gridPairs, this);

    // update collision pairs
    var pairs = this.pairs, timestamp = timing.timestamp;
    pairs.update(collisions, timestamp);
    pairs.removeOld(timestamp);

    // wake up bodies involved in collisions
    if (enableSleeping) Sleeping.afterCollisions(pairs.list, timing.timeScale);

    //TODO
    // trigger collision events
    // if (pairs.collisionStart.length > 0) Events.trigger(engine, 'collisionStart', {pairs: pairs.collisionStart});

    // iteratively resolve position between collisions
    Resolver.preSolvePosition(pairs.list);
    for (i = 0; i < positionIterations; i++) {
      Resolver.solvePosition(pairs.list, timing.timeScale);
    }
    Resolver.postSolvePosition(allBodies);

    // update all constraints (second pass)
    Constraint.preSolveAll(allBodies);
    for (i = 0; i < constraintIterations; i++) {
      Constraint.solveAll(allConstraints ?? [], timing.timeScale);
    }
    Constraint.postSolveAll(allBodies);

    // iteratively resolve velocity between collisions
    Resolver.preSolveVelocity(pairs.list);
    for (i = 0; i < velocityIterations; i++) {
      Resolver.solveVelocity(pairs.list, timing.timeScale);
    }

    // trigger collision events TODO
    // if (pairs.collisionActive.length > 0) Events.trigger(engine, 'collisionActive', {pairs: pairs.collisionActive});

    // if (pairs.collisionEnd.length > 0) Events.trigger(engine, 'collisionEnd', {pairs: pairs.collisionEnd});

    _bodiesClearForces(allBodies);
    // TODO
    //  Events.trigger(engine, 'afterUpdate', event);

    // log the time elapsed computing this update TODO
    // timing.lastElapsed = Common.now() - startTime;
  }

  void _bodiesApplyGravity(List<Body> bodies) {
    double gravityScale = this.gravity.scale;
    if ((gravity.x == 0 && gravity.y == 0) || gravityScale == 0) {
      return;
    }

    for (var i = 0; i < bodies.length; i++) {
      var body = bodies[i];

      if (body.isStatic || body.isSleeping) continue;

      // apply gravity
      body.force.y += body.mass * gravity.y * gravityScale;
      body.force.x += body.mass * gravity.x * gravityScale;
    }
  }

  void _bodiesUpdate(
    List<Body> bodies,
    double deltaTime,
    double timeScale,
    double correction,
  ) {
    for (var i = 0; i < bodies.length; i++) {
      var body = bodies[i];

      if (body.isStatic || body.isSleeping) continue;

      body.update(deltaTime, timeScale, correction);
    }
  }

  void _bodiesClearForces(List<Body> bodies) {
    for (var i = 0; i < bodies.length; i++) {
      Body body = bodies[i];

      // reset force buffers
      body.force.x = 0;
      body.force.y = 0;
      body.torque = 0;
    }
  }

  static void _merge(Engine engine, EngineOptions options) {
    engine.constraintIterations = options.constraintIterations ?? engine.constraintIterations;
    engine.enableSleeping = options.enableSleeping ?? engine.enableSleeping;
    engine.events = options.events ?? engine.events;
    engine.gravity = options.gravity ?? engine.gravity;
    engine.grid = options.grid ?? engine.grid;
    engine.broadphase = options.broadphase;
    engine.pairs = options.pairs ?? engine.pairs;
    engine.positionIterations = options.positionIterations ?? engine.positionIterations;
    engine.timing = options.timing ?? engine.timing;
    engine.velocityIterations = options.velocityIterations ?? engine.velocityIterations;
    engine.world = options.world ?? engine.world;
  }
}

class EngineTimingOptions {
  // Specifies the scaling factor of time for all bodies. 0 means freezed, 0.1 means slow-motion, 1.2 speedup.
  double timeScale;
  double timestamp;
  double lastDelta = 0;
  double lastElapsed = 0;

  EngineTimingOptions({required this.timeScale, this.timestamp = 0, this.lastDelta = 0, this.lastElapsed = 0});

  void updateTimeScale(double timeScale) {
    this.timeScale = timeScale;
  }
}

class EngineGravityOptions extends Vector {
  double scale;

  EngineGravityOptions({required this.scale, required x, required y}) : super(x, y);
}

class EngineOptions {
  double? positionIterations = 6;

  double? velocityIterations = 4;

  double? constraintIterations = 2;

  bool? enableSleeping = false;

  List<dynamic>? events = [];

  Grid? grid;

  Grid? broadphase;

  EngineGravityOptions? gravity;

  EngineTimingOptions? timing;

  Composite? world;

  Pairs? pairs;
}
