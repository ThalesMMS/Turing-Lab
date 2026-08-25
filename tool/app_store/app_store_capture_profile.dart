//
//  app_store_capture_profile.dart
//  Turing Lab
//
//  Declares one App Store device profile: the exact pixel canvas Apple expects
//  for a media slot plus the device pixel ratio used to derive the logical
//  viewport the capture harness renders into.
//
//  Thales Matheus Mendonça Santos - August 2026
//

/// Device class targeted by a single App Store screenshot directory.
class AppStoreCaptureProfile {
  const AppStoreCaptureProfile({
    required this.id,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.devicePixelRatio,
    required this.description,
  });

  /// Directory name and CLI identifier, for example `iphone-6.9`.
  final String id;

  /// Required App Store Connect width in device pixels.
  final int pixelWidth;

  /// Required App Store Connect height in device pixels.
  final int pixelHeight;

  /// Ratio between device pixels and logical pixels during capture.
  final double devicePixelRatio;

  /// Human readable slot description used in diagnostics and the manifest.
  final String description;

  double get logicalWidth => pixelWidth / devicePixelRatio;

  double get logicalHeight => pixelHeight / devicePixelRatio;

  @override
  String toString() => '$id (${pixelWidth}x$pixelHeight @${devicePixelRatio}x)';
}
