import 'package:flutter/material.dart';
import 'package:salon_app/generated/l10n.dart';

class LocaleProvider extends ChangeNotifier {
  // Default: Portuguese (Brazil) — first in supportedLocales
  Locale _locale = const Locale.fromSubtags(languageCode: 'pt', countryCode: 'BR');

  Locale get locale => _locale;

  void setLocaleByLanguageCode(String languageCode) {
    final supported = S.delegate.supportedLocales;
    final match = supported.firstWhere(
      (l) => l.languageCode == languageCode,
      orElse: () => supported.first,
    );
    if (match == _locale) return;
    _locale = match;
    notifyListeners();
  }
}
