import 'app_localizations.dart';

/// Small presentation-only translations for conversion previews.
///
/// Preview headings and labels are derived from intermediate artifacts rather
/// than generated messages, so they stay outside the shared ARB catalog. Data
/// such as state IDs, names, and formal expressions is intentionally left
/// unchanged.
extension AppLocalizationsConversionPreview on AppLocalizations {
  String conversionPreviewText(String english, String portuguese) =>
      localeName.toLowerCase().startsWith('pt') ? portuguese : english;
}
