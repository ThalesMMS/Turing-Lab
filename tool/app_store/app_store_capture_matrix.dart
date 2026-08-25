//
//  app_store_capture_matrix.dart
//  Turing Lab
//
//  Single source of truth for the App Store capture matrix: the supported
//  device profiles, journeys, locales and themes, plus the selection logic the
//  CLI, the Flutter harness and the validation tests all resolve against.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'app_store_capture_case.dart';
import 'app_store_capture_profile.dart';
import 'app_store_capture_screen.dart';

/// Declarative catalogue of every capture the release pipeline can produce.
class AppStoreCaptureMatrix {
  const AppStoreCaptureMatrix._();

  /// Directory holding the release-approved captures.
  static const String approvedOutputDir = 'screenshots/app_store';

  static const List<AppStoreCaptureProfile> profiles = <AppStoreCaptureProfile>[
    AppStoreCaptureProfile(
      id: 'iphone-6.9',
      pixelWidth: 1320,
      pixelHeight: 2868,
      devicePixelRatio: 3.0,
      description: 'iPhone 6.9-inch portrait',
    ),
    AppStoreCaptureProfile(
      id: 'iphone-6.5',
      pixelWidth: 1284,
      pixelHeight: 2778,
      devicePixelRatio: 3.0,
      description: 'iPhone 6.5-inch portrait',
    ),
    AppStoreCaptureProfile(
      id: 'iphone-5.5',
      pixelWidth: 1242,
      pixelHeight: 2208,
      devicePixelRatio: 3.0,
      description: 'iPhone 5.5-inch portrait',
    ),
    AppStoreCaptureProfile(
      id: 'ipad-13',
      pixelWidth: 2048,
      pixelHeight: 2732,
      devicePixelRatio: 2.0,
      description: 'iPad 13-inch portrait',
    ),
    AppStoreCaptureProfile(
      id: 'macos',
      pixelWidth: 2880,
      pixelHeight: 1800,
      devicePixelRatio: 2.2,
      description: 'macOS 16:10 landscape',
    ),
  ];

  static const List<AppStoreCaptureScreen> screens = <AppStoreCaptureScreen>[
    AppStoreCaptureScreen(
      id: 'fsa',
      slot: 1,
      aliases: <String>['fsa-editor', 'automaton'],
      description: 'Finite state automaton editor',
    ),
    AppStoreCaptureScreen(
      id: 'grammar',
      slot: 2,
      aliases: <String>['grammar-editor', 'cfg'],
      description: 'Context-free grammar editor',
    ),
    AppStoreCaptureScreen(
      id: 'pda',
      slot: 3,
      aliases: <String>['pda-editor'],
      description: 'Pushdown automaton editor',
    ),
    AppStoreCaptureScreen(
      id: 'tm',
      slot: 4,
      aliases: <String>['tm-editor', 'turing'],
      description: 'Turing machine editor',
    ),
    AppStoreCaptureScreen(
      id: 'regex',
      slot: 5,
      aliases: <String>['regex-editor', 'regular-expression'],
      description: 'Regular expression workspace',
    ),
  ];

  static const List<String> locales = <String>['en', 'pt'];

  static const List<String> themes = <String>['light', 'dark'];

  static AppStoreCaptureProfile profileById(String value) {
    final normalized = value.trim().toLowerCase();
    for (final profile in profiles) {
      if (profile.id == normalized) {
        return profile;
      }
    }
    throw ArgumentError(
      'Unknown profile "$value". Valid profiles: '
      '${profiles.map((profile) => profile.id).join(', ')}.',
    );
  }

  static AppStoreCaptureScreen screenById(String value) {
    for (final screen in screens) {
      if (screen.matches(value)) {
        return screen;
      }
    }
    throw ArgumentError(
      'Unknown screen "$value". Valid screens: '
      '${screens.map((screen) => screen.id).join(', ')}.',
    );
  }

  static String localeById(String value) {
    final normalized = value.trim().toLowerCase();
    if (locales.contains(normalized)) {
      return normalized;
    }
    throw ArgumentError(
      'Unknown locale "$value". Valid locales: ${locales.join(', ')}.',
    );
  }

  static String themeById(String value) {
    final normalized = value.trim().toLowerCase();
    if (themes.contains(normalized)) {
      return normalized;
    }
    throw ArgumentError(
      'Unknown theme "$value". Valid themes: ${themes.join(', ')}.',
    );
  }

  /// Complete release-approved matrix: every profile and screen in the default
  /// locale and theme, which is exactly the tracked screenshot set.
  static List<AppStoreCaptureCase> approvedCases() => resolve();

  /// Resolves a selection into an ordered, de-duplicated case list. Omitted or
  /// empty dimensions fall back to every profile, every screen, and the
  /// default locale and theme.
  static List<AppStoreCaptureCase> resolve({
    Iterable<String>? profileIds,
    Iterable<String>? screenIds,
    Iterable<String>? localeCodes,
    Iterable<String>? themeIds,
  }) {
    final selectedProfiles = _select(
      profileIds,
      profiles,
      profileById,
    );
    final selectedScreens = _select(
      screenIds,
      screens,
      screenById,
    );
    final selectedLocales = _select(
      localeCodes,
      const <String>[AppStoreCaptureCase.defaultLocale],
      localeById,
    );
    final selectedThemes = _select(
      themeIds,
      const <String>[AppStoreCaptureCase.defaultTheme],
      themeById,
    );

    final resolved = <AppStoreCaptureCase>[];
    for (final profile in selectedProfiles) {
      for (final screen in selectedScreens) {
        for (final locale in selectedLocales) {
          for (final theme in selectedThemes) {
            resolved.add(
              AppStoreCaptureCase(
                profile: profile,
                screen: screen,
                locale: locale,
                theme: theme,
              ),
            );
          }
        }
      }
    }
    return resolved;
  }

  static List<T> _select<T>(
    Iterable<String>? requested,
    List<T> fallback,
    T Function(String value) lookup,
  ) {
    if (requested == null || requested.isEmpty) {
      return List<T>.of(fallback);
    }
    final selected = <T>[];
    for (final value in requested) {
      final resolved = lookup(value);
      if (!selected.contains(resolved)) {
        selected.add(resolved);
      }
    }
    return selected;
  }
}
