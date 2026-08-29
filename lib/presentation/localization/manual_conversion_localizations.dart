import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../l10n/app_localizations.dart';

/// Presentation copy for evidence produced by manual-conversion oracles.
///
/// The session model stores locale-neutral prose so it can be persisted and
/// replayed. This adapter translates the known summaries while leaving formal
/// identifiers, expressions, and counterexamples unchanged.
extension AppLocalizationsManualConversions on AppLocalizations {
  String manualConversionCertainty(ManualConversionCertainty certainty) {
    if (!_isPortuguese) {
      return switch (certainty) {
        ManualConversionCertainty.exact => 'Exact equivalence',
        ManualConversionCertainty.structural => 'Structural validation',
        ManualConversionCertainty.bounded => 'Bounded evidence',
      };
    }
    return switch (certainty) {
      ManualConversionCertainty.exact => 'Equivalência exata',
      ManualConversionCertainty.structural => 'Validação estrutural',
      ManualConversionCertainty.bounded => 'Evidência limitada',
    };
  }

  String manualConversionCounterexample(String value) =>
      _isPortuguese ? 'Contraexemplo: $value' : 'Counterexample: $value';

  String manualConversionInvariantSummary({
    required int stateCount,
    required int transitionCount,
    required int acceptingCount,
    required Iterable<String> alphabet,
  }) {
    final alphabetText = alphabet.isEmpty
        ? (_isPortuguese ? 'vazio' : 'empty')
        : alphabet.join(', ');
    if (!_isPortuguese) {
      return '$stateCount states, $transitionCount transitions, one entry '
          'state, and $acceptingCount accepting states. Alphabet: '
          '$alphabetText.';
    }
    final stateLabel = stateCount == 1 ? 'estado' : 'estados';
    final transitionLabel = transitionCount == 1 ? 'transição' : 'transições';
    final acceptingLabel = acceptingCount == 1 ? 'estado' : 'estados';
    return '$stateCount $stateLabel, $transitionCount $transitionLabel, '
        'um estado de entrada e $acceptingCount $acceptingLabel de aceitação. '
        'Alfabeto: $alphabetText.';
  }

  String manualConversionProvenance(Iterable<String> ids) {
    final values = ids.toList(growable: false);
    if (values.isEmpty) {
      return _isPortuguese
          ? 'Nenhuma entidade de origem é referenciada por esta etapa.'
          : 'No source entities are referenced by this step.';
    }
    final label = _isPortuguese
        ? 'Proveniência da origem'
        : 'Source provenance';
    return '$label: ${values.join(', ')}';
  }

  String manualConversionEvidenceSummary(String source) {
    if (!_isPortuguese) return source;
    final exact = _ptManualConversionSummaries[source];
    if (exact != null) return exact;

    final regexNode = RegExp(
      r'^The submitted ([A-Za-z]+) fragment matches the canonical Thompson structure\.$',
    ).firstMatch(source);
    if (regexNode != null) {
      return 'O fragmento de ${_ptRegexNodeKind(regexNode.group(1)!)} enviado '
          'corresponde à estrutura canônica de Thompson.';
    }

    final stateMapping = RegExp(
      r'^State (.+) maps to nonterminal (.+)\.$',
    ).firstMatch(source);
    if (stateMapping != null) {
      return 'O estado ${stateMapping.group(1)} corresponde ao não terminal '
          '${stateMapping.group(2)}.';
    }

    final nonterminalMapping = RegExp(
      r'^Nonterminal (.+) maps to state (.+)\.$',
    ).firstMatch(source);
    if (nonterminalMapping != null) {
      return 'O não terminal ${nonterminalMapping.group(1)} corresponde ao '
          'estado ${nonterminalMapping.group(2)}.';
    }

    final epsilonProduction = RegExp(
      r'^The epsilon production preserves acceptance at source state (.+)\.$',
    ).firstMatch(source);
    if (epsilonProduction != null) {
      return 'A produção ε preserva a aceitação no estado de origem '
          '${epsilonProduction.group(1)}.';
    }

    final acceptingState = RegExp(
      r'^Accepting state (.+) preserves the source epsilon production\.$',
    ).firstMatch(source);
    if (acceptingState != null) {
      return 'O estado de aceitação ${acceptingState.group(1)} preserva a '
          'produção ε de origem.';
    }

    final validation = RegExp(
      r'^The submitted correspondence matches its source obligation\. (.+)$',
    ).firstMatch(source);
    if (validation != null) {
      final suffix = _ptManualConversionSummaries[validation.group(1)!];
      if (suffix != null) {
        return 'A correspondência enviada coincide com sua obrigação de origem. '
            '$suffix';
      }
    }
    return source;
  }

  /// Localizes diagnostics emitted by the locale-neutral manual-conversion
  /// models while preserving formal identifiers and counterexamples.
  String manualConversionDiagnostic(String source) {
    if (!_isPortuguese) return source;
    final exact = _ptManualConversionDiagnostics[source];
    if (exact != null) return exact;

    final completeCounterexample = RegExp(
      r'^The completed automaton is not language-equivalent\. Counterexample: (.*)\.$',
    ).firstMatch(source);
    if (completeCounterexample != null) {
      return 'O autômato concluído não é equivalente em linguagem. '
          'Contraexemplo: ${completeCounterexample.group(1)}.';
    }

    final completeBefore = RegExp(
      r'^Complete (.+) before (.+)\.$',
    ).firstMatch(source);
    if (completeBefore != null) {
      return 'Conclua ${completeBefore.group(1)} antes de '
          '${completeBefore.group(2)}.';
    }

    final buildChild = RegExp(
      r'^Build child fragment (.+) before (.+)\.$',
    ).firstMatch(source);
    if (buildChild != null) {
      return 'Construa o fragmento filho ${buildChild.group(1)} antes de '
          '${buildChild.group(2)}.';
    }

    final stateCollision = RegExp(
      r'^State ID (.+) collides with an unrelated active fragment\.$',
    ).firstMatch(source);
    if (stateCollision != null) {
      return 'O ID de estado ${stateCollision.group(1)} colide com um '
          'fragmento ativo não relacionado.';
    }

    final unknownNode = RegExp(
      r'^Unknown syntax-tree node (.+)\.$',
    ).firstMatch(source);
    if (unknownNode != null) {
      return 'Nó da árvore sintática desconhecido: ${unknownNode.group(1)}.';
    }

    return source;
  }

  bool get _isPortuguese => localeName.toLowerCase().startsWith('pt');
}

const _ptManualConversionSummaries = <String, String>{
  'The canonical regex is exactly language-equivalent to the source FSA.':
      'A expressão regular canônica é exatamente equivalente em linguagem ao AF de origem.',
  'The completed epsilon-NFA is exactly language-equivalent to the source regular expression.':
      'O AFN-ε concluído é exatamente equivalente em linguagem à expressão regular de origem.',
  'The learner FSA is structurally valid and exactly language-equivalent to the source regular expression.':
      'O AF do aluno é estruturalmente válido e exatamente equivalente em linguagem à expressão regular de origem.',
  'The learner fragment is structurally isomorphic to the canonical Thompson fragment.':
      'O fragmento do aluno é estruturalmente isomorfo ao fragmento canônico de Thompson.',
  'The selected state is an eliminable internal GNFA state.':
      'O estado selecionado é um estado interno eliminável do GNFA.',
  'The pair label matches the canonical elimination formula.':
      'O rótulo do par corresponde à fórmula canônica de eliminação.',
  'The pair label is exactly language-equivalent to the elimination formula.':
      'O rótulo do par é exatamente equivalente em linguagem à fórmula de eliminação.',
  'Every affected pair is valid, so the selected state can be removed.':
      'Todos os pares afetados são válidos, então o estado selecionado pode ser removido.',
  'The completed expression is not exactly equivalent to the source FA.':
      'A expressão concluída não é exatamente equivalente ao AF de origem.',
  'The learner expression is exactly language-equivalent to the source FA.':
      'A expressão do aluno é exatamente equivalente em linguagem ao AF de origem.',
  'Fresh endpoints protect the GNFA boundaries during elimination.':
      'Extremos novos protegem os limites do GNFA durante a eliminação.',
  'The selected state is neither the GNFA start nor final state.':
      'O estado selecionado não é o início nem o final do GNFA.',
  'The pair label follows the GNFA state-elimination identity exactly.':
      'O rótulo do par segue exatamente a identidade de eliminação de estados do GNFA.',
  'All paths through the removed state remain represented.':
      'Todos os caminhos pelo estado removido continuam representados.',
  'The extracted regex is exactly equivalent to the source FSA.':
      'A expressão regular extraída é exatamente equivalente ao AF de origem.',
  'The canonical result recognizes exactly the source language.':
      'O resultado canônico reconhece exatamente a linguagem de origem.',
  'The submitted production has the canonical source, label, and destination correspondence.':
      'A produção enviada tem a correspondência canônica de origem, rótulo e destino.',
  'The submitted transition has the canonical source, label, and destination correspondence.':
      'A transição enviada tem a correspondência canônica de origem, rótulo e destino.',
  'The accepted partial document is not language-equivalent yet.':
      'O documento parcial aceito ainda não é equivalente em linguagem.',
  'The current learner document is exactly language-equivalent.':
      'O documento atual do aluno é exatamente equivalente em linguagem.',
  'The accepted mapping is structurally valid; the learner document is still incomplete.':
      'O mapeamento aceito é estruturalmente válido; o documento do aluno ainda está incompleto.',
};

const _ptManualConversionDiagnostics = <String, String>{
  'Enter the learner fragment as an FSA document.':
      'Informe o fragmento do aprendiz como um documento de AF.',
  'The learner FSA document is malformed.':
      'O documento de AF do aprendiz está malformado.',
  'This session does not convert a regular expression to an automaton.':
      'Esta sessão não converte uma expressão regular em um autômato.',
  'The recorded learner fragments cannot be replayed by the Regex-to-FA oracle.':
      'Os fragmentos registrados do aprendiz não podem ser reproduzidos pelo oráculo de expressão regular para AF.',
  'The current Regex-to-FA requirement has no syntax-tree node.':
      'O requisito atual de expressão regular para AF não possui um nó da árvore sintática.',
  'The current syntax-tree node is not part of the source snapshot.':
      'O nó atual da árvore sintática não faz parte do instantâneo da origem.',
  'The current action does not match the syntax-tree node kind.':
      'A ação atual não corresponde ao tipo do nó da árvore sintática.',
  'The construction is already complete.': 'A construção já está concluída.',
  'The source document changed. Restart or branch from the new revision.':
      'O documento de origem mudou. Reinicie ou ramifique a partir da nova revisão.',
  'The construction does not satisfy this step yet.':
      'A construção ainda não satisfaz esta etapa.',
  'There is no applied action to undo.': 'Não há ação aplicada para desfazer.',
  'There is no action to redo.': 'Não há ação para refazer.',
  'This saved construction uses an unsupported schema.':
      'Esta construção salva usa um esquema incompatível.',
  'The saved construction belongs to another source revision.':
      'A construção salva pertence a outra revisão da origem.',
  'The saved construction is malformed.': 'A construção salva está malformada.',
  'The GNFA endpoints do not match the source automaton.':
      'Os extremos do GNFA não correspondem ao autômato de origem.',
  'The exact language comparison failed.':
      'A comparação exata das linguagens falhou.',
  'The submitted fragment is not canonical.':
      'O fragmento enviado não é canônico.',
  'The completed learner document is not language-equivalent.':
      'O documento concluído do aprendiz não é equivalente em linguagem.',
  'The learner artifact has no document.':
      'O artefato do aprendiz não possui um documento.',
  'The learner document is malformed.':
      'O documento do aprendiz está malformado.',
  'This action is not part of FA-to-regex construction.':
      'Esta ação não faz parte da construção de AF para expressão regular.',
  'Choose an internal GNFA state that has not been eliminated.':
      'Escolha um estado interno do GNFA que ainda não tenha sido eliminado.',
  'The canonical FA/grammar conversion is not exactly equivalent.':
      'A conversão canônica entre AF e gramática não é exatamente equivalente.',
  'The session is not an FA/regular-grammar construction.':
      'A sessão não é uma construção entre AF e gramática regular.',
  'The FA/grammar source snapshot has no restorable document.':
      'O instantâneo da origem de AF/gramática não possui um documento restaurável.',
  'The saved learner correspondence cannot be replayed.':
      'A correspondência salva do aprendiz não pode ser reproduzida.',
  'The FA/grammar source snapshot is malformed.':
      'O instantâneo da origem de AF/gramática está malformado.',
  'The learner production is malformed.':
      'A produção do aprendiz está malformada.',
  'The learner transition is malformed.':
      'A transição do aprendiz está malformada.',
  'The learner construction has no start mapping yet.':
      'A construção do aprendiz ainda não possui um mapeamento inicial.',
  'Only a fresh FA/grammar plan can start a shared session.':
      'Somente um plano novo de AF/gramática pode iniciar uma sessão compartilhada.',
  'The FA-to-regex oracle produced a non-equivalent canonical artifact.':
      'O oráculo de AF para expressão regular produziu um artefato canônico não equivalente.',
};

String _ptRegexNodeKind(String source) => switch (source) {
  'symbol' => 'símbolo',
  'dot' => 'curinga',
  'epsilon' => 'palavra vazia',
  'emptyLanguage' => 'linguagem vazia',
  'characterSet' => 'conjunto de caracteres',
  'shortcut' => 'atalho',
  'union' => 'união',
  'concatenation' => 'concatenação',
  'kleeneStar' => 'repetição de zero ou mais',
  'plus' => 'repetição de uma ou mais',
  'optional' => 'opcional',
  _ => source,
};
