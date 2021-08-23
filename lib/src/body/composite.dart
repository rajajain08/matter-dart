import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/constraint/constraint.dart';
import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';
import 'package:matter_dart/src/utils/common.dart';

import 'support/models.dart';

/// A composite is a collection of `Matter.Body`, `Matter.Constraint` and other `Matter.Composite` objects.
/// A composite could contain anything from a single body all the way up to a whole world.
class Composite extends MatterObject {
  Composite() : super(type: 'composite');

  late int id;
  String label = 'Composite';
  Composite? parent;
  bool isModified = false;
  List<Body> bodies = <Body>[];
  List<Composite> composites = <Composite>[];
  List<Constraint> constraints = <Constraint>[];

  /// Creates a new composite.
  factory Composite.create(CompositeOptions options) {
    Composite composite = Composite();

    composite
      ..id = options.id ?? ID.instance.nextID
      ..label = options.label ?? composite.label
      ..parent = options.parent ?? composite.parent
      ..isModified = options.isModified ?? composite.isModified
      ..bodies = options.bodies ?? composite.bodies
      ..composites = options.composites ?? composite.composites
      ..constraints = options.constraints ?? composite.constraints;

    return Composite();
  }

  /// Sets the composite's `isModified` flag.
  void setModified(bool isModified, [bool updateParents = false, bool updateChildren = false]) {
    this.isModified = isModified;

    if (updateParents && this.parent != null) {
      this.parent!.setModified(isModified, updateParents, updateChildren);
    }

    if (updateChildren) {
      for (int index = 0; index < this.composites.length; index++) {
        Composite childComposite = this.composites[index];
        childComposite.setModified(isModified, updateParents, updateChildren);
      }
    }
  }

  /// Generic single or multi-add function. Adds a single or an array of body(s), constraint(s)
  /// or composite(s) to the given composite.
  void add(List<MatterObject> objects) {
    for (int index = 0; index < objects.length; index++) {
      MatterObject object = objects[index];

      switch (object.type) {
        case 'body':
          final Body body = object as Body;
          // skip adding compound parts
          if (body.parent != body) break;
          addBody(object);
          break;

        case 'constraint':
          addConstraint(object as Constraint);
          break;

        case 'composite':
          addComposite(object as Composite);
          break;

        case 'mouseConstraint':
          break;
        // TODO:
      }
    }
  }

  /// Generic remove function. Removes one or many body(s), constraint(s) or a composite(s)
  /// to the given composite. Optionally searching its children recursively.
  void remove(List<MatterObject> objects, [bool deep = false]) {
    for (int index = 0; index < objects.length; index++) {
      MatterObject object = objects[index];

      switch (object.type) {
        case 'body':
          removeBody(object as Body, deep);
          break;

        case 'constraint':
          removeConstraint(object as Constraint, deep);
          break;

        case 'composite':
          removeComposite(object as Composite, deep);
          break;

        case 'mouseConstraint':
          // TODO:
          break;
      }
    }
  }

  /// Adds a composite to the given composite.
  void addComposite(Composite composite) {
    this.composites.add(composite);
    composite.parent = this;
    this.setModified(true, true, false);
  }

  /// Removes a composite from the given composite, and optionally searching its children recursively.
  void removeComposite(Composite composite, [bool deep = false]) {
    int position = this.composites.indexWhere((item) => item.id == composite.id);
    if (position != -1) {
      removeCompositeAt(position);
      setModified(true, true, false);
    }

    if (deep) {
      for (int index = 0; index < this.composites.length; index++) {
        removeComposite(this.composites[index], true);
      }
    }
  }

  /// Removes a composite from the given composite.
  void removeCompositeAt(int position) {
    this.composites.removeAt(position);
    setModified(true, true, false);
  }

  /// Adds a body to this composite.
  void addBody(Body body) {
    this.bodies.add(body);
    setModified(true, true, false);
  }

  /// Removes a body from this composite.
  void removeBody(Body body, [bool deep = false]) {
    int position = this.bodies.indexWhere((item) => item.id == body.id);
    if (position != -1) {
      removeBodyAt(position);
      setModified(true, true, false);
    }

    if (deep) {
      for (int index = 0; index < this.composites.length; index++) {
        this.composites[index].removeBody(body, true);
      }
    }
  }

  /// Removes a body from this composite.
  void removeBodyAt(int position) {
    this.bodies.removeAt(position);
    setModified(true, true, false);
  }

  /// Adds a constraint to this composite.
  void addConstraint(Constraint constraint) {
    this.constraints.add(constraint);
    setModified(true, true, false);
  }

  /// Removes a constraint from this composite.
  void removeConstraint(Constraint constraint, [bool deep = false]) {
    int position = this.constraints.indexWhere((item) => item.id == constraint.id);
    if (position != -1) {
      removeConstraintAt(position);
    }

    if (deep) {
      for (int index = 0; index < this.composites.length; index++) {
        this.composites[index].removeConstraint(constraint, true);
      }
    }
  }

  /// Removes a constraint from this composite.
  void removeConstraintAt(int position) {
    this.constraints.removeAt(position);
    setModified(true, true, false);
  }

  /// Removes all bodies, constraints and composites from the given composite.
  /// Optionally clearing its children recursively.
  void clear(keepStatic, [bool deep = false]) {
    if (deep) {
      for (int index = 0; index < this.composites.length; index++) {
        this.composites[index].clear(keepStatic, true);
      }
    }

    if (keepStatic) {
      this.bodies.retainWhere((body) => body.isStatic);
    } else {
      this.bodies.clear();
    }

    this.constraints.clear();
    this.composites.clear();
    setModified(true, true, false);
  }

  /// Returns all bodies in the given composite, including all bodies in its children, recursively.
  List<Body> allBodies() {
    List<Body> _allBodies = [];

    for (int index = 0; index < this.composites.length; index++) {
      _allBodies.addAll(this.composites[index].allBodies());
    }

    return _allBodies;
  }

  /// Returns all constraints in the given composite, including all constraints in its children, recursively.
  List<Constraint> allConstraints() {
    List<Constraint> allConstraints = [];

    for (int index = 0; index < this.composites.length; index++) {
      allConstraints.addAll(this.composites[index].allConstraints());
    }

    return allConstraints;
  }

  /// Returns all composites in the given composite, including all composites in its children, recursively.
  List<Composite> allComposites() {
    List<Composite> allComposites = [];

    for (int index = 0; index < this.composites.length; index++) {
      allComposites.addAll(this.composites[index].allComposites());
    }

    return allComposites;
  }

  /// Searches the composite recursively for an object matching the type and id supplied, null if not found.
  /// `Type` and `T` must match.
  T? get<T>(int id, String type) {
    switch (type) {
      case 'body':
        final objects = allBodies();
        int index = objects.indexWhere((body) => body.id == id);
        return index == -1 ? null : objects[index] as T;

      case 'constraint':
        final objects = allConstraints();
        int index = objects.indexWhere((constraint) => constraint.id == id);
        return index == -1 ? null : objects[index] as T;

      case 'composite':
        final objects = allComposites();
        int index = objects.indexWhere((composite) => composite.id == id);
        return index == -1 ? null : objects[index] as T;

      default:
        return null;
    }
  }

  /// Moves the given object(s) from `this` to `composite` (equal to a remove followed by an add).
  void move(List<MatterObject> objects, Composite composite) {
    this.remove(objects);
    composite.add(objects);
  }

  /// Assigns new ids for all objects in the composite, recursively.
  void rebase() {
    List<MatterObject> objects = <MatterObject>[]
      ..addAll(allBodies())
      ..addAll(allConstraints())
      ..addAll(allComposites());

    for (int index = 0; index < objects.length; index++) {
      switch (objects[index].type) {
        case 'body':
          (objects[index] as Body).id = ID.instance.nextID;
          break;
        case 'constraint':
          (objects[index] as Constraint).id = ID.instance.nextID;
          break;
        case 'composite':
          (objects[index] as Composite).id = ID.instance.nextID;
          break;
      }
    }

    setModified(true, true, false);
  }

  /// Translates all children in the composite by a given vector relative to their current positions,
  /// without imparting any velocity.
  void translate(Vector translation, [bool recursive = true]) {
    final _allbodies = recursive ? allBodies() : bodies;

    for (int index = 0; index < _allbodies.length; index++) {
      _allbodies[index].translate(translation);
    }

    setModified(true, true, false);
  }

  /// Rotates all children in the composite by a given angle about the given point,
  /// without imparting any angular velocity.
  void rotate(double rotation, Vector point, [bool recursive = true]) {
    double cos = math.cos(rotation), sin = math.sin(rotation);
    List<Body> _bodies = recursive ? allBodies() : bodies;

    for (int index = 0; index < _bodies.length; index++) {
      Body body = _bodies[index];
      double dx = body.position.x - point.x;
      double dy = body.position.y - point.y;

      body.setPosition(Vector(point.x + (dx * cos - dy * sin), point.y + (dx * sin + dy * cos)));
      body.rotate(rotation);
    }

    setModified(true, true, false);
  }

  /// Scales all children in the composite, including updating physical properties (mass, area, axes, inertia)
  /// from a world-space point.
  void scale(double scaleX, double scaleY, Vector point, [bool recursive = true]) {
    List<Body> _bodies = recursive ? allBodies() : bodies;

    for (int index = 0; index < _bodies.length; index++) {
      Body body = _bodies[index];
      double dx = body.position.x - point.x;
      double dy = body.position.y - point.y;

      body.setPosition(Vector(point.x + dx * scaleX, point.y + dy * scaleY));
      body.scale(scaleX, scaleY);
    }

    setModified(true, true, false);
  }

  /// Returns the union of the bounds of all of the composite's bodies.
  Bounds bounds() {
    final _bodies = allBodies();
    List<Vertex> vertices = <Vertex>[];

    for (int index = 0; index < _bodies.length; index++) {
      Body body = _bodies[index];
      final min = body.bounds!.min;
      final max = body.bounds!.max;
      vertices.addAll([
        Vertex(x: min.dx, y: min.dy, index: index),
        Vertex(x: max.dx, y: max.dy, index: index),
      ]);
    }

    return Bounds.fromVertices(vertices);
  }
}
