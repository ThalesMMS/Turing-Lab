//
//  app_store_capture_path.dart
//  Turing Lab
//
//  Normalizes capture paths emitted by dart:io so the validator compares the
//  same forward-slash slot names on Windows and POSIX hosts.
//

/// Returns [entityPath] relative to [rootPath] with `/` separators.
String appStoreCaptureRelativePath(String rootPath, String entityPath) {
  final normalizedRoot = _normalizeSeparators(
    rootPath,
  ).replaceFirst(RegExp(r'/+$'), '');
  final normalizedEntity = _normalizeSeparators(entityPath);
  final prefix = normalizedRoot.isEmpty ? '/' : '$normalizedRoot/';

  if (!normalizedEntity.startsWith(prefix)) {
    throw ArgumentError.value(
      entityPath,
      'entityPath',
      'Must be inside $rootPath',
    );
  }

  return normalizedEntity.substring(prefix.length);
}

String _normalizeSeparators(String path) => path.replaceAll(r'\', '/');
