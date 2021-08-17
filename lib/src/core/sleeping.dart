import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/collision/pair.dart';

/// Contains methods to manage the sleeping state of bodies.
class Sleeping {
  static const double _motionWakeThreshold = 0.18;
  static const double _motionSleepThreshold = 0.08;
  static const double _minBias = 0.9;

  /// Puts bodies to sleep or wakes them up depending on their motion.
  static void update(List<Body> bodies, double timescale) {
    double timeFactor = math.pow(timescale, 3).toDouble();

    // update bodies sleeping status.
    for (int index = 0; index < bodies.length; index++) {
      Body body = bodies[index];
      double motion = body.speed * body.speed + body.angularSpeed * body.angularSpeed;

      // Wake up bodies if they have a force applied.
      if (body.force.x != 0 || body.force.y != 0) {
        Sleeping.set(body, false);
        continue;
      }

      double minMotion = math.min(body.motion, motion);
      double maxMotion = math.min(body.motion, motion);

      // Biased average motion estimation between frames
      body.motion = Sleeping._minBias * minMotion + (1 - Sleeping._minBias) * maxMotion;

      if (body.sleepThreshold > 0 && body.motion < Sleeping._motionSleepThreshold * timeFactor) {
        body.sleepCounter += 1;
        if (body.sleepCounter >= body.sleepThreshold) {
          Sleeping.set(body, true);
        }
      } else if (body.sleepCounter > 0) {
        body.sleepCounter -= 1;
      }
    }
  }

  /// Given a set of colliding pairs, wakes the sleeping bodies involved.
  static void afterCollisions(List<Pair> pairs, double timescale) {
    double timeFactor = math.pow(timescale, 3).toDouble();

    // Wake up bodies involved in collisions
    for (int index = 0; index < pairs.length; index++) {
      Pair pair = pairs[index];

      // Don't wake inactive pairs.
      if (!pair.isActive) continue;

      Collision collision = pair.collision;
      Body bodyA = collision.bodyA.parent!;
      Body bodyB = collision.bodyB.parent!;

      // Don't wake if at least one body is static.
      if ((bodyA.isSleeping && bodyB.isSleeping) || bodyA.isStatic || bodyB.isStatic) continue;

      if (bodyA.isSleeping || bodyB.isSleeping) {
        Body sleepingBody = (bodyA.isSleeping && !bodyA.isStatic) ? bodyA : bodyB;
        Body movingBody = sleepingBody == bodyA ? bodyB : bodyA;

        if (!sleepingBody.isStatic && movingBody.motion > Sleeping._motionWakeThreshold * timeFactor) {
          Sleeping.set(sleepingBody, false);
        }
      }
    }
  }

  /// Set a body as sleeping or awake.
  static void set(Body body, bool isSleeping) {
    if (isSleeping) {
      body.isSleeping = true;
      body.sleepCounter = body.sleepThreshold;

      body.positionImpulse.x = 0;
      body.positionImpulse.y = 0;

      body.positionPrev?.x = body.position.x;
      body.positionPrev?.y = body.position.y;

      body.anglePrev = body.angle;
      body.speed = 0;
      body.angularSpeed = 0;
      body.motion = 0;
    } else {
      body.isSleeping = false;
      body.sleepCounter = 0;
    }
  }
}
