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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/production.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/grammar_provider.dart';
import 'grammar_editor_section.dart';
import '../../core/constants/monospace_typography.dart';

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
  bool _isEditing = false;

  String? _leftSideErrorText;
  String? _rightSideErrorText;

  AppLocalizations get _l10n => jflapLocalizationsOf(context);

  @override
  void initState() {
    super.initState();
    final state = ref.read(grammarProvider);
    _startSymbolController.text = state.startSymbol;
    _grammarNameController.text = state.name;
    if (widget.productionToEdit case final production?) {
      _selectedProductionId = production.id;
      _isEditing = true;
      _leftSideController.text = _formatSymbols(production.leftSide);
      _rightSideController.text = _formatRightSide(production);
    }
  }

  @override
  void dispose() {
    _startSymbolController.dispose();
    _leftSideController.dispose();
    _rightSideController.dispose();
    _grammarNameController.dispose();
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
    return Card(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (widget.section != GrammarEditorSection.details)
                _buildProductionsList(context, grammarState.productions),
            ],
          ),
        ),
      ),
    );
  }

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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                        suffixIcon: _LambdaShortcutButton(
                          onInsert: () => _insertIntoController(
                            controller: _rightSideController,
                            symbol: 'λ',
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
                            symbol: 'λ',
                          ),
                          child: Text(_l10n.insertLambda),
                        ),
                        TextButton(
                          onPressed: () => _insertIntoController(
                            controller: _rightSideController,
                            symbol: 'ε',
                          ),
                          child: Text(_l10n.insertEpsilon),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.rightSideHelper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                            suffixIcon: _LambdaShortcutButton(
                              onInsert: () => _insertIntoController(
                                controller: _rightSideController,
                                symbol: 'λ',
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
                                symbol: 'λ',
                              ),
                              child: Text(_l10n.insertLambda),
                            ),
                            TextButton(
                              onPressed: () => _insertIntoController(
                                controller: _rightSideController,
                                symbol: 'ε',
                              ),
                              child: Text(_l10n.insertEpsilon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _l10n.rightSideHelper,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
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
                      onPressed:
                          _isEditing ? _updateProduction : _addProduction,
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

  Widget _buildProductionsList(
    BuildContext context,
    List<Production> productions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _l10n.productionRulesCount(productions.length),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (productions.isEmpty)
          _buildEmptyState(context)
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: productions.asMap().entries.map((entry) {
              final index = entry.key;
              final production = entry.value;
              return _buildProductionItem(context, production, index);
            }).toList(),
          ),
      ],
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
            'No production rules yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.section == GrammarEditorSection.productions
                ? l10n.grammarEmptyProductionEditInstruction
                : 'Add your first production rule above',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionItem(
    BuildContext context,
    Production production,
    int index,
  ) {
    final isSelected = _selectedProductionId == production.id;

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
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            '${_formatSymbols(production.leftSide)} → ${_formatRightSide(production)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            'Rule ${index + 1}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                final onEditProduction = widget.onEditProduction;
                if (onEditProduction != null) {
                  onEditProduction(production);
                } else {
                  _editProduction(production);
                }
              } else if (value == 'delete') {
                _deleteProduction(production);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, size: 18),
                    const SizedBox(width: 8),
                    Text(_l10n.delete),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
          onTap: () => _selectProduction(production),
          selected: isSelected,
        ),
      ),
    );
  }

  void _addProduction() {
    if (!_validateProductionEditorInputs()) {
      return;
    }

    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();

    final parsedLeft = _parseLeftSide(leftSide);
    final parsedRight = _parseRightSide(rightSide);
    final isLambda =
        parsedRight.length == 1 && _isLambdaSymbol(parsedRight.first);
    final normalizedRight = isLambda ? <String>[] : parsedRight;

    ref.read(grammarProvider.notifier).addProduction(
          leftSide: parsedLeft,
          rightSide: normalizedRight,
          isLambda: isLambda,
        );

    _clearFields();
  }

  void _updateProduction() {
    if (_selectedProductionId == null) return;

    if (!_validateProductionEditorInputs()) {
      return;
    }

    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();

    final parsedLeft = _parseLeftSide(leftSide);
    final parsedRight = _parseRightSide(rightSide);
    final isLambda =
        parsedRight.length == 1 && _isLambdaSymbol(parsedRight.first);
    final normalizedRight = isLambda ? <String>[] : parsedRight;

    ref.read(grammarProvider.notifier).updateProduction(
          _selectedProductionId!,
          leftSide: parsedLeft,
          rightSide: normalizedRight,
          isLambda: isLambda,
        );
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
    });
    _clearFields();
  }

  void _editProduction(Production production) {
    setState(() {
      _selectedProductionId = production.id;
      _isEditing = true;
      _leftSideErrorText = null;
      _rightSideErrorText = null;
      _leftSideController.text = _formatSymbols(production.leftSide);
      _rightSideController.text = _formatRightSide(production);
    });
  }

  void _deleteProduction(Production production) {
    ref.read(grammarProvider.notifier).deleteProduction(production.id);
    if (_selectedProductionId == production.id) {
      setState(() {
        _selectedProductionId = null;
        _isEditing = false;
      });
      _clearFields();
    }
  }

  void _selectProduction(Production production) {
    setState(() {
      _selectedProductionId = production.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
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
      leftError = leftSide.isEmpty
          ? 'Both left side and right side must be specified'
          : null;
      rightError = rightSide.isEmpty
          ? 'Both left side and right side must be specified'
          : null;
    } else {
      final parsedLeft = _parseLeftSide(leftSide);
      if (parsedLeft.isEmpty) {
        leftError = 'Left side must contain a non-terminal symbol';
      } else if (parsedLeft.length != 1) {
        leftError = 'Left side must contain exactly one non-terminal symbol';
      }

      final parsedRight = _parseRightSide(rightSide);
      if (parsedRight.isEmpty) {
        rightError = 'Right side must contain at least one symbol (or λ/ε)';
      } else {
        final lambdaCount = parsedRight.where(_isLambdaSymbol).length;
        if (lambdaCount > 1) {
          rightError = 'Right side can contain only one λ/ε symbol';
        } else if (lambdaCount == 1 && parsedRight.length > 1) {
          rightError = 'λ/ε must be the only symbol on the right side';
        }
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

  bool _isLambdaSymbol(String symbol) =>
      symbol == 'ε' || symbol == 'λ' || symbol.toLowerCase() == 'lambda';

  String _formatSymbols(List<String> symbols) {
    if (symbols.isEmpty) {
      return '';
    }
    return symbols.join();
  }

  String _formatRightSide(Production production) {
    if (production.isLambda || production.rightSide.isEmpty) {
      return 'ε';
    }
    return _formatSymbols(production.rightSide);
  }
}

class _LambdaShortcutButton extends StatelessWidget {
  const _LambdaShortcutButton({required this.onInsert});

  final VoidCallback onInsert;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: appLocalizationsOf(context).insertLambda,
      onPressed: onInsert,
      icon: const Text(
        'λ',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );

    // Note: The tooltip provides an accessibility label for screen readers and
    // hover hints on desktop/web. The icon uses a Text widget so the symbol is
    // always rendered consistently across platforms.
  }
}
