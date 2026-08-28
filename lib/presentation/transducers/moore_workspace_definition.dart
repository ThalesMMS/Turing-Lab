import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/transducers/transducers.dart';
import 'moore_document_adapter.dart';
import 'transducer_editor_state.dart';
import 'transducer_workspace_definition.dart';

final mooreWorkspaceDefinition = TransducerWorkspaceDefinition<MooreMachine>(
  systemKey: TransducerFormalSystemIds.moore,
  schema: TransducerFormalSystemModules.moore.descriptor.schema,
  initialDocument: createEmptyMooreMachine,
  adapter: const MooreDocumentAdapter(),
  simulator: DeterministicTransducerSimulator.moore,
  emissionRule: const MooreEmissionRule(),
);

final mooreEditorProvider = StateNotifierProvider<
    TransducerEditorNotifier<MooreMachine>,
    TransducerEditorState<MooreMachine>>(
  (_) => TransducerEditorNotifier<MooreMachine>(createEmptyMooreMachine()),
);

MooreMachine createEmptyMooreMachine() => MooreMachine(
      id: const TransducerMachineId('moore_machine'),
      name: 'Moore machine',
      revision: const TransducerRevision(0),
      inputAlphabet: const [],
      outputAlphabet: const [],
      states: const [],
      transitions: const [],
    );
