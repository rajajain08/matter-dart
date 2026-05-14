/// Logical playfield for demos (walls, floor, inner bounds).
///
/// Mobile uses a tall phone aspect ratio; [WorldLayout.web] widens the field
/// so stacks and gadgets use horizontal space on desktop web.
class WorldLayout {
  const WorldLayout({
    required this.width,
    required this.height,
    required this.wallThickness,
    required this.groundThickness,
  });

  /// Default layout: phone-style portrait field (used on native mobile).
  static const WorldLayout mobile = WorldLayout(
    width: 400,
    height: 700,
    wallThickness: 40,
    groundThickness: 80,
  );

  /// Wider field, same vertical size as mobile so gravity demos feel familiar.
  static const WorldLayout web = WorldLayout(
    width: 1000,
    height: 700,
    wallThickness: 40,
    groundThickness: 80,
  );

  final double width;
  final double height;
  final double wallThickness;
  final double groundThickness;

  double get innerLeft => wallThickness;
  double get innerRight => width - wallThickness;
  double get innerTop => wallThickness;
  double get innerBottom => height - groundThickness;
  double get innerWidth => innerRight - innerLeft;
  double get innerHeight => innerBottom - innerTop;
  double get innerArea => innerWidth * innerHeight;

  /// Reference inner area for [mobile] — for scaling crowd sizes on wide layouts.
  static const double _mobileInnerArea = 320.0 * 580.0;

  /// Scales a body count tuned for [mobile] to the current layout, capped for web perf.
  int scaledBodyCount(int nominal, {int max = 240}) {
    if (nominal <= 0) return 0;
    final ratio = innerArea / _mobileInnerArea;
    final scaled = (nominal * ratio).round();
    return scaled < nominal ? nominal : (scaled > max ? max : scaled);
  }
}

/// Active world layout for the current demo session.
///
/// [DemoController] binds this for its lifetime; demos read static getters below.
class WorldDimensions {
  WorldDimensions._();

  static WorldLayout _active = WorldLayout.mobile;

  /// Swaps the layout used by [width], [innerLeft], etc. Demos should only run
  /// while a controller owns the binding.
  static void bind(WorldLayout layout) {
    _active = layout;
  }

  static void resetBinding() {
    _active = WorldLayout.mobile;
  }

  static double get width => _active.width;
  static double get height => _active.height;
  static double get wallThickness => _active.wallThickness;
  static double get groundThickness => _active.groundThickness;
  static double get innerLeft => _active.innerLeft;
  static double get innerRight => _active.innerRight;
  static double get innerTop => _active.innerTop;
  static double get innerBottom => _active.innerBottom;
  static double get innerWidth => _active.innerWidth;
  static double get innerHeight => _active.innerHeight;

  static int scaledBodyCount(int nominal, {int max = 240}) =>
      _active.scaledBodyCount(nominal, max: max);
}
