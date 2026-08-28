import 'dart:convert';

import '../../core/educational_content/educational_content_reference.dart';
import '../../core/manual_conversions/manual_conversion_content.dart';
import '../../core/manual_conversions/manual_conversion_session.dart';

final class ManualConversionContentCopy {
  const ManualConversionContentCopy({
    required this.title,
    required this.instruction,
    required this.hint,
    required this.revealExplanation,
    required this.accessibleDescription,
  });

  final String title;
  final String instruction;
  final String hint;
  final String revealExplanation;
  final String accessibleDescription;
}

abstract final class ManualConversionContentCopies {
  static final _entries = List<_ManualConversionContentEntry>.unmodifiable([
    _entry(
      reference: ManualConversionContent.faToRegexNormalize,
      en: const ManualConversionContentCopy(
        title: 'Protect the GNFA endpoints',
        instruction:
            'Create {startStateId} and {finalStateId}, then link the original start {initialStateId} and accepting states {acceptingStateIds} with epsilon bridges.',
        hint:
            'The new start has no incoming edges, and the new final has no outgoing edges.',
        revealExplanation:
            'Use {startStateId} as the protected start and {finalStateId} as the protected final. Connect every endpoint with epsilon.',
        accessibleDescription:
            'Add one protected start state and one protected final state before eliminating any state.',
      ),
      pt: const ManualConversionContentCopy(
        title: 'Proteja os extremos do GNFA',
        instruction:
            'Crie {startStateId} e {finalStateId}; depois ligue o estado inicial original {initialStateId} e os estados de aceitação {acceptingStateIds} com transições vazias.',
        hint:
            'O novo estado inicial não recebe transições, e o novo estado final não possui transições de saída.',
        revealExplanation:
            'Use {startStateId} como início protegido e {finalStateId} como final protegido. Conecte cada extremo com transições vazias.',
        accessibleDescription:
            'Adicione um estado inicial protegido e um estado final protegido antes de eliminar qualquer estado.',
      ),
    ),
    _entry(
      reference: ManualConversionContent.faToRegexSelectState,
      en: const ManualConversionContentCopy(
        title: 'Choose state {stateId}',
        instruction:
            'Select the next internal state in the elimination sequence.',
        hint:
            'Only internal states may be removed; the protected endpoints remain.',
        revealExplanation:
            'State {stateId} is internal and can be removed without discarding either protected endpoint.',
        accessibleDescription:
            'Choose internal state {stateId} as the next state to eliminate.',
      ),
      pt: const ManualConversionContentCopy(
        title: 'Escolha o estado {stateId}',
        instruction:
            'Selecione o próximo estado interno da sequência de eliminação.',
        hint:
            'Somente estados internos podem ser removidos; os extremos protegidos permanecem.',
        revealExplanation:
            'O estado {stateId} é interno e pode ser removido sem descartar nenhum extremo protegido.',
        accessibleDescription:
            'Escolha o estado interno {stateId} como o próximo estado a eliminar.',
      ),
    ),
    _entry(
      reference: ManualConversionContent.faToRegexPairExpression,
      en: const ManualConversionContentCopy(
        title: 'Update {fromStateId} to {toStateId}',
        instruction:
            'Combine the direct path with the path through {stateId}: {directExpression}, {incomingExpression}, {loopExpression}, and {outgoingExpression}.',
        hint:
            'Account for the direct edge, the incoming edge, the loop, and the outgoing edge exactly once.',
        revealExplanation:
            'The canonical label for {fromStateId} to {toStateId} is {expectedExpression}.',
        accessibleDescription:
            'Recalculate the connection from {fromStateId} to {toStateId} after removing state {stateId}.',
      ),
      pt: const ManualConversionContentCopy(
        title: 'Atualize {fromStateId} para {toStateId}',
        instruction:
            'Combine o caminho direto com o caminho por {stateId}: {directExpression}, {incomingExpression}, {loopExpression} e {outgoingExpression}.',
        hint:
            'Considere exatamente uma vez a aresta direta, a entrada, o laço e a saída.',
        revealExplanation:
            'O rótulo canônico de {fromStateId} para {toStateId} é {expectedExpression}.',
        accessibleDescription:
            'Recalcule a ligação de {fromStateId} para {toStateId} após remover o estado {stateId}.',
      ),
    ),
    _entry(
      reference: ManualConversionContent.faToRegexCommitElimination,
      en: const ManualConversionContentCopy(
        title: 'Remove state {stateId}',
        instruction:
            'Commit the elimination after all {pairCount} affected connections are valid.',
        hint:
            'Check every affected source-and-destination pair before removing the state.',
        revealExplanation:
            'All {pairCount} affected connections are valid, so {stateId} can now be removed.',
        accessibleDescription:
            'Confirm all {pairCount} updated connections, then remove state {stateId}.',
      ),
      pt: const ManualConversionContentCopy(
        title: 'Remova o estado {stateId}',
        instruction:
            'Confirme a eliminação depois que as {pairCount} ligações afetadas estiverem válidas.',
        hint:
            'Verifique cada par de origem e destino afetado antes de remover o estado.',
        revealExplanation:
            'As {pairCount} ligações afetadas estão válidas; agora {stateId} pode ser removido.',
        accessibleDescription:
            'Confirme as {pairCount} ligações atualizadas e depois remova o estado {stateId}.',
      ),
    ),
    _entry(
      reference: ManualConversionContent.faToRegexComplete,
      en: const ManualConversionContentCopy(
        title: 'Read the final regular expression',
        instruction:
            'Use the remaining connection from the protected start to the protected final.',
        hint: 'Only the two protected endpoint states should remain.',
        revealExplanation: 'The remaining connection is {regex}.',
        accessibleDescription:
            'Read the sole remaining start-to-final connection as the result.',
      ),
      pt: const ManualConversionContentCopy(
        title: 'Leia a expressão regular final',
        instruction:
            'Use a ligação restante do início protegido ao final protegido.',
        hint: 'Somente os dois estados extremos protegidos devem permanecer.',
        revealExplanation: 'A ligação restante é {regex}.',
        accessibleDescription:
            'Leia a única ligação restante do início ao final como resultado.',
      ),
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaSymbol,
      enName: 'symbol',
      ptName: 'símbolo',
      enCue: 'Create one consuming transition between fresh endpoints.',
      ptCue: 'Crie uma transição de consumo entre extremos novos.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaDot,
      enName: 'wildcard',
      ptName: 'curinga',
      enCue: 'Create one transition that accepts any supported symbol.',
      ptCue: 'Crie uma transição que aceite qualquer símbolo compatível.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaEpsilon,
      enName: 'empty-word',
      ptName: 'palavra vazia',
      enCue: 'Join fresh endpoints without consuming input.',
      ptCue: 'Una extremos novos sem consumir entrada.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaEmptyLanguage,
      enName: 'empty-language',
      ptName: 'linguagem vazia',
      enCue: 'Keep the fresh entry disconnected from acceptance.',
      ptCue: 'Mantenha a entrada nova desconectada da aceitação.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaCharacterSet,
      enName: 'character-set',
      ptName: 'conjunto de caracteres',
      enCue: 'Use parallel consuming choices between the same endpoints.',
      ptCue: 'Use escolhas de consumo paralelas entre os mesmos extremos.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaShortcut,
      enName: 'shortcut',
      ptName: 'atalho',
      enCue: 'Expand the shortcut into its supported symbol choices.',
      ptCue: 'Expanda o atalho nas escolhas de símbolos compatíveis.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaUnion,
      enName: 'union',
      ptName: 'união',
      enCue: 'Branch to both child fragments and merge their exits.',
      ptCue: 'Ramifique para os dois fragmentos filhos e una suas saídas.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaConcatenation,
      enName: 'concatenation',
      ptName: 'concatenação',
      enCue: 'Connect the first child exit to the second child entry.',
      ptCue: 'Ligue a saída do primeiro filho à entrada do segundo.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaKleeneStar,
      enName: 'zero-or-more repetition',
      ptName: 'repetição de zero ou mais',
      enCue: 'Allow bypass, entry, repetition, and exit paths.',
      ptCue: 'Permita caminhos de desvio, entrada, repetição e saída.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaPlus,
      enName: 'one-or-more repetition',
      ptName: 'repetição de uma ou mais',
      enCue: 'Require one child pass before enabling repetition.',
      ptCue: 'Exija uma passagem pelo filho antes de permitir repetição.',
    ),
    _regexNode(
      reference: ManualConversionContent.regexToFaOptional,
      enName: 'optional',
      ptName: 'opcional',
      enCue: 'Offer either the child fragment or a bypass path.',
      ptCue: 'Ofereça o fragmento filho ou um caminho de desvio.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.faGrammarMapState,
      enTitle: 'Map state {stateId}',
      ptTitle: 'Mapeie o estado {stateId}',
      enAction: 'Assign nonterminal {nonterminal} to state {stateId}.',
      ptAction: 'Associe o não terminal {nonterminal} ao estado {stateId}.',
      enReveal: 'State {stateId} maps to nonterminal {nonterminal}.',
      ptReveal: 'O estado {stateId} corresponde ao não terminal {nonterminal}.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.faGrammarAddProduction,
      enTitle: 'Add the transition production',
      ptTitle: 'Adicione a produção da transição',
      enAction:
          'Create production {production} from source transitions {sourceTransitionIds}.',
      ptAction:
          'Crie a produção {production} a partir das transições de origem {sourceTransitionIds}.',
      enReveal: 'The canonical production is {production}.',
      ptReveal: 'A produção canônica é {production}.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.faGrammarAddEpsilon,
      enTitle: 'Represent an accepting state',
      ptTitle: 'Represente um estado de aceitação',
      enAction: 'Add production {production} for accepting state {stateId}.',
      ptAction:
          'Adicione a produção {production} para o estado de aceitação {stateId}.',
      enReveal: 'State {stateId} contributes production {production}.',
      ptReveal: 'O estado {stateId} produz a produção {production}.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.grammarFaMapNonterminal,
      enTitle: 'Map nonterminal {nonterminal}',
      ptTitle: 'Mapeie o não terminal {nonterminal}',
      enAction: 'Assign state {stateId} to nonterminal {nonterminal}.',
      ptAction: 'Associe o estado {stateId} ao não terminal {nonterminal}.',
      enReveal: 'Nonterminal {nonterminal} maps to state {stateId}.',
      ptReveal: 'O não terminal {nonterminal} corresponde ao estado {stateId}.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.grammarFaAddTransition,
      enTitle: 'Add the production transition',
      ptTitle: 'Adicione a transição da produção',
      enAction:
          'Create transition {transition} from source productions {sourceProductionIds}.',
      ptAction:
          'Crie a transição {transition} a partir das produções de origem {sourceProductionIds}.',
      enReveal: 'The canonical transition is {transition}.',
      ptReveal: 'A transição canônica é {transition}.',
    ),
    _grammarEntry(
      reference: ManualConversionContent.grammarFaMarkAccepting,
      enTitle: 'Mark an accepting state',
      ptTitle: 'Marque um estado de aceitação',
      enAction:
          'Mark state {stateId} as accepting for source productions {sourceProductionIds}.',
      ptAction:
          'Marque o estado {stateId} como de aceitação para as produções de origem {sourceProductionIds}.',
      enReveal: 'State {stateId} is accepting.',
      ptReveal: 'O estado {stateId} é de aceitação.',
    ),
  ]);

  static List<EducationalContentReference> get references =>
      List<EducationalContentReference>.unmodifiable(
        _entries.map((entry) => entry.reference),
      );

  static ManualConversionContentCopy? resolve({
    required EducationalContentReference reference,
    required String languageCode,
    required Map<String, Object?> arguments,
  }) {
    for (final entry in _entries) {
      if (entry.reference == reference) {
        final template = languageCode.toLowerCase().startsWith('pt')
            ? entry.pt
            : entry.en;
        return _resolveTemplate(template, arguments);
      }
    }
    return null;
  }

  static ManualConversionContentCopy? resolveRequirement({
    required ManualConversionRequirement requirement,
    required String languageCode,
  }) {
    final arguments = <String, Object?>{
      ...requirement.supportingData,
      ...requirement.expectedPayload,
    };
    if (arguments['selectedStateId'] case final Object value) {
      arguments['stateId'] = value;
    }
    if (arguments['expression'] case final Object value) {
      arguments['expectedExpression'] = value;
    }
    return resolve(
      reference: requirement.contentReference,
      languageCode: languageCode,
      arguments: arguments,
    );
  }
}

final class _ManualConversionContentEntry {
  const _ManualConversionContentEntry({
    required this.reference,
    required this.en,
    required this.pt,
  });

  final EducationalContentReference reference;
  final ManualConversionContentCopy en;
  final ManualConversionContentCopy pt;
}

_ManualConversionContentEntry _entry({
  required EducationalContentReference reference,
  required ManualConversionContentCopy en,
  required ManualConversionContentCopy pt,
}) => _ManualConversionContentEntry(reference: reference, en: en, pt: pt);

_ManualConversionContentEntry _regexNode({
  required EducationalContentReference reference,
  required String enName,
  required String ptName,
  required String enCue,
  required String ptCue,
}) => _entry(
  reference: reference,
  en: ManualConversionContentCopy(
    title: 'Build the {nodeId} $enName fragment',
    instruction: '$enCue Use completed child fragments {childIds}.',
    hint: 'Review syntax source {sourceReference} and preserve child order.',
    revealExplanation:
        'The canonical $enName fragment for {nodeId} satisfies the required entry, exit, and transition structure.',
    accessibleDescription:
        'Regex node {nodeId}. Build its $enName automaton fragment. $enCue',
  ),
  pt: ManualConversionContentCopy(
    title: 'Construa o fragmento de $ptName {nodeId}',
    instruction: '$ptCue Use os fragmentos filhos concluídos {childIds}.',
    hint:
        'Revise a origem sintática {sourceReference} e preserve a ordem dos filhos.',
    revealExplanation:
        'O fragmento canônico de $ptName para {nodeId} satisfaz a estrutura exigida de entrada, saída e transições.',
    accessibleDescription:
        'Nó de expressão regular {nodeId}. Construa seu fragmento de $ptName. $ptCue',
  ),
);

_ManualConversionContentEntry _grammarEntry({
  required EducationalContentReference reference,
  required String enTitle,
  required String ptTitle,
  required String enAction,
  required String ptAction,
  required String enReveal,
  required String ptReveal,
}) => _entry(
  reference: reference,
  en: ManualConversionContentCopy(
    title: enTitle,
    instruction: enAction,
    hint: 'Trace the source identifiers before submitting the target object.',
    revealExplanation: enReveal,
    accessibleDescription: enAction,
  ),
  pt: ManualConversionContentCopy(
    title: ptTitle,
    instruction: ptAction,
    hint:
        'Confira os identificadores de origem antes de enviar o objeto de destino.',
    revealExplanation: ptReveal,
    accessibleDescription: ptAction,
  ),
);

ManualConversionContentCopy _resolveTemplate(
  ManualConversionContentCopy template,
  Map<String, Object?> arguments,
) => ManualConversionContentCopy(
  title: _interpolate(template.title, arguments),
  instruction: _interpolate(template.instruction, arguments),
  hint: _interpolate(template.hint, arguments),
  revealExplanation: _interpolate(template.revealExplanation, arguments),
  accessibleDescription: _interpolate(
    template.accessibleDescription,
    arguments,
  ),
);

String _interpolate(String template, Map<String, Object?> arguments) =>
    template.replaceAllMapped(RegExp(r'\{([A-Za-z][A-Za-z0-9]*)\}'), (match) {
      final key = match.group(1)!;
      if (!arguments.containsKey(key)) {
        throw StateError('manual_conversion.copy_argument.$key');
      }
      return _formatValue(arguments[key]);
    });

String _formatValue(Object? value) => switch (value) {
  null => '—',
  final Iterable<Object?> values => values.map(_formatValue).join(', '),
  final Map<Object?, Object?> map => jsonEncode(map),
  _ => value.toString(),
};
