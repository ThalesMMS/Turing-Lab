import 'package:flutter/material.dart';

import '../../core/constants/help_topic_ids.dart';
import '../transducers/mealy_workspace_definition.dart';
import '../transducers/transducer_workspace.dart';

class MealyPage extends StatelessWidget {
  const MealyPage({super.key});

  @override
  Widget build(BuildContext context) => TransducerWorkspace(
    provider: mealyEditorProvider,
    definition: mealyWorkspaceDefinition,
    helpTopicId: HelpTopicIds.mealyEditorOverview,
  );
}
