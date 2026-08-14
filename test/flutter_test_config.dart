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
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return testMain();
}
