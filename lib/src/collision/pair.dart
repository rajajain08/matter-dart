import 'package:matter_dart/body/body.dart';
import 'package:matter_dart/collision/collision.dart';
import 'package:matter_dart/collision/contact.dart';

class Pair {
  final Collision collision;
  final Body bodyA;
  final Body bodyB;
  final Body parentA;
  final Body parentB;
  final isSensor;
  final DateTime timeStamp;
  final DateTime timeCreated;
  final DateTime timeUpdated;
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
        timeUpdated = timeStamp;
}
