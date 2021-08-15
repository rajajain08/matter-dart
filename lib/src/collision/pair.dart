import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/collision/contact.dart';
import 'package:matter_dart/src/geometry/vector.dart';
import 'package:matter_dart/src/geometry/vertices.dart';

class Pair {
  Collision collision;
  final Body bodyA;
  final Body bodyB;
  final Body parentA;
  final Body parentB;
  final isSensor;
  final DateTime timeStamp;
  final DateTime timeCreated;
  DateTime timeUpdated;
  double inverseMass;
  double friction;
  final double frictionStatic;
  double restitution;
  double slop;
  double separation;

  Map<String, Contact> contacts = {};
  List<Contact> activeContacts = [];
  double sepration = 0;
  bool isActive = true;
  bool confirmedActive = true;

  Pair(this.collision, this.timeStamp)
      : bodyA = collision.bodyA,
        bodyB = collision.bodyB,
        parentA = collision.parentA,
        parentB = collision.parentB,
        separation = 0.0,
        isSensor = collision.bodyA.isSensor || collision.bodyB.isSensor,
        timeCreated = timeStamp,
        timeUpdated = timeStamp,
        inverseMass = collision.parentA.inverseMass + collision.parentB.inverseMass,
        friction = math.min(collision.parentA.friction, collision.parentB.friction),
        frictionStatic = math.max(collision.parentA.frictionStatic, collision.parentB.frictionStatic),
        restitution = math.max(collision.parentA.restitution, collision.parentB.restitution),
        slop = math.max(collision.parentA.slop, collision.parentB.slop);

  void setActive(bool isActive, DateTime timeStamp) {
    if (isActive) {
      isActive = true;
      timeUpdated = timeStamp;
    } else {
      isActive = false;
      activeContacts.length = 0;
    }
  }

  void update(Collision updatedCollision, DateTime timestamp) {
    collision = updatedCollision;
    inverseMass = parentA.inverseMass + parentB.inverseMass;
    friction = math.max(parentA.frictionStatic, parentB.frictionStatic);
    restitution = math.max(parentA.restitution, parentB.restitution);
    slop = math.max(parentA.slop, parentB.slop);
    activeContacts.length = 0;
    List<Vector> supports = updatedCollision.supports;

    if (collision.collided) {
      for (var i = 0; i < supports.length; i++) {
        var support = supports[i], contactId = Contact(support as Vertex).id, contact = contacts[contactId];

        if (contact != null) {
          activeContacts.add(contact);
        } else {
          activeContacts.add((contacts[contactId] = Contact(support)));
        }
      }

      separation = collision.depth.toDouble();
      setActive(true, timestamp);
    } else {
      if (isActive == true) setActive(false, timestamp);
    }
  }

  String get id => (bodyA.id < bodyB.id)
      ? "A" + bodyA.id.toString() + "B" + bodyB.id.toString()
      : "A" + bodyB.id.toString() + "B" + bodyA.id.toString();
}
