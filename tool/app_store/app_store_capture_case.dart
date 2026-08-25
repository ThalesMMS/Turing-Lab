//
//  app_store_capture_case.dart
//  Turing Lab
//
//  Binds a device profile, journey, locale and theme into the single unit the
//  capture pipeline schedules, names, validates and records in the manifest.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'app_store_capture_profile.dart';
import 'app_store_capture_screen.dart';

/// One profile/screen/locale/theme combination produced by the pipeline.
class AppStoreCaptureCase {
  const AppStoreCaptureCase({
    required this.profile,
    required this.screen,
    required this.locale,
    required this.theme,
  });

  /// Locale used by the release-approved matrix.
  static const String defaultLocale = 'en';

  /// Theme used by the release-approved matrix.
  static const String defaultTheme = 'light';

  final AppStoreCaptureProfile profile;
  final AppStoreCaptureScreen screen;
  final String locale;
  final String theme;

  /// True when this case belongs to the release-approved matrix.
  bool get isApproved => locale == defaultLocale && theme == defaultTheme;

  /// Filename inside the profile directory, suffixed for non-default variants
  /// so candidate locales and themes never overwrite an approved slot.
  String get fileName {
    final buffer = StringBuffer(screen.fileStem);
    if (locale != defaultLocale) {
      buffer.write('-$locale');
    }
    if (theme != defaultTheme) {
      buffer.write('-$theme');
    }
    buffer.write('.png');
    return buffer.toString();
  }

  /// Path of the rendered PNG relative to the output root.
  String get relativePath => '${profile.id}/$fileName';

  /// Stable identifier used by diagnostics and rerun instructions.
  String get id => '${profile.id}/${screen.id}/$locale/$theme';

  @override
  String toString() => id;
}
