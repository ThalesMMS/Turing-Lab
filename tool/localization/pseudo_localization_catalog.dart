import 'pseudo_localizer.dart';

/// Builds a nonshipping pseudo-localized copy of an ARB-shaped catalog.
abstract final class PseudoLocalizationCatalog {
  static Map<String, Object?> transform(
    Map<String, Object?> source, {
    Map<String, List<String>> protectedTextByMessage =
        const <String, List<String>>{},
  }) {
    final messageKeys = source.keys
        .where((key) => !key.startsWith('@'))
        .toSet();
    final unknownProtectionKeys = protectedTextByMessage.keys.toSet()
      ..removeAll(messageKeys);
    if (unknownProtectionKeys.isNotEmpty) {
      throw ArgumentError.value(
        unknownProtectionKeys.toList()..sort(),
        'protectedTextByMessage',
        'contains keys that are not messages',
      );
    }

    return <String, Object?>{
      for (final entry in source.entries)
        entry.key: _transformEntry(entry, protectedTextByMessage),
    };
  }

  static Object? _transformEntry(
    MapEntry<String, Object?> entry,
    Map<String, List<String>> protectedTextByMessage,
  ) {
    if (entry.key.startsWith('@')) return entry.value;
    final message = entry.value;
    if (message is! String) {
      throw FormatException('ARB message ${entry.key} must be a string.');
    }
    return PseudoLocalizer.localize(
      message,
      protectedText: protectedTextByMessage[entry.key] ?? const <String>[],
    );
  }
}
