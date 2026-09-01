//
//  grammar_editor.dart
//  Turing Lab
//
//  Provides the full formal-grammar editor with forms for start symbols,
//  productions, and metadata, offering quick validation and clear actions
//  to speed up language modeling.
//  Syncs with GrammarProvider via Riverpod so updates show in real time
//  and responsive layouts work on both mobile and desktop screens.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/monospace_typography.dart';
import '../../core/models/production.dart';
import '../../core/utils/epsilon_utils.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../empty_string_notation.dart';
import '../providers/grammar_provider.dart';
import 'grammar_editor_section.dart';

/// Comprehensive grammar editor widget
class GrammarEditor extends ConsumerStatefulWidget {
  const GrammarEditor({
    super.key,
    this.section = GrammarEditorSection.all,
    this.productionToEdit,
    this.onEditGrammar,
    this.onEditProduction,
  });

  final GrammarEditorSection section;
  final Production? productionToEdit;
  final VoidCallback? onEditGrammar;
  final ValueChanged<Production>? onEditProduction;

  @override
  ConsumerState<GrammarEditor> createState() => _GrammarEditorState();
}

class _GrammarEditorState extends ConsumerState<GrammarEditor> {
  final TextEditingController _startSymbolController = TextEditingController(
    text: 'S',
  );
  final TextEditingController _leftSideController = TextEditingController();
  final TextEditingController _rightSideController = TextEditingController();
  final TextEditingController _grammarNameController = TextEditingController(
    text: 'My Grammar',
  );

  String? _selectedProductionId;
  List<String>? _editingLeftSide;
  bool _isEditing = false;

  String? _leftSideErrorText;
  String? _rightSideErrorText;
  final Map<String, FocusNode> _reorderFocusNodes = {};
  String? _focusedReorderKey;
  String? _draggingReorderKey;
  _ProductionGroup? _pendingInitialEditingGroup;

  AppLocalizations get _l10n => jflapLocalizationsOf(context);

  @override
  void initState() {
    super.initState();
    final state = ref.read(grammarProvider);
    _startSymbolController.text = state.startSymbol;
    _grammarNameController.text = state.name;
    if (widget.productionToEdit case final production?) {
      final group = _groupForProduction(state.productions, production);
      _selectedProductionId = production.id;
      _editingLeftSide = List<String>.from(production.leftSide);
      _isEditing = true;
      _leftSideController.text = _formatSymbols(production.leftSide);
      _pendingInitialEditingGroup = group;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = _pendingInitialEditingGroup;
    if (group == null) return;
    _rightSideController.text = _formatGroupForInput(group);
    _pendingInitialEditingGroup = null;
  }

  @override
  void dispose() {
    _startSymbolController.dispose();
    _leftSideController.dispose();
    _rightSideController.dispose();
    _grammarNameController.dispose();
    for (final focusNode in _reorderFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Widget _buildFormalLanguageTextField({
    required TextEditingController controller,
    required InputDecoration decoration,
    ValueChanged<String>? onChanged,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      decoration: decoration.copyWith(errorText: errorText),
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    final leadingSections = <Widget>[
      if (widget.section != GrammarEditorSection.details) ...[
        _buildHeader(context),
        const SizedBox(height: 16),
      ],
      if (widget.section != GrammarEditorSection.productions) ...[
        _buildGrammarInfo(context),
        const SizedBox(height: 16),
        _buildProductionEditor(context),
      ],
      if (widget.section == GrammarEditorSection.all)
        const SizedBox(height: 16),
    ];

    if (widget.section == GrammarEditorSection.details) {
      return Card(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: leadingSections,
            ),
          ),
        ),
      );
    }

    final productions = grammarState.productions;
    final groups = _groupProductions(productions);
    return Card(
      child: CustomScrollView(
        key: const ValueKey('grammar-production-scroll-view'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: [
                ...leadingSections,
                Text(
                  _l10n.productionRulesCount(productions.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (productions.isEmpty) _buildEmptyState(context),
              ],
            ),
          ),
          if (groups.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverReorderableList(
                itemCount: groups.length,
                // Flutter 3.32 compatibility.
                // ignore: deprecated_member_use
                onReorder: _reorderProductionGroup,
                onReorderStart: (index) {
                  setState(
                    () => _draggingReorderKey = _productionGroupKey(
                      groups[index].leftSide,
                    ),
                  );
                },
                onReorderEnd: (_) {
                  if (mounted) setState(() => _draggingReorderKey = null);
                },
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return KeyedSubtree(
                    key: ValueKey(
                      'grammar-production-group-${group.productions.first.id}',
                    ),
                    child: _buildProductionGroupItem(
                      context,
                      group,
                      index,
                      groups.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _reorderProductionGroup(int oldIndex, int newIndex) {
    final groups = _groupProductions(ref.read(grammarProvider).productions);
    if (oldIndex < 0 || oldIndex >= groups.length) return;
    final group = groups[oldIndex];
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _moveProductionGroup(group, oldIndex, adjustedNewIndex, groups.length);
  }

  void _moveProductionGroup(
    _ProductionGroup group,
    int oldIndex,
    int newIndex,
    int total,
  ) {
    final changed = ref
        .read(grammarProvider.notifier)
        .reorderProductionGroup(oldIndex, newIndex);
    if (!changed || !mounted) return;
    final leftSide = _formatSymbols(group.leftSide);
    SemanticsService.sendAnnouncement(
      View.of(context),
      _l10n.productionGroupMoved(leftSide, newIndex + 1, total),
      Directionality.of(context),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNodeFor(group).requestFocus();
    });
  }

  FocusNode _focusNodeFor(_ProductionGroup group) {
    final key = _productionGroupKey(group.leftSide);
    return _reorderFocusNodes.putIfAbsent(
      key,
      () => FocusNode(debugLabel: 'Reorder productions for $key'),
    );
  }

  static String _productionGroupKey(List<String> leftSide) =>
      leftSide.join('\u0000');

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen =
        screenWidth < 600; // Increased breakpoint for better mobile support
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);
    final editButton = OutlinedButton.icon(
      onPressed: widget.onEditGrammar,
      icon: const Icon(Icons.edit, size: 16),
      label: Text(l10n.workspaceEditTooltip),
    );
    final clearButton = ElevatedButton.icon(
      onPressed: _clearGrammar,
      icon: const Icon(Icons.clear, size: 16),
      label: Text(_l10n.clear),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.text_fields,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _l10n.grammarEditorTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.onEditGrammar != null) ...[
                editButton,
                const SizedBox(width: 8),
              ],
              clearButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.text_fields, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _l10n.grammarEditorTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.onEditGrammar != null) ...[
          editButton,
          const SizedBox(width: 8),
        ],
        const SizedBox(width: 8),
        clearButton,
      ],
    );
  }

  Widget _buildGrammarInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _l10n.grammarInformation,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;

              if (isSmallScreen) {
                return Column(
                  children: [
                    TextField(
                      controller: _grammarNameController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateName(value.trim()),
                      decoration: InputDecoration(
                        labelText: _l10n.grammarNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFormalLanguageTextField(
                      controller: _startSymbolController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateStartSymbol(value.trim()),
                      decoration: InputDecoration(
                        labelText: _l10n.startSymbolLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _grammarNameController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateName(value.trim()),
                      decoration: InputDecoration(
                        labelText: _l10n.grammarNameLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormalLanguageTextField(
                      controller: _startSymbolController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateStartSymbol(value.trim()),
                      decoration: InputDecoration(
                        labelText: _l10n.startSymbolLabel,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductionEditor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? _l10n.editProductionRule : _l10n.addProductionRule,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;

              if (isSmallScreen) {
                return Column(
                  children: [
                    _buildFormalLanguageTextField(
                      controller: _leftSideController,
                      onChanged: (_) => _validateProductionEditorInputs(),
                      errorText: _leftSideErrorText,
                      decoration: InputDecoration(
                        labelText: _l10n.leftSideVariable,
                        hintText: _l10n.leftSideHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.leftSideHelper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildFormalLanguageTextField(
                      controller: _rightSideController,
                      onChanged: (_) => _validateProductionEditorInputs(),
                      errorText: _rightSideErrorText,
                      decoration: InputDecoration(
                        labelText: _l10n.rightSideProduction,
                        hintText: _l10n.rightSideHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: _EpsilonShortcutButton(
                          onInsert: () => _insertIntoController(
                            controller: _rightSideController,
                            symbol: kEpsilonSymbol,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => _insertIntoController(
                            controller: _rightSideController,
                            symbol: kEpsilonSymbol,
                          ),
                          child: Text(_l10n.insertEpsilon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.rightSideHelper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormalLanguageTextField(
                          controller: _leftSideController,
                          onChanged: (_) => _validateProductionEditorInputs(),
                          errorText: _leftSideErrorText,
                          decoration: InputDecoration(
                            labelText: _l10n.leftSideVariable,
                            hintText: _l10n.leftSideHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _l10n.leftSideHelper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormalLanguageTextField(
                          controller: _rightSideController,
                          onChanged: (_) => _validateProductionEditorInputs(),
                          errorText: _rightSideErrorText,
                          decoration: InputDecoration(
                            labelText: _l10n.rightSideProduction,
                            hintText: _l10n.rightSideHint,
                            border: const OutlineInputBorder(),
                            suffixIcon: _EpsilonShortcutButton(
                              onInsert: () => _insertIntoController(
                                controller: _rightSideController,
                                symbol: kEpsilonSymbol,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _insertIntoController(
                                controller: _rightSideController,
                                symbol: kEpsilonSymbol,
                              ),
                              child: Text(_l10n.insertEpsilon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _l10n.rightSideHelper,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              if (isSmallScreen) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isEditing
                          ? _updateProduction
                          : _addProduction,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? _l10n.update : _l10n.add),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _cancelEdit,
                        icon: const Icon(Icons.cancel),
                        label: Text(_l10n.cancel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isEditing ? _updateProduction : _addProduction,
                    icon: Icon(_isEditing ? Icons.save : Icons.add),
                    label: Text(_isEditing ? _l10n.update : _l10n.add),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _cancelEdit,
                      icon: const Icon(Icons.cancel),
                      label: Text(_l10n.cancel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_fields_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            _l10n.noProductionRulesYet,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.section == GrammarEditorSection.productions
                ? l10n.grammarEmptyProductionEditInstruction
                : _l10n.addFirstProductionRule,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionGroupItem(
    BuildContext context,
    _ProductionGroup group,
    int index,
    int total,
  ) {
    final isSelected = group.productions.any(
      (production) => production.id == _selectedProductionId,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          leading: _buildProductionGroupDragHandle(
            context,
            group,
            index,
            total,
          ),
          title: Text(
            '${_formatSymbols(group.leftSide)} → ${_formatGroupForDisplay(group)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontFamilyFallback: kMonospaceFontFamilyFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            _l10n.productionAlternativesCount(group.productions.length),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            tooltip: _l10n.productionGroupActions,
            onSelected: (value) async {
              if (value == 'edit') {
                final onEditProduction = widget.onEditProduction;
                if (onEditProduction != null) {
                  onEditProduction(group.productions.first);
                } else {
                  _editProductionGroup(group);
                }
              } else if (value == 'delete') {
                await _confirmDeleteGroup(group);
              } else if (value == 'move-up') {
                _moveProductionGroup(group, index, index - 1, total);
              } else if (value == 'move-down') {
                _moveProductionGroup(group, index, index + 1, total);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'move-up',
                enabled: index > 0,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.moveUp),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'move-down',
                enabled: index < total - 1,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.moveDown),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.editAlternatives),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.deleteGroup),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
          onTap: () => _selectProductionGroup(group),
          selected: isSelected,
        ),
      ),
    );
  }

  Widget _buildProductionGroupDragHandle(
    BuildContext context,
    _ProductionGroup group,
    int index,
    int total,
  ) {
    final leftSide = _formatSymbols(group.leftSide);
    final label = _l10n.reorderProductionsFor(leftSide);
    final position = _l10n.productionPosition(index + 1, total);
    final groupKey = _productionGroupKey(group.leftSide);
    final focusNode = _focusNodeFor(group);
    final focused = _focusedReorderKey == groupKey;
    final colors = Theme.of(context).colorScheme;
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        key: ValueKey(
          'grammar-production-group-handle-${group.productions.first.id}',
        ),
        container: true,
        focusable: true,
        focused: focused,
        label: label,
        value: position,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: Focus(
            focusNode: focusNode,
            onFocusChange: (hasFocus) {
              if (!mounted) return;
              setState(() => _focusedReorderKey = hasFocus ? groupKey : null);
            },
            child: Listener(
              onPointerDown: (_) => focusNode.requestFocus(),
              child: MouseRegion(
                cursor: _draggingReorderKey == groupKey
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: SizedBox.square(
                  dimension: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: focused
                          ? Border.all(color: colors.primary, width: 2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.drag_indicator,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addProduction() {
    if (!_validateProductionEditorInputs()) {
      return;
    }

    final leftSide = _leftSideController.text.trim();
    final parsedLeft = _parseLeftSide(leftSide);
    final parsed = _parseAlternatives(_rightSideController.text)!;
    final result = ref
        .read(grammarProvider.notifier)
        .addProductionAlternatives(
          leftSide: parsedLeft,
          alternatives: parsed.alternatives,
        );

    _showDuplicateFeedback(result);
    if (result.changed) {
      _clearFields();
    }
  }

  void _updateProduction() {
    if (_selectedProductionId == null) return;

    if (!_validateProductionEditorInputs()) {
      return;
    }

    final leftSide = _leftSideController.text.trim();
    final parsedLeft = _parseLeftSide(leftSide);
    final parsed = _parseAlternatives(_rightSideController.text)!;
    final originalLeftSide = _editingLeftSide;
    if (originalLeftSide == null) return;
    final result = ref
        .read(grammarProvider.notifier)
        .replaceProductionGroup(
          originalLeftSide: originalLeftSide,
          leftSide: parsedLeft,
          alternatives: parsed.alternatives,
        );
    _showDuplicateFeedback(result);
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
      _editingLeftSide = null;
    });
    _clearFields();
  }

  void _editProductionGroup(_ProductionGroup group) {
    setState(() {
      _selectedProductionId = group.productions.first.id;
      _editingLeftSide = List<String>.from(group.leftSide);
      _isEditing = true;
      _leftSideErrorText = null;
      _rightSideErrorText = null;
      _leftSideController.text = _formatSymbols(group.leftSide);
      _rightSideController.text = _formatGroupForInput(group);
    });
  }

  Future<void> _confirmDeleteGroup(_ProductionGroup group) async {
    final count = group.productions.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_l10n.deleteProductionGroupTitle),
        content: Text(_l10n.deleteProductionGroupMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_l10n.deleteGroup),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    ref.read(grammarProvider.notifier).deleteProductionGroup(group.leftSide);
    if (group.productions.any(
      (production) => production.id == _selectedProductionId,
    )) {
      setState(() {
        _selectedProductionId = null;
        _editingLeftSide = null;
        _isEditing = false;
      });
      _clearFields();
    }
  }

  void _selectProductionGroup(_ProductionGroup group) {
    setState(() {
      _selectedProductionId = group.productions.first.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
      _editingLeftSide = null;
      _leftSideErrorText = null;
      _rightSideErrorText = null;
    });
    _clearFields();
  }

  Future<void> _clearGrammar() async {
    final grammarState = ref.read(grammarProvider);
    if (grammarState.productions.isEmpty) {
      return;
    }

    final previousProductions = List<Production>.from(grammarState.productions);

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_l10n.clearAllProductionsTitle),
          content: Text(_l10n.clearAllProductionsMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(_l10n.clear),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    ref.read(grammarProvider.notifier).clearProductions();
    setState(() {
      _selectedProductionId = null;
      _editingLeftSide = null;
      _isEditing = false;
    });
    _clearFields();

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_l10n.productionsCleared),
          action: SnackBarAction(
            label: _l10n.undo,
            onPressed: () {
              ref
                  .read(grammarProvider.notifier)
                  .setProductions(previousProductions);
            },
          ),
        ),
      );
  }

  void _clearFields() {
    _leftSideController.clear();
    _rightSideController.clear();
    setState(() {
      _leftSideErrorText = null;
      _rightSideErrorText = null;
    });
  }

  void _insertIntoController({
    required TextEditingController controller,
    required String symbol,
  }) {
    final value = controller.value;
    final text = value.text;
    final selection = value.selection;

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);

    final newText = text.replaceRange(safeStart, safeEnd, symbol);
    final newOffset = safeStart + symbol.length;

    controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );

    _validateProductionEditorInputs();
  }

  bool _validateProductionEditorInputs() {
    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();

    String? leftError;
    String? rightError;

    if (leftSide.isEmpty || rightSide.isEmpty) {
      leftError = leftSide.isEmpty ? _l10n.bothSidesRequired : null;
      rightError = rightSide.isEmpty ? _l10n.bothSidesRequired : null;
    } else {
      final parsedLeft = _parseLeftSide(leftSide);
      if (parsedLeft.isEmpty) {
        leftError = _l10n.leftSideMustBeNonterminal;
      } else if (parsedLeft.length != 1) {
        leftError = _l10n.leftSideExactlyOneNonterminal;
      }

      final parsed = _parseAlternatives(rightSide);
      switch (parsed?.error) {
        case _AlternativeParseError.emptyAlternative:
          rightError = _l10n.rightSideEmptyAlternative;
          break;
        case _AlternativeParseError.arrowExpression:
          rightError = _l10n.rightSideArrowNotAccepted;
          break;
        case _AlternativeParseError.repeatedEmptyString:
          rightError = _l10n.rightSideSingleLambda;
          break;
        case _AlternativeParseError.mixedEmptyString:
          rightError = _l10n.lambdaMustBeOnlySymbol;
          break;
        case null:
          break;
      }
    }

    final isValid = leftError == null && rightError == null;
    if (_leftSideErrorText != leftError || _rightSideErrorText != rightError) {
      setState(() {
        _leftSideErrorText = leftError;
        _rightSideErrorText = rightError;
      });
    }

    return isValid;
  }

  List<String> _parseLeftSide(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.contains(RegExp(r'\s+'))) {
      return trimmed
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
    }
    return [trimmed];
  }

  List<String> _parseRightSide(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.contains(RegExp(r'\s+'))) {
      return trimmed
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
    }
    return trimmed.split('');
  }

  _ParsedAlternatives? _parseAlternatives(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.contains('->') || trimmed.contains('→')) {
      return const _ParsedAlternatives.error(
        _AlternativeParseError.arrowExpression,
      );
    }

    final rawAlternatives = <String>[];
    var buffer = StringBuffer();
    for (var index = 0; index < trimmed.length; index++) {
      final character = trimmed[index];
      if (character == '\\' &&
          index + 1 < trimmed.length &&
          trimmed[index + 1] == '|') {
        buffer.write('|');
        index++;
      } else if (character == '|') {
        rawAlternatives.add(buffer.toString().trim());
        buffer = StringBuffer();
      } else {
        buffer.write(character);
      }
    }
    rawAlternatives.add(buffer.toString().trim());
    if (rawAlternatives.any((alternative) => alternative.isEmpty)) {
      return const _ParsedAlternatives.error(
        _AlternativeParseError.emptyAlternative,
      );
    }

    final alternatives = <ProductionAlternativeDraft>[];
    for (final alternative in rawAlternatives) {
      if (_isEmptyStringSymbol(alternative)) {
        alternatives.add(
          const ProductionAlternativeDraft(rightSide: [], isLambda: true),
        );
        continue;
      }

      final symbols = _parseRightSide(alternative);
      final emptyStringCount = symbols.where(_isEmptyStringSymbol).length;
      if (emptyStringCount > 1) {
        return const _ParsedAlternatives.error(
          _AlternativeParseError.repeatedEmptyString,
        );
      }
      if (emptyStringCount == 1) {
        return const _ParsedAlternatives.error(
          _AlternativeParseError.mixedEmptyString,
        );
      }
      alternatives.add(ProductionAlternativeDraft(rightSide: symbols));
    }
    return _ParsedAlternatives(alternatives);
  }

  bool _isEmptyStringSymbol(String symbol) => isEpsilonSymbol(symbol);

  String _formatSymbols(List<String> symbols) {
    if (symbols.isEmpty) {
      return '';
    }
    return symbols.join();
  }

  String _formatRightSide(Production production) {
    if (production.isLambda || production.rightSide.isEmpty) {
      return EmptyStringNotation.symbolOf(context);
    }
    return _formatSymbolsForInput(production.rightSide);
  }

  String _formatSymbolsForInput(List<String> symbols) {
    final escaped = symbols
        .map((symbol) => symbol.replaceAll('|', r'\|'))
        .toList(growable: false);
    return symbols.any((symbol) => symbol.length > 1)
        ? escaped.join(' ')
        : escaped.join();
  }

  String _formatGroupForInput(_ProductionGroup group) =>
      group.productions.map(_formatRightSide).join(' | ');

  String _formatGroupForDisplay(_ProductionGroup group) =>
      group.productions.map(_formatRightSide).join(' | ');

  void _showDuplicateFeedback(ProductionGroupMutationResult result) {
    if (result.duplicateCount == 0 || !mounted) return;
    final message = result.addedCount > 0
        ? _l10n.productionAlternativesSkippedDuplicates(
            result.addedCount,
            result.duplicateCount,
          )
        : _l10n.productionAlternativesAlreadyExist(result.duplicateCount);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static List<_ProductionGroup> _groupProductions(
    Iterable<Production> productions,
  ) {
    final groups = <_ProductionGroup>[];
    for (final production in productions) {
      final index = groups.indexWhere(
        (group) => listEquals(group.leftSide, production.leftSide),
      );
      if (index == -1) {
        groups.add(
          _ProductionGroup(
            leftSide: List<String>.from(production.leftSide),
            productions: [production],
          ),
        );
      } else {
        groups[index].productions.add(production);
      }
    }
    return groups;
  }

  static _ProductionGroup _groupForProduction(
    Iterable<Production> productions,
    Production selected,
  ) => _groupProductions(productions).firstWhere(
    (group) => listEquals(group.leftSide, selected.leftSide),
    orElse: () => _ProductionGroup(
      leftSide: List<String>.from(selected.leftSide),
      productions: [selected],
    ),
  );
}

class _ProductionGroup {
  _ProductionGroup({required this.leftSide, required this.productions});

  final List<String> leftSide;
  final List<Production> productions;
}

enum _AlternativeParseError {
  emptyAlternative,
  arrowExpression,
  repeatedEmptyString,
  mixedEmptyString,
}

class _ParsedAlternatives {
  const _ParsedAlternatives(this.alternatives) : error = null;

  const _ParsedAlternatives.error(this.error) : alternatives = const [];

  final List<ProductionAlternativeDraft> alternatives;
  final _AlternativeParseError? error;
}

class _EpsilonShortcutButton extends StatelessWidget {
  const _EpsilonShortcutButton({required this.onInsert});

  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: appLocalizationsOf(context).insertEpsilon,
      onPressed: onInsert,
      icon: const Text(
        kEpsilonSymbol,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );

    // Note: The tooltip provides an accessibility label for screen readers and
    // hover hints on desktop/web. The icon uses a Text widget so the symbol is
    // always rendered consistently across platforms.
  }
}
