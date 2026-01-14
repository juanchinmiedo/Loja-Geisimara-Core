import 'package:flutter/material.dart';

class AppPreviewCard extends StatelessWidget {
  const AppPreviewCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
    this.accent = const Color(0xff721c80),
  });

  final Widget child;
  final EdgeInsets padding;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.20)),
      ),
      child: child,
    );
  }
}
