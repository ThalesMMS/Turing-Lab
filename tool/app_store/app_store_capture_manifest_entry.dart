//
//  app_store_capture_manifest_entry.dart
//  Turing Lab
//
//  Machine-readable record describing one capture attempt: the slot it fills,
//  the geometry it was rendered at, the revision it came from, and whether the
//  attempt succeeded.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'app_store_capture_case.dart';

/// Single manifest row emitted for every attempted capture.
class AppStoreCaptureManifestEntry {
  const AppStoreCaptureManifestEntry({
    required this.path,
    required this.profile,
    required this.screen,
    required this.slot,
    required this.locale,
    required this.theme,
    required this.logicalWidth,
    required this.logicalHeight,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.devicePixelRatio,
    required this.revision,
    required this.capturedAt,
    required this.status,
    required this.approved,
    this.failure,
  });

  /// Status recorded for a capture that produced a validated PNG.
  static const String statusCaptured = 'captured';

  /// Status recorded for a capture that raised before writing a PNG.
  static const String statusFailed = 'failed';

  factory AppStoreCaptureManifestEntry.fromJson(Map<String, Object?> json) {
    return AppStoreCaptureManifestEntry(
      path: json['path']! as String,
      profile: json['profile']! as String,
      screen: json['screen']! as String,
      slot: (json['slot']! as num).toInt(),
      locale: json['locale']! as String,
      theme: json['theme']! as String,
      logicalWidth: (json['logicalWidth']! as num).toDouble(),
      logicalHeight: (json['logicalHeight']! as num).toDouble(),
      pixelWidth: (json['pixelWidth']! as num).toInt(),
      pixelHeight: (json['pixelHeight']! as num).toInt(),
      devicePixelRatio: (json['devicePixelRatio']! as num).toDouble(),
      revision: json['revision']! as String,
      capturedAt: json['capturedAt']! as String,
      status: json['status']! as String,
      approved: json['approved']! as bool,
      failure: json['failure'] as String?,
    );
  }

  /// Builds an entry from [captureCase] using the geometry the profile
  /// declares, so the manifest always mirrors the approved slot contract.
  factory AppStoreCaptureManifestEntry.forCase(
    AppStoreCaptureCase captureCase, {
    required String revision,
    required String capturedAt,
    required String status,
    String? failure,
  }) {
    final profile = captureCase.profile;
    return AppStoreCaptureManifestEntry(
      path: captureCase.relativePath,
      profile: profile.id,
      screen: captureCase.screen.id,
      slot: captureCase.screen.slot,
      locale: captureCase.locale,
      theme: captureCase.theme,
      logicalWidth: profile.logicalWidth,
      logicalHeight: profile.logicalHeight,
      pixelWidth: profile.pixelWidth,
      pixelHeight: profile.pixelHeight,
      devicePixelRatio: profile.devicePixelRatio,
      revision: revision,
      capturedAt: capturedAt,
      status: status,
      approved: captureCase.isApproved,
      failure: failure,
    );
  }

  final String path;
  final String profile;
  final String screen;
  final int slot;
  final String locale;
  final String theme;
  final double logicalWidth;
  final double logicalHeight;
  final int pixelWidth;
  final int pixelHeight;
  final double devicePixelRatio;
  final String revision;
  final String capturedAt;
  final String status;
  final bool approved;
  final String? failure;

  bool get isCaptured => status == statusCaptured;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
      'profile': profile,
      'screen': screen,
      'slot': slot,
      'locale': locale,
      'theme': theme,
      'logicalWidth': logicalWidth,
      'logicalHeight': logicalHeight,
      'pixelWidth': pixelWidth,
      'pixelHeight': pixelHeight,
      'devicePixelRatio': devicePixelRatio,
      'revision': revision,
      'capturedAt': capturedAt,
      'status': status,
      'approved': approved,
      if (failure != null) 'failure': failure,
    };
  }
}
