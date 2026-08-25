//
//  app_store_capture_session.dart
//  Turing Lab
//
//  Runs one App Store capture end to end: pins the viewport, locale, theme and
//  fixtures, prepares the journey through bounded waits, rasterizes the frame,
//  records a manifest row, and prints actionable diagnostics before rethrowing
//  when a stage fails.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';

import '../../tool/app_store/app_store_capture_manifest.dart';
import '../../tool/app_store/app_store_capture_manifest_entry.dart';
import '../../tool/app_store/app_store_png_size.dart';
import 'app_store_capture_request.dart';
import 'app_store_capture_settings_repository.dart';
import 'app_store_capture_simulation_notifier.dart';
import 'app_store_capture_screens.dart';
import 'app_store_capture_timeout.dart';
import 'app_store_capture_waits.dart';

/// Executes a single capture request inside a widget test process.
class AppStoreCaptureSession {
  AppStoreCaptureSession(this.request);

  /// Maximum number of visible strings echoed in a failure diagnostic.
  static const int diagnosticTextSamples = 25;

  final AppStoreCaptureRequest request;

  Future<void> capture(WidgetTester tester) async {
    final captureCase = request.captureCase;
    final profile = captureCase.profile;
    final logicalSize = Size(profile.logicalWidth, profile.logicalHeight);
    final waits = AppStoreCaptureWaits(
      frameBudget: request.settleFrames,
      stageTimeout: request.stageTimeout,
      viewport: logicalSize,
    );

    final previousOnError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      flutterErrors.add(details);
      previousOnError?.call(details);
    };

    var stage = 'bootstrap';
    ProviderContainer? container;

    try {
      await resetDependencies();
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final preferences = await initializeSharedPreferences();

      _applyViewOverrides(tester, logicalSize);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
        timeDilation = 1.0;
      });
      await tester.binding.setSurfaceSize(logicalSize);

      stage = 'mount';
      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            settingsRepositoryProvider.overrideWithValue(
              AppStoreCaptureSettingsRepository(
                localeCode: captureCase.locale,
                themeMode: captureCase.theme,
              ),
            ),
            automatonSimulationProvider.overrideWith(
              (ref) => AppStoreCaptureSimulationNotifier(
                ref: ref,
                tracePersistenceService: ref.watch(
                  dataTracePersistenceServiceProvider,
                ),
              ),
            ),
          ],
          child: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: logicalSize.width,
              height: logicalSize.height,
              child: const TuringLabApp(),
            ),
          ),
        ),
      );
      await waits.untilLoaded(tester, stage: 'mount');

      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      container = ProviderScope.containerOf(
        tester.element(materialAppFinder),
        listen: false,
      );

      stage = 'prepare';
      await _injectFault(tester, waits);
      await AppStoreCaptureScreens(
        tester: tester,
        container: container,
        waits: waits,
        localizations: localizationsFor(captureCase.locale),
      ).prepare(captureCase.screen);

      stage = 'settle';
      FocusManager.instance.primaryFocus?.unfocus();
      await waits.untilLoaded(tester, stage: 'settle');

      if (flutterErrors.isNotEmpty) {
        throw StateError(
          'Flutter reported ${flutterErrors.length} exception(s) while '
          'preparing ${captureCase.id}.',
        );
      }

      stage = 'rasterize';
      await _writeScreenshot(tester, repaintKey, profile.devicePixelRatio);

      stage = 'manifest';
      _recordManifest(
        status: AppStoreCaptureManifestEntry.statusCaptured,
      );
    } catch (error, stackTrace) {
      _reportDiagnostics(
        tester: tester,
        container: container,
        stage: stage,
        error: error,
        stackTrace: stackTrace,
        flutterErrors: flutterErrors,
      );
      _recordManifest(
        status: AppStoreCaptureManifestEntry.statusFailed,
        failure: '$stage: $error',
      );
      rethrow;
    } finally {
      FlutterError.onError = previousOnError;
      // Tearing the tree down must never mask the failure being propagated.
      try {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(AppStoreCaptureWaits.frame);
      } on Object catch (error) {
        debugPrint('App Store capture teardown reported: $error');
      }
    }
  }

  /// Localization bundle used to assert on visible copy for [locale].
  static AppLocalizations localizationsFor(String locale) {
    return locale == 'pt' ? AppLocalizationsPt() : AppLocalizationsEn();
  }

  void _applyViewOverrides(WidgetTester tester, Size logicalSize) {
    final profile = request.captureCase.profile;
    tester.view
      ..physicalSize = Size(
        profile.pixelWidth.toDouble(),
        profile.pixelHeight.toDouble(),
      )
      ..devicePixelRatio = profile.devicePixelRatio
      ..padding = FakeViewPadding.zero
      ..viewPadding = FakeViewPadding.zero
      ..viewInsets = FakeViewPadding.zero
      ..systemGestureInsets = FakeViewPadding.zero;
    tester.platformDispatcher
      ..textScaleFactorTestValue = 1.0
      ..platformBrightnessTestValue = request.captureCase.theme == 'dark'
          ? Brightness.dark
          : Brightness.light
      ..localeTestValue = Locale(request.captureCase.locale)
      ..localesTestValue = <Locale>[Locale(request.captureCase.locale)]
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures();
    timeDilation = 1.0;
  }

  Future<void> _injectFault(
    WidgetTester tester,
    AppStoreCaptureWaits waits,
  ) async {
    final fault = request.fault;
    if (fault == null || fault.isEmpty) {
      return;
    }
    switch (fault) {
      case 'block-prepare':
        await waits.runReal<Object>(
          tester,
          'injected-fault',
          () => Completer<Object>().future,
        );
      case 'block-settle':
        await waits.until(
          tester,
          stage: 'injected-fault',
          pending: 'the injected fixture condition never becomes true',
          condition: () => false,
        );
      default:
        throw StateError(
          'Unknown injected fault "$fault". '
          'Supported faults: block-prepare, block-settle.',
        );
    }
  }

  Future<void> _writeScreenshot(
    WidgetTester tester,
    GlobalKey repaintKey,
    double pixelRatio,
  ) async {
    final boundary =
        repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final outputPath = request.outputPath;
    // Rasterizing and PNG-encoding complete on the engine's real event loop.
    // Awaiting them from inside the test's fake-async zone never resolves and
    // hangs the capture, so they have to run through `runAsync`.
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('Failed to encode screenshot for $outputPath');
        }

        final file = File(outputPath);
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(byteData.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });

    final profile = request.captureCase.profile;
    final written = AppStorePngSize.read(File(outputPath));
    if (written.width != profile.pixelWidth ||
        written.height != profile.pixelHeight) {
      throw StateError(
        'Rendered $written but the ${profile.id} slot requires '
        '${profile.pixelWidth}x${profile.pixelHeight}.',
      );
    }
  }

  void _recordManifest({required String status, String? failure}) {
    AppStoreCaptureManifest.writePart(
      request.outputDir,
      AppStoreCaptureManifestEntry.forCase(
        request.captureCase,
        revision: request.revision,
        capturedAt: DateTime.now().toUtc().toIso8601String(),
        status: status,
        failure: failure,
      ),
    );
  }

  void _reportDiagnostics({
    required WidgetTester tester,
    required ProviderContainer? container,
    required String stage,
    required Object error,
    required StackTrace stackTrace,
    required List<FlutterErrorDetails> flutterErrors,
  }) {
    final captureCase = request.captureCase;
    final pending = error is AppStoreCaptureTimeout
        ? '${error.pending} (budget: ${error.budget})'
        : error.toString();
    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('--- APP STORE CAPTURE DIAGNOSTICS ---')
      ..writeln('  case:    ${captureCase.id}')
      ..writeln('  profile: ${captureCase.profile}')
      ..writeln('  screen:  ${captureCase.screen.description}')
      ..writeln('  locale:  ${captureCase.locale}')
      ..writeln('  theme:   ${captureCase.theme}')
      ..writeln('  output:  ${request.outputPath}')
      ..writeln('  stage:   $stage')
      ..writeln(
        '  waits:   ${request.settleFrames} frames / '
        '${request.stageTimeout.inSeconds}s per real-async stage',
      )
      ..writeln('  pending: $pending');

    if (container != null) {
      buffer.writeln(
        '  route:   workspace index '
        '${container.read(homeNavigationProvider)}',
      );
    } else {
      buffer.writeln('  route:   the app was never mounted');
    }

    final visibleText = _visibleText(tester);
    buffer.writeln('  visible text (${visibleText.length}):');
    for (final text in visibleText) {
      buffer.writeln('    - $text');
    }

    if (flutterErrors.isNotEmpty) {
      buffer.writeln('  flutter exceptions (${flutterErrors.length}):');
      for (final details in flutterErrors) {
        buffer.writeln('    - ${details.exceptionAsString()}');
      }
    }

    buffer
      ..writeln('  stack:')
      ..writeln(
        stackTrace
            .toString()
            .split('\n')
            .take(12)
            .map((line) => '    $line')
            .join('\n'),
      )
      ..writeln('--- END APP STORE CAPTURE DIAGNOSTICS ---');
    debugPrint(buffer.toString());
  }

  List<String> _visibleText(WidgetTester tester) {
    final samples = <String>[];
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      final data = widget.data ?? widget.textSpan?.toPlainText();
      if (data == null || data.trim().isEmpty) {
        continue;
      }
      final trimmed = data.trim();
      if (samples.contains(trimmed)) {
        continue;
      }
      samples.add(trimmed);
      if (samples.length >= diagnosticTextSamples) {
        break;
      }
    }
    return samples;
  }
}
