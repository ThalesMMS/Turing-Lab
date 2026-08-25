//
//  app_store_capture_validation_issue.dart
//  Turing Lab
//
//  One problem reported by the screenshot validator, carrying the machine
//  readable kind, the offending path and an operator-facing explanation.
//
//  Thales Matheus Mendonça Santos - August 2026
//

/// Problem detected while validating a capture output directory.
class AppStoreCaptureValidationIssue {
  const AppStoreCaptureValidationIssue({
    required this.kind,
    required this.path,
    required this.message,
  });

  /// An approved slot has no rendered PNG.
  static const String missingSlot = 'missing-slot';

  /// A PNG does not match the pixel size App Store Connect requires.
  static const String dimensionMismatch = 'dimension-mismatch';

  /// A file inside the output directory maps to no known slot.
  static const String unexpectedFile = 'unexpected-file';

  /// A filename does not follow the slot naming contract.
  static const String invalidName = 'invalid-name';

  /// Two different slots hold byte-identical images.
  static const String duplicateContent = 'duplicate-content';

  /// The manifest has no row for a captured slot.
  static const String manifestMissingEntry = 'manifest-missing-entry';

  /// A manifest row disagrees with the slot it claims to describe.
  static const String manifestMismatch = 'manifest-mismatch';

  /// The manifest records the capture as failed.
  static const String captureFailed = 'capture-failed';

  final String kind;
  final String path;
  final String message;

  @override
  String toString() => '[$kind] $path: $message';
}
