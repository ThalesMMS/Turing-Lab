//
//  app_store_capture_manifest.dart
//  Turing Lab
//
//  Reads, merges and writes the machine-readable manifest that accompanies a
//  capture run. Each capture process drops a sidecar part so a rerun of one
//  slot updates only that row, and the CLI folds the parts into manifest.json.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:convert';
import 'dart:io';

import 'app_store_capture_manifest_entry.dart';

/// Collection of manifest rows persisted next to a capture output directory.
class AppStoreCaptureManifest {
  const AppStoreCaptureManifest(this.entries);

  /// Manifest filename written at the root of an output directory.
  static const String fileName = 'manifest.json';

  /// Directory holding per-capture sidecar parts before they are merged.
  static const String partsDirName = '.capture-parts';

  /// Manifest schema version, bumped when the row shape changes.
  static const int schemaVersion = 1;

  final List<AppStoreCaptureManifestEntry> entries;

  /// Reads the manifest from [outputDir], returning an empty manifest when the
  /// directory has never been captured into.
  static AppStoreCaptureManifest read(Directory outputDir) {
    final file = File('${outputDir.path}/$fileName');
    if (!file.existsSync()) {
      return const AppStoreCaptureManifest(<AppStoreCaptureManifestEntry>[]);
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Malformed manifest at ${file.path}');
    }
    final rows = decoded['captures'];
    if (rows is! List) {
      throw FormatException('Manifest at ${file.path} has no capture list');
    }
    return AppStoreCaptureManifest(
      rows
          .cast<Map<String, Object?>>()
          .map(AppStoreCaptureManifestEntry.fromJson)
          .toList(growable: false),
    );
  }

  /// Writes a sidecar part for a single capture attempt.
  static void writePart(
    Directory outputDir,
    AppStoreCaptureManifestEntry entry,
  ) {
    final partsDir = Directory('${outputDir.path}/$partsDirName');
    partsDir.createSync(recursive: true);
    final slug = entry.path.replaceAll('/', '__').replaceAll('.png', '');
    File('${partsDir.path}/$slug.json')
        .writeAsStringSync(jsonEncode(entry.toJson()));
  }

  /// Reads and removes every sidecar part currently present in [outputDir].
  static List<AppStoreCaptureManifestEntry> drainParts(Directory outputDir) {
    final partsDir = Directory('${outputDir.path}/$partsDirName');
    if (!partsDir.existsSync()) {
      return const <AppStoreCaptureManifestEntry>[];
    }
    final drained = <AppStoreCaptureManifestEntry>[];
    final files = partsDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is Map<String, Object?>) {
        drained.add(AppStoreCaptureManifestEntry.fromJson(decoded));
      }
    }
    partsDir.deleteSync(recursive: true);
    return drained;
  }

  /// Returns a manifest where [updates] replace rows with the same path.
  AppStoreCaptureManifest merge(
    Iterable<AppStoreCaptureManifestEntry> updates,
  ) {
    final byPath = <String, AppStoreCaptureManifestEntry>{
      for (final entry in entries) entry.path: entry,
    };
    for (final entry in updates) {
      byPath[entry.path] = entry;
    }
    final merged = byPath.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return AppStoreCaptureManifest(List.unmodifiable(merged));
  }

  /// Persists the manifest to [outputDir] with stable key and row ordering so
  /// repeated runs only differ in the metadata that genuinely changed.
  void write(Directory outputDir, {required String generator}) {
    outputDir.createSync(recursive: true);
    final payload = <String, Object?>{
      'schemaVersion': schemaVersion,
      'generator': generator,
      'captures': entries.map((entry) => entry.toJson()).toList(),
    };
    File('${outputDir.path}/$fileName').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
    );
  }

  AppStoreCaptureManifestEntry? entryForPath(String path) {
    for (final entry in entries) {
      if (entry.path == path) {
        return entry;
      }
    }
    return null;
  }
}
