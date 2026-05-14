import 'dart:math' as math;

import 'package:example/core/world_dimensions.dart';
import 'package:example/demos/pyramid_demo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter_dart/matter_dart.dart';

void main() {
  tearDown(WorldDimensions.resetBinding);

  test('pyramid stays 10 rows on the wide web playfield', () {
    WorldDimensions.bind(WorldLayout.web);
    final world = Composite.create(CompositeOptions(bodies: <Body>[]));

    pyramidDemo.build(world, math.Random(42));

    final bodies = world.allBodies();
    final bottomY = bodies.map((b) => b.position.y).reduce(math.max);
    final bottomRow = bodies.where((b) => (b.position.y - bottomY).abs() < 0.001);

    expect(bodies.length, 55);
    expect(bottomRow.length, 10);
    expect(bottomRow.map((b) => b.position.x).reduce(math.min), 365);
    expect(bottomRow.map((b) => b.position.x).reduce(math.max), 635);
  });
}
