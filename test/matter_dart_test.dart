import 'package:flutter_test/flutter_test.dart';
import 'package:matter_dart/matter_dart.dart';

void main() {
  test('engine advances dynamic bodies under gravity', () {
    final engine = Engine.create(null);
    final ball = Bodies.circle(100, 100, 20, null);
    final startY = ball.position.y;

    engine.world!.add([ball]);
    engine.update(1000 / 60, 1);

    expect(ball.position.y, greaterThan(startY));
  });
}
