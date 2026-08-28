import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/user_derivation_workspace.dart';
import '../widgets/variable_dependency_graph_workspace.dart';
import '../widgets/workspace_dock.dart';
import 'unrestricted_grammar_editor_controller.dart';
import 'unrestricted_grammar_workspace_strings.dart';

/// Builds the examples section rendered inside the Algorithms & Examples
/// surface. [closeSurface] dismisses the hosting sheet or dock panel after an
/// example is applied.
typedef UnrestrictedGrammarExamplesSectionBuilder =
    Widget Function(BuildContext context, VoidCallback closeSurface);

final class UnrestrictedGrammarWorkspace extends StatefulWidget {
  const UnrestrictedGrammarWorkspace({
    super.key,
    required this.controller,
    this.strings = UnrestrictedGrammarWorkspaceStrings.portuguese,
    this.infoPanel,
    this.examplesSectionBuilder,
    this.onQuickActionsChanged,
  });

  final UnrestrictedGrammarEditorController controller;
  final UnrestrictedGrammarWorkspaceStrings strings;
  final Widget? infoPanel;
  final UnrestrictedGrammarExamplesSectionBuilder? examplesSectionBuilder;
  final ValueChanged<WorkspaceQuickActions>? onQuickActionsChanged;

  @override
  State<UnrestrictedGrammarWorkspace> createState() =>
      _UnrestrictedGrammarWorkspaceState();
}

final class _UnrestrictedGrammarWorkspaceState
    extends State<UnrestrictedGrammarWorkspace>
    with WidgetsBindingObserver {
  final _leftController = TextEditingController(text: '["n:S"]');
  final _rightController = TextEditingController(text: '[]');
  final _inputController = TextEditingController(text: '[]');
  final _maxExpandedController = TextEditingController(text: '10000');
  final _nameController = TextEditingController();
  final _terminalsController = TextEditingController();
  final _nonterminalsController = TextEditingController();
  final _startSymbolController = TextEditingController();
  final _dockController = WorkspaceDockController();
  String? _editingProductionId;
  int? _editingProductionOrder;
  DerivationCancellationToken? _cancellationToken;
  DerivationSearchOutcome? _outcome;
  String? _inputError;
  String? _metadataError;
  bool _running = false;
  UnrestrictedGrammar? _manualGrammar;
  GrammarSymbolSequence? _manualTarget;
  UserDerivationDiagnosticCode? _manualInvalidationCode;
  int _manualSessionSerial = 0;
  UnrestrictedGrammar? _dependencyGrammar;
  bool _dependencyInvalidated = false;
  int _dependencySerial = 0;
  StateSetter? _sheetSetState;
  BuildContext? _sheetContext;
  bool? _lastCompactLayout;

  void _updateState(VoidCallback update) {
    setState(update);
    if (_sheetContext?.mounted ?? false) _sheetSetState?.call(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncGrammarDetails();
    widget.controller.addListener(_handleGrammarChanged);
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final view = View.of(context);
    final logicalWidth = view.physicalSize.width / view.devicePixelRatio;
    final compact = logicalWidth < AutomatonWorkspaceScaffold.mobileBreakpoint;
    final sheetContext = _sheetContext;
    if (compact && _dockController.openPanelId != null) {
      _dockController.closePanel(restoreFocus: false);
    } else if (!compact && sheetContext != null) {
      final route = ModalRoute.of(sheetContext);
      if (route != null) Navigator.of(sheetContext).removeRoute(route);
    }
  }

  @override
  void didUpdateWidget(UnrestrictedGrammarWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleGrammarChanged);
      widget.controller.addListener(_handleGrammarChanged);
    }
    if (!identical(oldWidget.infoPanel, widget.infoPanel) &&
        _sheetSetState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (_sheetContext?.mounted ?? false)) {
          _sheetSetState?.call(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_handleGrammarChanged);
    _cancellationToken?.cancel();
    _leftController.dispose();
    _rightController.dispose();
    _inputController.dispose();
    _maxExpandedController.dispose();
    _nameController.dispose();
    _terminalsController.dispose();
    _nonterminalsController.dispose();
    _startSymbolController.dispose();
    _dockController.dispose();
    super.dispose();
  }

  void _handleGrammarChanged() {
    _cancellationToken?.cancel();
    if (!mounted) return;
    _syncGrammarDetails();
    _updateState(() {
      _outcome = null;
      _running = false;
      _cancellationToken = null;
      if (_manualGrammar != null) {
        _manualInvalidationCode = UserDerivationDiagnosticCode.sourceChanged;
      }
      if (_dependencyGrammar != null) _dependencyInvalidated = true;
    });
  }

  void _syncGrammarDetails() {
    final grammar = widget.controller.grammar;
    _nameController.text = grammar.name;
    _terminalsController.text = jsonEncode(
      grammar.terminals.map((symbol) => symbol.value).toList()..sort(),
    );
    _nonterminalsController.text = jsonEncode(
      grammar.nonterminals.map((symbol) => symbol.value).toList()..sort(),
    );
    _startSymbolController.text = grammar.startSymbol.value;
  }

  void _saveGrammarDetails() {
    try {
      final terminalNames = _parseStringVector(_terminalsController.text);
      final nonterminalNames = _parseStringVector(_nonterminalsController.text);
      final start = _startSymbolController.text.trim();
      if (_nameController.text.trim().isEmpty ||
          start.isEmpty ||
          !nonterminalNames.contains(start)) {
        throw const FormatException('Invalid grammar details.');
      }
      widget.controller.updateGrammarDetails(
        name: _nameController.text.trim(),
        terminals: terminalNames.map(TerminalGrammarSymbol.new),
        nonterminals: nonterminalNames.map(NonterminalGrammarSymbol.new),
        startSymbol: NonterminalGrammarSymbol(start),
      );
      _updateState(() => _metadataError = null);
    } on FormatException {
      _updateState(() => _metadataError = widget.strings.invalidTokenVector);
    }
  }

  void _handleInputChanged() {
    _cancellationToken?.cancel();
    _updateState(() {
      _outcome = null;
      _running = false;
      _cancellationToken = null;
      if (_manualGrammar != null) {
        _manualInvalidationCode = UserDerivationDiagnosticCode.targetChanged;
      }
    });
  }

  void _startManualDerivation() {
    try {
      final target = _parseInput(_inputController.text);
      _updateState(() {
        _manualGrammar = widget.controller.grammar;
        _manualTarget = target;
        _manualInvalidationCode = null;
        _manualSessionSerial++;
        _inputError = null;
      });
    } on FormatException {
      _updateState(() => _inputError = widget.strings.invalidTokenVector);
    }
  }

  void _openDependencyGraph() {
    _updateState(() {
      _dependencyGrammar = widget.controller.grammar;
      _dependencyInvalidated = false;
      _dependencySerial++;
    });
  }

  void _addProduction() {
    try {
      final grammar = widget.controller.grammar;
      final production = PhraseStructureProduction(
        id: _editingProductionId ?? widget.controller.nextProductionId(),
        order: _editingProductionOrder ?? grammar.productions.length,
        left: _parseTaggedSequence(_leftController.text),
        right: _parseTaggedSequence(_rightController.text),
      );
      widget.controller.upsertProduction(production);
      _updateState(() {
        _inputError = null;
        _editingProductionId = null;
        _editingProductionOrder = null;
      });
    } on FormatException {
      _updateState(() => _inputError = widget.strings.invalidTokenVector);
    }
  }

  void _beginEditingProduction(PhraseStructureProduction production) {
    _leftController.text = _encodeTaggedSequence(production.left);
    _rightController.text = _encodeTaggedSequence(production.right);
    _updateState(() {
      _editingProductionId = production.id;
      _editingProductionOrder = production.order;
      _inputError = null;
    });
    _openEdit();
  }

  void _cancelProductionEdit() {
    _updateState(() {
      _editingProductionId = null;
      _editingProductionOrder = null;
      _inputError = null;
    });
  }

  Future<void> _runSearch() async {
    GrammarSymbolSequence input;
    try {
      input = _parseInput(_inputController.text);
    } on FormatException {
      _updateState(() => _inputError = widget.strings.invalidTokenVector);
      return;
    }
    final maxExpanded = int.tryParse(_maxExpandedController.text);
    if (maxExpanded == null || maxExpanded < 0) {
      _updateState(() => _inputError = widget.strings.invalidTokenVector);
      return;
    }
    final token = DerivationCancellationToken();
    _updateState(() {
      _cancellationToken = token;
      _outcome = null;
      _inputError = null;
      _running = true;
    });
    final outcome = await BoundedDerivationSearch.run(
      grammar: widget.controller.grammar,
      input: input,
      limits: DerivationSearchLimits(maxExpandedForms: maxExpanded),
      cancellationToken: token,
    );
    if (!mounted || !identical(_cancellationToken, token)) return;
    _updateState(() {
      _outcome = outcome;
      _running = false;
      _cancellationToken = null;
    });
  }

  bool get _usesCompactSurface =>
      MediaQuery.sizeOf(context).width <
      AutomatonWorkspaceScaffold.mobileBreakpoint;

  void _openEdit() {
    if (_usesCompactSurface) {
      _showWorkspaceSheet(
        title: widget.strings.editGrammar,
        childBuilder: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditorPane(),
            if (widget.infoPanel != null) ...[
              const SizedBox(height: 12),
              widget.infoPanel!,
            ],
          ],
        ),
      );
      return;
    }
    _dockController.openPanel(
      _editPanelId,
      returnFocusTo: FocusManager.instance.primaryFocus,
    );
  }

  void _openDerivation() {
    if (_usesCompactSurface) {
      _showWorkspaceSheet(
        title: widget.strings.derivationTitle,
        childBuilder: _buildDerivationPane,
      );
      return;
    }
    _dockController.openPanel(
      AutomatonWorkspaceScaffold.simulationPanelId,
      returnFocusTo: FocusManager.instance.primaryFocus,
    );
  }

  void _openAlgorithms() {
    if (_usesCompactSurface) {
      _showWorkspaceSheet(
        title: widget.strings.algorithmsTitle,
        childBuilder: _buildAlgorithmsPane,
      );
      return;
    }
    _dockController.openPanel(
      AutomatonWorkspaceScaffold.algorithmPanelId,
      returnFocusTo: FocusManager.instance.primaryFocus,
    );
  }

  Future<void> _showWorkspaceSheet({
    required String title,
    required Widget Function() childBuilder,
  }) {
    final future = showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSetState) {
          _sheetSetState = sheetSetState;
          _sheetContext = context;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.82,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: widget.strings.close,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(12),
                    children: [childBuilder()],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    future.whenComplete(() {
      if (mounted) {
        _sheetSetState = null;
        _sheetContext = null;
      }
    });
    return future;
  }

  Widget _buildEditorPane() => _GrammarEditorPane(
    controller: widget.controller,
    strings: widget.strings,
    nameController: _nameController,
    terminalsController: _terminalsController,
    nonterminalsController: _nonterminalsController,
    startSymbolController: _startSymbolController,
    leftController: _leftController,
    rightController: _rightController,
    error: _inputError,
    metadataError: _metadataError,
    onAdd: _addProduction,
    editingProductionId: _editingProductionId,
    onEdit: _beginEditingProduction,
    onCancelEdit: _cancelProductionEdit,
    onSaveDetails: _saveGrammarDetails,
  );

  Widget _buildDerivationPane() => _DerivationPane(
    controller: widget.controller,
    strings: widget.strings,
    inputController: _inputController,
    maxExpandedController: _maxExpandedController,
    running: _running,
    outcome: _outcome,
    onRun: _runSearch,
    onCancel: _cancellationToken?.cancel,
    onInputChanged: _handleInputChanged,
    onStartManual: _startManualDerivation,
    manualGrammar: _manualGrammar,
    manualTarget: _manualTarget,
    manualInvalidationCode: _manualInvalidationCode,
    manualSessionSerial: _manualSessionSerial,
  );

  /// Dismisses whichever surface currently hosts the algorithms pane: the
  /// compact bottom sheet when one is open, the dock panel otherwise.
  void _closeActiveSurface() {
    final sheetContext = _sheetContext;
    if (sheetContext != null && sheetContext.mounted) {
      Navigator.of(sheetContext).maybePop();
      return;
    }
    _dockController.closePanel();
  }

  Widget _buildAlgorithmsPane() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final report = PhraseGrammarClassifier.classify(
            widget.controller.grammar,
          );
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      widget.strings.classificationLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _ClassificationReport(
                    report: report,
                    strings: widget.strings,
                  ),
                  for (final diagnostic in report.diagnostics)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(widget.strings.diagnostic(diagnostic)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        key: const ValueKey('unrestricted-open-variable-dependency-graph'),
        onPressed: _openDependencyGraph,
        icon: const Icon(Icons.hub_outlined),
        label: Text(
          widget.strings.usesPortuguese
              ? 'Abrir grafo de dependência de variáveis'
              : 'Open variable dependency graph',
        ),
      ),
      if (_dependencyGrammar != null) ...[
        const SizedBox(height: 12),
        VariableDependencyGraphWorkspace.unrestricted(
          key: ValueKey('unrestricted-vdg-$_dependencySerial'),
          grammar: _dependencyGrammar!,
          invalidated: _dependencyInvalidated,
        ),
      ],
      if (widget.examplesSectionBuilder != null) ...[
        const SizedBox(height: 12),
        Builder(
          builder: (context) =>
              widget.examplesSectionBuilder!(context, _closeActiveSurface),
        ),
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final compactLayout = _usesCompactSurface;
    final previousCompactLayout = _lastCompactLayout;
    if (previousCompactLayout != compactLayout) {
      _lastCompactLayout = compactLayout;
      if (compactLayout && _dockController.openPanelId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _usesCompactSurface) {
            _dockController.closePanel(restoreFocus: false);
          }
        });
      }
    }
    widget.onQuickActionsChanged?.call(
      WorkspaceQuickActions(
        onSimulate: _openDerivation,
        onAlgorithms: _openAlgorithms,
        onEdit: _openEdit,
        simulateTooltip: widget.strings.openDerivation,
        algorithmsTooltip: widget.strings.algorithmsTitle,
        editTooltip: widget.strings.openEditor,
      ),
    );
    return AutomatonWorkspaceScaffold(
      dockController: _dockController,
      canvasWithToolbar: ({required isMobile}) => _ProductionsSurface(
        controller: widget.controller,
        strings: widget.strings,
        onEditGrammar: _openEdit,
        onEditProduction: _beginEditingProduction,
      ),
      simulationPanel: _buildDerivationPane(),
      simulationTabTitle: widget.strings.derivationTitle,
      algorithmPanel: _buildAlgorithmsPane(),
      algorithmTabTitle: widget.strings.algorithmsTitle,
      infoPanel: widget.infoPanel,
      infoTabTitle: widget.strings.informationTitle,
      extraPanels: [
        WorkspaceDockPanel(
          id: _editPanelId,
          label: widget.strings.editGrammar,
          icon: Icons.edit_outlined,
          child: _buildEditorPane(),
        ),
      ],
    );
  }
}

const _editPanelId = 'unrestricted-edit';

final class _ProductionsSurface extends StatelessWidget {
  const _ProductionsSurface({
    required this.controller,
    required this.strings,
    required this.onEditGrammar,
    required this.onEditProduction,
  });

  final UnrestrictedGrammarEditorController controller;
  final UnrestrictedGrammarWorkspaceStrings strings;
  final VoidCallback onEditGrammar;
  final ValueChanged<PhraseStructureProduction> onEditProduction;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final report = PhraseGrammarClassifier.classify(controller.grammar);
      final offendingProductionIds = _offendingProductionIds(report);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CustomScrollView(
            key: const ValueKey('unrestricted-grammar-productions-surface'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            strings.editorTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('unrestricted-edit-grammar'),
                        tooltip: strings.editGrammar,
                        onPressed: onEditGrammar,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              if (controller.grammar.productions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(strings.noProductions),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  sliver: SliverList.builder(
                    itemCount: controller.grammar.productions.length,
                    itemBuilder: (context, index) {
                      final production = controller.grammar.productions[index];
                      return _ProductionTile(
                        production: production,
                        strings: strings,
                        offending: offendingProductionIds.contains(
                          production.id,
                        ),
                        onEdit: () => onEditProduction(production),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

final class _GrammarEditorPane extends StatelessWidget {
  const _GrammarEditorPane({
    required this.controller,
    required this.strings,
    required this.nameController,
    required this.terminalsController,
    required this.nonterminalsController,
    required this.startSymbolController,
    required this.leftController,
    required this.rightController,
    required this.error,
    required this.metadataError,
    required this.onAdd,
    required this.editingProductionId,
    required this.onEdit,
    required this.onCancelEdit,
    required this.onSaveDetails,
  });

  final UnrestrictedGrammarEditorController controller;
  final UnrestrictedGrammarWorkspaceStrings strings;
  final TextEditingController nameController;
  final TextEditingController terminalsController;
  final TextEditingController nonterminalsController;
  final TextEditingController startSymbolController;
  final TextEditingController leftController;
  final TextEditingController rightController;
  final String? error;
  final String? metadataError;
  final VoidCallback onAdd;
  final String? editingProductionId;
  final ValueChanged<PhraseStructureProduction> onEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveDetails;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final report = PhraseGrammarClassifier.classify(controller.grammar);
          final offendingProductionIds = _offendingProductionIds(report);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings.editorTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-name'),
                controller: nameController,
                decoration: InputDecoration(
                  labelText: strings.grammarNameLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-terminals'),
                controller: terminalsController,
                decoration: InputDecoration(
                  labelText: strings.terminalsLabel,
                  helperText: strings.symbolSetFormatHelp,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-nonterminals'),
                controller: nonterminalsController,
                decoration: InputDecoration(
                  labelText: strings.nonterminalsLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-start-symbol'),
                controller: startSymbolController,
                decoration: InputDecoration(
                  labelText: strings.startSymbolLabel,
                  errorText: metadataError,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  key: const ValueKey('unrestricted-grammar-save-details'),
                  onPressed: onSaveDetails,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(strings.saveGrammarDetails),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${strings.classificationLabel}: '
                '${strings.classification(report.classification)}',
                key: const ValueKey('unrestricted-grammar-classification'),
              ),
              _ClassificationReport(report: report, strings: strings),
              for (final diagnostic in report.diagnostics)
                Semantics(
                  label: strings.diagnosticLabel,
                  value: strings.diagnostic(diagnostic),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(strings.diagnostic(diagnostic)),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-left'),
                controller: leftController,
                decoration: InputDecoration(
                  labelText: strings.leftSideLabel,
                  helperText: strings.productionFormatHelp,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('unrestricted-grammar-right'),
                controller: rightController,
                decoration: InputDecoration(
                  labelText: strings.rightSideLabel,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('unrestricted-grammar-add'),
                    onPressed: onAdd,
                    icon: Icon(
                      editingProductionId == null ? Icons.add : Icons.save,
                    ),
                    label: Text(
                      editingProductionId == null
                          ? strings.addProduction
                          : strings.saveProduction,
                    ),
                  ),
                  if (editingProductionId != null)
                    OutlinedButton.icon(
                      key: const ValueKey('unrestricted-grammar-cancel-edit'),
                      onPressed: onCancelEdit,
                      icon: const Icon(Icons.close),
                      label: Text(strings.cancelEdit),
                    ),
                  OutlinedButton(
                    onPressed: controller.canUndo ? controller.undo : null,
                    child: Text(strings.undo),
                  ),
                  OutlinedButton(
                    onPressed: controller.canRedo ? controller.redo : null,
                    child: Text(strings.redo),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (controller.grammar.productions.isEmpty)
                Text(strings.noProductions)
              else
                for (final production in controller.grammar.productions)
                  _ProductionTile(
                    production: production,
                    strings: strings,
                    offending: offendingProductionIds.contains(production.id),
                    onEdit: () => onEdit(production),
                    onRemove: () => controller.removeProduction(production.id),
                  ),
            ],
          );
        },
      ),
    ),
  );
}

final class _ProductionTile extends StatelessWidget {
  const _ProductionTile({
    required this.production,
    required this.strings,
    required this.offending,
    this.onEdit,
    this.onRemove,
  });

  final PhraseStructureProduction production;
  final UnrestrictedGrammarWorkspaceStrings strings;
  final bool offending;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: offending ? strings.offendingProduction : null,
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        key: ValueKey('grammar-production-${production.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        tileColor: offending
            ? Theme.of(context).colorScheme.errorContainer
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          '${_formatSequence(production.left)} → '
          '${_formatSequence(production.right)}',
        ),
        subtitle: Text(production.id),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: strings.editProduction,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            if (onRemove != null)
              IconButton(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: strings.removeProduction,
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    ),
  );
}

final class _ClassificationReport extends StatelessWidget {
  const _ClassificationReport({required this.report, required this.strings});

  final PhraseGrammarClassificationReport report;
  final UnrestrictedGrammarWorkspaceStrings strings;

  @override
  Widget build(BuildContext context) {
    final forms = report.normalForms
        .map(strings.normalForm)
        .toList(growable: false);
    return ExpansionTile(
      key: const ValueKey('grammar-classification-report'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(strings.classifyGrammar),
      children: [
        Semantics(
          label: strings.classifyGrammar,
          value: strings.classification(report.classification),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final classification in const [
                PhraseGrammarClassification.regular,
                PhraseGrammarClassification.contextFree,
                PhraseGrammarClassification.contextSensitive,
                PhraseGrammarClassification.unrestricted,
              ]) ...[
                Chip(
                  avatar: report.classification == classification
                      ? const Icon(Icons.check, size: 18)
                      : null,
                  label: Text(strings.classification(classification)),
                ),
                if (classification != PhraseGrammarClassification.unrestricted)
                  const ExcludeSemantics(child: Text('⊂')),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${strings.regularOrientationLabel}: '
            '${strings.orientation(report.regularOrientation)}',
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            '${strings.normalFormsLabel}: '
            '${forms.isEmpty ? strings.noNormalForms : forms.join(', ')}',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(strings.grammarStructureDisclaimer),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const ValueKey('copy-grammar-classification-report'),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: jsonEncode(report.toStructuredJson())),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(strings.reportCopied)));
            },
            icon: const Icon(Icons.copy),
            label: Text(strings.copyStructuredReport),
          ),
        ),
      ],
    );
  }
}

final class _DerivationPane extends StatelessWidget {
  const _DerivationPane({
    required this.controller,
    required this.strings,
    required this.inputController,
    required this.maxExpandedController,
    required this.running,
    required this.outcome,
    required this.onRun,
    required this.onCancel,
    required this.onInputChanged,
    required this.onStartManual,
    required this.manualGrammar,
    required this.manualTarget,
    required this.manualInvalidationCode,
    required this.manualSessionSerial,
  });

  final UnrestrictedGrammarEditorController controller;
  final UnrestrictedGrammarWorkspaceStrings strings;
  final TextEditingController inputController;
  final TextEditingController maxExpandedController;
  final bool running;
  final DerivationSearchOutcome? outcome;
  final VoidCallback onRun;
  final VoidCallback? onCancel;
  final VoidCallback onInputChanged;
  final VoidCallback onStartManual;
  final UnrestrictedGrammar? manualGrammar;
  final GrammarSymbolSequence? manualTarget;
  final UserDerivationDiagnosticCode? manualInvalidationCode;
  final int manualSessionSerial;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              strings.derivationTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('unrestricted-grammar-input'),
            controller: inputController,
            decoration: InputDecoration(
              labelText: strings.inputLabel,
              helperText: strings.inputFormatHelp,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              if (!running) onRun();
            },
            onChanged: (_) => onInputChanged(),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('unrestricted-grammar-max-expanded'),
            controller: maxExpandedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.maxExpandedLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('unrestricted-grammar-run'),
                onPressed: running ? null : onRun,
                icon: const Icon(Icons.play_arrow),
                label: Text(strings.runSearch),
              ),
              if (running)
                OutlinedButton.icon(
                  key: const ValueKey('unrestricted-grammar-cancel'),
                  onPressed: onCancel,
                  icon: const Icon(Icons.stop),
                  label: Text(strings.cancelSearch),
                ),
              OutlinedButton.icon(
                key: const ValueKey('unrestricted-start-manual-derivation'),
                onPressed: onStartManual,
                icon: const Icon(Icons.edit_note),
                label: Text(
                  strings.usesPortuguese
                      ? 'Iniciar derivação controlada'
                      : 'Start user-controlled derivation',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              running ? strings.searching : _outcomeLabel(outcome, strings),
              key: const ValueKey('unrestricted-grammar-outcome'),
            ),
          ),
          if (outcome case final DerivationAccepted accepted) ...[
            const SizedBox(height: 12),
            Semantics(
              header: true,
              child: Text(
                strings.witnessTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in _boundedWitness(accepted.witness))
              if (entry == null)
                Text(
                  strings.omittedWitnessSteps(
                    accepted.witness.length - _maximumVisibleWitnessSteps,
                  ),
                )
              else
                Text(
                  '${entry.occurrence.productionId} @ '
                  '${entry.occurrence.startIndex}: '
                  '${_formatSequence(entry.before)} → '
                  '${_formatSequence(entry.after)}',
                ),
          ],
          if (outcome case final DerivationInvalid invalid)
            for (final diagnostic in invalid.diagnostics)
              Text(strings.diagnostic(diagnostic)),
          if (manualGrammar != null && manualTarget != null)
            UserDerivationWorkspace(
              key: ValueKey('unrestricted-manual-session-$manualSessionSerial'),
              grammar: manualGrammar!,
              target: manualTarget!,
              initialMode: UserDerivationMode.unrestrictedOccurrence,
              invalidationCode: manualInvalidationCode,
              onInvalidatedRestart: onStartManual,
            ),
        ],
      ),
    ),
  );
}

GrammarSymbolSequence _parseTaggedSequence(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List || decoded.any((item) => item is! String)) {
    throw const FormatException('Expected a JSON string array.');
  }
  return GrammarSymbolSequence(
    decoded.cast<String>().map((item) {
      if (item.startsWith('n:')) {
        return NonterminalGrammarSymbol(item.substring(2));
      }
      if (item.startsWith('t:')) {
        return TerminalGrammarSymbol(item.substring(2));
      }
      throw const FormatException('Tagged grammar symbol expected.');
    }),
  );
}

GrammarSymbolSequence _parseInput(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List || decoded.any((item) => item is! String)) {
    throw const FormatException('Expected a JSON string array.');
  }
  return GrammarSymbolSequence(
    decoded.cast<String>().map(TerminalGrammarSymbol.new),
  );
}

Set<String> _parseStringVector(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! List ||
      decoded.any((item) => item is! String || item.trim().isEmpty)) {
    throw const FormatException('Expected a JSON string array.');
  }
  return decoded.cast<String>().map((item) => item.trim()).toSet();
}

String _encodeTaggedSequence(GrammarSymbolSequence sequence) => jsonEncode(
  sequence.symbols
      .map((symbol) => '${symbol.isNonterminal ? 'n' : 't'}:${symbol.value}')
      .toList(growable: false),
);

String _formatSequence(GrammarSymbolSequence sequence) => sequence.isEmpty
    ? 'ε'
    : sequence.symbols
          .map(
            (symbol) => '${symbol.isNonterminal ? 'n' : 't'}:${symbol.value}',
          )
          .join(' ');

String _outcomeLabel(
  DerivationSearchOutcome? outcome,
  UnrestrictedGrammarWorkspaceStrings strings,
) => switch (outcome) {
  DerivationAccepted() => strings.accepted,
  DerivationExhausted() => strings.exhausted,
  DerivationBoundedUnknown() => strings.boundedUnknown,
  DerivationCancelled() => strings.cancelled,
  DerivationInvalid() => strings.invalid,
  null => '',
};

const _maximumVisibleWitnessSteps = 25;

Iterable<ProductionApplication?> _boundedWitness(
  List<ProductionApplication> witness,
) sync* {
  if (witness.length <= _maximumVisibleWitnessSteps) {
    yield* witness;
    return;
  }
  yield* witness.take(20);
  yield null;
  yield* witness.skip(witness.length - 5);
}

Set<String> _offendingProductionIds(PhraseGrammarClassificationReport report) =>
    report.productionEvidence
        .where(
          (evidence) => switch (report.classification) {
            PhraseGrammarClassification.invalid => evidence.violated.contains(
              PhraseGrammarPredicateCode.validPhraseRule,
            ),
            PhraseGrammarClassification.regular => false,
            PhraseGrammarClassification.contextFree =>
              evidence.violated.contains(
                    PhraseGrammarPredicateCode.rightLinearRule,
                  ) ||
                  evidence.violated.contains(
                    PhraseGrammarPredicateCode.leftLinearRule,
                  ),
            PhraseGrammarClassification.contextSensitive =>
              evidence.violated.contains(
                PhraseGrammarPredicateCode.contextFreeLeftSide,
              ),
            PhraseGrammarClassification.unrestricted =>
              evidence.violated.contains(
                    PhraseGrammarPredicateCode.noncontractingRule,
                  ) ||
                  evidence.violated.contains(
                    PhraseGrammarPredicateCode.epsilonRestriction,
                  ),
          },
        )
        .map((evidence) => evidence.productionId)
        .toSet();
