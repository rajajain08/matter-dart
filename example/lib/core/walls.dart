import 'package:matter_dart/matter_dart.dart';

import 'world_dimensions.dart';

/// Builds the static enclosure (floor + 3 walls) used by every demo.
class Walls {
  Walls._();

  static void addTo(Composite world) {
    final w = WorldDimensions.width;
    final h = WorldDimensions.height;
    final wall = WorldDimensions.wallThickness;
    final ground = WorldDimensions.groundThickness;

    world.add(<MatterObject>[
      _wall(w / 2, h - ground / 2, w + 2 * wall, ground),
      _wall(w / 2, wall / 2, w, wall),
      _wall(wall / 2, h / 2, wall, h),
      _wall(w - wall / 2, h / 2, wall, h),
    ]);
  }

  static Body _wall(double x, double y, double w, double h) {
    return Bodies.rectangle(x, y, w, h, BodyOptions(isStatic: true));
  }
}
