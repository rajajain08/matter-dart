import 'package:flutter_test/flutter_test.dart';
import 'package:matter_dart/matter_dart.dart';

// Debug tests for circle-vs-polygon penetration bug.
// Goal: isolate WHICH layer is broken — geometry, narrow phase, or solver.
void main() {
  Body makeCircle(double x, double y, double r) => Bodies.circle(x, y, r, null);
  Body makeBox(double x, double y, double w, double h) => Bodies.rectangle(x, y, w, h, null);

  group('rectangle vertex winding (sanity)', () {
    test('rectangle vertices wrap around body.position', () {
      final box = makeBox(100, 100, 40, 20);
      // Expect vertices spread around (100,100)
      double minX = double.infinity, maxX = -double.infinity;
      double minY = double.infinity, maxY = -double.infinity;
      for (final v in box.vertices) {
        if (v.x < minX) minX = v.x;
        if (v.x > maxX) maxX = v.x;
        if (v.y < minY) minY = v.y;
        if (v.y > maxY) maxY = v.y;
      }
      expect(maxX - minX, closeTo(40, 0.01));
      expect(maxY - minY, closeTo(20, 0.01));
      expect((minX + maxX) / 2, closeTo(100, 0.01));
      expect((minY + maxY) / 2, closeTo(100, 0.01));
    });

    test('Vertices.contains returns true for box center', () {
      final box = makeBox(100, 100, 40, 20);
      final inside = Vertices.contains(box.vertices, Vector(100, 100));
      expect(inside, isTrue, reason: 'box center MUST be inside its own polygon');
    });

    test('Vertices.contains returns false for point clearly outside', () {
      final box = makeBox(100, 100, 40, 20);
      expect(Vertices.contains(box.vertices, Vector(200, 100)), isFalse);
    });

    test('Vertices.contains returns false for point above the box (screen y < min y)', () {
      // box spans y in [90,110]. Point at y=50 is above (smaller y in screen coords).
      final box = makeBox(100, 100, 40, 20);
      final result = Vertices.contains(box.vertices, Vector(100, 50));
      expect(result, isFalse);
    });
  });

  group('circle-polygon depth & normal cases', () {
    test('A. circle just touching box top from above — small overlap', () {
      // box top edge at y=90; circle center y=83 r=10 → bottom at y=93 → overlap 3
      final circle = makeCircle(100, 83, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      expect(c.depth, closeTo(3.0, 0.5));
    });

    test('B. circle center ON box top edge', () {
      // circle center exactly on top edge y=90
      final circle = makeCircle(100, 90, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      // half the circle is inside → depth should be ~r = 10
      expect(c.depth, closeTo(10.0, 0.5));
    });

    test('C. circle center DEEP INSIDE box (penetration)', () {
      // circle center at box center (100,100). Box spans (50..150, 90..110).
      // Nearest edge: top (y=90) or bottom (y=110), both 10 units away.
      // depth should be r + minDist = 10 + 10 = 20
      final circle = makeCircle(100, 100, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      expect(c.depth, closeTo(20.0, 0.5), reason: 'deep penetration depth = r + minDist');
      // normal magnitude should be 1
      final mag = (c.normal!.x * c.normal!.x + c.normal!.y * c.normal!.y);
      expect(mag, closeTo(1.0, 0.01));
    });

    test('D. circle center INSIDE near top edge', () {
      // circle center at (100,95) → 5 below top edge (y=90).
      // Closest edge is top, depth = r + 5 = 15.
      final circle = makeCircle(100, 95, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      expect(c.depth, closeTo(15.0, 0.5));
    });

    test('E. circle fully outside — no collision', () {
      final circle = makeCircle(100, 50, 10);
      final box = makeBox(100, 100, 40, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isFalse);
    });

    test('F. SAT-convention normal — points bodyB → bodyA (away from bodyA, per sat.dart)', () {
      final circle = makeCircle(100, 83, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      final mag = (c.normal!.x * c.normal!.x + c.normal!.y * c.normal!.y);
      expect(mag, closeTo(1.0, 0.01));
      // Engine SAT convention (sat.dart:84): normal flipped if dot(axis, B−A) > 0,
      // so the stored normal points away from bodyA. We therefore expect
      // dot(normal, B − A) ≤ 0.
      final dx = c.bodyB.position.x - c.bodyA.position.x;
      final dy = c.bodyB.position.y - c.bodyA.position.y;
      final dot = c.normal!.x * dx + c.normal!.y * dy;
      expect(dot, lessThanOrEqualTo(0),
          reason: 'SAT convention used by this engine: normal must face B→A');
    });
  });

  group('engine integration — does circle stay above floor?', () {
    test('falling circle rests on thick floor', () {
      final engine = Engine.create(null);
      final circle = Bodies.circle(100, 50, 10, BodyOptions(restitution: 0.2));
      final floor = Bodies.rectangle(100, 200, 200, 20, BodyOptions(isStatic: true));
      engine.world!.add([circle, floor]);

      double minY = 0, maxY = 0;
      for (int i = 0; i < 300; i++) {
        engine.update(1000 / 60, 1);
        if (circle.position.y < minY) minY = circle.position.y;
        if (circle.position.y > maxY) maxY = circle.position.y;
      }
      // floor top is y=190; circle radius 10 → resting center should be ~180 (with slop)
      expect(circle.position.y, lessThan(192), reason: 'circle should not pass through floor');
      expect(circle.position.y, greaterThan(170), reason: 'circle should be near resting position');
    });

    test('falling circle on THIN floor (h=4) — tunneling check', () {
      final engine = Engine.create(null);
      final circle = Bodies.circle(100, 50, 10, BodyOptions(restitution: 0.2));
      // thin floor: only 4 units thick
      final floor = Bodies.rectangle(100, 200, 200, 4, BodyOptions(isStatic: true));
      engine.world!.add([circle, floor]);

      double maxY = 0;
      for (int i = 0; i < 300; i++) {
        engine.update(1000 / 60, 1);
        if (circle.position.y > maxY) maxY = circle.position.y;
      }
      // floor spans y[198..202]; circle should sit on top with center ~188
      expect(circle.position.y, lessThan(200),
          reason: 'circle should not tunnel through thin floor');
    });

    test('multiple circles stacked on floor', () {
      final engine = Engine.create(null);
      final floor = Bodies.rectangle(100, 300, 400, 20, BodyOptions(isStatic: true));
      final circles = [
        Bodies.circle(100, 50, 10, null),
        Bodies.circle(100, 100, 10, null),
        Bodies.circle(100, 150, 10, null),
      ];
      engine.world!.add([floor, ...circles]);

      for (int i = 0; i < 300; i++) {
        engine.update(1000 / 60, 1);
      }
      for (final c in circles) {
        expect(c.position.y, lessThan(291),
            reason: 'no circle should pass through floor');
      }
    });
  });
}
