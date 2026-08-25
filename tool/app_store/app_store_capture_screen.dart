//
//  app_store_capture_screen.dart
//  Turing Lab
//
//  Declares one journey captured for every device profile and maps it to the
//  ordered App Store Connect media slot its filename encodes.
//
//  Thales Matheus Mendonça Santos - August 2026
//

/// Journey captured for a media slot, such as the FSA editor.
class AppStoreCaptureScreen {
  const AppStoreCaptureScreen({
    required this.id,
    required this.slot,
    required this.aliases,
    required this.description,
  });

  /// Canonical CLI identifier, for example `fsa`.
  final String id;

  /// One-based App Store Connect upload position.
  final int slot;

  /// Alternative identifiers accepted by `--screen`.
  final List<String> aliases;

  /// Human readable journey description used in diagnostics and the manifest.
  final String description;

  /// Filename stem without locale/theme suffixes, for example `01-fsa`.
  String get fileStem => '${slot.toString().padLeft(2, '0')}-$id';

  /// Whether [value] selects this screen through its id, slot or aliases.
  bool matches(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == id ||
        normalized == fileStem ||
        aliases.contains(normalized);
  }

  @override
  String toString() => '$id (slot $slot)';
}
