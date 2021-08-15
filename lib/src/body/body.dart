import 'package:matter_dart/src/geometry/bounds.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

class Body {
  int id = 0;
  bool isSensor = false;
  double inverseMass = 0;
  double friction = 1;
  double frictionStatic = 1;
  double restitution = 1;
  double slop = 0.05;
  bool isSleeping = false;
  int totalContacts = 0;
  Vector position = Vector(0, 0);
  Vector? positionPrev;
  Vector positionImpulse = Vector(0, 0);
  double angle = 0;
  double anglePrev = 0;
  double inertia = 0;
  double inverseInertia = 0;
  double angularVelocity = 0;

  // Indicates whether a body is considered static. A static body can never change position or angle and is completely fixed.
  bool isStatic = false;

  // An array of bodies that make up this body.
  List<Body> parts = <Body>[];

  // TODO: Default value should be resolved from path.
  List<Vertex> vertices = <Vertex>[];

  // Defines the AABB region for the body.
  Bounds? bounds;

  // The current velocity of the body after the last `Body.update`.
  Vector velocity = Vector(0, 0);
}
