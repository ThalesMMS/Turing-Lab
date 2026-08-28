import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/transducers/transducers.dart';
import 'mealy_document_adapter.dart';
import 'transducer_editor_state.dart';
import 'transducer_workspace_definition.dart';

final mealyWorkspaceDefinition = TransducerWorkspaceDefinition<MealyMachine>(
  systemKey: TransducerFormalSystemIds.mealy,
  schema: TransducerFormalSystemModules.mealy.descriptor.schema,
  initialDocument: createEmptyMealyMachine,
  adapter: const MealyDocumentAdapter(),
  simulator: DeterministicTransducerSimulator.mealy,
  emissionRule: const MealyEmissionRule(),
);

final mealyEditorProvider = StateNotifierProvider<
    TransducerEditorNotifier<MealyMachine>,
    TransducerEditorState<MealyMachine>>(
  (_) => TransducerEditorNotifier<MealyMachine>(createEmptyMealyMachine()),
);

MealyMachine createEmptyMealyMachine() => MealyMachine(
      id: const TransducerMachineId('mealy_machine'),
      name: 'Mealy machine',
      revision: const TransducerRevision(0),
      inputAlphabet: const [],
      outputAlphabet: const [],
      states: const [],
      transitions: const [],
    );
