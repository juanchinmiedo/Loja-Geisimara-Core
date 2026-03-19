import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app/provider/locale_provider.dart';

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
    this.showLanguageSelector = true,
  });

  final String title;
  final String? subtitle;
  final double height;
  final Widget? child;
  final EdgeInsets padding;
  final List<Color> colors;
  final bool centerTitle;
  final TextStyle? titleStyle;
  final bool showLanguageSelector;

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
      // Stack inside the gradient container — pill floats top-right,
      // content fills the rest. Container has fixed height so pill is always visible.
      child: Stack(
        children: [
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (centerTitle)
                  Center(child: Text(title, style: tStyle))
                else
                  Text(title, style: tStyle),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!,
                      style: TextStyle(color: Colors.white.withOpacity(0.9))),
                ],
                if (child != null) ...[
                  const SizedBox(height: 10),
                  child!,
                ],
              ],
            ),
          ),
          if (showLanguageSelector)
            Positioned(
              top: padding.top,
              right: 18,
              child: const _LanguagePill(),
            ),
        ],
      ),
    );
  }
}

// ── Language selector pill — lives inside the gradient header ─────────────────

class _LanguagePill extends StatelessWidget {
  const _LanguagePill();

  static const _langs = [
    _Lang('PT', 'pt'),
    _Lang('EN', 'en'),
    _Lang('ES', 'es'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale  = context.watch<LocaleProvider>().locale;
    final current = locale.languageCode;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _langs.map((lang) {
            final isActive = lang.code == current;
            return GestureDetector(
              onTap: isActive
                  ? null
                  : () => context
                      .read<LocaleProvider>()
                      .setLocaleByLanguageCode(lang.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.90)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  lang.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                    color: isActive
                        ? const Color(0xff721c80)
                        : Colors.white.withOpacity(0.80),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _Lang {
  const _Lang(this.label, this.code);
  final String label;
  final String code;
}
