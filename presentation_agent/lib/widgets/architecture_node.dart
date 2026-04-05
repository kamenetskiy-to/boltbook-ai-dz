import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';

class ArchitectureNode extends StatelessWidget {
  const ArchitectureNode({
    required this.title,
    required this.subtitle,
    required this.detail,
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: PresentationTheme.panelColor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: PresentationTheme.panelBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: textTheme.bodySmall.copyWith(
              color: PresentationTheme.evidence,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            title,
            style: textTheme.title.copyWith(
              color: Colors.white,
              fontSize: compact ? 20 : null,
              height: compact ? 1.08 : null,
            ),
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            detail,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: compact ? 15 : null,
              height: compact ? 1.2 : null,
            ),
          ),
        ],
      ),
    );
  }
}
