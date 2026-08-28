//
//  app_store_capture_fonts.dart
//  Turing Lab
//
//  Registers the final monospace fallback used by automata notation. Widget
//  tests otherwise render unsupported symbols with the test font's .notdef
//  glyph, even though platform builds resolve them through system fonts.
//

import 'dart:io';

import 'package:flutter/services.dart';

const String _captureFallbackFamily = 'Roboto Mono';
const String _captureFallbackPath = 'test/app_store/fonts/WorkSans-Regular.ttf';

Future<void> loadAppStoreCaptureFonts() async {
  final repoRoot = Platform.environment['APP_STORE_REPO_ROOT'];
  final fontPath = repoRoot == null || repoRoot.isEmpty
      ? _captureFallbackPath
      : '$repoRoot/$_captureFallbackPath';
  final bytes = await File(fontPath).readAsBytes();
  final loader = FontLoader(_captureFallbackFamily)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
