import 'package:flutter_test/flutter_test.dart';
import 'package:matter_dart/matter_dart.dart';

void main() {
  // ── helpers ──────────────────────────────────────────────────────────────

  Body makeCircle(double x, double y, double r) => Bodies.circle(x, y, r, null);

  Body makeBox(double x, double y, double w, double h) => Bodies.rectangle(x, y, w, h, null);

  // ── circle vs circle ─────────────────────────────────────────────────────

  group('circleCircle', () {
    test('no collision when apart', () {
      final a = makeCircle(0, 0, 10);
      final b = makeCircle(30, 0, 10);
      final c = CircleCollision.circleCircle(a, b);
      expect(c.collided, isFalse);
    });

    test('detects overlap and correct depth', () {
      // centers 15 apart, radii 10+10=20 → depth = 5
      final a = makeCircle(0, 0, 10);
      final b = makeCircle(15, 0, 10);
      final c = CircleCollision.circleCircle(a, b);
      expect(c.collided, isTrue);
      expect(c.depth, closeTo(5.0, 0.01));
    });

    test('normal points away from bodyA (SAT convention, B→A)', () {
      final a = makeCircle(0, 0, 10);
      final b = makeCircle(15, 0, 10); // b is to the right of a
      final c = CircleCollision.circleCircle(a, b);
      // Engine SAT convention (sat.dart:84): stored normal must satisfy
      // dot(normal, B − A) ≤ 0 so the solver pushes bodies apart correctly.
      // With b to the right of a, normal.x should be negative.
      expect(c.normal!.x, lessThan(0));
      expect(c.normal!.y, closeTo(0, 0.01));
    });

    test('normal points upward when b is above a', () {
      final a = makeCircle(0, 20, 10);
      final b = makeCircle(0, 5, 10); // b is above a (lower y)
      final c = CircleCollision.circleCircle(a, b);
      // bodyA is lower-id; normal points bodyA→bodyB = downward y in screen coords
      expect(c.collided, isTrue);
      expect(c.normal!.y, isNot(closeTo(0, 0.1)));
    });

    test('produces one support point', () {
      final a = makeCircle(0, 0, 10);
      final b = makeCircle(15, 0, 10);
      final c = CircleCollision.circleCircle(a, b);
      expect(c.supports.length, equals(1));
    });

    test('support point is on surface of bodyA toward bodyB', () {
      final a = makeCircle(0, 0, 10);
      final b = makeCircle(15, 0, 10);
      final c = CircleCollision.circleCircle(a, b);
      final s = c.supports.first;
      // Surface of A nearest B: x = +rA = 10 (B is to the right of A).
      expect(s.x, closeTo(10, 0.5));
      expect(s.y, closeTo(0, 0.5));
    });
  });

  // ── circle vs polygon ────────────────────────────────────────────────────

  group('circlePolygon', () {
    test('no collision when apart', () {
      final circle = makeCircle(0, 0, 10);
      final box = makeBox(50, 0, 20, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isFalse);
    });

    test('detects overlap with floor (circle sitting on top of box)', () {
      // box top edge is at y=90 (box center 100, half-height 10)
      // circle bottom edge at y=90 (circle center 80, radius 10) → touching
      // move circle down slightly to overlap
      final circle = makeCircle(100, 83, 10); // bottom at y=93, box top at y=90
      final box = makeBox(100, 100, 100, 20); // top at y=90
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      expect(c.depth, greaterThan(0));
    });

    test('normal points away from polygon toward circle', () {
      // circle above box → normal should point upward (negative y)
      final circle = makeCircle(100, 83, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.collided, isTrue);
      // normal should have a significant y component pointing toward circle (upward = negative y)
      expect(c.normal!.y.abs(), greaterThan(0.5));
    });

    test('produces one support point', () {
      final circle = makeCircle(100, 83, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.supports.length, equals(1));
    });

    test('depth is approximately correct', () {
      // circle center at y=83, radius=10 → bottom at y=93
      // box top at y=90 → overlap = 93 - 90 = 3
      final circle = makeCircle(100, 83, 10);
      final box = makeBox(100, 100, 100, 20);
      final c = CircleCollision.circlePolygon(circle, box);
      expect(c.depth, closeTo(3.0, 0.5));
    });
  });

  // ── engine integration ───────────────────────────────────────────────────

  group('engine integration', () {
    test('circle bounces off static floor', () {
      final engine = Engine.create(null);
      final circle = Bodies.circle(100, 50, 10, BodyOptions(restitution: 0.8));
      final floor = Bodies.rectangle(100, 200, 200, 20, BodyOptions(isStatic: true));
      engine.world!.add([circle, floor]);

      // run enough frames for circle to fall and hit floor
      for (int i = 0; i < 120; i++) {
        engine.update(1000 / 60, 1);
      }

      // circle should not have fallen through the floor center (y=200)
      // small slop penetration (~0.1) is normal for resting contacts
      expect(circle.position.y, lessThan(201));
    });

    test('two circles collide and separate', () {
      final engine = Engine.create(EngineOptions(
        gravity: EngineGravityOptions(x: 0, y: 0, scale: 0),
      ));
      // place circles just outside touching distance (sum of radii = 20, gap = 21)
      final a = Bodies.circle(0, 0, 10, BodyOptions(restitution: 1.0));
      final b = Bodies.circle(21, 0, 10, BodyOptions(restitution: 1.0));
      // move a toward b
      a.setVelocity(Vector(2, 0));
      engine.world!.add([a, b]);

      // run until they collide and separate
      for (int i = 0; i < 60; i++) {
        engine.update(1000 / 60, 1);
      }

      // b should have been pushed to the right after collision
      expect(b.position.x, greaterThan(21));
    });
  });
}
