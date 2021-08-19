import 'dart:math' as math;

import 'package:matter_dart/matter_dart.dart';
import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/composite.dart';
import 'package:matter_dart/src/core/engine.dart';

/// Contains methods for creating and manipulating collision broadphase grid structures.
class Grid {
  // Hashmap of pairID and grid pair.
  Map<String, GridPair> _pairs = {};

  // List of broadphase pairs.
  List<GridPair> pairsList = [];

  // Hashmap of bucketID and bodies in that bucket.
  Map<String, List<Body>> buckets = {};

  final double bucketWidth;
  final double bucketHeight;

  Grid({
    this.bucketWidth = 48,
    this.bucketHeight = 48,
  });

  /// Updates the grid.
  void update(List<Body> bodies, Engine engine, bool forceUpdate) {
    bool gridChanged = false;
    Composite world = engine.world!;

    for (int index = 0; index < bodies.length; index++) {
      Body body = bodies[index];
      if (body.isSleeping && !forceUpdate) continue;

      // Temporary back compatibility bounds check.
      if (world.bounds != null &&
          (body.bounds!.max.dx < world.bounds!.min.dx ||
              body.bounds!.min.dx > world.bounds!.max.dx ||
              body.bounds!.max.dy < world.bounds!.min.dy ||
              body.bounds!.min.dy > world.bounds!.max.dy)) {
        continue;
      }

      Region newRegion = _getRegion(body);

      // If the body has changed grid region
      if (body.region == null || newRegion.id != body.region!.id || forceUpdate) {
        if (body.region == null || forceUpdate) {
          body.region = newRegion;
        }

        Region union = _regionUnion(newRegion, body.region!);

        // Update grid buckets affected by region change
        // Iterate over the union of both regions
        for (int col = union.startCol; col <= union.endCol; col++) {
          for (int row = union.startRow; row <= union.endRow; row++) {
            String bucketId = _getBucketId(col, row);
            List<Body>? bucket = buckets[bucketId];

            bool isInsideNewRegion = col >= newRegion.startCol &&
                col <= newRegion.endCol &&
                row >= newRegion.startRow &&
                row <= newRegion.endRow;
            bool isInsideOldRegion = col >= body.region!.startCol &&
                col <= body.region!.endCol &&
                row >= body.region!.startRow &&
                row <= body.region!.endRow;

            // Remove from old region buckets.
            if (!isInsideNewRegion && isInsideOldRegion) {
              if (isInsideOldRegion) {
                if (bucket != null) {
                  _bucketRemoveBody(bucket, body);
                }
              }
            }

            // Add to new region buckets.
            if (body.region == newRegion || (isInsideNewRegion && !isInsideOldRegion) || forceUpdate) {
              if (bucket == null) {
                buckets[bucketId] = <Body>[];
              }
              _bucketAddBody(buckets[bucketId]!, body);
            }
          }
        }

        // Set the new region.
        body.region = newRegion;

        // Flag changes so we can update pairs.
        gridChanged = true;
      }
    }

    // Update pairs list only if pairs changed (i.e. a body changed region)
    if (gridChanged) {
      pairsList = _createActivePairsList();
    }
  }

  /// Clears the grid.
  void clear() {
    this._pairs.clear();
    this.pairsList.clear();
    this.buckets.clear();
  }

  /// Finds the union of two regions.
  Region _regionUnion(Region regionA, Region regionB) {
    final int startCol = math.min(regionA.startCol, regionB.startCol);
    final int endCol = math.max(regionA.endCol, regionB.endCol);
    final int startRow = math.min(regionA.startRow, regionB.startRow);
    final int endRow = math.max(regionA.endRow, regionB.endRow);

    return Region(startCol: startCol, endCol: endCol, startRow: startRow, endRow: endRow);
  }

  /// Gets the region a given body falls in for a given grid.
  Region _getRegion(Body body) {
    final bounds = body.bounds;
    final int startCol = (bounds!.min.dx / this.bucketWidth).floor();
    final int endCol = (bounds.max.dx / this.bucketWidth).floor();
    final int startRow = (bounds.min.dy / this.bucketHeight).floor();
    final int endRow = (bounds.max.dy / this.bucketHeight).floor();

    return Region(startCol: startCol, endCol: endCol, startRow: startRow, endRow: endRow);
  }

  /// Gets the bucket id at the given position.
  String _getBucketId(int column, int row) => 'C${column}R$row';

  /// Adds a body to a bucket.
  void _bucketAddBody(List<Body> bucket, Body body) {
    // Add new pairs.
    for (int index = 0; index < bucket.length; index++) {
      final Body bodyB = bucket[index];
      if (body.id == bodyB.id || (body.isStatic && bodyB.isStatic)) {
        continue;
      }
      // Keep track of the number of buckets the pair exists in, Important for Grid.update to work
      final pairId = Pair.getPairId(body, bodyB);
      GridPair? pair = _pairs[pairId];
      if (pair != null) {
        pair.pairCount++;
      } else {
        _pairs[pairId] = GridPair(body, bodyB, 1);
      }
    }

    // Add to bodies (after pairs, otherwise pairs with self)
    bucket.add(body);
  }

  /// Removes a body from a bucket.
  void _bucketRemoveBody(List<Body> bucket, Body body) {
    bucket.removeWhere((item) => item.id == body.id);

    // Update pair count.
    for (int index = 0; index < bucket.length; index++) {
      // Keep track of the number of buckets the pair exists in ,important for _createActivePairsList to work
      final Body bodyB = bucket[index];
      final pairId = Pair.getPairId(body, bodyB);
      GridPair? pair = _pairs[pairId];

      if (pair != null) {
        pair.pairCount--;
      }
    }
  }

  /// Generates a list of the active pairs in the grid.
  List<GridPair> _createActivePairsList() {
    List<String> pairKeys = _pairs.keys.toList();
    List<GridPair> pairs = [];

    for (int k = 0; k < pairKeys.length; k++) {
      GridPair? pair = _pairs[pairKeys[k]];

      if (pair != null) {
        // If pair exists in at least one bucket
        // It is a pair that needs further collision testing so push it
        if (pair.pairCount > 0) {
          pairs.add(pair);
        } else {
          _pairs.remove(pairKeys[k]);
        }
      }
    }

    return pairs;
  }
}

/// Represents single broadphase pair.
class GridPair {
  Body body1;
  Body body2;
  int pairCount;

  GridPair(this.body1, this.body2, this.pairCount);
}
