import '../core/demo.dart';
import 'ball_pit_demo.dart';
import 'chain_demo.dart';
import 'mixed_shapes_demo.dart';
import 'mixed_soup_demo.dart';
import 'newtons_cradle_demo.dart';
import 'plinko_demo.dart';
import 'pyramid_demo.dart';
import 'restitution_demo.dart';
import 'stress_demo.dart';
import 'wrecking_ball_demo.dart';

/// Single source of truth for the demo list. Adding a demo here is the only
/// change required to surface it in the home screen.
final List<Demo> demoRegistry = <Demo>[
  mixedShapesDemo,
  pyramidDemo,
  restitutionDemo,
  chainDemo,
  stressDemo,
  newtonsCradleDemo,
  plinkoDemo,
  wreckingBallDemo,
  mixedSoupDemo,
  ballPitDemo,
];
