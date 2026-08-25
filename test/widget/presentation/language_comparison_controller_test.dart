//
//  language_comparison_controller_test.dart
//  Turing Lab
//
//  Suite for LanguageComparisonController: request generations, stale-result
//  rejection, disposal safety, and the guard that refuses a verdict whose
//  witness was not computed from the requested automaton revisions.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/presentation/widgets/language_comparison_controller.dart';

FSA _buildFsa({
  required String id,
  int stateCount = 2,
  DateTime? modified,
}) {
  final states = <automaton_state.State>[];
  for (var i = 0; i < stateCount; i++) {
    states.add(
      automaton_state.State(
        id: '$id-q$i',
        label: 'q$i',
        position: Vector2(i * 100.0, 0),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      ),
    );
  }

  final transitions = <FSATransition>{};
  for (var i = 0; i < stateCount - 1; i++) {
    transitions.add(
      FSATransition.deterministic(
        id: '$id-t$i',
        fromState: states[i],
        toState: states[i + 1],
        symbol: 'a',
      ),
    );
  }

  return FSA(
    id: id,
    name: id,
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 1, 1),
    modified: modified ?? DateTime.utc(2026, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

EquivalenceComparisonResult _resultFor(
  LanguageComparisonRequest request, {
  required bool isEquivalent,
  String? distinguishingString,
}) {
  return EquivalenceComparisonResult(
    originalAutomaton: request.automatonA,
    comparedAutomaton: request.automatonB,
    isEquivalent: isEquivalent,
    distinguishingString: distinguishingString,
    executionTimeMs: 5,
  );
}

LanguageComparisonRequest _request({String suffix = ''}) {
  return LanguageComparisonRequest(
    automatonA: _buildFsa(id: 'a$suffix'),
    automatonB: _buildFsa(id: 'b$suffix'),
  );
}

void main() {
  group('LanguageComparisonRequest', () {
    test('fingerprints two edits of the same document differently', () {
      final first = LanguageComparisonRequest(
        automatonA: _buildFsa(id: 'doc', stateCount: 2),
        automatonB: _buildFsa(id: 'other'),
      );
      final second = LanguageComparisonRequest(
        automatonA: _buildFsa(
          id: 'doc',
          stateCount: 3,
          modified: DateTime.utc(2026, 2, 1),
        ),
        automatonB: _buildFsa(id: 'other'),
      );

      // Automaton equality compares only id, name and type, which is exactly
      // why the revision fingerprint has to add more than that.
      expect(first.automatonA, equals(second.automatonA));
      expect(first.revision, isNot(second.revision));
      expect(
        first.producedThis(_resultFor(second, isEquivalent: true)),
        isFalse,
      );
      expect(
        first.producedThis(_resultFor(first, isEquivalent: true)),
        isTrue,
      );
    });
  });

  group('LanguageComparisonController', () {
    test('publishes the outcome of a completed request', () async {
      final request = _request();
      final controller = LanguageComparisonController(
        runner: (request) async => LanguageComparisonCompleted(
          _resultFor(request, isEquivalent: true),
        ),
      );
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.compare(request);

      expect(controller.snapshot.isRunning, isFalse);
      expect(identical(controller.snapshot.request, request), isTrue);
      expect(
        controller.snapshot.outcome?.status,
        LanguageComparisonStatus.equivalent,
      );
      // One notification for the running state, one for the outcome.
      expect(notifications, 2);
    });

    test('ignores a stale result once a newer request is started', () async {
      final slow = Completer<LanguageComparisonOutcome>();
      final fast = Completer<LanguageComparisonOutcome>();
      final staleRequest = _request(suffix: '-old');
      final freshRequest = _request(suffix: '-new');

      final controller = LanguageComparisonController(
        runner: (request) =>
            request == staleRequest ? slow.future : fast.future,
      );
      addTearDown(controller.dispose);

      final staleRun = controller.compare(staleRequest);
      expect(controller.generation, 1);

      final freshRun = controller.compare(freshRequest);
      expect(controller.generation, 2);

      fast.complete(
        LanguageComparisonCompleted(
          _resultFor(
            freshRequest,
            isEquivalent: false,
            distinguishingString: 'new',
          ),
        ),
      );
      await freshRun;

      // The older comparison finishes last and must be discarded.
      slow.complete(
        LanguageComparisonCompleted(
          _resultFor(
            staleRequest,
            isEquivalent: true,
          ),
        ),
      );
      await staleRun;

      expect(identical(controller.snapshot.request, freshRequest), isTrue);
      expect(
        controller.snapshot.outcome?.status,
        LanguageComparisonStatus.notEquivalent,
      );
      final outcome = controller.snapshot.outcome;
      expect(outcome, isA<LanguageComparisonCompleted>());
      expect(
        (outcome! as LanguageComparisonCompleted).result.distinguishingString,
        'new',
      );
    });

    test('drops a result that arrives after disposal', () async {
      final pending = Completer<LanguageComparisonOutcome>();
      final controller = LanguageComparisonController(
        runner: (_) => pending.future,
      );

      final run = controller.compare(_request());
      controller.dispose();

      pending.complete(
        const LanguageComparisonFailure(
          reason: LanguageComparisonFailureReason.timeout,
        ),
      );

      // Publishing into a disposed ChangeNotifier would throw.
      await expectLater(run, completes);
    });

    test('turns a thrown error into an internal failure', () async {
      final controller = LanguageComparisonController(
        runner: (_) async => throw StateError('determinizer exploded'),
      );
      addTearDown(controller.dispose);

      await controller.compare(_request());

      final outcome = controller.snapshot.outcome;
      expect(outcome, isA<LanguageComparisonFailure>());
      expect(outcome!.status, LanguageComparisonStatus.error);
      expect(outcome.isEquivalent, isNull);
      expect(
        (outcome as LanguageComparisonFailure).message,
        contains('determinizer exploded'),
      );
    });

    test('refuses a verdict computed from other automaton revisions', () async {
      final request = _request();
      final otherRequest = _request(suffix: '-other');
      final controller = LanguageComparisonController(
        runner: (_) async => LanguageComparisonCompleted(
          _resultFor(otherRequest, isEquivalent: true),
        ),
      );
      addTearDown(controller.dispose);

      await controller.compare(request);

      final outcome = controller.snapshot.outcome;
      expect(outcome, isA<LanguageComparisonFailure>());
      expect(outcome!.status, LanguageComparisonStatus.error);
      expect(outcome.isEquivalent, isNull);
    });

    test('forwards a failure outcome untouched', () async {
      final controller = LanguageComparisonController(
        runner: (_) async => const LanguageComparisonFailure(
          reason: LanguageComparisonFailureReason.stateLimit,
          message: 'product exceeded 10000 states',
        ),
      );
      addTearDown(controller.dispose);

      await controller.compare(_request());

      final outcome = controller.snapshot.outcome;
      expect(outcome, isA<LanguageComparisonFailure>());
      expect(outcome!.status, LanguageComparisonStatus.inconclusive);
      expect(
        (outcome as LanguageComparisonFailure).reason,
        LanguageComparisonFailureReason.stateLimit,
      );
    });

    test('cancel abandons the in-flight comparison', () async {
      final pending = Completer<LanguageComparisonOutcome>();
      final controller = LanguageComparisonController(
        runner: (_) => pending.future,
      );
      addTearDown(controller.dispose);

      final run = controller.compare(_request());
      expect(controller.snapshot.isRunning, isTrue);

      controller.cancel();
      expect(controller.snapshot.isRunning, isFalse);

      pending.complete(
        LanguageComparisonCompleted(
          _resultFor(_request(), isEquivalent: true),
        ),
      );
      await run;

      expect(controller.snapshot.outcome, isNull);
    });

    test('reset clears the published outcome', () async {
      final request = _request();
      final controller = LanguageComparisonController(
        runner: (request) async => LanguageComparisonCompleted(
          _resultFor(request, isEquivalent: true),
        ),
      );
      addTearDown(controller.dispose);

      await controller.compare(request);
      expect(controller.snapshot.outcome, isNotNull);

      controller.reset();

      expect(controller.snapshot.outcome, isNull);
      expect(controller.snapshot.request, isNull);
      expect(controller.snapshot.isRunning, isFalse);
    });
  });
}
