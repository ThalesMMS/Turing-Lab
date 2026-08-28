import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_building_blocks.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/transition.dart';

/// Offline example project demonstrating reusable two-tape TM blocks.
final class TMBlockExampleCatalog implements ExampleCatalogCapability<TM> {
  const TMBlockExampleCatalog();

  static const exampleName = 'TM - Reusable building blocks';

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.tm.building-blocks.v1');

  @override
  Future<List<AssetExample<TM>>> loadExamples() async => [
        AssetExample<TM>(
          id: 'tm-building-blocks-composition',
          name: exampleName,
          description: 'A shared-tape project with reusable scan, rewind, '
              'copy, compare, and nested composition blocks.',
          category: ExampleCategory.tm,
          difficultyLevel: DifficultyLevel.hard,
          complexityLevel: ExampleComplexityLevel.high,
          tags: const [
            'tm',
            'building-blocks',
            'submachine',
            'composition',
            'shared-tape',
          ],
          payload: _project(),
        ),
      ];
}

TM _project() {
  final scan = _scanBlock();
  final rewind = _rewindBlock();
  final copy = _copyBlock();
  final compare = _compareBlock();
  final composition = _compositionBlock();
  final start = _state('root-start', 'Nested: scan + rewind', initial: true);
  final accept = _state('root-accept', 'Accept', accepting: true);
  final transitions = <TMTransition>{
    for (final symbol in const ['0', '1', 'B'])
      _transition(
        'root-$symbol',
        start,
        accept,
        [symbol, 'B'],
        [symbol, 'B'],
        const [TapeDirection.stay, TapeDirection.stay],
      ),
  };
  return _machine(
    id: 'tm-building-blocks-composition',
    name: TMBlockExampleCatalog.exampleName,
    states: {start, accept},
    transitions: transitions,
    initial: start,
    accepting: {accept},
    definitions: {
      scan.id: scan,
      rewind.id: rewind,
      copy.id: copy,
      compare.id: compare,
      composition.id: composition,
    },
    invocations: const [
      TMBlockInvocationNode(
        id: 'root-compose-call',
        stateId: 'root-start',
        reference: TMBlockReference(blockId: 'composition', revision: 1),
      ),
    ],
  );
}

TMBlockDefinition _scanBlock() {
  final scan = _state('scan-loop', 'Scan', initial: true);
  return TMBlockDefinition(
    id: 'scan',
    name: 'Scan right',
    revision: 1,
    machine: _machine(
      id: 'scan',
      name: 'Scan right',
      states: {scan},
      transitions: {
        for (final symbol in const ['0', '1'])
          _transition(
            'scan-$symbol',
            scan,
            scan,
            [symbol, 'B'],
            [symbol, 'B'],
            const [TapeDirection.right, TapeDirection.stay],
          ),
      },
      initial: scan,
    ),
  );
}

TMBlockDefinition _rewindBlock() {
  final rewind = _state('rewind-loop', 'Rewind', initial: true);
  final done = _state('rewind-done', 'Done');
  return TMBlockDefinition(
    id: 'rewind',
    name: 'Rewind left',
    revision: 1,
    machine: _machine(
      id: 'rewind',
      name: 'Rewind left',
      states: {rewind, done},
      transitions: {
        for (final symbol in const ['0', '1'])
          _transition(
            'rewind-$symbol',
            rewind,
            rewind,
            [symbol, 'B'],
            [symbol, 'B'],
            const [TapeDirection.left, TapeDirection.stay],
          ),
        _transition(
          'rewind-blank',
          rewind,
          done,
          const ['B', 'B'],
          const ['B', 'B'],
          const [TapeDirection.right, TapeDirection.stay],
        ),
      },
      initial: rewind,
    ),
  );
}

TMBlockDefinition _copyBlock() {
  final copy = _state('copy-loop', 'Copy', initial: true);
  final done = _state('copy-done', 'Done');
  return TMBlockDefinition(
    id: 'copy',
    name: 'Copy to tape 2',
    revision: 1,
    machine: _machine(
      id: 'copy',
      name: 'Copy to tape 2',
      states: {copy, done},
      transitions: {
        for (final symbol in const ['0', '1'])
          _transition(
            'copy-$symbol',
            copy,
            copy,
            [symbol, 'B'],
            [symbol, symbol],
            const [TapeDirection.right, TapeDirection.right],
          ),
        _transition(
          'copy-blank',
          copy,
          done,
          const ['B', 'B'],
          const ['B', 'B'],
          const [TapeDirection.stay, TapeDirection.stay],
        ),
      },
      initial: copy,
    ),
  );
}

TMBlockDefinition _compareBlock() {
  final compare = _state('compare-loop', 'Compare', initial: true);
  final equal = _state('compare-equal', 'Equal');
  return TMBlockDefinition(
    id: 'compare',
    name: 'Compare tapes',
    revision: 1,
    machine: _machine(
      id: 'compare',
      name: 'Compare tapes',
      states: {compare, equal},
      transitions: {
        for (final symbol in const ['0', '1'])
          _transition(
            'compare-$symbol',
            compare,
            compare,
            [symbol, symbol],
            [symbol, symbol],
            const [TapeDirection.right, TapeDirection.right],
          ),
        _transition(
          'compare-blank',
          compare,
          equal,
          const ['B', 'B'],
          const ['B', 'B'],
          const [TapeDirection.stay, TapeDirection.stay],
        ),
      },
      initial: compare,
    ),
  );
}

TMBlockDefinition _compositionBlock() {
  final scan = _state('composition-scan', 'Call scan', initial: true);
  final rewind = _state('composition-rewind', 'Call rewind');
  return TMBlockDefinition(
    id: 'composition',
    name: 'Nested scan and rewind',
    revision: 1,
    machine: _machine(
      id: 'composition',
      name: 'Nested scan and rewind',
      states: {scan, rewind},
      transitions: {
        _transition(
          'composition-next',
          scan,
          rewind,
          const ['B', 'B'],
          const ['B', 'B'],
          const [TapeDirection.stay, TapeDirection.stay],
        ),
      },
      initial: scan,
    ),
    invocations: const [
      TMBlockInvocationNode(
        id: 'composition-scan-call',
        stateId: 'composition-scan',
        reference: TMBlockReference(blockId: 'scan', revision: 1),
      ),
      TMBlockInvocationNode(
        id: 'composition-rewind-call',
        stateId: 'composition-rewind',
        reference: TMBlockReference(blockId: 'rewind', revision: 1),
      ),
    ],
  );
}

TM _machine({
  required String id,
  required String name,
  required Set<State> states,
  required Set<TMTransition> transitions,
  required State initial,
  Set<State> accepting = const {},
  Map<String, TMBlockDefinition> definitions = const {},
  List<TMBlockInvocationNode> invocations = const [],
}) =>
    TM(
      id: id,
      name: name,
      states: states,
      transitions: transitions,
      alphabet: const {'0', '1'},
      initialState: initial,
      acceptingStates: accepting,
      created: DateTime.utc(2026, 8, 25),
      modified: DateTime.utc(2026, 8, 25),
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: const {'0', '1', 'B'},
      blankSymbol: 'B',
      tapeCount: 2,
      blockDefinitions: definitions,
      blockInvocations: invocations,
    );

State _state(
  String id,
  String label, {
  bool initial = false,
  bool accepting = false,
}) =>
    State(
      id: id,
      label: label,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

TMTransition _transition(
  String id,
  State from,
  State to,
  List<String> read,
  List<String> write,
  List<TapeDirection> directions,
) =>
    TMTransition(
      id: id,
      fromState: from,
      toState: to,
      label: id,
      type: TransitionType.deterministic,
      readSymbols: read,
      writeSymbols: write,
      directions: directions,
    );
