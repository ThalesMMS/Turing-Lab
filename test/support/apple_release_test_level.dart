//
//  apple_release_test_level.dart
//  Turing Lab
//
//  Declares the three Apple release validation levels so every suite states
//  which level it belongs to, which local command runs it, and which
//  prerequisites it needs. Keeping the levels in one enum is what stops
//  signing, App Store Connect and physical-device work from leaking into the
//  ordinary `flutter test` run.
//

/// Validation levels defined for the Apple release scope.
///
/// The levels are deliberately ordered from the cheapest and most
/// deterministic to the most expensive and least automatable. A suite may only
/// depend on the prerequisites of its own level.
enum AppleReleaseTestLevel {
  /// Headless widget smoke over deterministic Apple platform variants.
  widgetPlatformSmoke(
    id: 'L1',
    title: 'Widget/platform smoke',
    command:
        'flutter test test/integration/apple_release_smoke_test.dart --concurrency=1',
    prerequisites:
        'None. Runs headless under the standard Flutter test runner, with no '
        'simulator, signing identity or hardware.',
  ),

  /// Journey smoke driven through `integration_test` on a declared local
  /// simulator or on the local macOS target.
  simulatorIntegrationSmoke(
    id: 'L2',
    title: 'Simulator/local integration smoke',
    command:
        'flutter test integration_test/apple_release_user_journeys_test.dart '
        '-d <device-id> '
        '--dart-define=APPLE_RELEASE_TARGET=<iphone|ipad|macos> '
        '--dart-define=APPLE_RELEASE_DEVICE=<device-id>',
    prerequisites:
        'A booted local iOS simulator or the local macOS target, selected with '
        '-d and declared with the APPLE_RELEASE_TARGET and '
        'APPLE_RELEASE_DEVICE defines.',
  ),

  /// Archive, signing, store-submission and real-hardware validation.
  releaseArtifactManualQa(
    id: 'L3',
    title: 'Release artifact/manual QA',
    command:
        'release/APPLE_QA_MATRIX.md workflow rows, driven by the release scripts',
    prerequisites:
        'Signed archives, signing identities, App Store Connect credentials '
        'and real hardware. Never executed by `flutter test`.',
  );

  const AppleReleaseTestLevel({
    required this.id,
    required this.title,
    required this.command,
    required this.prerequisites,
  });

  /// Stable short identifier used by the Apple QA matrix rows.
  final String id;

  /// Human readable level name.
  final String title;

  /// The exact local command (or document) that executes this level.
  final String command;

  /// What has to exist locally before this level can run at all.
  final String prerequisites;

  /// Whether this level is allowed to run inside an ordinary `flutter test`.
  bool get runsUnderFlutterTest => this == widgetPlatformSmoke;

  @override
  String toString() => '$id $title';
}
