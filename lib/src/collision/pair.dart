import 'dart:math' as math;

import 'package:matter_dart/src/body/body.dart';
import 'package:matter_dart/src/collision/collision.dart';
import 'package:matter_dart/src/collision/contact.dart';

class Pair {
  final Collision collision;
  final Body bodyA;
  final Body bodyB;
  final Body parentA;
  final Body parentB;
  final isSensor;
  final DateTime timeStamp;
  final DateTime timeCreated;
  DateTime timeUpdated;
  final double inverseMass;
  final double friction;
  final double frictionStatic;
  final double restitution;
  final double slop;

  Map<int, Contact> contacts = {};
  List<Contact> activeContacts = [];
  double sepration = 0;
  bool isActive = true;
  bool confirmedActive = true;

  Pair(this.collision, this.timeStamp)
      : bodyA = collision.bodyA,
        bodyB = collision.bodyB,
        parentA = collision.parentA,
        parentB = collision.parentB,
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

  String get id => (bodyA.id < bodyB.id)
      ? "A" + bodyA.id.toString() + "B" + bodyB.id.toString()
      : "A" + bodyB.id.toString() + "B" + bodyA.id.toString();
}
