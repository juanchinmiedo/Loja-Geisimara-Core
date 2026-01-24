import 'package:flutter/material.dart';

/// Pill button with optional leading icon.
/// Updated to match "edit" style: same color, NO shadows by default.
///
/// ✅ Responsive pro:
/// - If space is tight, it reduces padding automatically
/// - It can also shrink content slightly using FittedBox (without hiding icon)
class AppIconValuePillButton extends StatelessWidget {
  const AppIconValuePillButton({
    super.key,
    required this.color,
    required this.label,
    required this.onTap,
    this.icon,
    this.showIcon = true,
    this.enabled = true,

    /// Base padding (used on normal widths)
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

    /// Compact padding (used automatically on small widths)
    this.compactPadding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),

    /// If true, uses compact padding when the available width is small.
    this.autoCompact = true,
    this.compactBreakpoint = 330,

    /// If true, wraps content in a FittedBox to slightly shrink if needed.
    this.fitContent = true,

    this.textStyle,

    // Match edit-ish style
    this.fillOpacity = 0.12,
    this.borderOpacity = 0.28,

    // No shadows (as requested)
    this.shadow = false,
    this.shadowOpacity = 0.14,
    this.shadowBlur = 14,
    this.shadowOffset = const Offset(0, 6),
  });

  final Color color;
  final String label;
  final VoidCallback? onTap;

  final IconData? icon;
  final bool showIcon;
  final bool enabled;

  final EdgeInsets padding;
  final EdgeInsets compactPadding;

  final bool autoCompact;
  final double compactBreakpoint;

  final bool fitContent;

  final TextStyle? textStyle;

  final double fillOpacity;
  final double borderOpacity;

  final bool shadow;
  final double shadowOpacity;
  final double shadowBlur;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final tap = enabled ? onTap : null;

    final fg = enabled ? color : Colors.black26;
    final bg = color.withOpacity(fillOpacity);
    final br = color.withOpacity(borderOpacity);

    return LayoutBuilder(
      builder: (context, c) {
        final useCompact = autoCompact && c.maxWidth > 0 && c.maxWidth < compactBreakpoint;
        final pad = useCompact ? compactPadding : padding;

        final row = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && showIcon) ...[
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8), // icono + espacio + valor
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (textStyle ??
                        const TextStyle(
                          fontWeight: FontWeight.w800,
                        ))
                    .copyWith(color: fg),
              ),
            ),
          ],
        );

        final content = fitContent
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: row,
              )
            : row;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: pad,
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
              child: content,
            ),
          ),
        );
      },
    );
  }
}
