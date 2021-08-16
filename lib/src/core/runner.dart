import 'package:flutter/scheduler.dart';

import 'engine.dart';

/// Callback that provides deltaTime dt (in seconds) and time correction factor.
typedef RunnerCallback = void Function(double dt, double timeCorrection);

/// Runner provides a simple game loop, that updates the Engine on every frame.
class Runner {
  double _correction = 1.0;
  Ticker? _ticker;
  RunnerCallback? _dtCallback;

  // Maintain previous duration to calculate the next deltaTime.
  Duration _previousTime = Duration.zero;

  // Maintiain previous deltaTime (in seconds) to calculate next time correction.
  // Initially, assumed that we are ticking at 60 frames per second.
  double _prevDeltaTime = 1000 / 60;

  // Engine timescale options.
  EngineTimingOptions? _engineTiming;

  // Maintain previous time scale to calculate correction based on engine timescale.
  double _prevTimeScale = 1.0;

  /// Creates a gameloop that provides callback to help continously [tick] the Engine.
  void run(RunnerCallback dtCallback, {required EngineTimingOptions? engineTiming}) {
    _engineTiming = engineTiming;
    _dtCallback = dtCallback;
    _ticker?.dispose();
    _ticker = Ticker(_tick);
    _ticker!.start();
  }

  /// Calculates time delta and correction factor from current time.
  void _tick(Duration currentTime) {
    final diff = _previousTime == Duration.zero ? Duration.zero : currentTime - _previousTime;
    _previousTime = currentTime;

    // New delta time in seconds.
    final deltaTime = diff.inMicroseconds / Duration.microsecondsPerSecond;

    // TODO: filter delta over a few frames, to improve stability

    // Calculate time correction.
    _correction = deltaTime / _prevDeltaTime;
    _prevDeltaTime = deltaTime;

    // Apply time correction for time scaling.
    if (_prevTimeScale != 0) {
      _correction *= _engineTiming!.timeScale / _prevTimeScale;
    }
    if (_engineTiming!.timeScale == 0) {
      _correction = 0;
    }

    _prevTimeScale = _engineTiming!.timeScale;
    _dtCallback?.call(deltaTime, _correction);
  }

  void pause() {
    _ticker?.muted = true;
    _previousTime = Duration.zero;
  }

  void resume() {
    _ticker?.muted = false;
  }

  /// Stops the runner, and reset all values.
  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _correction = 1.0;
    _previousTime = Duration.zero;
    _prevDeltaTime = 1000 / 60;
    _ticker = null;
    _dtCallback = null;
  }
}
