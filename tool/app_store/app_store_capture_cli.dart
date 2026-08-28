//
//  app_store_capture_cli.dart
//  Turing Lab
//
//  Command line front end for the local App Store screenshot pipeline. It
//  resolves the requested matrix, drives the capture runner, and validates the
//  resulting directory and manifest. This tool is local-only by design and is
//  never wired into CI.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:io';

import 'app_store_capture_case.dart';
import 'app_store_capture_manifest.dart';
import 'app_store_capture_options.dart';
import 'app_store_capture_runner.dart';
import 'app_store_capture_validator.dart';

Future<void> main(List<String> args) async {
  AppStoreCaptureOptions options;
  try {
    options = AppStoreCaptureOptions.parse(args);
  } on FormatException catch (error) {
    stderr.writeln('error: ${error.message}');
    stderr.writeln('');
    stderr.writeln(AppStoreCaptureOptions.usage);
    exitCode = 64;
    return;
  } on ArgumentError catch (error) {
    stderr.writeln('error: ${error.message}');
    stderr.writeln('');
    stderr.writeln(AppStoreCaptureOptions.usage);
    exitCode = 64;
    return;
  }

  if (options.help) {
    stdout.writeln(AppStoreCaptureOptions.usage);
    return;
  }

  final repoRoot = _repoRoot();
  final cases = options.resolveCases();
  final outputDir = Directory(_absolutePath(repoRoot, options.outputDir));

  if (options.command == 'plan') {
    stdout.writeln('output: ${outputDir.path}');
    stdout.writeln('cases: ${cases.length}');
    for (final captureCase in cases) {
      stdout.writeln(
        '${captureCase.id}\t${captureCase.relativePath}\t'
        '${captureCase.profile.pixelWidth}x${captureCase.profile.pixelHeight}',
      );
    }
    return;
  }

  if (options.command == 'validate') {
    exitCode = _validate(options, outputDir, cases);
    return;
  }

  final runner = AppStoreCaptureRunner(
    options: options,
    repoRoot: repoRoot,
    flutterBin: _flutterBin(),
    revision: _revision(repoRoot),
    outputDir: outputDir,
  );
  final captureExit = await runner.run(cases);
  if (captureExit != 0) {
    exitCode = captureExit;
    if (!options.bestEffort) {
      return;
    }
  }

  if (!options.runValidation) {
    return;
  }
  final validationExit = _validate(options, outputDir, cases);
  if (validationExit != 0) {
    exitCode = validationExit;
  }
}

int _validate(
  AppStoreCaptureOptions options,
  Directory outputDir,
  List<AppStoreCaptureCase> cases,
) {
  final validator = AppStoreCaptureValidator(
    outputDir: outputDir,
    cases: cases,
    strict: options.coversApprovedMatrix,
  );
  final issues = validator.validate();
  if (issues.isEmpty) {
    stdout.writeln(
      'Validated ${cases.length} capture(s) in ${outputDir.path} '
      '(manifest: ${AppStoreCaptureManifest.fileName}).',
    );
    return 0;
  }
  stderr.writeln('');
  stderr.writeln('--- APP STORE CAPTURE VALIDATION FAILED ---');
  for (final issue in issues) {
    stderr.writeln('  $issue');
  }
  stderr.writeln('--- END APP STORE CAPTURE VALIDATION FAILED ---');
  return 2;
}

String _repoRoot() {
  final fromEnv = Platform.environment['APP_STORE_REPO_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  return Directory.current.path;
}

String _flutterBin() {
  final fromEnv = Platform.environment['FLUTTER_BIN'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    if (Platform.isWindows &&
        !fromEnv.toLowerCase().endsWith('.bat') &&
        File('$fromEnv.bat').existsSync()) {
      return '$fromEnv.bat';
    }
    return fromEnv;
  }
  return Platform.isWindows ? 'flutter.bat' : 'flutter';
}

String _absolutePath(String repoRoot, String path) {
  if (path.startsWith('/')) {
    return path;
  }
  return '$repoRoot/$path';
}

String _revision(String repoRoot) {
  final fromEnv = Platform.environment['APP_STORE_REVISION'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  try {
    final head = Process.runSync(
      'git',
      <String>['rev-parse', '--short', 'HEAD'],
      workingDirectory: repoRoot,
    );
    if (head.exitCode != 0) {
      return 'unknown';
    }
    final revision = (head.stdout as String).trim();
    final dirty = Process.runSync(
      'git',
      <String>['diff', '--quiet', 'HEAD'],
      workingDirectory: repoRoot,
    );
    return dirty.exitCode == 0 ? revision : '$revision-dirty';
  } on ProcessException {
    return 'unknown';
  }
}
