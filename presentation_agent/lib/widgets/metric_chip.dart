import 'package:flutter/material.dart';
import 'package:presentation_agent/app/theme.dart';

class MetricChip extends StatelessWidget {
  const MetricChip({
    required this.label,
    required this.value,
    this.compact = false,
    super.key,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final valueStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 18 : 20,
      fontWeight: FontWeight.w700,
      height: compact ? 1.1 : 1.15,
    );
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return Container(
      constraints: BoxConstraints(minWidth: compact ? 140 : 156),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            PresentationTheme.panelColor.withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: valueStyle),
          SizedBox(height: compact ? 3 : 4),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}
