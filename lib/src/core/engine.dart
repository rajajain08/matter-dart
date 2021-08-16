import 'package:matter_dart/src/body/composite.dart';
import 'package:matter_dart/src/collision/pairs.dart';
import 'package:matter_dart/src/geometry/vector.dart';

class Engine {
  // Specifies the number of position iterations to perform each update.
  double positionIterations;

  // Specifies the number of velocity iterations to perform each update.
  double velocityIterations;

  // Specifies the number of constraint iterations to perform each update.
  double constraintIterations;

  // Specifies whether the engine should allow sleeping via the `Matter.Sleeping` module.
  bool enableSleeping;

  // The gravity to apply on all bodies in `engine.world`.
  late EngineGravityOptions gravity;

  // Specifies timescale property to apply slow-motion or fast-motion effect on engine.
  late EngineTimingOptions timing;

  Composite? world;

  // TODO:
  dynamic grid;

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
    this.gravity = gravity ?? EngineGravityOptions(x: 0, y: 1, scale: 0.001);
    this.timing = timing ?? EngineTimingOptions(timeScale: 1);
    this.pairs = Pairs.create();
  }
}

class EngineTimingOptions {
  // Specifies the scaling factor of time for all bodies. 0 means freezed, 0.1 means slow-motion, 1.2 speedup.
  double timeScale;

  EngineTimingOptions({required this.timeScale});

  void updateTimeScale(double timeScale) {
    this.timeScale = timeScale;
  }
}

class EngineGravityOptions extends Vector {
  double scale;

  EngineGravityOptions({required this.scale, required x, required y}) : super(x, y);
}
