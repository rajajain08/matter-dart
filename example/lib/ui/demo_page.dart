import 'package:flutter/material.dart';
import 'package:matter_dart/matter_dart.dart';

import '../core/demo.dart';
import '../core/demo_controller.dart';
import '../core/pointer_drag.dart';
import '../core/world_dimensions.dart';

class DemoPage extends StatefulWidget {
  final Demo demo;
  const DemoPage({Key? key, required this.demo}) : super(key: key);

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late final DemoController _controller;
  late final PointerDrag _drag;

  @override
  void initState() {
    super.initState();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenWidth = view.physicalSize.width / view.devicePixelRatio;
    final layout = WorldLayout.forScreenWidth(screenWidth);
    _controller = DemoController(
      demo: widget.demo,
      onTick: _onTick,
      worldLayout: layout,
    );
    _drag = PointerDrag(
      worldGetter: () => _controller.world,
      layout: layout,
    );
    _controller.start();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _reset() {
    _drag.onEnd();
    _controller.reset();
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.demo.accent;
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.6,
              colors: [
                accent.withValues(alpha: 0.10),
                const Color(0xFF0B0C14),
              ],
            ),
          ),
          child: Column(
            children: [
              _TopBar(demo: widget.demo, onReset: _reset),
              Expanded(child: _Stage(controller: _controller, drag: _drag, accent: accent)),
              _BottomBar(controller: _controller, accent: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final Demo demo;
  final VoidCallback onReset;
  const _TopBar({required this.demo, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: Colors.white,
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: demo.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(demo.icon, color: demo.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  demo.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  demo.description,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onReset,
            color: Colors.white,
            tooltip: 'Reset',
          ),
        ],
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  final DemoController controller;
  final PointerDrag drag;
  final Color accent;
  const _Stage({required this.controller, required this.drag, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.worldLayout.width / controller.worldLayout.height,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: -8,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: GestureDetector(
                    onPanStart: (d) => drag.onStart(d.localPosition, size),
                    onPanUpdate: (d) => drag.onUpdate(d.localPosition, size),
                    onPanEnd: (_) => drag.onEnd(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF14151F),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: WorldPaint(
                        bodies: controller.bodies,
                        constraints: [
                          ...controller.constraints,
                          if (drag.current != null) drag.current!,
                        ],
                        highlightedBody: drag.draggedBody,
                        worldWidth: controller.worldLayout.width,
                        worldHeight: controller.worldLayout.height,
                        highlightColor: accent,
                        constraintColor: accent,
                      ),
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

class _BottomBar extends StatelessWidget {
  final DemoController controller;
  final Color accent;
  const _BottomBar({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          _Stat(label: 'BODIES', value: '${controller.bodyCount}', accent: accent),
          const SizedBox(width: 8),
          _Stat(label: 'FPS', value: controller.fps.toStringAsFixed(0), accent: accent),
          const Spacer(),
          _Hint(accent: accent),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _Stat({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final Color accent;
  const _Hint({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.touch_app_rounded, size: 14, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(width: 6),
        Text(
          'drag to interact',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
        ),
      ],
    );
  }
}
