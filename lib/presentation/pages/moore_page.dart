import 'package:flutter/material.dart';

import '../../core/constants/help_topic_ids.dart';
import '../transducers/moore_workspace_definition.dart';
import '../transducers/transducer_workspace.dart';

class MoorePage extends StatelessWidget {
  const MoorePage({super.key});

  @override
  Widget build(BuildContext context) => TransducerWorkspace(
        provider: mooreEditorProvider,
        definition: mooreWorkspaceDefinition,
        helpTopicId: HelpTopicIds.mooreEditorOverview,
      );
}
