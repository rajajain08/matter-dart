import 'package:flutter/material.dart';

import '../core/demo.dart';
import 'demo_page.dart';
import 'home_physics_background.dart';

/// Tile used on the home / web landing grids to open a [DemoPage].
class DemoPreviewCard extends StatefulWidget {
  final Demo demo;
  final CardRectRegistry rectSink;

  const DemoPreviewCard({
    Key? key,
    required this.demo,
    required this.rectSink,
  }) : super(key: key);

  @override
  State<DemoPreviewCard> createState() => _DemoPreviewCardState();
}

class _DemoPreviewCardState extends State<DemoPreviewCard> {
  bool _hover = false;
  final GlobalKey _key = GlobalKey();
  late final int _id = identityHashCode(this);

  void _publishRect() {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    widget.rectSink.update(_id, topLeft & box.size);
  }

  @override
  void dispose() {
    widget.rectSink.remove(_id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _publishRect());
    final accent = widget.demo.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _hover ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DemoPage(demo: widget.demo)),
          ),
          child: AnimatedContainer(
            key: _key,
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accent.withValues(alpha: _hover ? 0.22 : 0.16),
                  accent.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accent.withValues(alpha: _hover ? 0.5 : 0.25),
                width: 1,
              ),
              boxShadow: _hover
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 22,
                        spreadRadius: -4,
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.demo.icon, color: accent, size: 20),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.demo.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.demo.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
