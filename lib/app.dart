//
//  app.dart
//  Turing Lab
//
//  Configura o widget raiz do aplicativo com ProviderScope, definindo temas
//  claro e escuro do Material 3 e estabelecendo a HomePage como tela inicial
//  responsiva para todas as plataformas suportadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'l10n/app_localizations.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/active_session_lifecycle.dart';

/// Main application widget with clean architecture
class TuringLabApp extends ConsumerWidget {
  const TuringLabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ActiveSessionLifecycle(
      child: MaterialApp(
        title: 'Turing Lab',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _resolveThemeMode(settings.themeMode),
        locale: _resolveLocale(settings.localeCode),
        home: const HomePage(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      default:
        return ThemeMode.system;
    }
  }

  static Locale? _resolveLocale(String? localeCode) {
    switch (localeCode) {
      case 'en':
        return const Locale('en');
      case 'pt':
        return const Locale('pt');
      default:
        return null;
    }
  }
}
