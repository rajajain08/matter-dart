# matter_dart

A Flutter-friendly 2D physics engine inspired by [Matter.js](https://brm.io/matter-js/), written in Dart.

`matter_dart` gives Flutter apps a rigid-body simulation toolkit for interactive demos, games, prototypes, and physics-driven UI. It includes engines, bodies, composites, constraints, collision handling, geometry helpers, and an optional Flutter painter for rendering worlds.

## Features

- Create and step 2D rigid-body simulations with `Engine`.
- Build circles, rectangles, polygons, and trapezoids with `Bodies`.
- Group bodies and constraints with `Composite` and `World`.
- Configure gravity, sleeping, restitution, friction, and collision filters.
- Listen to engine and collision events.
- Render simulations in Flutter with `WorldPainter`.
- Explore a full Flutter demo app in the `example/` directory.

## Installation

Add the package to your Flutter app:

```sh
flutter pub add matter_dart
```

Then import it:

```dart
import 'package:matter_dart/matter_dart.dart';
```

## Quick Start

Create an engine, add a static floor and a falling ball, then advance the simulation:

```dart
import 'package:matter_dart/matter_dart.dart';

void main() {
  final engine = Engine.create(null);

  final ball = Bodies.circle(200, 40, 24, BodyOptions(restitution: 0.8));
  final floor = Bodies.rectangle(
    200,
    400,
    360,
    40,
    BodyOptions(isStatic: true),
  );

  engine.world!.add([ball, floor]);

  for (var i = 0; i < 120; i++) {
    engine.update(1000 / 60, 1);
  }

  print('Ball position: ${ball.position.x}, ${ball.position.y}');
}
```

## Flutter Rendering

Use `WorldPaint` for a lightweight debug view (it wraps `CustomPaint` for you):

```dart
WorldPaint(
  bodies: engine.world!.allBodies(),
  worldWidth: 800,
  worldHeight: 600,
  constraints: engine.world!.allConstraints(),
)
```

Use `WorldPainter` only when you need a `CustomPainter` directly (for example a custom `CustomPaint` setup):

```dart
CustomPaint(
  painter: WorldPainter(
    bodies: engine.world!.allBodies(),
    worldWidth: 800,
    worldHeight: 600,
    constraints: engine.world!.allConstraints(),
  ),
)
```

For a complete UI, see the Flutter demo app in `example/`. It includes multiple interactive scenes such as plinko, a ball pit, Newton's cradle, mixed shapes, chains, and stress demos.

## API Scope

This package follows Matter.js concepts and naming where practical, but it is not intended to be a byte-for-byte port or a guaranteed drop-in replacement. The first stable release focuses on the exported Flutter-friendly simulation surface:

- `Engine`, `Runner`, and engine events
- `Body`, `Bodies`, `Composite`, and `World`
- `Constraint`
- collision detection, pairs, contacts, queries, and resolver utilities
- sleeping support
- geometry helpers such as vectors, bounds, axes, and vertices
- Flutter rendering through `WorldPaint` / `WorldPainter`

## Publishing And Maintenance

Before publishing a release, run:

```sh
flutter test
flutter pub publish --dry-run
```

## License

MIT. See [LICENSE](LICENSE).
