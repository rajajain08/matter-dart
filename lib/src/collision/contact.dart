import 'package:matter_dart/src/geometry/vertices.dart';

class Contact {
  final Vertex vertex;
  double normalImpulse = 0;
  double tangentImpulse = 0;
  Contact(this.vertex);
  String get id => vertex.body.id.toString() + '_' + vertex.index.toString();
}
