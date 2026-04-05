import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/scene_plan.dart';
import 'package:presentation_agent/models/slide_spec.dart';

class SceneShell extends StatelessWidget {
  const SceneShell({
    required this.scene,
    required this.accentColor,
    required this.child,
    super.key,
  });

  final SceneSpec scene;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final background = _background(scene.composition, accentColor);

    return DecoratedBox(
      decoration: BoxDecoration(gradient: background),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _SceneOrb(
              color: accentColor.withValues(alpha: 0.18),
              size: 320,
            ),
          ),
          Positioned(
            left: -80,
            bottom: -120,
            child: _SceneOrb(
              color: PresentationTheme.evidence.withValues(alpha: 0.12),
              size: 260,
            ),
          ),
          Positioned(
            top: 72,
            right: 68,
            child: Text(
              scene.composition.replaceAll('-', ' '),
              style: FlutterDeckTheme.of(context).textTheme.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.16),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 60, 72, 48),
            child: child,
          ),
        ],
      ),
    );
  }

  static Gradient _background(String composition, Color accentColor) {
    switch (composition) {
      case 'signal-columns':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF130E0A), Color(0xFF251C16), Color(0xFF31251C)],
        );
      case 'capsule-wall':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07141A), Color(0xFF11313D), Color(0xFF1C4B46)],
        );
      case 'control-tower':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF08101B), Color(0xFF16203E), Color(0xFF173A54)],
        );
      case 'proof-dashboard':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080E1A), Color(0xFF102535), Color(0xFF163D4A)],
        );
      case 'radar-grid':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF090E1D), Color(0xFF162641), Color(0xFF213246)],
        );
      case 'release-board':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0F18), Color(0xFF112335), Color(0xFF20303B)],
        );
      case 'decision-poster':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF130C10), Color(0xFF301720), Color(0xFF41292F)],
        );
      case 'hero-orbit':
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF09141D),
            accentColor.withValues(alpha: 0.16),
            const Color(0xFF2A3E33),
          ],
        );
    }
  }
}

class SceneIntro extends StatelessWidget {
  const SceneIntro({
    required this.spec,
    required this.accentColor,
    this.centered = false,
    super.key,
  });

  final SlideSpec spec;
  final Color accentColor;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;
    final alignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accentColor.withValues(alpha: 0.28)),
          ),
          child: Text(
            spec.eyebrow ?? spec.kind.name.toUpperCase(),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.bodySmall.copyWith(
              color: accentColor,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          spec.title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.header.copyWith(color: Colors.white),
        ),
        if (spec.headline != null) ...[
          const SizedBox(height: 18),
          Text(
            spec.headline!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.title.copyWith(
              color: Colors.white.withValues(alpha: 0.94),
              height: 1.12,
            ),
          ),
        ],
        if (spec.subtitle != null) ...[
          const SizedBox(height: 16),
          Text(
            spec.subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }
}

class SceneReveal extends StatelessWidget {
  const SceneReveal({
    required this.scene,
    required this.child,
    this.delay = 0,
    super.key,
  });

  final SceneSpec scene;
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        final progress = Interval(
          delay,
          1,
          curve: Curves.easeOutCubic,
        ).transform(value);
        final offset = switch (scene.motionIntent) {
          'glide-left' => Offset(30 * (1 - progress), 0),
          'orbit-pop' => Offset(0, 20 * (1 - progress)),
          'trace-scan' => Offset(0, 28 * (1 - progress)),
          'dashboard-lift' => Offset(0, 24 * (1 - progress)),
          'poster-rise' => Offset(0, 34 * (1 - progress)),
          _ => Offset(0, 22 * (1 - progress)),
        };
        final scale = switch (scene.motionIntent) {
          'orbit-pop' => 0.94 + (progress * 0.06),
          'constellation' => 0.96 + (progress * 0.04),
          _ => 1.0,
        };

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: offset,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({
    required this.title,
    required this.body,
    required this.accentColor,
    this.indexLabel,
    super.key,
  });

  final String title;
  final String body;
  final Color accentColor;
  final String? indexLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PresentationTheme.panelColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (indexLabel != null) ...[
            Text(
              indexLabel!,
              style: textTheme.bodySmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(title, style: textTheme.title.copyWith(color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            body,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneOrb extends StatelessWidget {
  const _SceneOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
