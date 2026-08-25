//
//  app_store_capture_request.dart
//  Turing Lab
//
//  Reads the single capture a harness process must produce from the
//  environment the capture CLI exports, so the harness never guesses an output
//  location and can never be driven accidentally by plain `flutter test`.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:io';

import '../../tool/app_store/app_store_capture_case.dart';
import '../../tool/app_store/app_store_capture_matrix.dart';

/// One capture request handed to the harness process by the capture CLI.
class AppStoreCaptureRequest {
  const AppStoreCaptureRequest({
    required this.captureCase,
    required this.outputDir,
    required this.revision,
    required this.settleFrames,
    required this.stageTimeout,
    required this.fault,
  });

  /// Environment flag the CLI sets to authorize a capture process.
  static const String enableVariable = 'APP_STORE_CAPTURE';

  /// Instructions printed when the harness is invoked without a request.
  static const String missingRequestMessage =
      'The App Store capture harness is driven by '
      'tool/capture_app_store_screenshots.sh, which exports the profile, '
      'screen, locale, theme and output directory for a single slot. Run '
      '`tool/capture_app_store_screenshots.sh --help` instead of invoking this '
      'file directly.';

  /// Builds a request from [environment], or null when the process was not
  /// launched by the capture CLI.
  static AppStoreCaptureRequest? fromEnvironment(
    Map<String, String> environment,
  ) {
    if (environment[enableVariable] != '1') {
      return null;
    }
    final outputDir = environment['APP_STORE_OUTPUT'];
    if (outputDir == null || outputDir.isEmpty) {
      return null;
    }
    final captureCase = AppStoreCaptureCase(
      profile: AppStoreCaptureMatrix.profileById(
        environment['APP_STORE_PROFILE'] ?? '',
      ),
      screen: AppStoreCaptureMatrix.screenById(
        environment['APP_STORE_SCREEN'] ?? '',
      ),
      locale: AppStoreCaptureMatrix.localeById(
        environment['APP_STORE_LOCALE'] ?? AppStoreCaptureCase.defaultLocale,
      ),
      theme: AppStoreCaptureMatrix.themeById(
        environment['APP_STORE_THEME'] ?? AppStoreCaptureCase.defaultTheme,
      ),
    );
    return AppStoreCaptureRequest(
      captureCase: captureCase,
      outputDir: Directory(outputDir),
      revision: environment['APP_STORE_REVISION'] ?? 'unknown',
      settleFrames:
          int.tryParse(environment['APP_STORE_SETTLE_FRAMES'] ?? '') ?? 240,
      stageTimeout: Duration(
        milliseconds:
            int.tryParse(environment['APP_STORE_STAGE_TIMEOUT_MS'] ?? '') ??
                60000,
      ),
      fault: environment['APP_STORE_FAULT'],
    );
  }

  final AppStoreCaptureCase captureCase;
  final Directory outputDir;
  final String revision;

  /// Maximum frames a bounded wait may pump before it reports a timeout.
  final int settleFrames;

  /// Maximum wall clock time a real-async stage may take.
  final Duration stageTimeout;

  /// Optional injected fault used to exercise the diagnostics path.
  final String? fault;

  String get outputPath => '${outputDir.path}/${captureCase.relativePath}';
}
