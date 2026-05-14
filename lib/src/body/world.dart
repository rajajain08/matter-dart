import 'package:matter_dart/src/body/composite.dart';
import 'package:matter_dart/src/body/support/models.dart';

/// `World` is the top-level [Composite] holding everything in a simulation.
///
/// Matches matter-js semantics: `Matter.World` is an alias for `Matter.Composite`.
/// Call `world.add(...)`, `world.remove(...)`, `world.clear(...)` like any Composite.
class World extends Composite {
  World() : super();

  factory World.create([CompositeOptions? options]) {
    final composite = Composite.create(options ?? CompositeOptions(label: 'World'));
    return World()
      ..id = composite.id
      ..label = composite.label
      ..parent = composite.parent
      ..isModified = composite.isModified
      ..bodies = composite.bodies
      ..composites = composite.composites
      ..constraints = composite.constraints;
  }
}
