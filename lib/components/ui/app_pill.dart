import 'package:flutter/material.dart';

class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.child,
    this.background,
    this.borderColor,
    this.radius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  });

  final Widget child;
  final Color? background;
  final Color? borderColor;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.black12),
      ),
      child: child,
    );
  }
}
