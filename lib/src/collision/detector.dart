import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/core/engine.dart';

import 'SAT.dart';
import 'collision.dart';
import 'grid.dart';
import 'pair.dart';

class Detector {
  /// Finds all collisions given a list of pairs.
  static List<Collision> collisions(List<GridPair> broadphasePairs, Engine engine) {
    List<Collision> collisions = [];
    Map<String, Pair> pairsTable = engine.pairs?.table ?? {};

    for (int index = 0; index < broadphasePairs.length; index++) {
      Body bodyA = broadphasePairs[index].body1;
      Body bodyB = broadphasePairs[index].body2;

      if ((bodyA.isStatic || bodyA.isSleeping) && (bodyB.isStatic || bodyB.isSleeping)) continue;

      if (!Detector.canCollide(bodyA.collisionFilter, bodyB.collisionFilter)) continue;

      // Mid phase
      if (bodyA.bounds!.overlaps(bodyB.bounds!)) {
        for (int j = bodyA.parts.length > 1 ? 1 : 0; j < bodyA.parts.length; j++) {
          Body partA = bodyA.parts[j];

          for (int k = bodyB.parts.length > 1 ? 1 : 0; k < bodyB.parts.length; k++) {
            Body partB = bodyB.parts[k];

            if ((partA == bodyA && partB == bodyB) || partA.bounds!.overlaps(partB.bounds!)) {
              // Find a previous collision we could reuse
              String pairId = Pair.getPairId(partA, partB);
              Pair? pair = pairsTable[pairId];
              Collision? previousCollision;

              if (pair != null && pair.isActive) {
                previousCollision = pair.collision;
              } else {
                previousCollision = null;
              }

              // Narrow phase
              Collision collision = SAT.collides(partA, partB, previousCollision);
              if (collision.collided) collisions.add(collision);
            }
          }
        }
      }
    }

    return collisions;
  }

  /// Returns `true` if both supplied collision filters will allow a collision to occur.
  static bool canCollide(CollisionFilter filterA, CollisionFilter filterB) {
    if (filterA.group == filterB.group && filterA.group != 0) {
      return filterA.group > 0;
    }
    return (filterA.mask & filterB.category) != 0 && (filterB.mask & filterA.category) != 0;
  }
}
