//
//  apple_release_target.dart
//  Turing Lab
//
//  Describes the Apple form factors the release smoke suites parameterize
//  over. One target carries the platform, viewport, safe area and shell the
//  harness has to install, so the iPhone, iPad and macOS runs stay a data
//  difference instead of diverging test bodies.
//

import 'package:flutter/widgets.dart';

import 'apple_release_shell.dart';

/// An Apple form factor the release smoke suites run against.
@immutable
class AppleReleaseTarget {
  const AppleReleaseTarget({
    required this.id,
    required this.label,
    required this.platform,
    required this.logicalSize,
    required this.devicePixelRatio,
    required this.safeArea,
    required this.hasPointerAndKeyboard,
  });

  /// Compact iPhone layout with a notch and a home indicator.
  static const AppleReleaseTarget iPhone = AppleReleaseTarget(
    id: 'iphone',
    label: 'iPhone',
    platform: TargetPlatform.iOS,
    logicalSize: Size(430, 932),
    devicePixelRatio: 1,
    safeArea: EdgeInsets.only(top: 47, bottom: 34),
    hasPointerAndKeyboard: false,
  );

  /// iPad at the width where `HomePage` switches to the desktop rail.
  static const AppleReleaseTarget iPad = AppleReleaseTarget(
    id: 'ipad',
    label: 'iPad',
    platform: TargetPlatform.iOS,
    logicalSize: Size(1024, 1366),
    devicePixelRatio: 1,
    safeArea: EdgeInsets.only(top: 24, bottom: 20),
    hasPointerAndKeyboard: true,
  );

  /// Native macOS window wide enough to extend the navigation rail.
  static const AppleReleaseTarget macOS = AppleReleaseTarget(
    id: 'macos',
    label: 'macOS',
    platform: TargetPlatform.macOS,
    logicalSize: Size(1440, 900),
    devicePixelRatio: 1,
    safeArea: EdgeInsets.zero,
    hasPointerAndKeyboard: true,
  );

  /// Every target the widget/platform smoke level covers.
  static const List<AppleReleaseTarget> all = <AppleReleaseTarget>[
    iPhone,
    iPad,
    macOS,
  ];

  /// Resolves a target from the identifier used by the release commands.
  static AppleReleaseTarget? byId(String id) {
    for (final target in all) {
      if (target.id == id) {
        return target;
      }
    }
    return null;
  }

  /// Identifier accepted by `--dart-define=APPLE_RELEASE_TARGET`.
  final String id;

  /// Human readable name used in test names and failure diagnostics.
  final String label;

  /// Platform the widget smoke level pins through `TargetPlatformVariant`.
  final TargetPlatform platform;

  /// Logical viewport installed by the harness.
  final Size logicalSize;

  /// Device pixel ratio installed by the harness.
  ///
  /// Kept at 1.0 so logical and physical pixels coincide and the safe area
  /// below can be read as logical insets.
  final double devicePixelRatio;

  /// Safe area insets installed by the harness, in logical pixels.
  final EdgeInsets safeArea;

  /// Whether the target exposes a hardware keyboard and a pointer, which the
  /// macOS-flavoured assertions rely on.
  final bool hasPointerAndKeyboard;

  /// Shell `HomePage` renders at [logicalSize].
  AppleReleaseShell get expectedShell =>
      AppleReleaseShell.forWidth(logicalSize.width);

  /// Physical size the harness assigns to the test view.
  Size get physicalSize => logicalSize * devicePixelRatio;

  @override
  String toString() =>
      '$label (${platform.name}, ${logicalSize.width.toStringAsFixed(0)}x'
      '${logicalSize.height.toStringAsFixed(0)}, ${expectedShell.name} shell)';
}
