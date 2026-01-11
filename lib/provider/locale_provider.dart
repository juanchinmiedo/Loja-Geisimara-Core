import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = S.delegate.supportedLocales.first;

  Locale get locale => _locale;

  /// Cambia de idioma usando SOLO el languageCode ('en', 'es', 'pt')
  void setLocaleByLanguageCode(String languageCode) {
    final supported = S.delegate.supportedLocales;

    // Buscamos el primer locale que tenga ese languageCode
    final match = supported.firstWhere(
      (l) => l.languageCode == languageCode,
      orElse: () => supported.first,
    );

    if (match == _locale) return; // ya está
    _locale = match;
    notifyListeners();
  }
}