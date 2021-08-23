import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/support/models.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// [Bodies] contains factory methods for creating rigid body models with commonly used body
/// configurations (such as rectangles, circles and other polygons).
class Bodies {
  static Body rectangle(double x, double y, double width, double height, Body? options) {
    Body newBody = Body();
    newBody.label = 'Rectangle Body';
    newBody.position = Vector(x, y);
    newBody.vertices = [
      Vertex(x: 0, y: 0, index: 0),
      Vertex(x: width, y: 0, index: 1),
      Vertex(x: width, y: height, index: 0),
      Vertex(x: 0, y: height, index: 0)
    ];
    if (options?.chamfer != null) {
      ChamferOptions? chamfer = options?.chamfer;
      newBody.vertices = Vertices.chamfer(newBody.vertices,
          radius: chamfer?.radius ?? [8],
          quality: chamfer?.quality ?? -1,
          qualityMin: chamfer?.qualityMin ?? 2,
          qualityMax: chamfer?.qualityMax ?? 14);
    }

    return newBody;
  }
}
