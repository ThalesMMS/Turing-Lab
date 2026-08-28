//
//  app_store_capture_validator.dart
//  Turing Lab
//
//  Checks a capture output directory against the declared matrix: required
//  pixel dimensions, slot naming, missing or duplicated slots, unexpected
//  files and manifest agreement.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:io';
import 'dart:typed_data';

import 'app_store_capture_case.dart';
import 'app_store_capture_manifest.dart';
import 'app_store_capture_path.dart';
import 'app_store_capture_validation_issue.dart';
import 'app_store_png_size.dart';

/// Validates rendered screenshots and their manifest against the matrix.
class AppStoreCaptureValidator {
  const AppStoreCaptureValidator({
    required this.outputDir,
    required this.cases,
    this.strict = true,
  });

  /// Files allowed at the output root that are not screenshot slots.
  static const List<String> allowedRootFiles = <String>[
    AppStoreCaptureManifest.fileName,
  ];

  static final RegExp _fileNamePattern =
      RegExp(r'^\d{2}-[a-z0-9]+(-[a-z]{2})?(-[a-z]+)?\.png$');

  final Directory outputDir;
  final List<AppStoreCaptureCase> cases;

  /// When true the whole directory is swept for unexpected or duplicated
  /// files; partial reruns disable it so untouched slots are not reported.
  final bool strict;

  List<AppStoreCaptureValidationIssue> validate() {
    final issues = <AppStoreCaptureValidationIssue>[];
    if (!outputDir.existsSync()) {
      return <AppStoreCaptureValidationIssue>[
        AppStoreCaptureValidationIssue(
          kind: AppStoreCaptureValidationIssue.missingSlot,
          path: outputDir.path,
          message: 'Output directory does not exist.',
        ),
      ];
    }

    final manifest = AppStoreCaptureManifest.read(outputDir);
    final expectedPaths = <String>{};
    final contents = <String, Uint8List>{};

    for (final captureCase in cases) {
      expectedPaths.add(captureCase.relativePath);
      final file = File('${outputDir.path}/${captureCase.relativePath}');
      final entry = manifest.entryForPath(captureCase.relativePath);

      if (!file.existsSync()) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.missingSlot,
            path: captureCase.relativePath,
            message: 'No screenshot for ${captureCase.id}.',
          ),
        );
        continue;
      }

      contents[captureCase.relativePath] = file.readAsBytesSync();

      final profile = captureCase.profile;
      final size = AppStorePngSize.read(file);
      if (size.width != profile.pixelWidth ||
          size.height != profile.pixelHeight) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.dimensionMismatch,
            path: captureCase.relativePath,
            message: 'Expected ${profile.pixelWidth}x${profile.pixelHeight}, '
                'found $size.',
          ),
        );
      }

      if (entry == null) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.manifestMissingEntry,
            path: captureCase.relativePath,
            message: 'Manifest has no row for ${captureCase.id}.',
          ),
        );
      } else if (!entry.isCaptured) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.captureFailed,
            path: captureCase.relativePath,
            message: 'Manifest records status "${entry.status}"'
                '${entry.failure == null ? '' : ': ${entry.failure}'}.',
          ),
        );
      } else if (entry.pixelWidth != profile.pixelWidth ||
          entry.pixelHeight != profile.pixelHeight ||
          entry.profile != profile.id ||
          entry.screen != captureCase.screen.id ||
          entry.locale != captureCase.locale ||
          entry.theme != captureCase.theme) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.manifestMismatch,
            path: captureCase.relativePath,
            message: 'Manifest row does not describe ${captureCase.id}.',
          ),
        );
      }
    }

    if (!strict) {
      return issues;
    }

    issues.addAll(_sweepDirectory(expectedPaths));
    issues.addAll(_findDuplicates(contents));
    return issues;
  }

  List<AppStoreCaptureValidationIssue> _sweepDirectory(
    Set<String> expectedPaths,
  ) {
    final issues = <AppStoreCaptureValidationIssue>[];
    final rootPath = outputDir.path;
    for (final entity in outputDir.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final relative = appStoreCaptureRelativePath(rootPath, entity.path);
      final segments = relative.split('/');
      if (segments.any((segment) => segment.startsWith('.'))) {
        continue;
      }
      if (segments.length == 1) {
        if (allowedRootFiles.contains(segments.single) ||
            segments.single.toLowerCase().endsWith('.md')) {
          continue;
        }
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.unexpectedFile,
            path: relative,
            message: 'Unexpected file at the output root.',
          ),
        );
        continue;
      }
      if (!_fileNamePattern.hasMatch(segments.last)) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.invalidName,
            path: relative,
            message: 'Filename does not follow the '
                '<slot>-<screen>[-<locale>][-<theme>].png contract.',
          ),
        );
        continue;
      }
      if (!expectedPaths.contains(relative)) {
        issues.add(
          AppStoreCaptureValidationIssue(
            kind: AppStoreCaptureValidationIssue.unexpectedFile,
            path: relative,
            message: 'File maps to no slot in the requested matrix.',
          ),
        );
      }
    }
    return issues;
  }

  List<AppStoreCaptureValidationIssue> _findDuplicates(
    Map<String, Uint8List> contents,
  ) {
    final issues = <AppStoreCaptureValidationIssue>[];
    final byLength = <int, List<String>>{};
    for (final entry in contents.entries) {
      byLength.putIfAbsent(entry.value.length, () => <String>[]).add(entry.key);
    }
    for (final group in byLength.values) {
      if (group.length < 2) {
        continue;
      }
      group.sort();
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          if (_sameBytes(contents[group[i]]!, contents[group[j]]!)) {
            issues.add(
              AppStoreCaptureValidationIssue(
                kind: AppStoreCaptureValidationIssue.duplicateContent,
                path: group[j],
                message: 'Byte-identical to ${group[i]}; '
                    'two slots captured the same screen.',
              ),
            );
          }
        }
      }
    }
    return issues;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
