//
//  flutter_test_config.dart
//  Turing Lab
//
//  Global test configuration for golden tests using golden_toolkit.
//  This file is automatically loaded by Flutter when running tests and ensures
//  that fonts are properly loaded for consistent golden test rendering across
//  different environments.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Native goldens need explicit font loading. On Web, the engine owns fonts;
  // golden_toolkit's rootBundle load runs before the suite is registered and
  // requests an unavailable FontManifest.json, preventing test discovery.
  if (!kIsWeb) {
    await loadAppFonts();
  }
  return testMain();
}
