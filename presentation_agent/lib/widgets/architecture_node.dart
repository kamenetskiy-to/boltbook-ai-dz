import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:presentation_agent/app/theme.dart';

class ArchitectureNode extends StatelessWidget {
  const ArchitectureNode({
    required this.title,
    required this.subtitle,
    required this.detail,
    super.key,
  });

  final String title;
  final String subtitle;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 8),
          Text(title, style: textTheme.title.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            detail,
            style: textTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
