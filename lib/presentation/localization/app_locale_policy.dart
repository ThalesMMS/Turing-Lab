import 'dart:ui';

/// Resolves the persisted language choice and the primary platform locale.
abstract final class AppLocalePolicy {
  static const Locale englishUnitedStates = Locale('en', 'US');
  static const Locale portugueseBrazil = Locale('pt', 'BR');

  static const List<Locale> supportedLocales = <Locale>[
    englishUnitedStates,
    portugueseBrazil,
  ];

  static Locale resolve({
    required String? persistedLocaleCode,
    required List<Locale> platformLocales,
  }) {
    switch (persistedLocaleCode) {
      case 'en':
        return englishUnitedStates;
      case 'pt':
        return portugueseBrazil;
    }

    if (platformLocales.isNotEmpty &&
        platformLocales.first == portugueseBrazil) {
      return portugueseBrazil;
    }
    return englishUnitedStates;
  }
}
