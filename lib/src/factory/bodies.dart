import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/body/support/models.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

/// [Bodies] contains factory methods for creating rigid body models with commonly used body
/// configurations (such as rectangles, circles and other polygons).
class Bodies {
  static Body rectangle(double x, double y, double width, double height, BodyOptions? options) {
    options = options ?? BodyOptions();

    options.label = 'Rectangle Body';
    options.position = Vector(x, y);
    options.vertices = [
      Vertex(x: 0, y: 0, index: 0),
      Vertex(x: width, y: 0, index: 1),
      Vertex(x: width, y: height, index: 2),
      Vertex(x: 0, y: height, index: 3)
    ];
    if (options.chamfer != null) {
      ChamferOptions? chamfer = options.chamfer;
      options.vertices = Vertices.chamfer(options.vertices ?? [],
          radius: chamfer?.radius ?? [8],
          quality: chamfer?.quality ?? -1,
          qualityMin: chamfer?.qualityMin ?? 2,
          qualityMax: chamfer?.qualityMax ?? 14);
    }

    return Body.create(options);
  }

  static Body trapezoid(double x, double y, double width, double height, double slope, BodyOptions? options) {
    options = options ?? BodyOptions();
    slope = slope * 0.5;
    double roof = (1 - (slope * 2)) * width;
    double x1 = width * slope;
    double x2 = x1 + roof;
    double x3 = x2 + x1;
    List<Vertex> vertices;

    if (slope < 0.5) {
      vertices = [
        Vertex(index: 0, x: 0, y: 0),
        Vertex(index: 1, x: x1, y: -height),
        Vertex(index: 2, x: x2, y: -height),
        Vertex(index: 3, x: x3, y: 0),
      ];
    } else {
      vertices = [
        Vertex(index: 0, x: 0, y: 0),
        Vertex(index: 1, x: x2, y: -height),
        Vertex(index: 2, x: x3, y: 0),
      ];
    }
    options.label = 'Trapezoid Body';
    options.position = Vector(x, y);
    options.vertices = vertices;
    if (options.chamfer != null) {
      ChamferOptions chamfer = options.chamfer!;
      options.vertices = Vertices.chamfer(options.vertices ?? [],
          radius: chamfer.radius ?? [8],
          quality: chamfer.quality ?? -1,
          qualityMin: chamfer.qualityMin ?? 2,
          qualityMax: chamfer.qualityMax ?? 14);
    }
    return Body.create(options);
  }
}
