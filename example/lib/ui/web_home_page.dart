import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../demos/demo_registry.dart';
import '../games/suika/suika_page.dart';
import 'project_about.dart';
import 'demo_preview_card.dart';
import 'home_physics_background.dart';

/// Web-first landing: wide layout, pinned nav, responsive grid, scroll affordances.
class WebDemoHomePage extends StatefulWidget {
  const WebDemoHomePage({Key? key}) : super(key: key);

  @override
  State<WebDemoHomePage> createState() => _WebDemoHomePageState();
}

class _WebDemoHomePageState extends State<WebDemoHomePage> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _demosKey = GlobalKey();
  final HomePhysicsController _physics = HomePhysicsController();
  final CardRectRegistry _cardRects = CardRectRegistry();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openRepo(BuildContext context) {
    final uri = Uri.parse(ProjectAbout.repoUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication).then((ok) {
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the repository link')),
        );
      }
    });
  }

  void _scrollToDemos() {
    final ctx = _demosKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  int _columnsForWidth(double w) {
    if (w >= 1200) return 4;
    if (w >= 880) return 3;
    if (w >= 520) return 2;
    return 1;
  }

  double _horizontalPad(double w) {
    if (w >= 1100) return 40;
    if (w >= 600) return 28;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F1020),
                    const Color(0xFF0B0C14),
                    const Color(0xFF12182A),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.85, -0.35),
                  radius: 1.15,
                  colors: [
                    const Color(0xFF60A5FA).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0B0C14).withValues(alpha: 0.35),
                      const Color(0xFF0B0C14).withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: w >= 700,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                    PointerDeviceKind.stylus,
                  },
                ),
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPad(w),
                            media.padding.top + 16,
                            _horizontalPad(w),
                            8,
                          ),
                          child: _WebTopBar(
                            onDemos: _scrollToDemos,
                            onGitHub: () => _openRepo(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: _horizontalPad(w),
                            vertical: 12,
                          ),
                          child: _WebHero(
                            width: w,
                            onTryDemos: _scrollToDemos,
                            onGitHub: () => _openRepo(context),
                            onDropShapes: () => _physics.spawnBurst(count: 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPad(w),
                            8,
                            _horizontalPad(w),
                            8,
                          ),
                          child: _WebSuikaCta(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SuikaPage()),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: Padding(
                          key: _demosKey,
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPad(w),
                            8,
                            _horizontalPad(w),
                            12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF60A5FA),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Interactive demos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Click a card to run in-page — drag bodies. Demos use a wide playfield on web.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      _horizontalPad(w),
                      0,
                      _horizontalPad(w),
                      32,
                    ),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final cw = constraints.crossAxisExtent;
                        final cols = _columnsForWidth(cw);
                        return SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: cols >= 3 ? 1.02 : 0.98,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => DemoPreviewCard(
                              demo: demoRegistry[i],
                              rectSink: _cardRects,
                            ),
                            childCount: demoRegistry.length,
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            _horizontalPad(w),
                            8,
                            _horizontalPad(w),
                            56,
                          ),
                          child: _WebFooter(onGitHub: () => _openRepo(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          Positioned.fill(
            child: HomePhysicsBackground(
              controller: _physics,
              cardRects: _cardRects,
              maxBodies: w < 600 ? 8 : 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _WebTopBar extends StatelessWidget {
  final VoidCallback onDemos;
  final VoidCallback onGitHub;

  const _WebTopBar({
    required this.onDemos,
    required this.onGitHub,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 560;
        final logo = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF60A5FA), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.science_rounded, color: Colors.white, size: 24),
        );
        final titleBlock = Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      ProjectAbout.repoName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60A5FA).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'v${ProjectAbout.version}',
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                ProjectAbout.tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        );
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(72, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                foregroundColor: const Color(0xFF93C5FD),
              ),
              onPressed: onDemos,
              child: const Text('Demos'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(108, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
              ),
              onPressed: onGitHub,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('GitHub'),
            ),
          ],
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  logo,
                  const SizedBox(width: 14),
                  titleBlock,
                ],
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            logo,
            const SizedBox(width: 14),
            titleBlock,
            actions,
          ],
        );
      },
    );
  }
}

class _WebHero extends StatelessWidget {
  final double width;
  final VoidCallback onTryDemos;
  final VoidCallback onGitHub;
  final VoidCallback onDropShapes;

  const _WebHero({
    required this.width,
    required this.onTryDemos,
    required this.onGitHub,
    required this.onDropShapes,
  });

  @override
  Widget build(BuildContext context) {
    final wide = width >= 960;
    final titleSize = wide ? 30.0 : 24.0;

    final headline = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Rigid-body physics in the browser',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${ProjectAbout.repoName} — Dart port of Matter.js for Flutter Web.',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          maxLines: wide ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: wide ? 14 : 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: onTryDemos,
              style: FilledButton.styleFrom(
                minimumSize: const Size(124, 40),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                backgroundColor: const Color(0xFF60A5FA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Browse demos'),
            ),
            OutlinedButton(
              onPressed: onGitHub,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(118, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
              ),
              child: const Text('View source'),
            ),
            TextButton.icon(
              onPressed: onDropShapes,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Drop shapes'),
              style: TextButton.styleFrom(
                minimumSize: const Size(124, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                foregroundColor: const Color(0xFF93C5FD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _MetaChip(
              icon: Icons.person_rounded,
              label: ProjectAbout.authorName,
              sub: '@${ProjectAbout.authorHandle}',
            ),
            const _MetaChip(
              icon: Icons.layers_rounded,
              label: 'Flutter Web',
              sub: 'Runs in the browser',
            ),
          ],
        ),
      ],
    );

    final showcase = _HeroShowcase(width: width);

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 12, child: headline),
          const SizedBox(width: 20),
          Expanded(flex: 8, child: showcase),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        headline,
        const SizedBox(height: 16),
        showcase,
      ],
    );
  }
}

class _HeroShowcase extends StatelessWidget {
  final double width;

  const _HeroShowcase({required this.width});

  @override
  Widget build(BuildContext context) {
    final icons = demoRegistry.take(6).map((d) => d.icon).toList();
    final wide = width >= 960;
    final h = wide ? 118.0 : 108.0;

    return IgnorePointer(
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B).withValues(alpha: 0.72),
                const Color(0xFF0F172A).withValues(alpha: 0.88),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.85, -0.4),
                        radius: 1.1,
                        colors: [
                          const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Included demos',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Icons only — open a card below.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.end,
                        children: [
                          for (final icon in icons)
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: Icon(icon, color: Colors.white.withValues(alpha: 0.72), size: 16),
                            ),
                        ],
                      ),
                    ],
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.55)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WebFooter extends StatelessWidget {
  final VoidCallback onGitHub;

  const _WebFooter({required this.onGitHub});

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 13,
      height: 1.5,
    );
    return Column(
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 20),
        SelectableText(
          'matter_dart example — open source. Built with Flutter Web.',
          style: muted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(120, 44),
            foregroundColor: const Color(0xFF93C5FD),
          ),
          onPressed: onGitHub,
          child: const Text('Open repository on GitHub'),
        ),
      ],
    );
  }
}

class _WebSuikaCta extends StatelessWidget {
  final VoidCallback onTap;
  const _WebSuikaCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF472B6), Color(0xFFFB7185)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF472B6).withValues(alpha: 0.35),
                blurRadius: 36,
                spreadRadius: -10,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bubble_chart_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Play Suika — built on matter_dart',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 3),
                    Text('Drop fruits, merge same tiers, chase the melon.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
