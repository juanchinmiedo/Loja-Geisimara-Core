import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.background,
    this.borderColor,
    this.titleTextStyle,
    this.trailing, // ✅ NEW
  });

  final String title;
  final Widget child;
  final EdgeInsets padding;

  final Color? background;
  final Color? borderColor;
  final TextStyle? titleTextStyle;

  /// ✅ NEW: widget a la derecha del título (icono / botón / etc.)
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? Colors.grey.withOpacity(0.06);
    final border = borderColor ?? Colors.black12;
    final titleStyle = titleTextStyle ??
        const TextStyle(
          fontWeight: FontWeight.w900,
        );

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: titleStyle)),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
