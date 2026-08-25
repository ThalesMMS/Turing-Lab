//
//  monospace_typography.dart
//  Turing Lab
//
//  Shared monospace typeface stack for the places that display symbols,
//  tapes, stacks, and grammar productions in fixed width.
//
//  Thales Matheus Mendonça Santos - August 2026
//

/// Font families tried, in order, wherever the app needs fixed-width text.
///
/// `monospace` on its own is a generic CSS-style alias that only some engines
/// resolve; on the rest it silently falls back to the default face, which
/// renders as unstyled boxes under `flutter test`. Naming real faces after it
/// keeps the text readable everywhere.
const List<String> kMonospaceFontFamilyFallback = <String>[
  'monospace',
  'Menlo',
  'Consolas',
  'DejaVu Sans Mono',
  'Courier New',
  'Roboto Mono',
];
