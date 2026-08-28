//
//  app.dart
//  Turing Lab
//
//  Configures the app root widget with ProviderScope, defining Material 3
//  light and dark themes and setting HomePage as the responsive home screen
//  for all supported platforms.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'core/pumping_lemma/pumping_lemma.dart';
import 'presentation/localization/app_locale_policy.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/pumping_lemma_chooser_page.dart';
import 'presentation/pages/pumping_lemma_page.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/active_session_lifecycle.dart';

/// Main application widget with clean architecture
class TuringLabApp extends ConsumerWidget {
  const TuringLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final platformLocales = View.of(context).platformDispatcher.locales;

    return ActiveSessionLifecycle(
      child: MaterialApp(
        title: 'Turing Lab',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _resolveThemeMode(settings.themeMode),
        locale: AppLocalePolicy.resolve(
          persistedLocaleCode: settings.localeCode,
          platformLocales: platformLocales,
        ),
        home: const HomePage(),
        routes: {
          PumpingLemmaChooserPage.route: (_) => const PumpingLemmaChooserPage(),
          PumpingLemmaChooserPage.regularRoute: (_) =>
              const PumpingLemmaPage(theorem: PumpingLemmaTheorem.regular),
          PumpingLemmaChooserPage.contextFreeRoute: (_) =>
              const PumpingLemmaPage(theorem: PumpingLemmaTheorem.contextFree),
        },
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalePolicy.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  static ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
