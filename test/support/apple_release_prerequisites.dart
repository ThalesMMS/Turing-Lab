//
//  apple_release_prerequisites.dart
//  Turing Lab
//
//  Resolves whether the simulator/local integration level may run at all. A
//  run without a declared Apple target and device is reported as a not-run
//  prerequisite state, so a headless invocation can never be mistaken for a
//  passing simulator smoke test.
//

import 'package:flutter/foundation.dart';

import 'apple_release_target.dart';
import 'apple_release_test_level.dart';

/// Outcome of checking the prerequisites of a local Apple release level.
///
/// The harness cannot introspect the host toolchain from inside the test
/// process, so the operator declares the selected simulator or macOS target
/// with `--dart-define`. The declaration is verified against
/// [defaultTargetPlatform] and recorded verbatim as QA evidence.
@immutable
class AppleReleasePrerequisites {
  const AppleReleasePrerequisites._({
    required this.level,
    required this.declaredTargetId,
    required this.declaredDeviceId,
    required this.target,
    required this.notRunReason,
  });

  /// Define naming the Apple form factor under test.
  static const String targetDefine = 'APPLE_RELEASE_TARGET';

  /// Define naming the concrete simulator or device the run was pointed at.
  static const String deviceDefine = 'APPLE_RELEASE_DEVICE';

  static const String _declaredTarget = String.fromEnvironment(targetDefine);
  static const String _declaredDevice = String.fromEnvironment(deviceDefine);

  /// Checks the prerequisites of [level] against the current process.
  factory AppleReleasePrerequisites.resolve({
    required AppleReleaseTestLevel level,
  }) {
    AppleReleasePrerequisites notRun(String reason) {
      return AppleReleasePrerequisites._(
        level: level,
        declaredTargetId: _declaredTarget.isEmpty ? null : _declaredTarget,
        declaredDeviceId: _declaredDevice.isEmpty ? null : _declaredDevice,
        target: AppleReleaseTarget.byId(_declaredTarget),
        notRunReason: reason,
      );
    }

    if (kIsWeb) {
      return notRun(
        'Not run: the Apple release journeys need a local iOS simulator or the '
        'local macOS target, and this process is running on the web.',
      );
    }

    if (_declaredTarget.isEmpty || _declaredDevice.isEmpty) {
      return notRun(
        'Not run: no local Apple device was declared. Select one and declare '
        'it, for example:\n  ${level.command}',
      );
    }

    final target = AppleReleaseTarget.byId(_declaredTarget);
    if (target == null) {
      final supported =
          AppleReleaseTarget.all.map((candidate) => candidate.id).join(', ');
      return notRun(
        'Not run: "$_declaredTarget" is not a supported $targetDefine value. '
        'Supported values: $supported.',
      );
    }

    if (target.platform != defaultTargetPlatform) {
      return notRun(
        'Not run: $targetDefine=$_declaredTarget expects '
        '${target.platform.name}, but this process is running on '
        '${defaultTargetPlatform.name}. Re-run with `-d $_declaredDevice` so '
        'the journeys execute on the declared device.',
      );
    }

    return AppleReleasePrerequisites._(
      level: level,
      declaredTargetId: _declaredTarget,
      declaredDeviceId: _declaredDevice,
      target: target,
      notRunReason: null,
    );
  }

  /// Level whose prerequisites were checked.
  final AppleReleaseTestLevel level;

  /// Raw `APPLE_RELEASE_TARGET` value, or null when it was not declared.
  final String? declaredTargetId;

  /// Raw `APPLE_RELEASE_DEVICE` value, or null when it was not declared.
  final String? declaredDeviceId;

  /// Resolved target, or null when the declaration was missing or unknown.
  final AppleReleaseTarget? target;

  /// Why the level must not run, or null when every prerequisite is met.
  final String? notRunReason;

  /// Whether the level may execute.
  bool get isMet => notRunReason == null;

  /// The resolved target, for suites that already checked [isMet].
  AppleReleaseTarget get requiredTarget {
    final target = this.target;
    if (target == null) {
      throw StateError(notRunReason ?? 'No Apple release target was declared.');
    }
    return target;
  }

  /// Evidence line recorded in the Apple QA matrix for this run.
  String get report {
    final buffer = StringBuffer()
      ..writeln('${level.id} ${level.title} prerequisites')
      ..writeln('  $targetDefine: ${declaredTargetId ?? '<not declared>'}')
      ..writeln('  $deviceDefine: ${declaredDeviceId ?? '<not declared>'}')
      ..writeln('  process platform: ${defaultTargetPlatform.name}')
      ..writeln('  status: ${isMet ? 'met' : 'NOT MET'}');
    if (notRunReason != null) {
      buffer.writeln('  $notRunReason');
    }
    return buffer.toString();
  }
}
