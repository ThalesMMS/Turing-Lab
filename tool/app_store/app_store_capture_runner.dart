//
//  app_store_capture_runner.dart
//  Turing Lab
//
//  Drives the capture matrix one isolated `flutter test` process per slot,
//  enforces the per-capture wall clock budget, prints actionable diagnostics
//  on timeout or failure, and folds every attempt into the run manifest.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'app_store_capture_case.dart';
import 'app_store_capture_manifest.dart';
import 'app_store_capture_manifest_entry.dart';
import 'app_store_capture_options.dart';

/// Executes the resolved capture matrix and reports the process exit code.
class AppStoreCaptureRunner {
  AppStoreCaptureRunner({
    required this.options,
    required this.repoRoot,
    required this.flutterBin,
    required this.revision,
    required this.outputDir,
  });

  /// Entry point executed by each capture process.
  static const String harnessPath =
      'test/app_store/app_store_capture_runner.dart';

  /// Grace period granted to a timed out capture before it is killed.
  static const Duration terminationGrace = Duration(seconds: 5);

  /// Number of trailing output lines echoed back in a failure diagnostic.
  static const int diagnosticTailLines = 40;

  final AppStoreCaptureOptions options;
  final String repoRoot;
  final String flutterBin;
  final String revision;
  final Directory outputDir;

  Future<int> run(List<AppStoreCaptureCase> cases) async {
    outputDir.createSync(recursive: true);
    final failures = <String>[];
    final extraEntries = <AppStoreCaptureManifestEntry>[];

    try {
      for (var index = 0; index < cases.length; index++) {
        final captureCase = cases[index];
        stdout.writeln(
          '==> [${index + 1}/${cases.length}] ${captureCase.id} '
          '-> ${captureCase.relativePath}',
        );
        final outcome = await _captureOne(captureCase);
        if (outcome == null) {
          continue;
        }
        failures.add(captureCase.id);
        extraEntries.add(
          AppStoreCaptureManifestEntry.forCase(
            captureCase,
            revision: revision,
            capturedAt: DateTime.now().toUtc().toIso8601String(),
            status: AppStoreCaptureManifestEntry.statusFailed,
            failure: outcome,
          ),
        );
        if (!options.bestEffort) {
          stderr.writeln(
            'Stopping after the first failed capture. '
            'Pass --best-effort to continue through the remaining slots.',
          );
          break;
        }
      }
    } finally {
      _writeManifest(extraEntries);
    }

    if (failures.isEmpty) {
      return 0;
    }
    stderr.writeln('Failed captures: ${failures.join(', ')}');
    return 1;
  }

  /// Runs one capture, returning null on success or a failure summary.
  Future<String?> _captureOne(AppStoreCaptureCase captureCase) async {
    final environment = <String, String>{
      'APP_STORE_CAPTURE': '1',
      'APP_STORE_PROFILE': captureCase.profile.id,
      'APP_STORE_SCREEN': captureCase.screen.id,
      'APP_STORE_LOCALE': captureCase.locale,
      'APP_STORE_THEME': captureCase.theme,
      'APP_STORE_OUTPUT': outputDir.path,
      'APP_STORE_REVISION': revision,
      'APP_STORE_SETTLE_FRAMES': '${options.settleBudgetFrames}',
      'APP_STORE_STAGE_TIMEOUT_MS': '${_stageTimeout.inMilliseconds}',
      if (options.fault != null) 'APP_STORE_FAULT': options.fault!,
    };

    final process = await Process.start(
      flutterBin,
      <String>[
        'test',
        harnessPath,
        '--reporter',
        'compact',
        '--timeout',
        '${_testTimeout.inSeconds}s',
      ],
      workingDirectory: repoRoot,
      environment: environment,
    );

    final tail = <String>[];
    final drained = <Future<void>>[
      _pipe(process.stdout, stdout, tail),
      _pipe(process.stderr, stderr, tail),
    ];

    int exitCode;
    try {
      exitCode = await process.exitCode.timeout(
        Duration(seconds: options.timeoutSeconds),
      );
    } on TimeoutException {
      process.kill();
      try {
        await process.exitCode.timeout(terminationGrace);
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
      }
      await Future.wait(drained);
      return _reportFailure(
        captureCase,
        headline: 'TIMEOUT after ${options.timeoutSeconds}s',
        pending: 'The capture process never exited. The stage budget is '
            '${_stageTimeout.inSeconds}s and the in-test budget is '
            '${_testTimeout.inSeconds}s, so the harness itself is stuck.',
        tail: tail,
      );
    }

    await Future.wait(drained);
    if (exitCode == 0) {
      return null;
    }
    return _reportFailure(
      captureCase,
      headline: 'FAILED with exit code $exitCode',
      pending: 'See the harness diagnostics above for the stage that raised.',
      tail: tail,
    );
  }

  Duration get _stageTimeout =>
      Duration(seconds: (options.timeoutSeconds / 3).ceil().clamp(10, 120));

  Duration get _testTimeout =>
      Duration(seconds: (options.timeoutSeconds * 2 / 3).ceil());

  Future<void> _pipe(
    Stream<List<int>> source,
    IOSink sink,
    List<String> tail,
  ) {
    return source
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      sink.writeln(line);
      tail.add(line);
      if (tail.length > diagnosticTailLines) {
        tail.removeAt(0);
      }
    }).asFuture<void>();
  }

  String _reportFailure(
    AppStoreCaptureCase captureCase, {
    required String headline,
    required String pending,
    required List<String> tail,
  }) {
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('--- APP STORE CAPTURE FAILURE ---')
      ..writeln('  outcome: $headline')
      ..writeln('  profile: ${captureCase.profile}')
      ..writeln(
        '  screen:  ${captureCase.screen} (${captureCase.screen.description})',
      )
      ..writeln('  locale:  ${captureCase.locale}')
      ..writeln('  theme:   ${captureCase.theme}')
      ..writeln('  target:  ${outputDir.path}/${captureCase.relativePath}')
      ..writeln('  pending: $pending')
      ..writeln('  rerun:   ${rerunCommand(captureCase)}');
    if (tail.isNotEmpty) {
      buffer.writeln('  last ${tail.length} output lines:');
      for (final line in tail) {
        buffer.writeln('    $line');
      }
    }
    buffer.writeln('--- END APP STORE CAPTURE FAILURE ---');
    stderr.write(buffer.toString());
    return headline;
  }

  /// Command that reproduces exactly one capture.
  String rerunCommand(AppStoreCaptureCase captureCase) {
    return 'tool/capture_app_store_screenshots.sh '
        '--profile ${captureCase.profile.id} '
        '--screen ${captureCase.screen.id} '
        '--locale ${captureCase.locale} '
        '--theme ${captureCase.theme} '
        '--output ${options.outputDir}';
  }

  void _writeManifest(List<AppStoreCaptureManifestEntry> extraEntries) {
    final parts = AppStoreCaptureManifest.drainParts(outputDir);
    if (parts.isEmpty && extraEntries.isEmpty) {
      return;
    }
    final byPath = <String, AppStoreCaptureManifestEntry>{
      for (final part in parts) part.path: part,
    };
    // A sidecar part carries the stage that raised, so it outranks the coarse
    // process-level summary; the summary only fills in when the harness died
    // before writing one, or when it claimed success and the process failed.
    final updates = <AppStoreCaptureManifestEntry>[
      ...parts,
      ...extraEntries.where((entry) {
        final part = byPath[entry.path];
        return part == null || part.isCaptured;
      }),
    ];
    AppStoreCaptureManifest.read(outputDir)
        .merge(updates)
        .write(outputDir, generator: 'tool/capture_app_store_screenshots.sh');
  }
}
