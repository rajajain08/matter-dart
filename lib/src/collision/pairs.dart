import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/collision/pair.dart';

class Pairs {
  double pairMaxIdleLife; //ms
  Map<String, Pair> table;
  List<Pair> list;
  List<Pair> collisionStart;
  List<Pair> collisionActive;
  List<Pair> collisionEnd;

  Pairs(this.table, this.list, this.collisionStart, this.collisionActive, this.collisionEnd,
      {this.pairMaxIdleLife = 1000});

  void update(List<Collision> collisions, DateTime timeStamp) {
    Collision collision;
    String pairId;
    Pair? pair;
    collisionStart.clear();
    collisionEnd.clear();
    collisionEnd.clear();

    for (int i = 0; i < list.length; i++) {
      list[i].confirmedActive = false;
    }

    for (int i = 0; i < collisions.length; i++) {
      collision = collisions[i];

      if (collision.collided) {
        pairId = Pair(collision, timeStamp).id;

        pair = table[pairId];

        if (pair != null) {
          // pair already exists (but may or may not be active)
          if (pair.isActive) {
            // pair exists and is active
            collisionActive.add(pair);
          } else {
            // pair exists but was inactive, so a collision has just started again
            collisionStart.add(pair);
          }

          // update the pair
          pair.update(collision, timeStamp);
          pair.confirmedActive = true;
        } else {
          // pair did not exist, create a new pair
          pair = Pair(collision, timeStamp);
          table[pairId] = pair;

          // push the new pair
          collisionStart.add(pair);
          list.add(pair);
        }
      }
    }
  }

  void removeOld(Pair pair, DateTime timeStamp) {
    Collision collision;
    String pairId;
    Pair? pair;
    List<int> indexesToRemove = [];
    int pairIndex;
    for (int i = 0; i < list.length; i++) {
      pair = list[i];
      collision = pair.collision;

      // never remove sleeping pairs
      if (collision.bodyA.isSleeping || collision.bodyB.isSleeping) {
        pair.timeUpdated = timeStamp;
        continue;
      }

      // if pair is inactive for too long, mark it to be removed
      if (timeStamp.difference(pair.timeUpdated).inMilliseconds > pairMaxIdleLife) {
        indexesToRemove.add(i);
      }
    }

    for (int i = 0; i < indexesToRemove.length; i++) {
      pairIndex = indexesToRemove[i] - i;
      pair = list[pairIndex];
      table.remove(pair.id);
      list.removeAt(pairIndex);
    }
  }
}