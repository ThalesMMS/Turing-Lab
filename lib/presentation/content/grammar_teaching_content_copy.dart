import 'dart:convert';

import '../../core/educational_content/educational_content_reference.dart';
import '../../core/grammar/teaching/grammar_teaching_content.dart';

final class GrammarTeachingContentCopy {
  const GrammarTeachingContentCopy({
    required this.title,
    required this.instruction,
    required this.accessibleDescription,
  });

  final String title;
  final String instruction;
  final String accessibleDescription;
}

abstract final class GrammarTeachingContentCopies {
  static final _entries = List<_GrammarTeachingContentEntry>.unmodifiable([
    _entry(
      reference: GrammarTeachingContent.normalizationLambda,
      en: const GrammarTeachingContentCopy(
        title: 'Remove empty productions',
        instruction:
            'Rewrite the grammar so nullable choices are preserved without unnecessary empty productions.',
        accessibleDescription:
            'First normalization stage. Preserve words generated through nullable symbols while removing redundant empty rules.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Remova produções vazias',
        instruction:
            'Reescreva a gramática preservando as escolhas anuláveis sem produções vazias desnecessárias.',
        accessibleDescription:
            'Primeira etapa da normalização. Preserve as palavras geradas por símbolos anuláveis ao remover regras vazias redundantes.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.normalizationUnit,
      en: const GrammarTeachingContentCopy(
        title: 'Eliminate unit productions',
        instruction:
            'Replace single-nonterminal steps with the productions reachable through those steps.',
        accessibleDescription:
            'Second normalization stage. Bypass rules that only rename one nonterminal as another.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Elimine produções unitárias',
        instruction:
            'Substitua passos formados por um único não terminal pelas produções alcançáveis por esses passos.',
        accessibleDescription:
            'Segunda etapa da normalização. Ignore regras que apenas renomeiam um não terminal como outro.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.normalizationUseless,
      en: const GrammarTeachingContentCopy(
        title: 'Remove useless symbols',
        instruction:
            'Keep only symbols that can produce terminal words and are reachable from the start symbol.',
        accessibleDescription:
            'Third normalization stage. Remove nonproductive and unreachable portions of the grammar.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Remova símbolos inúteis',
        instruction:
            'Mantenha somente símbolos capazes de produzir palavras terminais e alcançáveis desde o símbolo inicial.',
        accessibleDescription:
            'Terceira etapa da normalização. Remova partes improdutivas e inalcançáveis da gramática.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.normalizationCnf,
      en: const GrammarTeachingContentCopy(
        title: 'Build Chomsky normal form',
        instruction:
            'Isolate terminals in longer rules and split long right-hand sides into binary steps.',
        accessibleDescription:
            'Final normalization stage. Express each rule as one terminal or two nonterminals, apart from the permitted empty start rule.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Construa a forma normal de Chomsky',
        instruction:
            'Isole terminais em regras longas e divida lados direitos extensos em passos binários.',
        accessibleDescription:
            'Etapa final da normalização. Expresse cada regra como um terminal ou dois não terminais, além da regra vazia inicial permitida.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.parseTableLl1,
      en: const GrammarTeachingContentCopy(
        title: 'Practice the LL(1) table',
        instruction:
            'Edit cell {row}, {column}. Compare the generated choices {alternatives} only after making your own decision.',
        accessibleDescription:
            'Predictive parsing table practice. Enter the production for row {row} and lookahead {column}.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Pratique a tabela LL(1)',
        instruction:
            'Edite a célula {row}, {column}. Compare as escolhas geradas {alternatives} somente depois de decidir.',
        accessibleDescription:
            'Prática da tabela preditiva. Informe a produção da linha {row} para o símbolo de antecipação {column}.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.parseTableLr1,
      en: const GrammarTeachingContentCopy(
        title: 'Practice the LR(1) table',
        instruction:
            'Edit cell {row}, {column}. Resolve among the generated actions {alternatives} without changing the reference table.',
        accessibleDescription:
            'Bottom-up parsing table practice. Choose the action for state {row} and symbol {column}.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Pratique a tabela LR(1)',
        instruction:
            'Edite a célula {row}, {column}. Resolva entre as ações geradas {alternatives} sem alterar a tabela de referência.',
        accessibleDescription:
            'Prática da tabela ascendente. Escolha a ação para o estado {row} e o símbolo {column}.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.bruteForceSearch,
      en: const GrammarTeachingContentCopy(
        title: 'Inspect the bounded derivation search',
        instruction:
            'Review limit {limits}, witness {witness}, and pruned branches {prunedCounts} before interpreting the result.',
        accessibleDescription:
            'Bounded search report. It summarizes the active limit, a derivation witness, and branches excluded by each pruning rule.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Inspecione a busca limitada de derivações',
        instruction:
            'Revise o limite {limits}, a testemunha {witness} e os ramos podados {prunedCounts} antes de interpretar o resultado.',
        accessibleDescription:
            'Relatório de busca limitada. Resume o limite ativo, uma derivação testemunha e os ramos excluídos por cada regra de poda.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.lr1Construction,
      en: const GrammarTeachingContentCopy(
        title: 'Explore LR(1) state {state}',
        instruction:
            'Inspect lookahead {lookahead}, available actions {actions}, and conflicts {conflicts} while following the canonical collection.',
        accessibleDescription:
            'LR parser construction. Explore the selected item-set state, its lookahead actions, and any conflicting actions.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Explore o estado LR(1) {state}',
        instruction:
            'Inspecione a antecipação {lookahead}, as ações disponíveis {actions} e os conflitos {conflicts} ao percorrer a coleção canônica.',
        accessibleDescription:
            'Construção do analisador LR. Explore o estado selecionado, suas ações de antecipação e eventuais ações em conflito.',
      ),
    ),
    _entry(
      reference: GrammarTeachingContent.userDerivation,
      en: const GrammarTeachingContentCopy(
        title: 'Derive target {target}',
        instruction:
            'Choose production {production} at occurrence {occurrence}. Respect the active bound {limit}.',
        accessibleDescription:
            'User-controlled derivation. Choose an applicable production and its exact occurrence while working toward the target word.',
      ),
      pt: const GrammarTeachingContentCopy(
        title: 'Derive o alvo {target}',
        instruction:
            'Escolha a produção {production} na ocorrência {occurrence}. Respeite o limite ativo {limit}.',
        accessibleDescription:
            'Derivação controlada pela pessoa usuária. Escolha uma produção aplicável e sua ocorrência exata para alcançar a palavra-alvo.',
      ),
    ),
  ]);

  static List<EducationalContentReference> get references =>
      List<EducationalContentReference>.unmodifiable(
        _entries.map((entry) => entry.reference),
      );

  static GrammarTeachingContentCopy resolve({
    required EducationalContentReference reference,
    required String languageCode,
    required Map<String, Object?> arguments,
  }) {
    final entry = _entries.firstWhere(
      (candidate) => candidate.reference == reference,
      orElse: () => throw StateError('grammar_teaching.copy_reference'),
    );
    final template = languageCode.toLowerCase().startsWith('pt')
        ? entry.pt
        : entry.en;
    return GrammarTeachingContentCopy(
      title: _interpolate(template.title, arguments),
      instruction: _interpolate(template.instruction, arguments),
      accessibleDescription: _interpolate(
        template.accessibleDescription,
        arguments,
      ),
    );
  }
}

final class _GrammarTeachingContentEntry {
  const _GrammarTeachingContentEntry({
    required this.reference,
    required this.en,
    required this.pt,
  });

  final EducationalContentReference reference;
  final GrammarTeachingContentCopy en;
  final GrammarTeachingContentCopy pt;
}

_GrammarTeachingContentEntry _entry({
  required EducationalContentReference reference,
  required GrammarTeachingContentCopy en,
  required GrammarTeachingContentCopy pt,
}) => _GrammarTeachingContentEntry(reference: reference, en: en, pt: pt);

String _interpolate(String template, Map<String, Object?> arguments) =>
    template.replaceAllMapped(RegExp(r'\{([A-Za-z][A-Za-z0-9]*)\}'), (match) {
      final key = match.group(1)!;
      if (!arguments.containsKey(key)) {
        throw StateError('grammar_teaching.copy_argument.$key');
      }
      return _formatValue(arguments[key]);
    });

String _formatValue(Object? value) => switch (value) {
  null => '—',
  final Iterable<Object?> values => values.map(_formatValue).join(', '),
  final Map<Object?, Object?> map => jsonEncode(map),
  _ => value.toString(),
};
