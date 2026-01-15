import 'package:flutter/material.dart';

class AppGradientHeader extends StatelessWidget {
  const AppGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.height = 220,
    this.child,
    this.padding = const EdgeInsets.only(top: 46, left: 18, right: 18),
    this.colors = const [Color(0xff721c80), Color.fromARGB(255, 196, 103, 169)],
    this.centerTitle = false,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final double height;
  final Widget? child;
  final EdgeInsets padding;
  final List<Color> colors;

  /// ✅ para pantallas tipo calendario donde el título va centrado
  final bool centerTitle;

  /// override opcional
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final tStyle = titleStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 20,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        );

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: centerTitle ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          children: [
            if (centerTitle)
              Center(child: Text(title, style: tStyle))
            else
              Text(title, style: tStyle),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: TextStyle(color: Colors.white.withOpacity(0.9))),
            ],
            if (child != null) ...[
              const SizedBox(height: 10),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}
