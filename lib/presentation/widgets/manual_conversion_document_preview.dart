import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/models/state.dart' as automaton;
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/conversion_preview_localizations.dart';
import '../empty_string_notation.dart';

typedef _PreviewTextBuilder = String Function(AppLocalizations l10n);

class ManualConversionDocumentPreview extends StatelessWidget {
  const ManualConversionDocumentPreview._({
    required _PreviewTextBuilder headingBuilder,
    required List<_PreviewTextBuilder> lineBuilders,
  }) : _headingBuilder = headingBuilder,
       _lineBuilders = lineBuilders;

  factory ManualConversionDocumentPreview.fsa(FSA fsa) {
    final states = fsa.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitions = fsa.fsaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return ManualConversionDocumentPreview._(
      headingBuilder: (_) => fsa.name,
      lineBuilders: [
        (l10n) =>
            '${l10n.conversionPreviewText('States', 'Estados')}: ${states.map((state) => _fsaStateText(l10n, fsa, state)).join(', ')}',
        (l10n) =>
            '${l10n.conversionPreviewText('Alphabet', 'Alfabeto')}: ${_ordered(fsa.alphabet).join(', ')}',
        for (final transition in transitions)
          (l10n) =>
              '${transition.fromState.label} → ${transition.toState.label}: ${transition.isEpsilonTransition ? 'ε' : _ordered(transition.inputSymbols).join(', ')} [${transition.id}]',
      ],
    );
  }

  factory ManualConversionDocumentPreview.grammar(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((left, right) {
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return ManualConversionDocumentPreview._(
      headingBuilder: (_) => grammar.name,
      lineBuilders: [
        (l10n) =>
            '${l10n.conversionPreviewText('Start', 'Início')}: ${grammar.startSymbol}',
        (l10n) =>
            '${l10n.conversionPreviewText('Nonterminals', 'Não terminais')}: ${_ordered(grammar.nonterminals).join(', ')}',
        (l10n) =>
            '${l10n.conversionPreviewText('Terminals', 'Terminais')}: ${_ordered(grammar.terminals).join(', ')}',
        for (final production in productions)
          (l10n) => _productionText(production),
      ],
    );
  }

  factory ManualConversionDocumentPreview.regex(String regex) {
    return ManualConversionDocumentPreview._(
      headingBuilder: (l10n) =>
          l10n.conversionPreviewText('Regular expression', 'Expressão regular'),
      lineBuilders: [(l10n) => regex.isEmpty ? 'ε' : regex],
    );
  }

  factory ManualConversionDocumentPreview.artifact(
    Map<String, Object?> artifact,
  ) {
    final regex = artifact['regex'];
    if (regex is String) {
      return ManualConversionDocumentPreview.regex(regex);
    }
    final gnfa = artifact['gnfa'];
    if (gnfa is Map) {
      return _gnfaPreview(artifact, gnfa);
    }
    final nestedDocument = artifact['document'];
    final fsaJson =
        artifact['fsa'] ??
        (artifact['kind'] == 'fsa' ? nestedDocument : null) ??
        (artifact.containsKey('states') && artifact.containsKey('transitions')
            ? artifact
            : null);
    if (fsaJson is Map) {
      try {
        return ManualConversionDocumentPreview.fsa(
          FSA.fromJson(Map<String, dynamic>.from(fsaJson)),
        );
      } on Object {
        // Fall through to the diagnostic representation below.
      }
    }
    final grammarJson =
        (artifact['kind'] == 'grammar' ? nestedDocument : null) ??
        (artifact.containsKey('productions') &&
                artifact.containsKey('nonterminals')
            ? artifact
            : null);
    if (grammarJson is Map) {
      try {
        return ManualConversionDocumentPreview.grammar(
          Grammar.fromJson(Map<String, dynamic>.from(grammarJson)),
        );
      } on Object {
        // Fall through to the diagnostic representation below.
      }
    }
    if (artifact['kind'] == 'grammar') {
      return _partialGrammarPreview(artifact);
    }
    if (artifact['kind'] == 'fsa') {
      return _partialFsaPreview(artifact);
    }
    return ManualConversionDocumentPreview._(
      headingBuilder: (l10n) => l10n.conversionPreviewText(
        'Constructed result',
        'Resultado construído',
      ),
      lineBuilders: [
        for (final line in const JsonEncoder.withIndent(
          '  ',
        ).convert(artifact).split('\n'))
          (l10n) => line,
      ],
    );
  }

  final _PreviewTextBuilder _headingBuilder;
  final List<_PreviewTextBuilder> _lineBuilders;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final heading = EmptyStringNotation.format(context, _headingBuilder(l10n));
    final lines = [
      for (final builder in _lineBuilders)
        EmptyStringNotation.format(context, builder(l10n)),
    ];
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: heading,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(heading, style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            for (final line in lines) ...[
              SelectableText(line),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  static List<String> _ordered(Iterable<String> values) =>
      values.toList()..sort();

  static ManualConversionDocumentPreview _gnfaPreview(
    Map<String, Object?> artifact,
    Map<Object?, Object?> encodedGnfa,
  ) {
    final gnfa = Map<String, Object?>.from(encodedGnfa);
    final startStateId = gnfa['startStateId'];
    final finalStateId = gnfa['finalStateId'];
    final states = _mapList(gnfa['states']);
    final labels = _mapList(gnfa['labels']);
    final pairLabels = _mapList(artifact['pairLabels']);
    final selectedStateId = artifact['selectedStateId'];
    return ManualConversionDocumentPreview._(
      headingBuilder: (l10n) =>
          '${l10n.conversionPreviewText('GNFA revision', 'Revisão do GNFA')} ${gnfa['revision'] ?? '?'}',
      lineBuilders: [
        for (final state in states)
          (l10n) => _gnfaStateText(
            l10n,
            state,
            startStateId: startStateId,
            finalStateId: finalStateId,
          ),
        if (selectedStateId is String)
          (l10n) =>
              '${l10n.conversionPreviewText('Selected state', 'Estado selecionado')}: $selectedStateId',
        for (final label in labels)
          (l10n) =>
              '${label['fromStateId']} → ${label['toStateId']}: ${label['expression']}',
        for (final label in pairLabels)
          (l10n) =>
              '${l10n.conversionPreviewText('Pending pair', 'Par pendente')} ${label['fromStateId']} → ${label['toStateId']}: ${label['expression']}',
        if (states.isEmpty && labels.isEmpty)
          (l10n) => l10n.conversionPreviewText(
            'The saved GNFA has no states.',
            'O GNFA salvo não possui estados.',
          ),
      ],
    );
  }

  static ManualConversionDocumentPreview _partialGrammarPreview(
    Map<String, Object?> artifact,
  ) {
    final mappings = _stringMap(artifact['stateToNonterminal']);
    final productions = _mapList(artifact['productions']);
    return ManualConversionDocumentPreview._(
      headingBuilder: (l10n) => l10n.conversionPreviewText(
        'Learner grammar',
        'Gramática do aprendiz',
      ),
      lineBuilders: [
        if (mappings.isNotEmpty)
          (l10n) =>
              '${l10n.conversionPreviewText('State mappings', 'Mapeamentos de estados')}: ${mappings.entries.map((entry) => '${entry.key} → ${entry.value}').join(', ')}',
        for (final production in productions)
          (l10n) =>
              '${_strings(production['leftSide']).join(' ')} → ${_productionRightSide(production)}',
        if (mappings.isEmpty && productions.isEmpty)
          (l10n) => l10n.conversionPreviewText(
            'No grammar mappings entered yet.',
            'Nenhum mapeamento de gramática foi informado.',
          ),
      ],
    );
  }

  static ManualConversionDocumentPreview _partialFsaPreview(
    Map<String, Object?> artifact,
  ) {
    final mappings = _stringMap(artifact['nonterminalToState']);
    final transitions = _mapList(artifact['transitions']);
    final acceptingStateIds = _strings(artifact['acceptingStateIds']);
    return ManualConversionDocumentPreview._(
      headingBuilder: (l10n) => l10n.conversionPreviewText(
        'Learner automaton',
        'Autômato do aprendiz',
      ),
      lineBuilders: [
        if (mappings.isNotEmpty)
          (l10n) =>
              '${l10n.conversionPreviewText('Nonterminal mappings', 'Mapeamentos de não terminais')}: ${mappings.entries.map((entry) => '${entry.key} → ${entry.value}').join(', ')}',
        if (acceptingStateIds.isNotEmpty)
          (l10n) =>
              '${l10n.conversionPreviewText('Accepting states', 'Estados de aceitação')}: ${acceptingStateIds.join(', ')}',
        for (final transition in transitions)
          (l10n) =>
              '${transition['fromStateId']} → ${transition['toStateId']}: ${transition['isEpsilon'] == true ? 'ε' : transition['inputSymbol']}',
        if (mappings.isEmpty &&
            transitions.isEmpty &&
            acceptingStateIds.isEmpty)
          (l10n) => l10n.conversionPreviewText(
            'No automaton mappings entered yet.',
            'Nenhum mapeamento de autômato foi informado.',
          ),
      ],
    );
  }

  static String _gnfaStateText(
    AppLocalizations l10n,
    Map<String, Object?> state, {
    required Object? startStateId,
    required Object? finalStateId,
  }) {
    final id = state['id'];
    final flags = <String>[
      if (id == startStateId)
        l10n.conversionPreviewText('protected start', 'início protegido'),
      if (id == finalStateId)
        l10n.conversionPreviewText('protected final', 'final protegido'),
      if (state['isProtected'] == true &&
          id != startStateId &&
          id != finalStateId)
        l10n.conversionPreviewText('protected', 'protegido'),
    ];
    final suffix = flags.isEmpty ? '' : '; ${flags.join(', ')}';
    return '${state['label'] ?? id} [$id$suffix]';
  }

  static List<Map<String, Object?>> _mapList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is Map) Map<String, Object?>.from(entry),
    ];
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};
    final entries = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is String && entry.value is String) {
        entries[entry.key as String] = entry.value as String;
      }
    }
    return Map.fromEntries(
      entries.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return [
      for (final entry in value)
        if (entry is String) entry,
    ];
  }

  static String _productionRightSide(Map<String, Object?> production) {
    final rightSide = _strings(production['rightSide']);
    return production['isEpsilon'] == true || rightSide.isEmpty
        ? 'ε'
        : rightSide.join(' ');
  }

  static String _productionText(Production production) {
    final left = production.leftSide.join(' ');
    final right = production.isLambda || production.rightSide.isEmpty
        ? 'ε'
        : production.rightSide.join(' ');
    return '$left → $right [${production.id}]';
  }

  static String _fsaStateText(
    AppLocalizations l10n,
    FSA fsa,
    automaton.State state,
  ) {
    final flags = [
      if (state == fsa.initialState)
        l10n.conversionPreviewText('initial', 'inicial'),
      if (fsa.acceptingStates.contains(state))
        l10n.conversionPreviewText('accepting', 'de aceitação'),
    ];
    return flags.isEmpty
        ? '${state.label} [${state.id}]'
        : '${state.label} [${state.id}; ${flags.join(', ')}]';
  }
}
