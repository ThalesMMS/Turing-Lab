import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_algorithm_step_highlight_channel.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_highlight_controller.dart';

import '../../../tool/hard_edge/repository_algorithm_inventory.dart';

void main() {
  test('source-backed repository inventory is current and fully owned', () {
    final root = Directory.current.absolute;
    final inventory = RepositoryAlgorithmInventory.discover(root);

    expect(inventory.validate(root), isEmpty);
    final committed = jsonDecode(
      File(
        'test/fixtures/hard_edge/repository_algorithm_inventory.v1.json',
      ).readAsStringSync(),
    );
    expect(inventory.toJson(), committed);
    expect(
      inventory.entries.map((entry) => entry['issue']).toSet(),
      containsAll({335, 336, 337, 338, 339, 340, 341, 342}),
    );
    expect(
      inventory.entries.map((entry) => entry['sourcePath']).toSet(),
      containsAll({
        'lib/core/models/fsa_computation_branch_adapter.dart',
        'lib/core/models/serialized_state_resolver.dart',
        'lib/core/services/algorithm_step_highlight_extractor.dart',
        'lib/core/services/algorithm_step_highlight_service.dart',
        'lib/core/services/automaton_diagnostic_highlight_service.dart',
        'lib/core/services/canvas_highlight_coordinator.dart',
        'lib/core/services/highlight_channel.dart',
        'lib/core/services/simulation_highlight_service.dart',
      }),
    );
  });

  test('import reachability alone is not accepted as executable evidence', () {
    final root = Directory.current.absolute;
    final inventory = RepositoryAlgorithmInventory.discover(root);
    final target = inventory.entries.singleWhere(
      (entry) =>
          entry['sourcePath'] ==
          'lib/core/models/serialized_state_resolver.dart',
    );
    final invalid = RepositoryAlgorithmInventory(
      entries: [
        for (final entry in inventory.entries)
          if (identical(entry, target))
            {
              ...entry,
              // This local variable exists in the declaration file but is not
              // called or referenced by the executable evidence graph.
              'entryPoints': ['synthesizedState'],
            }
          else
            entry,
      ],
      exclusions: inventory.exclusions,
    );

    expect(
      invalid.validate(root),
      contains(contains('references none of its public entry points')),
    );
  });

  test('validator rejects missing property evidence and duplicate ownership',
      () {
    final root = Directory.current.absolute;
    final inventory = RepositoryAlgorithmInventory.discover(root);
    final first = inventory.entries.first;
    final invalid = RepositoryAlgorithmInventory(
      entries: [
        {...first, 'propertyEvidence': ''},
        first,
        ...inventory.entries.skip(1),
      ],
      exclusions: inventory.exclusions,
    );

    final issues = invalid.validate(root);

    expect(issues, contains(contains('duplicate inventory id')));
    expect(issues, contains(contains('more than one primary owner')));
    expect(issues, contains(contains('property/oracle evidence is missing')));
  });

  test('algorithm-step highlight inventory path executes production', () {
    final controller = _RecordingHighlightController();
    final channel = GraphViewAlgorithmStepHighlightChannel(controller);
    final highlight = SimulationHighlight(
      stateIds: {'q0'},
      transitionIds: {'t0'},
    );

    channel.send(highlight);
    channel.clear();

    expect(controller.lastHighlight, highlight);
    expect(controller.clearCount, 1);
  });
}

final class _RecordingHighlightController
    implements GraphViewHighlightController {
  SimulationHighlight? lastHighlight;
  int clearCount = 0;

  @override
  void applyHighlight(SimulationHighlight highlight) {
    lastHighlight = highlight;
  }

  @override
  void clearHighlight() {
    clearCount++;
  }
}
