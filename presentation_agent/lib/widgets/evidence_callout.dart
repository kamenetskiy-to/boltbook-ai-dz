import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';

class EvidenceCallout extends StatelessWidget {
  const EvidenceCallout({
    required this.title,
    required this.refs,
    required this.accentColor,
    super.key,
  });

  final String title;
  final List<String> refs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = FlutterDeckTheme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final ref in refs) ...[
            Text(
              ref,
              style: textTheme.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
