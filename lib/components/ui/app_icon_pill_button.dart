import 'package:flutter/material.dart';

class AppIconPillButton extends StatelessWidget {
  const AppIconPillButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.color,
    this.size = 38,
    this.iconSize = 18,
    this.tooltip,
    this.enabled = true,
    this.fillOpacity = 0.12,
    this.borderOpacity = 0.28,
    this.activeFillOpacity = 0.20,
    this.activeBorderOpacity = 0.55,
    this.active = false,

    /// Shadow (keep, but default OFF for your new style)
    this.shadow = false,
    this.shadowOpacity = 0.18,
    this.shadowBlur = 14,
    this.shadowOffset = const Offset(0, 6),
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  final double size;
  final double iconSize;

  final String? tooltip;
  final bool enabled;

  final double fillOpacity;
  final double borderOpacity;

  final bool active;
  final double activeFillOpacity;
  final double activeBorderOpacity;

  final bool shadow;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final tap = enabled ? onTap : null;

    final bg = color.withOpacity(active ? activeFillOpacity : fillOpacity);
    final br = color.withOpacity(active ? activeBorderOpacity : borderOpacity);

    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: br),
            boxShadow: shadow
                ? [
                    BoxShadow(
                      color: color.withOpacity(shadowOpacity),
                      blurRadius: shadowBlur,
                      offset: shadowOffset,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: enabled ? color : Colors.black26,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.trim().isEmpty) return child;

    return Tooltip(
      message: tooltip!,
      child: child,
    );
  }
}
