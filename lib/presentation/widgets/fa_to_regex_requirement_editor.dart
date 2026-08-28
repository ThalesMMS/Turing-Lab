import 'package:flutter/material.dart';

import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';

/// Semantic form for one GNFA state-elimination step.
class FaToRegexRequirementEditor extends StatefulWidget {
  const FaToRegexRequirementEditor({
    super.key,
    required this.requirement,
    required this.onSubmit,
  });

  final ManualConversionRequirement requirement;
  final ValueChanged<Map<String, Object?>> onSubmit;

  @override
  State<FaToRegexRequirementEditor> createState() =>
      _FaToRegexRequirementEditorState();
}

class _FaToRegexRequirementEditorState
    extends State<FaToRegexRequirementEditor> {
  final _formKey = GlobalKey<FormState>();
  final _expressionController = TextEditingController();
  final _expressionFocusNode = FocusNode();
  final _stateFocusNode = FocusNode();
  String? _selectedStateId;

  @override
  void dispose() {
    _expressionController.dispose();
    _expressionFocusNode.dispose();
    _stateFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: _localized('FA to Regex step input'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ..._fieldsFor(widget.requirement),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('fa-to-regex-submit-step'),
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(_localized('Check step')),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fieldsFor(ManualConversionRequirement requirement) {
    return switch (requirement.type) {
      ManualConversionActionType.normalizeEndpoints => [
          _fixedValue(
            label: 'Protected start state',
            value: _stringValue(requirement.expectedPayload['startStateId']),
          ),
          const SizedBox(height: 12),
          _fixedValue(
            label: 'Protected final state',
            value: _stringValue(requirement.expectedPayload['finalStateId']),
          ),
          const SizedBox(height: 12),
          _fixedValue(label: 'Endpoint bridge label', value: 'ε'),
        ],
      ManualConversionActionType.selectState => [_stateSelector(requirement)],
      ManualConversionActionType.submitPairExpression =>
        _pairExpressionFields(requirement),
      ManualConversionActionType.commitElimination =>
        _commitFields(requirement),
      ManualConversionActionType.complete => _completionFields(),
      _ => [
          Text(
            _localized('This step has no FA to Regex editor.'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
    };
  }

  Widget _stateSelector(ManualConversionRequirement requirement) {
    final stateIds = _stringList(
      requirement.supportingData['eliminableStateIds'],
    );
    final choices = stateIds.isEmpty
        ? requirement.acceptedPayloads
            .map((payload) => payload['stateId'])
            .whereType<String>()
            .toSet()
            .toList()
        : stateIds;
    choices.sort();
    return DropdownButtonFormField<String>(
      key: const ValueKey('fa-to-regex-state'),
      focusNode: _stateFocusNode,
      initialValue: _selectedStateId,
      decoration: InputDecoration(
        labelText: _localized('State to eliminate'),
        helperText: _localized(
          'Protected start and final states cannot be eliminated.',
        ),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final stateId in choices)
          DropdownMenuItem(value: stateId, child: Text(stateId)),
      ],
      validator: (value) =>
          value == null ? _localized('Select a state to eliminate.') : null,
      onChanged: (value) => setState(() => _selectedStateId = value),
    );
  }

  List<Widget> _pairExpressionFields(
    ManualConversionRequirement requirement,
  ) {
    final data = requirement.supportingData;
    return [
      _fixedValue(
        label: 'Affected state pair',
        value: '${_stringValue(data['fromStateId'])} → '
            '${_stringValue(data['toStateId'])}',
      ),
      const SizedBox(height: 12),
      Semantics(
        container: true,
        label: _localized('State-elimination formula and current labels'),
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localized('State-elimination formula'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                const SelectableText('R_ij ∪ R_ik(R_kk)*R_kj'),
                const SizedBox(height: 8),
                SelectableText(
                    'R_ij = ${_stringValue(data['directExpression'])}'),
                SelectableText(
                  'R_ik = ${_stringValue(data['incomingExpression'])}',
                ),
                SelectableText(
                    'R_kk = ${_stringValue(data['loopExpression'])}'),
                SelectableText(
                  'R_kj = ${_stringValue(data['outgoingExpression'])}',
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _expressionField(
        key: const ValueKey('fa-to-regex-pair-expression'),
        label: 'Resulting pair expression',
        helper: 'Enter the label after applying the formula.',
      ),
    ];
  }

  List<Widget> _commitFields(ManualConversionRequirement requirement) => [
        _fixedValue(
          label: 'State to remove',
          value: _stringValue(requirement.supportingData['stateId']),
        ),
        const SizedBox(height: 12),
        _fixedValue(
          label: 'Validated affected pairs',
          value: '${requirement.supportingData['pairCount'] ?? 0}',
        ),
        const SizedBox(height: 8),
        Text(
          _localized(
            'Checking this step removes the state only after every affected pair is valid.',
          ),
        ),
      ];

  List<Widget> _completionFields() => [
        _expressionField(
          key: const ValueKey('fa-to-regex-final-expression'),
          label: 'Final regular expression',
          helper: 'Enter an expression equivalent to the source automaton.',
        ),
      ];

  Widget _fixedValue({required String label, required String value}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: _localized(label),
        border: const OutlineInputBorder(),
      ),
      child: SelectableText(value),
    );
  }

  Widget _expressionField({
    required Key key,
    required String label,
    required String helper,
  }) {
    return TextFormField(
      key: key,
      controller: _expressionController,
      focusNode: _expressionFocusNode,
      decoration: InputDecoration(
        labelText: _localized(label),
        helperText: _localized(helper),
        border: const OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.done,
      validator: (value) => value == null || value.trim().isEmpty
          ? _localized('Enter a regular expression.')
          : null,
      onFieldSubmitted: (_) => _submit(),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      if (widget.requirement.type == ManualConversionActionType.selectState) {
        _stateFocusNode.requestFocus();
      } else {
        _expressionFocusNode.requestFocus();
      }
      return;
    }
    final requirement = widget.requirement;
    final payload = switch (requirement.type) {
      ManualConversionActionType.selectState => <String, Object?>{
          'stateId': _selectedStateId,
        },
      ManualConversionActionType.submitPairExpression => <String, Object?>{
          'fromStateId': requirement.expectedPayload['fromStateId'],
          'toStateId': requirement.expectedPayload['toStateId'],
          'expression': _expressionController.text.trim(),
        },
      ManualConversionActionType.complete => <String, Object?>{
          'regex': _expressionController.text.trim(),
        },
      _ => Map<String, Object?>.from(requirement.expectedPayload),
    };
    widget.onSubmit(payload);
  }

  List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: true)
      : <String>[];

  String _stringValue(Object? value) => value?.toString() ?? '∅';

  String _localized(String text) =>
      appLocalizationsOf(context).localizeWorkflowText(text);
}
