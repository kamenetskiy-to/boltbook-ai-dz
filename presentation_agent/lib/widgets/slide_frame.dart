import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';
import 'package:presentation_agent/models/slide_spec.dart';
import 'package:presentation_agent/widgets/evidence_callout.dart';

class SlideFrame extends StatelessWidget {
  const SlideFrame({
    required this.spec,
    required this.accentColor,
    this.body,
    this.aside,
    super.key,
  });

  final SlideSpec spec;
  final Color accentColor;
  final Widget? body;
  final Widget? aside;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumns = constraints.maxWidth > 1120;
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                spec.eyebrow ?? spec.kind.name.toUpperCase(),
                style: textTheme.bodySmall.copyWith(
                  color: accentColor,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              spec.title,
              style: textTheme.header.copyWith(color: Colors.white),
            ),
            if (spec.headline != null) ...[
              const SizedBox(height: 18),
              Text(
                spec.headline!,
                style: textTheme.title.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                ),
              ),
            ],
            if (spec.subtitle != null) ...[
              const SizedBox(height: 18),
              Text(
                spec.subtitle!,
                style: textTheme.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ],
        );

        final keyPointCards = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final point in spec.keyPoints) ...[
              _KeyPointCard(point: point, accentColor: accentColor),
              const SizedBox(height: 14),
            ],
            if (spec.evidenceRefs.isNotEmpty)
              EvidenceCallout(
                title: 'Evidence refs',
                refs: spec.evidenceRefs,
                accentColor: accentColor,
              ),
          ],
        );

        final mainColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            intro,
            const SizedBox(height: 28),
            if (body != null) ...[body!, const SizedBox(height: 22)],
            keyPointCards,
          ],
        );

        final content = useColumns
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 8, child: mainColumn),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 4,
                    child:
                        aside ??
                        _VisualDirectionCard(
                          visualDirection: spec.visualDirection,
                          accentColor: accentColor,
                        ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mainColumn,
                  const SizedBox(height: 28),
                  aside ??
                      _VisualDirectionCard(
                        visualDirection: spec.visualDirection,
                        accentColor: accentColor,
                      ),
                ],
              );

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF060A16), Color(0xFF0F1831), Color(0xFF130F22)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -60,
                child: _PanelGlow(color: accentColor),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 64, 72, 42),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 420),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - value)),
                      child: child,
                    ),
                  ),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KeyPointCard extends StatelessWidget {
  const _KeyPointCard({required this.point, required this.accentColor});

  final String point;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PresentationTheme.panelColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: PresentationTheme.panelBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 9),
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              point,
              style: textTheme.bodyLarge.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualDirectionCard extends StatelessWidget {
  const _VisualDirectionCard({
    required this.visualDirection,
    required this.accentColor,
  });

  final String visualDirection;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11182C).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PresentationTheme.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual direction',
            style: textTheme.bodySmall.copyWith(
              color: accentColor,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            visualDirection,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelGlow extends StatelessWidget {
  const _PanelGlow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
