<div align="center">

# matter_dart

**A Flutter-friendly 2D rigid-body physics engine inspired by [Matter.js](https://brm.io/matter-js/), written in Dart.**

[![pub package](https://img.shields.io/pub/v/matter_dart.svg)](https://pub.dev/packages/matter_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Live Demo](https://img.shields.io/badge/demo-matter--dart.vercel.app-0B0C14?logo=vercel&logoColor=white)](https://matter-dart.vercel.app)
[![Buy Me A Coffee](https://img.shields.io/badge/buy%20me%20a%20coffee-rajajain08-FFDD00?logo=buymeacoffee&logoColor=000)](https://buymeacoffee.com/rajajain08)

[**Live Demo**](https://matter-dart.vercel.app) · [pub.dev](https://pub.dev/packages/matter_dart) · [Issues](https://github.com/rajajain08/matter-dart/issues) · [Contributing](#contributing)

</div>

---

`matter_dart` gives Flutter apps a rigid-body simulation toolkit for interactive demos, games, prototypes, and physics-driven UI. It includes engines, bodies, composites, constraints, collision handling, geometry helpers, and an optional Flutter painter for rendering worlds.

## Live Demo

Try the full interactive demo gallery in your browser — ten built-in scenes you can play with right now:

> **[matter-dart.vercel.app](https://matter-dart.vercel.app)**

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Flutter Rendering](#flutter-rendering)
- [Demos](#demos)
- [API Scope](#api-scope)
- [Publishing And Maintenance](#publishing-and-maintenance)
- [Contributing](#contributing)
- [Support](#support)
- [Contributors](#contributors)
- [License](#license)

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

For a complete UI, see the Flutter demo app in `example/`.

## Demos

The example app ships ten interactive scenes — each one is a self-contained `Demo` registered in [`example/lib/demos/demo_registry.dart`](example/lib/demos/demo_registry.dart). Use any of them as a starting template for your own scene.

| Demo | What it shows |
|------|---------------|
| Ball Pit | Circles in a bounded enclosure with friction |
| Plinko | Fixed pegs, falling discs, scoring ramps |
| Newton's Cradle | A row of constrained pendula |
| Wrecking Ball | Constraint-driven destruction |
| Pyramid | Stacked rectangles, stability under gravity |
| Chain | Soft-link constraints |
| Mixed Shapes | Polygons of varying density |
| Mixed Soup | Heterogeneous body soup |
| Restitution | Bounce coefficients across materials |
| Stress | Many bodies, performance test |

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

## Contributing

`matter_dart` is open source and contributions are very welcome — bug reports, feature ideas, demos, docs, and pull requests all help.

**Ways to help:**

- **Found a bug?** [Open an issue](https://github.com/rajajain08/matter-dart/issues/new) and describe what you expected vs. what happened. A minimal repro snippet helps a lot.
- **Have an idea or feature request?** [Start a discussion](https://github.com/rajajain08/matter-dart/issues/new) with the `enhancement` label.
- **Want to contribute code?** Fork the repo, branch off `main`, and open a Pull Request. Please run `flutter test` and `flutter analyze` before pushing, and add tests where reasonable.
- **Want to add a demo?** Drop a new file in `example/lib/demos/`, register it in `demo_registry.dart`, and open a PR. New scene ideas (cars, pegs, soft bodies, particle systems, etc.) are especially welcome.

There's no formal CLA. Be kind in code review, assume good intent, and ship.

## Support

If `matter_dart` has been useful in your project, you can support the author here:

<a href="https://buymeacoffee.com/rajajain08" target="_blank"><img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=rajajain08&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee" height="48"/></a>

Or just star the repo — it genuinely helps with visibility.

## Contributors

Thanks to everyone who has contributed to `matter_dart`:

<a href="https://github.com/rajajain08/matter-dart/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=rajajain08/matter-dart" alt="Contributors" />
</a>

## License

MIT. See [LICENSE](LICENSE).
