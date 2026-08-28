import '../../core/formal_systems/formal_systems.dart';

/// Positional workspace names retained for compatibility with test and capture
/// harnesses. Production dispatch uses [FormalSystemKey].
enum WorkspaceTab { fsa, grammar, pda, tm, regex, pumping }

extension WorkspaceTabFormalSystemKey on WorkspaceTab {
  FormalSystemKey get formalSystemKey => switch (this) {
        WorkspaceTab.fsa => DefaultFormalSystemIds.fsa,
        WorkspaceTab.grammar => DefaultFormalSystemIds.grammar,
        WorkspaceTab.pda => DefaultFormalSystemIds.pda,
        WorkspaceTab.tm => DefaultFormalSystemIds.tm,
        WorkspaceTab.regex => DefaultFormalSystemIds.regex,
        WorkspaceTab.pumping => DefaultFormalSystemIds.pumping,
      };
}
