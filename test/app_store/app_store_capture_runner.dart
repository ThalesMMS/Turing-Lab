//
//  app_store_capture_runner.dart
//  Turing Lab
//
//  Entry point for a single App Store capture process. The filename
//  deliberately omits the `_test` suffix so `flutter test` never discovers the
//  capture matrix; tool/capture_app_store_screenshots.sh targets this file
//  explicitly and exports the slot to render.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'app_store_capture_fonts.dart';
import 'app_store_capture_request.dart';
import 'app_store_capture_session.dart';

Future<void> main() async {
  AppStoreCaptureRequest? request;
  String? requestError;
  try {
    request = AppStoreCaptureRequest.fromEnvironment(Platform.environment);
  } on ArgumentError catch (error) {
    requestError = error.message.toString();
  }

  final resolved = request;
  if (resolved == null) {
    test('app store capture harness is driven by the capture script', () {
      fail(
        requestError == null
            ? AppStoreCaptureRequest.missingRequestMessage
            : '$requestError\n\n'
                '${AppStoreCaptureRequest.missingRequestMessage}',
      );
    });
    return;
  }

  await loadAppStoreCaptureFonts();

  testWidgets('captures ${resolved.captureCase.id}', (tester) async {
    await AppStoreCaptureSession(resolved).capture(tester);
  });
}
