//
//  app_store_capture_waits.dart
//  Turing Lab
//
//  Bounded, state-based waits for the screenshot harness. Every stage advances
//  frames until an observable condition holds, or fails with the pending
//  condition named, so no capture depends on pumpAndSettle or on sleeping for
//  an arbitrary amount of time.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_store_capture_timeout.dart';

/// Frame-budgeted waits shared by every capture stage.
class AppStoreCaptureWaits {
  const AppStoreCaptureWaits({
    required this.frameBudget,
    required this.stageTimeout,
    required this.viewport,
  });

  /// Simulated duration advanced by each bounded pump.
  static const Duration frame = Duration(milliseconds: 16);

  /// Maximum frames a single wait may pump.
  final int frameBudget;

  /// Wall clock budget for stages that must run on the real event loop.
  final Duration stageTimeout;

  /// Logical viewport of the capture, used for visibility checks.
  final Size viewport;

  /// Pumps frames until [condition] holds, or reports the pending condition.
  Future<void> until(
    WidgetTester tester, {
    required String stage,
    required String pending,
    required bool Function() condition,
  }) async {
    await tester.pump();
    if (condition()) {
      return;
    }
    for (var pumped = 0; pumped < frameBudget; pumped++) {
      await tester.pump(frame);
      if (condition()) {
        return;
      }
    }
    throw AppStoreCaptureTimeout(
      stage: stage,
      pending: pending,
      budget: '$frameBudget frames of ${frame.inMilliseconds}ms',
    );
  }

  /// Advances frames until the scheduler stops requesting them. Widgets that
  /// animate forever (a focused caret, for instance) keep frames scheduled, so
  /// exhausting the budget is a normal, deterministic outcome here.
  Future<void> quiesce(WidgetTester tester) async {
    await tester.pump();
    for (var pumped = 0; pumped < frameBudget; pumped++) {
      if (!tester.binding.hasScheduledFrame) {
        return;
      }
      await tester.pump(frame);
    }
  }

  /// Advances simulated and real time until no loading affordance is on
  /// screen. Asset-backed panels resolve on the real event loop, so pumping
  /// frames alone would rasterize a half-loaded workspace.
  Future<void> untilLoaded(WidgetTester tester, {required String stage}) async {
    for (var round = 0; round < frameBudget; round++) {
      await quiesce(tester);
      if (!hasLoadingAffordance(tester)) {
        return;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(frame);
    }
    throw AppStoreCaptureTimeout(
      stage: stage,
      pending: 'a loading affordance was still rendered',
      budget: '$frameBudget rounds of ${frame.inMilliseconds}ms',
    );
  }

  /// True while the tree still renders a progress or pending-load indicator.
  bool hasLoadingAffordance(WidgetTester tester) {
    return isVisible(tester, find.byType(CircularProgressIndicator)) ||
        isVisible(tester, find.byType(LinearProgressIndicator)) ||
        isVisible(tester, find.byIcon(Icons.hourglass_top));
  }

  /// Waits until a [finder] match is laid out inside the capture viewport.
  Future<void> untilVisible(
    WidgetTester tester,
    Finder finder, {
    required String stage,
    required String pending,
  }) {
    return until(
      tester,
      stage: stage,
      pending: pending,
      condition: () => isVisible(tester, finder),
    );
  }

  /// True when [finder] resolves to a laid out widget inside the viewport.
  bool isVisible(WidgetTester tester, Finder finder) {
    final matches = finder.evaluate();
    if (matches.isEmpty) {
      return false;
    }
    final bounds = Offset.zero & viewport;
    for (final element in matches) {
      final renderObject = element.renderObject;
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        continue;
      }
      final topLeft = renderObject.localToGlobal(Offset.zero);
      final rect = topLeft & renderObject.size;
      if (!rect.isEmpty && rect.overlaps(bounds)) {
        return true;
      }
    }
    return false;
  }

  /// Runs [body] on the real event loop under the stage wall clock budget.
  Future<T> runReal<T extends Object>(
    WidgetTester tester,
    String stage,
    Future<T> Function() body,
  ) async {
    final result = await tester.runAsync<T>(
      () => body().timeout(
        stageTimeout,
        onTimeout: () => throw AppStoreCaptureTimeout(
          stage: stage,
          pending: 'asynchronous fixture never completed',
          budget: '${stageTimeout.inSeconds}s of wall clock time',
        ),
      ),
    );
    if (result == null) {
      throw AppStoreCaptureTimeout(
        stage: stage,
        pending:
            'the asynchronous stage did not complete on the real event loop',
        budget: '${stageTimeout.inSeconds}s of wall clock time',
      );
    }
    return result;
  }
}
