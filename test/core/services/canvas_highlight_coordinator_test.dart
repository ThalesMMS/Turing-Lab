import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';

class _RecordingHighlightChannel implements HighlightChannel {
  final List<SimulationHighlight?> events = <SimulationHighlight?>[];

  @override
  void clear() {
    events.add(null);
  }

  @override
  void send(SimulationHighlight highlight) {
    events.add(highlight);
  }
}

CanvasHighlightTarget _target({
  required Object surface,
  AutomatonSurfaceKind kind = AutomatonSurfaceKind.pda,
  String? documentId = 'document-1',
  int revision = 0,
}) {
  return CanvasHighlightTarget(
    kind: kind,
    surface: surface,
    documentId: documentId,
    revision: revision,
  );
}

void main() {
  group('CanvasHighlightCoordinator', () {
    test('restores lower layers when higher-priority owners clear', () {
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: _target(surface: Object()),
        output: output,
      );
      final validation = coordinator.source(CanvasHighlightSource.validation);
      final analysis = coordinator.source(CanvasHighlightSource.analysis);
      final simulation = coordinator.source(CanvasHighlightSource.simulation);
      final warning = SimulationHighlight(
        transitionIds: const {'warning-edge'},
      );
      final result = SimulationHighlight(
        stateIds: const {'reachable-state'},
      );
      final runtime = SimulationHighlight(
        stateIds: const {'active-state'},
      );

      validation.send(warning);
      analysis.send(result);
      simulation.send(runtime);
      simulation.clear();
      analysis.clear();
      validation.clear();

      expect(output.events, <SimulationHighlight?>[
        warning,
        result,
        runtime,
        result,
        warning,
        null,
      ]);
    });

    test('an obsolete owner cannot clear a replacement on the same layer', () {
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: _target(surface: Object()),
        output: output,
      );
      final oldAnalysis = coordinator.source(CanvasHighlightSource.analysis);
      final newAnalysis = coordinator.source(CanvasHighlightSource.analysis);
      final oldResult = SimulationHighlight(stateIds: const {'old-result'});
      final newResult = SimulationHighlight(stateIds: const {'new-result'});

      oldAnalysis.send(oldResult);
      newAnalysis.send(newResult);
      oldAnalysis.clear();

      expect(output.events, <SimulationHighlight?>[oldResult, newResult]);

      newAnalysis.clear();
      expect(output.events, <SimulationHighlight?>[
        oldResult,
        newResult,
        null,
      ]);
    });

    test('retarget clears active output and rejects stale async results', () {
      final surface = Object();
      final firstTarget = _target(surface: surface);
      final secondTarget = _target(surface: surface, revision: 1);
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: firstTarget,
        output: output,
      );
      final analysis = coordinator.source(CanvasHighlightSource.analysis);
      final firstResult = SimulationHighlight(stateIds: const {'first'});
      final staleResult = SimulationHighlight(stateIds: const {'stale'});
      final currentResult = SimulationHighlight(stateIds: const {'current'});

      analysis.sendFor(firstTarget, firstResult);
      coordinator.retarget(secondTarget);
      analysis.sendFor(firstTarget, staleResult);
      analysis.sendFor(secondTarget, currentResult);

      expect(output.events, <SimulationHighlight?>[
        firstResult,
        null,
        currentResult,
      ]);
    });

    test('deduplicates equal effective payloads and equal targets', () {
      final surface = Object();
      final target = _target(surface: surface);
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: target,
        output: output,
      );
      final validation = coordinator.source(CanvasHighlightSource.validation);
      final analysis = coordinator.source(CanvasHighlightSource.analysis);
      final shared = SimulationHighlight(stateIds: const {'shared'});

      validation.send(shared);
      validation.send(shared);
      analysis.send(shared);
      coordinator.retarget(
        _target(surface: surface),
      );

      expect(output.events, <SimulationHighlight?>[shared]);
    });

    test('empty publication clears only the publishing owner slot', () {
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: _target(surface: Object()),
        output: output,
      );
      final validation = coordinator.source(CanvasHighlightSource.validation);
      final analysis = coordinator.source(CanvasHighlightSource.analysis);
      final warning = SimulationHighlight(
        transitionIds: const {'warning-edge'},
      );
      final result = SimulationHighlight(stateIds: const {'result-state'});

      validation.send(warning);
      analysis.send(result);
      analysis.send(SimulationHighlight.empty);

      expect(output.events, <SimulationHighlight?>[warning, result, warning]);
    });

    test('dispose clears once and makes coordinator and handles inert', () {
      final output = _RecordingHighlightChannel();
      final coordinator = CanvasHighlightCoordinator(
        target: _target(surface: Object()),
        output: output,
      );
      final analysis = coordinator.source(CanvasHighlightSource.analysis);
      final result = SimulationHighlight(stateIds: const {'result-state'});

      analysis.send(result);
      coordinator.dispose();
      analysis.send(SimulationHighlight(stateIds: const {'ignored'}));
      analysis.clear();
      coordinator.dispose();

      expect(output.events, <SimulationHighlight?>[result, null]);
    });

    test('overlapping ids remain isolated between concrete surfaces', () {
      final pdaOutput = _RecordingHighlightChannel();
      final tmOutput = _RecordingHighlightChannel();
      final pdaCoordinator = CanvasHighlightCoordinator(
        target: _target(
          surface: Object(),
          kind: AutomatonSurfaceKind.pda,
          documentId: 'shared-document-id',
        ),
        output: pdaOutput,
      );
      final tmCoordinator = CanvasHighlightCoordinator(
        target: _target(
          surface: Object(),
          kind: AutomatonSurfaceKind.tm,
          documentId: 'shared-document-id',
        ),
        output: tmOutput,
      );
      final pdaHighlight = SimulationHighlight(
        stateIds: const {'overlap'},
        transitionIds: const {'edge-overlap'},
      );
      final tmHighlight = SimulationHighlight(
        stateIds: const {'overlap', 'tm-only'},
        transitionIds: const {'edge-overlap'},
      );

      pdaCoordinator.source(CanvasHighlightSource.analysis).send(pdaHighlight);
      tmCoordinator.source(CanvasHighlightSource.validation).send(tmHighlight);

      expect(pdaOutput.events, <SimulationHighlight?>[pdaHighlight]);
      expect(tmOutput.events, <SimulationHighlight?>[tmHighlight]);
    });
  });
}
