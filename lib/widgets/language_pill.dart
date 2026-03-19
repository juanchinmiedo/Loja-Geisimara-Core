import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:salon_app/provider/locale_provider.dart';

/// Floating language selector — use inside a Stack as Positioned(top:..., right:18)
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  static const _langs = [
    _Lang('PT', 'pt'),
    _Lang('EN', 'en'),
    _Lang('ES', 'es'),
  ];

  @override
  Widget build(BuildContext context) {
    final locale  = context.watch<LocaleProvider>().locale;
    final current = locale.languageCode;

    return Container(
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
                  color: isActive
                      ? const Color(0xff721c80)
                      : Colors.white.withOpacity(0.80),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Lang {
  const _Lang(this.label, this.code);
  final String label;
  final String code;
}
