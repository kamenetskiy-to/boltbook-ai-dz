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
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(gradient: background),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScenePatternPainter(
                  composition: scene.composition,
                  accentColor: accentColor,
                ),
              ),
            ),
          ),
          Positioned(
            top: -140,
            right: -110,
            child: _SceneOrb(
              color: accentColor.withValues(alpha: 0.18),
              size: 360,
            ),
          ),
          Positioned(
            left: -100,
            bottom: -150,
            child: _SceneOrb(
              color: PresentationTheme.evidence.withValues(alpha: 0.12),
              size: 300,
            ),
          ),
          Positioned(
            top: 72,
            right: 68,
            child: Text(
              scene.composition.replaceAll('-', ' '),
              style: textTheme.bodySmall.copyWith(
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
      case 'signal-stage':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1319), Color(0xFF123E3B), Color(0xFF365E4E)],
        );
      case 'tension-bridge':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17100A), Color(0xFF2D1B14), Color(0xFF4B2F23)],
        );
      case 'relay-diagram':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF091118), Color(0xFF0F293B), Color(0xFF155B52)],
        );
      case 'editorial-runway':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0F1D), Color(0xFF182342), Color(0xFF234E73)],
        );
      case 'audit-wall':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07131C), Color(0xFF11303E), Color(0xFF1E4855)],
        );
      case 'constellation-ring':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0D1D), Color(0xFF1A2045), Color(0xFF263252)],
        );
      case 'proof-mosaic':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1018), Color(0xFF13263C), Color(0xFF264249)],
        );
      case 'closing-manifesto':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF170D12), Color(0xFF351822), Color(0xFF573741)],
        );
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
    this.compact = false,
    super.key,
  });

  final SlideSpec spec;
  final Color accentColor;
  final bool centered;
  final bool compact;

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
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 8 : 10,
          ),
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
        SizedBox(height: compact ? 14 : 18),
        Text(
          spec.title,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: textTheme.header.copyWith(
            color: Colors.white,
            fontSize: compact ? 26 : null,
            height: compact ? 1.08 : null,
          ),
        ),
        if (spec.headline != null) ...[
          SizedBox(height: compact ? 14 : 18),
          Text(
            spec.headline!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.title.copyWith(
              color: Colors.white.withValues(alpha: 0.94),
              fontSize: compact ? 20 : null,
              height: compact ? 1.18 : 1.12,
            ),
          ),
        ],
        if (spec.subtitle != null) ...[
          SizedBox(height: compact ? 12 : 16),
          Text(
            spec.subtitle!,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: textTheme.bodyLarge.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: compact ? 18 : null,
              height: compact ? 1.24 : null,
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
          'scanline' => Offset(18 * (1 - progress), 0),
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

class _ScenePatternPainter extends CustomPainter {
  const _ScenePatternPainter({
    required this.composition,
    required this.accentColor,
  });

  final String composition;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final accentStroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = accentColor.withValues(alpha: 0.18)
      ..strokeWidth = 1.2;

    switch (composition) {
      case 'tension-bridge':
        final path = Path()
          ..moveTo(size.width * 0.08, size.height * 0.82)
          ..lineTo(size.width * 0.36, size.height * 0.36)
          ..lineTo(size.width * 0.7, size.height * 0.54)
          ..lineTo(size.width * 0.95, size.height * 0.18);
        canvas.drawPath(path, accentStroke);
        break;
      case 'relay-diagram':
        for (final x in [0.24, 0.5, 0.76]) {
          canvas.drawCircle(
            Offset(size.width * x, size.height * 0.44),
            110,
            stroke,
          );
        }
        break;
      case 'editorial-runway':
        for (var i = 0; i < 8; i++) {
          final y = size.height * (0.12 + (i * 0.1));
          canvas.drawLine(
            Offset(size.width * 0.5, y),
            Offset(size.width * 0.92, y),
            stroke,
          );
        }
        break;
      case 'constellation-ring':
        canvas.drawCircle(
          Offset(size.width * 0.62, size.height * 0.48),
          size.height * 0.24,
          accentStroke,
        );
        break;
      case 'proof-mosaic':
        for (var col = 0; col < 4; col++) {
          for (var row = 0; row < 3; row++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  size.width * (0.52 + (col * 0.1)),
                  size.height * (0.1 + (row * 0.17)),
                  size.width * 0.07,
                  size.height * 0.1,
                ),
                const Radius.circular(18),
              ),
              stroke,
            );
          }
        }
        break;
      case 'closing-manifesto':
        for (var i = 0; i < 5; i++) {
          final dx = size.width * (0.08 + i * 0.18);
          canvas.drawLine(
            Offset(dx, size.height * 0.18),
            Offset(dx + size.width * 0.12, size.height * 0.02),
            accentStroke,
          );
        }
        break;
      default:
        canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.18),
          160,
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePatternPainter oldDelegate) {
    return oldDelegate.composition != composition ||
        oldDelegate.accentColor != accentColor;
  }
}

class SignalCard extends StatelessWidget {
  const SignalCard({
    required this.title,
    required this.body,
    required this.accentColor,
    this.indexLabel,
    this.compact = false,
    super.key,
  });

  final String title;
  final String body;
  final Color accentColor;
  final String? indexLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
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
            SizedBox(height: compact ? 6 : 8),
          ],
          Text(
            title,
            style: textTheme.title.copyWith(
              color: Colors.white,
              fontSize: compact ? 18 : null,
              height: compact ? 1.08 : null,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            body,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: compact ? 15 : null,
              height: compact ? 1.2 : null,
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
