import 'package:flutter/material.dart';

import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';

/// Semantic form for one FA/right-linear-grammar correspondence step.
class FaGrammarRequirementEditor extends StatefulWidget {
  const FaGrammarRequirementEditor({
    super.key,
    required this.requirement,
    required this.onSubmit,
  });

  final ManualConversionRequirement requirement;
  final ValueChanged<Map<String, Object?>> onSubmit;

  @override
  State<FaGrammarRequirementEditor> createState() =>
      _FaGrammarRequirementEditorState();
}

class _FaGrammarRequirementEditorState
    extends State<FaGrammarRequirementEditor> {
  final _formKey = GlobalKey<FormState>();
  final _stateController = TextEditingController();
  final _nonterminalController = TextEditingController();
  final _productionLeftController = TextEditingController();
  final _productionRightController = TextEditingController();
  final _transitionFromController = TextEditingController();
  final _transitionToController = TextEditingController();
  final _transitionSymbolController = TextEditingController();
  final _stateFocus = FocusNode();
  final _nonterminalFocus = FocusNode();
  final _productionLeftFocus = FocusNode();
  final _productionRightFocus = FocusNode();
  final _transitionFromFocus = FocusNode();
  final _transitionToFocus = FocusNode();
  final _transitionKindFocus = FocusNode();
  final _transitionSymbolFocus = FocusNode();
  final _acceptingFocus = FocusNode();

  bool _productionIsEpsilon = false;
  bool _destinationIsAccepting = false;
  bool _acceptingConfirmed = false;
  _TransitionInputKind? _transitionKind;
  String? _selectionError;

  @override
  void dispose() {
    _stateController.dispose();
    _nonterminalController.dispose();
    _productionLeftController.dispose();
    _productionRightController.dispose();
    _transitionFromController.dispose();
    _transitionToController.dispose();
    _transitionSymbolController.dispose();
    _stateFocus.dispose();
    _nonterminalFocus.dispose();
    _productionLeftFocus.dispose();
    _productionRightFocus.dispose();
    _transitionFromFocus.dispose();
    _transitionToFocus.dispose();
    _transitionKindFocus.dispose();
    _transitionSymbolFocus.dispose();
    _acceptingFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requirement = widget.requirement;
    return Semantics(
      container: true,
      label: _localized('Step input'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSourceReference(requirement),
            if (_sourceIds(requirement).isNotEmpty) const SizedBox(height: 16),
            ..._fieldsFor(requirement),
            if (_selectionError case final message?) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _localized(message),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('fa-grammar-submit-step'),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(_localized('Check step')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceReference(ManualConversionRequirement requirement) {
    final sourceIds = _sourceIds(requirement);
    if (sourceIds.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: _localized('Source entities'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _localized('Source entities'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sourceId in sourceIds)
                Chip(
                  avatar: const Icon(Icons.link, size: 18),
                  label: Text(sourceId),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _fieldsFor(ManualConversionRequirement requirement) {
    return switch (requirement.type) {
      ManualConversionActionType.mapState => _mapStateFields(requirement),
      ManualConversionActionType.mapNonterminal => _mapNonterminalFields(
        requirement,
      ),
      ManualConversionActionType.addProduction => _productionFields(),
      ManualConversionActionType.addTransition => _transitionFields(),
      ManualConversionActionType.markEpsilon => _epsilonFields(requirement),
      ManualConversionActionType.markAccepting => _acceptingFields(),
      _ => [
        Text(
          _localized('This step has no FA or grammar editor.'),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    };
  }

  List<Widget> _mapStateFields(ManualConversionRequirement requirement) => [
    _fixedValue(
      label: 'State',
      value: _stringValue(requirement.expectedPayload['stateId']),
    ),
    const SizedBox(height: 12),
    _textField(
      key: const ValueKey('fa-grammar-nonterminal'),
      controller: _nonterminalController,
      focusNode: _nonterminalFocus,
      label: 'Nonterminal',
      error: 'Enter a nonterminal.',
      onSubmitted: (_) => _submit(),
    ),
  ];

  List<Widget> _mapNonterminalFields(ManualConversionRequirement requirement) =>
      [
        _fixedValue(
          label: 'Nonterminal',
          value: _stringValue(requirement.expectedPayload['nonterminal']),
        ),
        const SizedBox(height: 12),
        _textField(
          key: const ValueKey('fa-grammar-state-id'),
          controller: _stateController,
          focusNode: _stateFocus,
          label: 'State ID',
          error: 'Enter a state ID.',
          onSubmitted: (_) => _submit(),
        ),
      ];

  List<Widget> _productionFields() => [
    _textField(
      key: const ValueKey('fa-grammar-production-left'),
      controller: _productionLeftController,
      focusNode: _productionLeftFocus,
      label: 'Left-side nonterminal',
      error: 'Enter the left-side nonterminal.',
    ),
    const SizedBox(height: 12),
    SwitchListTile(
      key: const ValueKey('fa-grammar-production-epsilon'),
      contentPadding: EdgeInsets.zero,
      title: Text(_localized('Use ε as the right side')),
      subtitle: Text(_localized('Epsilon consumes no input symbol.')),
      value: _productionIsEpsilon,
      onChanged: (value) => setState(() {
        _productionIsEpsilon = value;
      }),
    ),
    if (!_productionIsEpsilon) ...[
      const SizedBox(height: 12),
      _textField(
        key: const ValueKey('fa-grammar-production-right'),
        controller: _productionRightController,
        focusNode: _productionRightFocus,
        label: 'Right-side symbols',
        helper: 'Separate symbols with spaces, for example: a A.',
        error: 'Enter at least one right-side symbol.',
        onSubmitted: (_) => _submit(),
      ),
    ],
  ];

  List<Widget> _transitionFields() => [
    Row(
      children: [
        Expanded(
          child: _textField(
            key: const ValueKey('fa-grammar-transition-from'),
            controller: _transitionFromController,
            focusNode: _transitionFromFocus,
            label: 'From state',
            error: 'Enter the source state ID.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _textField(
            key: const ValueKey('fa-grammar-transition-to'),
            controller: _transitionToController,
            focusNode: _transitionToFocus,
            label: 'To state',
            error: 'Enter the destination state ID.',
          ),
        ),
      ],
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<_TransitionInputKind>(
      key: const ValueKey('fa-grammar-transition-kind'),
      focusNode: _transitionKindFocus,
      initialValue: _transitionKind,
      decoration: InputDecoration(
        labelText: _localized('Transition type'),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: _TransitionInputKind.symbol,
          child: Text(_localized('Input symbol')),
        ),
        DropdownMenuItem(
          value: _TransitionInputKind.epsilon,
          child: Text(_localized('Epsilon (ε)')),
        ),
      ],
      validator: (value) =>
          value == null ? _localized('Select a transition type.') : null,
      onChanged: (value) => setState(() {
        _transitionKind = value;
      }),
    ),
    if (_transitionKind == _TransitionInputKind.symbol) ...[
      const SizedBox(height: 12),
      _textField(
        key: const ValueKey('fa-grammar-transition-symbol'),
        controller: _transitionSymbolController,
        focusNode: _transitionSymbolFocus,
        label: 'Input symbol',
        error: 'Enter an input symbol.',
      ),
    ],
    const SizedBox(height: 4),
    SwitchListTile(
      key: const ValueKey('fa-grammar-transition-accepting'),
      contentPadding: EdgeInsets.zero,
      title: Text(_localized('Destination state is accepting')),
      value: _destinationIsAccepting,
      onChanged: (value) => setState(() {
        _destinationIsAccepting = value;
      }),
    ),
  ];

  List<Widget> _epsilonFields(ManualConversionRequirement requirement) => [
    _fixedValue(
      label: 'Accepting state',
      value: _stringValue(requirement.expectedPayload['stateId']),
    ),
    const SizedBox(height: 12),
    _textField(
      key: const ValueKey('fa-grammar-production-left'),
      controller: _productionLeftController,
      focusNode: _productionLeftFocus,
      label: 'Left-side nonterminal',
      error: 'Enter the left-side nonterminal.',
      onSubmitted: (_) => _submit(),
    ),
    const SizedBox(height: 12),
    _fixedValue(label: 'Right side', value: 'ε'),
  ];

  List<Widget> _acceptingFields() => [
    _textField(
      key: const ValueKey('fa-grammar-state-id'),
      controller: _stateController,
      focusNode: _stateFocus,
      label: 'State ID',
      error: 'Enter a state ID.',
    ),
    const SizedBox(height: 4),
    SwitchListTile(
      key: const ValueKey('fa-grammar-mark-accepting'),
      focusNode: _acceptingFocus,
      contentPadding: EdgeInsets.zero,
      title: Text(_localized('Mark state as accepting')),
      value: _acceptingConfirmed,
      onChanged: (value) => setState(() {
        _acceptingConfirmed = value;
        if (value) _selectionError = null;
      }),
    ),
  ];

  Widget _fixedValue({required String label, required String value}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: _localized(label),
        border: const OutlineInputBorder(),
      ),
      child: SelectableText(EmptyStringNotation.formatMarkers(context, value)),
    );
  }

  Widget _textField({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String error,
    String? helper,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: _localized(label),
        helperText: helper == null ? null : _localized(helper),
        border: const OutlineInputBorder(),
      ),
      textInputAction: onSubmitted == null
          ? TextInputAction.next
          : TextInputAction.done,
      validator: (value) =>
          value == null || value.trim().isEmpty ? _localized(error) : null,
      onFieldSubmitted: onSubmitted,
    );
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (widget.requirement.type == ManualConversionActionType.markAccepting &&
        !_acceptingConfirmed) {
      setState(() {
        _selectionError = 'Select accepting before checking this step.';
      });
      _acceptingFocus.requestFocus();
      return;
    }
    if (!valid) {
      _focusFirstInvalidField();
      return;
    }
    setState(() => _selectionError = null);
    widget.onSubmit(_payload());
  }

  Map<String, Object?> _payload() {
    final requirement = widget.requirement;
    return switch (requirement.type) {
      ManualConversionActionType.mapState => {
        'stateId': _stringValue(requirement.expectedPayload['stateId']),
        'nonterminal': _nonterminalController.text.trim(),
      },
      ManualConversionActionType.mapNonterminal => {
        'nonterminal': _stringValue(requirement.expectedPayload['nonterminal']),
        'stateId': _stateController.text.trim(),
      },
      ManualConversionActionType.addProduction => {
        'sourceTransitionIds': _sourceIds(requirement),
        'production': {
          'leftSide': [_productionLeftController.text.trim()],
          'rightSide': _productionIsEpsilon
              ? <String>[]
              : _symbols(_productionRightController.text),
          'isEpsilon': _productionIsEpsilon,
        },
      },
      ManualConversionActionType.addTransition => {
        'sourceProductionIds': _sourceIds(requirement),
        'transition': {
          'fromStateId': _transitionFromController.text.trim(),
          'toStateId': _transitionToController.text.trim(),
          'inputSymbol': _transitionKind == _TransitionInputKind.epsilon
              ? ''
              : _transitionSymbolController.text.trim(),
          'isEpsilon': _transitionKind == _TransitionInputKind.epsilon,
          'toStateIsAccepting': _destinationIsAccepting,
        },
      },
      ManualConversionActionType.markEpsilon => {
        'stateId': _stringValue(requirement.expectedPayload['stateId']),
        'production': {
          'leftSide': [_productionLeftController.text.trim()],
          'rightSide': <String>[],
          'isEpsilon': true,
        },
      },
      ManualConversionActionType.markAccepting => {
        'sourceProductionIds': _sourceIds(requirement),
        'stateId': _stateController.text.trim(),
        'isAccepting': _acceptingConfirmed,
      },
      _ => <String, Object?>{},
    };
  }

  void _focusFirstInvalidField() {
    final focusNode = switch (widget.requirement.type) {
      ManualConversionActionType.mapState => _nonterminalFocus,
      ManualConversionActionType.mapNonterminal ||
      ManualConversionActionType.markAccepting => _stateFocus,
      ManualConversionActionType.addProduction =>
        _productionLeftController.text.trim().isEmpty
            ? _productionLeftFocus
            : _productionRightFocus,
      ManualConversionActionType.markEpsilon => _productionLeftFocus,
      ManualConversionActionType.addTransition =>
        _transitionFromController.text.trim().isEmpty
            ? _transitionFromFocus
            : _transitionToController.text.trim().isEmpty
            ? _transitionToFocus
            : _transitionKind == null
            ? _transitionKindFocus
            : _transitionSymbolFocus,
      _ => null,
    };
    focusNode?.requestFocus();
  }

  List<String> _sourceIds(ManualConversionRequirement requirement) {
    final key = switch (requirement.type) {
      ManualConversionActionType.addProduction => 'sourceTransitionIds',
      ManualConversionActionType.addTransition ||
      ManualConversionActionType.markAccepting => 'sourceProductionIds',
      _ => null,
    };
    if (key == null) return requirement.provenanceIds;
    final encoded = requirement.expectedPayload[key];
    if (encoded is! Iterable) return requirement.provenanceIds;
    return encoded.whereType<String>().toList(growable: false);
  }

  List<String> _symbols(String raw) => raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((symbol) => symbol.isNotEmpty)
      .toList(growable: false);

  String _stringValue(Object? value) => value is String ? value : '';

  String _localized(String text) => EmptyStringNotation.formatTerminology(
    context,
    appLocalizationsOf(context).localizeWorkflowText(text),
  );
}

enum _TransitionInputKind { symbol, epsilon }
