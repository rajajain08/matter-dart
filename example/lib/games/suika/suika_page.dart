import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../../core/world_dimensions.dart';
import 'suika_controller.dart';
import 'suika_tiers.dart';

// ── palette ──────────────────────────────────────────────────────────────────
const Color _kBg       = Color(0xFF0A0B12);
const Color _kSurface  = Color(0xFF12131E);
const Color _kCard     = Color(0xFF181929);
const Color _kAccent   = Color(0xFFF472B6);
const Color _kAccent2  = Color(0xFFA78BFA);
const Color _kWarn     = Color(0xFFFF4D6D);
const Color _kBorder   = Color(0xFF2A2B3D);

// ── fruit emoji ──────────────────────────────────────────────────────────────
const List<String> kFruitEmoji = ['🍒', '🍓', '🍇', '🍊', '🍎', '🍑', '🍍', '🍉'];

// ─────────────────────────────────────────────────────────────────────────────

class SuikaPage extends StatefulWidget {
  const SuikaPage({Key? key}) : super(key: key);

  @override
  State<SuikaPage> createState() => _SuikaPageState();
}

class _SuikaPageState extends State<SuikaPage>
    with SingleTickerProviderStateMixin {
  late final SuikaController _controller;
  late final AnimationController _scoreAnim;
  double? _hoverWorldX;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    _scoreAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenWidth = view.physicalSize.width / view.devicePixelRatio;
    final layout = WorldLayout.forScreenWidth(screenWidth);
    _controller = SuikaController(onTick: _onTick, worldLayout: layout);
    _controller.start();
  }

  void _onTick() {
    if (!mounted) return;
    if (_controller.score != _displayedScore) {
      _displayedScore = _controller.score;
      _scoreAnim.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _scoreAnim.dispose();
    _controller.dispose();
    super.dispose();
  }

  double _worldX(Offset local, Size size) =>
      local.dx / (size.width / _controller.worldLayout.width);

  void _onTapDown(TapDownDetails d, Size size) =>
      setState(() => _hoverWorldX = _worldX(d.localPosition, size));

  void _onTapUp(TapUpDetails d, Size size) =>
      _controller.drop(_worldX(d.localPosition, size));

  void _onPanUpdate(DragUpdateDetails d, Size size) =>
      setState(() => _hoverWorldX = _worldX(d.localPosition, size));

  void _onHover(PointerEvent e, Size size) =>
      setState(() => _hoverWorldX = _worldX(e.localPosition, size));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0E1A), Color(0xFF0A0B12)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                score: _displayedScore,
                scoreAnim: _scoreAnim,
                nextTier: _controller.nextTier,
                previewTier: _controller.previewTier,
                onBack: () => Navigator.of(context).pop(),
                onReset: () {
                  _controller.restart();
                  setState(() => _displayedScore = 0);
                },
              ),
              Expanded(
                child: _Stage(
                  controller: _controller,
                  hoverWorldX: _hoverWorldX,
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onPanUpdate: _onPanUpdate,
                  onHover: _onHover,
                ),
              ),
              _BottomHint(fps: _controller.fps),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int score;
  final AnimationController scoreAnim;
  final int nextTier;
  final int previewTier;
  final VoidCallback onBack;
  final VoidCallback onReset;

  const _TopBar({
    required this.score,
    required this.scoreAnim,
    required this.nextTier,
    required this.previewTier,
    required this.onBack,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 400;
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 8, 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: onBack,
                color: Colors.white70,
              ),
              // title — hide subtitle on very narrow screens to save space
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      colors: [_kAccent, _kAccent2],
                    ).createShader(r),
                    child: Text('Suika',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: narrow ? 17 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      )),
                  ),
                  if (!narrow)
                    Text('merge fruits',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        letterSpacing: 0.5,
                      )),
                ],
              ),
              const Spacer(),
              // CURRENT fruit
              _FruitPreviewCard(label: 'NOW', tierIndex: nextTier, compact: narrow),
              const SizedBox(width: 6),
              // NEXT fruit
              _FruitPreviewCard(label: 'NEXT', tierIndex: previewTier, dim: true, compact: narrow),
              const SizedBox(width: 8),
              // Score
              AnimatedBuilder(
                animation: scoreAnim,
                builder: (_, __) {
                  final scale = 1.0 + 0.18 * math.sin(scoreAnim.value * math.pi);
                  return Transform.scale(
                    scale: scale,
                    child: _ScoreChip(score: score, compact: narrow),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: onReset,
                color: Colors.white54,
                tooltip: 'Restart',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FruitPreviewCard extends StatelessWidget {
  final String label;
  final int tierIndex;
  final bool dim;
  final bool compact;
  const _FruitPreviewCard({
    required this.label,
    required this.tierIndex,
    this.dim = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = tierAt(tierIndex);
    final hPad = compact ? 7.0 : 10.0;
    final emojiSize = compact ? (dim ? 14.0 : 18.0) : (dim ? 18.0 : 22.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 6),
      decoration: BoxDecoration(
        color: dim
            ? Colors.white.withValues(alpha: 0.04)
            : t.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dim
              ? _kBorder
              : t.color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: dim ? 0.3 : 0.55),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            )),
          const SizedBox(height: 3),
          Text(kFruitEmoji[tierIndex],
            style: TextStyle(fontSize: emojiSize)),
          const SizedBox(height: 2),
          Text(t.name,
            style: TextStyle(
              color: dim ? Colors.white38 : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            )),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final int score;
  final bool compact;
  const _ScoreChip({required this.score, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent.withValues(alpha: 0.22),
            _kAccent2.withValues(alpha: 0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _kAccent.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SCORE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
          const SizedBox(height: 2),
          Text('$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 15 : 18,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        ],
      ),
    );
  }
}

// ── Stage ─────────────────────────────────────────────────────────────────────

class _Stage extends StatelessWidget {
  final SuikaController controller;
  final double? hoverWorldX;
  final void Function(TapDownDetails, Size) onTapDown;
  final void Function(TapUpDetails, Size) onTapUp;
  final void Function(DragUpdateDetails, Size) onPanUpdate;
  final void Function(PointerEvent, Size) onHover;

  const _Stage({
    required this.controller,
    required this.hoverWorldX,
    required this.onTapDown,
    required this.onTapUp,
    required this.onPanUpdate,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final layout = controller.worldLayout;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Center(
        child: AspectRatio(
          aspectRatio: layout.width / layout.height,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return _ArenaShell(
                child: MouseRegion(
                  onHover: (e) => onHover(e, size),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => onTapDown(d, size),
                    onTapUp: (d) => onTapUp(d, size),
                    onPanUpdate: (d) => onPanUpdate(d, size),
                    child: Stack(
                      children: [
                        // arena background with dot grid
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ArenaBgPainter(),
                          ),
                        ),
                        // physics bodies
                        Positioned.fill(
                          child: _FruitPainter(
                            bodies: controller.bodies,
                            bodyTier: controller.bodyTierMap,
                            worldWidth: layout.width,
                            worldHeight: layout.height,
                          ),
                        ),
                        // HUD overlay: danger line, preview ghost, drop guide
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _SuikaOverlay(
                                worldWidth: layout.width,
                                worldHeight: layout.height,
                                dangerLineY: controller.dangerLineY,
                                previewX: hoverWorldX,
                                previewTier: controller.nextTier,
                                gameOver: controller.gameOver,
                              ),
                            ),
                          ),
                        ),
                        // game over
                        if (controller.gameOver)
                          Positioned.fill(
                            child: _GameOverOverlay(
                              score: controller.score,
                              onReset: controller.restart,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Glossy rounded container for the arena.
class _ArenaShell extends StatelessWidget {
  final Widget child;
  const _ArenaShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _kAccent.withValues(alpha: 0.12),
            blurRadius: 48,
            spreadRadius: -8,
          ),
          BoxShadow(
            color: _kAccent2.withValues(alpha: 0.08),
            blurRadius: 64,
            spreadRadius: -12,
            offset: const Offset(-10, 20),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: child,
      ),
    );
  }
}

/// Subtle dot-grid background inside the arena.
class _ArenaBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deep dark base
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = _kSurface,
    );

    // Very subtle dot grid
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const spacing = 22.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dot);
      }
    }

    // Top glow (spawn zone)
    final topGrad = ui.Gradient.linear(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height * 0.18),
      [
        _kAccent.withValues(alpha: 0.07),
        Colors.transparent,
      ],
    );
    canvas.drawRect(
      Offset.zero & Size(size.width, size.height * 0.18),
      Paint()..shader = topGrad,
    );
  }

  @override
  bool shouldRepaint(covariant _ArenaBgPainter old) => false;
}

/// Custom painter that renders each fruit as a circle with radial-gradient
/// sheen and an emoji label.
class _FruitPainter extends StatelessWidget {
  final List<Body> bodies;
  final Map<int, int> bodyTier;
  final double worldWidth;
  final double worldHeight;

  const _FruitPainter({
    required this.bodies,
    required this.bodyTier,
    required this.worldWidth,
    required this.worldHeight,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FruitCustomPainter(
        bodies: bodies,
        bodyTier: bodyTier,
        worldWidth: worldWidth,
        worldHeight: worldHeight,
      ),
    );
  }
}

class _FruitCustomPainter extends CustomPainter {
  final List<Body> bodies;
  final Map<int, int> bodyTier;
  final double worldWidth;
  final double worldHeight;

  _FruitCustomPainter({
    required this.bodies,
    required this.bodyTier,
    required this.worldWidth,
    required this.worldHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / worldWidth;
    final sy = size.height / worldHeight;

    for (final body in bodies) {
      final tier = bodyTier[body.id];
      final r = body.circleRadius;

      if (tier != null && r != null) {
        // Fruit body
        _drawFruit(canvas, body, tier, r * sx, sx, sy);
      } else {
        // Static wall — draw as semi-transparent dark slab
        _drawWall(canvas, body, sx, sy);
      }
    }
  }

  void _drawFruit(
    Canvas canvas, Body body, int tier, double pr, double sx, double sy,
  ) {
    final t = tierAt(tier);
    final cx = body.position.x * sx;
    final cy = body.position.y * sy;

    // Outer glow
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = t.color.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(cx, cy), pr * 1.05, glow);

    // Radial fill: lighter highlight top-left, base color, slight shadow bottom
    final grad = ui.Gradient.radial(
      Offset(cx - pr * 0.28, cy - pr * 0.28),
      pr * 1.2,
      [
        Color.lerp(t.color, Colors.white, 0.55)!,
        t.color,
        Color.lerp(t.color, Colors.black, 0.30)!,
      ],
      [0.0, 0.55, 1.0],
    );
    canvas.drawCircle(Offset(cx, cy), pr, Paint()..shader = grad);

    // Specular highlight — small bright spot
    final spec = ui.Gradient.radial(
      Offset(cx - pr * 0.3, cy - pr * 0.32),
      pr * 0.38,
      [
        Colors.white.withValues(alpha: 0.70),
        Colors.white.withValues(alpha: 0.0),
      ],
    );
    canvas.drawCircle(Offset(cx, cy), pr, Paint()..shader = spec);

    // Thin stroke
    canvas.drawCircle(
      Offset(cx, cy),
      pr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.18),
    );

    // Emoji — using a TextPainter
    if (pr > 8) {
      final fontSize = (pr * 1.1).clamp(10.0, 54.0);
      final tp = TextPainter(
        text: TextSpan(
          text: kFruitEmoji[tier],
          style: TextStyle(fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(cx - tp.width / 2, cy - tp.height / 2),
      );
    }
  }

  void _drawWall(Canvas canvas, Body body, double sx, double sy) {
    if (body.vertices.isEmpty) return;
    final path = Path();
    final verts = body.vertices;
    path.moveTo(verts[0].x * sx, verts[0].y * sy);
    for (int i = 1; i < verts.length; i++) {
      path.lineTo(verts[i].x * sx, verts[i].y * sy);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = _kCard,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _kBorder,
    );
  }

  @override
  bool shouldRepaint(covariant _FruitCustomPainter old) => true;
}

// ── Overlay ───────────────────────────────────────────────────────────────────

class _SuikaOverlay extends CustomPainter {
  final double worldWidth;
  final double worldHeight;
  final double dangerLineY;
  final double? previewX;
  final int previewTier;
  final bool gameOver;

  _SuikaOverlay({
    required this.worldWidth,
    required this.worldHeight,
    required this.dangerLineY,
    required this.previewX,
    required this.previewTier,
    required this.gameOver,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / worldWidth;
    final sy = size.height / worldHeight;

    // Danger zone band — soft red gradient
    final dy = dangerLineY * sy;
    final bandGrad = ui.Gradient.linear(
      Offset(0, dy - 12),
      Offset(0, dy + 4),
      [
        Colors.transparent,
        _kWarn.withValues(alpha: 0.14),
        _kWarn.withValues(alpha: 0.06),
        Colors.transparent,
      ],
      [0, 0.4, 0.75, 1.0],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, dy - 12, size.width, 16),
      Paint()..shader = bandGrad,
    );

    // Dashed danger line
    const dashW = 6.0;
    const dashGap = 5.0;
    double x = 0;
    final linePaint = Paint()
      ..color = _kWarn.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    while (x < size.width) {
      canvas.drawLine(Offset(x, dy), Offset(x + dashW, dy), linePaint);
      x += dashW + dashGap;
    }

    // Preview ghost + drop guide
    if (!gameOver && previewX != null) {
      final t = tierAt(previewTier);
      final radius = t.radius * sx;
      final cx = previewX!.clamp(0.0, worldWidth) * sx;
      final cy = (WorldDimensions.innerTop + 24) * sy;

      // Drop guide gradient line
      final guideGrad = ui.Gradient.linear(
        Offset(cx, cy + radius),
        Offset(cx, size.height),
        [
          t.color.withValues(alpha: 0.35),
          Colors.transparent,
        ],
      );
      canvas.drawLine(
        Offset(cx, cy + radius),
        Offset(cx, size.height),
        Paint()
          ..shader = guideGrad
          ..strokeWidth = 1.5,
      );

      // Ghost circle
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()..color = t.color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = t.color.withValues(alpha: 0.85),
      );

      // Mini emoji inside ghost
      final fontSize = (radius * 1.1).clamp(10.0, 54.0);
      final tp = TextPainter(
        text: TextSpan(
          text: kFruitEmoji[previewTier],
          style: TextStyle(fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _SuikaOverlay old) => true;
}

// ── Game Over ─────────────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onReset;
  const _GameOverOverlay({required this.score, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _kBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _kAccent.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🍉', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    colors: [_kAccent, _kAccent2],
                  ).createShader(r),
                  child: const Text(
                    'Game Over',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAccent, _kAccent2],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccent.withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: -4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onReset,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Play Again',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom hint ───────────────────────────────────────────────────────────────

class _BottomHint extends StatelessWidget {
  final double fps;
  const _BottomHint({required this.fps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_rounded,
            size: 13, color: Colors.white24),
          const SizedBox(width: 6),
          const Text(
            'Tap inside arena to drop',
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const Spacer(),
          Text(
            '${fps.toStringAsFixed(0)} fps',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 11,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
