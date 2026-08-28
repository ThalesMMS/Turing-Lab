import '../../core/grammar/phrase_structure/phrase_structure.dart';
import 'package:flutter/widgets.dart';

final class UnrestrictedGrammarWorkspaceStrings {
  const UnrestrictedGrammarWorkspaceStrings({
    required this.usesPortuguese,
    required this.title,
    required this.editorTitle,
    required this.derivationTitle,
    required this.classificationLabel,
    required this.classifyGrammar,
    required this.grammarStructureDisclaimer,
    required this.regularOrientationLabel,
    required this.normalFormsLabel,
    required this.noNormalForms,
    required this.copyStructuredReport,
    required this.reportCopied,
    required this.offendingProduction,
    required this.leftSideLabel,
    required this.rightSideLabel,
    required this.productionFormatHelp,
    required this.addProduction,
    required this.removeProduction,
    required this.undo,
    required this.redo,
    required this.inputLabel,
    required this.inputFormatHelp,
    required this.maxExpandedLabel,
    required this.runSearch,
    required this.cancelSearch,
    required this.searching,
    required this.accepted,
    required this.exhausted,
    required this.boundedUnknown,
    required this.cancelled,
    required this.invalid,
    required this.invalidTokenVector,
    required this.witnessTitle,
    required this.noProductions,
    required this.diagnosticLabel,
  });

  final bool usesPortuguese;
  final String title;
  final String editorTitle;
  final String derivationTitle;
  final String classificationLabel;
  final String classifyGrammar;
  final String grammarStructureDisclaimer;
  final String regularOrientationLabel;
  final String normalFormsLabel;
  final String noNormalForms;
  final String copyStructuredReport;
  final String reportCopied;
  final String offendingProduction;
  final String leftSideLabel;
  final String rightSideLabel;
  final String productionFormatHelp;
  final String addProduction;
  final String removeProduction;
  final String undo;
  final String redo;
  final String inputLabel;
  final String inputFormatHelp;
  final String maxExpandedLabel;
  final String runSearch;
  final String cancelSearch;
  final String searching;
  final String accepted;
  final String exhausted;
  final String boundedUnknown;
  final String cancelled;
  final String invalid;
  final String invalidTokenVector;
  final String witnessTitle;
  final String noProductions;
  final String diagnosticLabel;

  String get editGrammar =>
      usesPortuguese ? 'Editar gramática' : 'Edit grammar';
  String get editProduction =>
      usesPortuguese ? 'Editar produção' : 'Edit production';
  String get saveProduction =>
      usesPortuguese ? 'Salvar produção' : 'Save production';
  String get cancelEdit => usesPortuguese ? 'Cancelar edição' : 'Cancel edit';
  // Mirrors the shared algorithmsAndExamples ARB values until this class
  // migrates to ARB-backed localization.
  String get algorithmsTitle =>
      usesPortuguese ? 'Algoritmos e Exemplos' : 'Algorithms & Examples';
  String get filesTitle => usesPortuguese ? 'Arquivos' : 'Files';
  String get informationTitle => usesPortuguese ? 'Informações' : 'Information';
  String get close => usesPortuguese ? 'Fechar' : 'Close';
  String get openDerivation =>
      usesPortuguese ? 'Abrir derivação' : 'Open derivation';
  String get openAlgorithms =>
      usesPortuguese ? 'Abrir algoritmos' : 'Open algorithms';
  String get openEditor => usesPortuguese ? 'Abrir editor' : 'Open editor';
  String get grammarNameLabel =>
      usesPortuguese ? 'Nome da gramática' : 'Grammar name';
  String get productionEvidenceLabel =>
      usesPortuguese ? 'Evidências de produção' : 'Production evidence';
  String get allPredicatesSatisfied => usesPortuguese
      ? 'todos os predicados testados foram satisfeitos'
      : 'all tested predicates satisfied';

  String violatesPredicates(String predicates) =>
      usesPortuguese ? 'viola $predicates' : 'violates $predicates';

  String get terminalsLabel => usesPortuguese ? 'Terminais' : 'Terminals';
  String get nonterminalsLabel =>
      usesPortuguese ? 'Não terminais' : 'Nonterminals';
  String get startSymbolLabel =>
      usesPortuguese ? 'Símbolo inicial' : 'Start symbol';
  String get symbolSetFormatHelp => usesPortuguese
      ? 'Use um vetor JSON de nomes de símbolos.'
      : 'Use a JSON array of symbol names.';
  String get saveGrammarDetails =>
      usesPortuguese ? 'Salvar detalhes' : 'Save details';

  static const portuguese = UnrestrictedGrammarWorkspaceStrings(
    usesPortuguese: true,
    title: 'Gramática irrestrita',
    editorTitle: 'Produções',
    derivationTitle: 'Derivação limitada',
    classificationLabel: 'Classificação',
    classifyGrammar: 'Classificar gramática',
    grammarStructureDisclaimer:
        'Este relatório classifica as produções escritas, não a classe mínima da linguagem gerada.',
    regularOrientationLabel: 'Orientação regular',
    normalFormsLabel: 'Formas normais',
    noNormalForms: 'Nenhuma comprovada',
    copyStructuredReport: 'Copiar relatório JSON',
    reportCopied: 'Relatório copiado',
    offendingProduction: 'Produção que viola uma restrição mais forte',
    leftSideLabel: 'Lado esquerdo',
    rightSideLabel: 'Lado direito',
    productionFormatHelp:
        'Use um vetor JSON com n: para não terminais e t: para terminais.',
    addProduction: 'Adicionar produção',
    removeProduction: 'Remover produção',
    undo: 'Desfazer',
    redo: 'Refazer',
    inputLabel: 'Palavra de entrada',
    inputFormatHelp: 'Use um vetor JSON de símbolos terminais.',
    maxExpandedLabel: 'Máximo de formas exploradas',
    runSearch: 'Buscar derivação',
    cancelSearch: 'Cancelar busca',
    searching: 'Buscando derivação…',
    accepted: 'Derivação encontrada',
    exhausted: 'Espaço finito esgotado sem derivação',
    boundedUnknown: 'Resultado inconclusivo: limite atingido',
    cancelled: 'Busca cancelada',
    invalid: 'Gramática ou entrada inválida',
    invalidTokenVector: 'Vetor de símbolos inválido',
    witnessTitle: 'Testemunho da derivação',
    noProductions: 'Nenhuma produção definida',
    diagnosticLabel: 'Diagnóstico',
  );

  static const english = UnrestrictedGrammarWorkspaceStrings(
    usesPortuguese: false,
    title: 'Unrestricted grammar',
    editorTitle: 'Productions',
    derivationTitle: 'Bounded derivation',
    classificationLabel: 'Classification',
    classifyGrammar: 'Classify grammar',
    grammarStructureDisclaimer:
        'This report classifies the written productions, not the minimal class of the generated language.',
    regularOrientationLabel: 'Regular orientation',
    normalFormsLabel: 'Normal forms',
    noNormalForms: 'None proven',
    copyStructuredReport: 'Copy JSON report',
    reportCopied: 'Report copied',
    offendingProduction: 'Production violating a stronger restriction',
    leftSideLabel: 'Left-hand side',
    rightSideLabel: 'Right-hand side',
    productionFormatHelp:
        'Use a JSON array with n: for nonterminals and t: for terminals.',
    addProduction: 'Add production',
    removeProduction: 'Remove production',
    undo: 'Undo',
    redo: 'Redo',
    inputLabel: 'Input word',
    inputFormatHelp: 'Use a JSON array of terminal symbols.',
    maxExpandedLabel: 'Maximum expanded forms',
    runSearch: 'Search for derivation',
    cancelSearch: 'Cancel search',
    searching: 'Searching for a derivation…',
    accepted: 'Derivation found',
    exhausted: 'Finite search space exhausted without a derivation',
    boundedUnknown: 'Inconclusive result: a bound was reached',
    cancelled: 'Search cancelled',
    invalid: 'Invalid grammar or input',
    invalidTokenVector: 'Invalid symbol vector',
    witnessTitle: 'Derivation witness',
    noProductions: 'No productions defined',
    diagnosticLabel: 'Diagnostic',
  );

  static UnrestrictedGrammarWorkspaceStrings forLocale(Locale locale) =>
      locale.languageCode.toLowerCase() == 'pt' ? portuguese : english;

  String classification(PhraseGrammarClassification value) => usesPortuguese
      ? switch (value) {
          PhraseGrammarClassification.regular => 'regular',
          PhraseGrammarClassification.contextFree => 'livre de contexto',
          PhraseGrammarClassification.contextSensitive =>
            'sensível ao contexto',
          PhraseGrammarClassification.unrestricted => 'irrestrita',
          PhraseGrammarClassification.invalid => 'inválida',
        }
      : switch (value) {
          PhraseGrammarClassification.regular => 'regular',
          PhraseGrammarClassification.contextFree => 'context-free',
          PhraseGrammarClassification.contextSensitive => 'context-sensitive',
          PhraseGrammarClassification.unrestricted => 'unrestricted',
          PhraseGrammarClassification.invalid => 'invalid',
        };

  String diagnostic(PhraseGrammarDiagnostic diagnostic) {
    final suffix = <String>[
      if (diagnostic.productionId != null) ' (${diagnostic.productionId})',
      if (diagnostic.symbol != null) ' [${diagnostic.symbol}]',
    ].join();
    if (!usesPortuguese) {
      return switch (diagnostic.code) {
        PhraseGrammarDiagnosticCode.emptyGrammar =>
          'The grammar has no productions$suffix.',
        PhraseGrammarDiagnosticCode.emptySymbol =>
          'A declared symbol is empty$suffix.',
        PhraseGrammarDiagnosticCode.overlappingSymbolIdentity =>
          'A symbol is declared as both terminal and nonterminal$suffix.',
        PhraseGrammarDiagnosticCode.undeclaredStartSymbol =>
          'The start symbol is not declared$suffix.',
        PhraseGrammarDiagnosticCode.emptyProductionId =>
          'A production ID is empty$suffix.',
        PhraseGrammarDiagnosticCode.duplicateProductionId =>
          'Production IDs must be unique$suffix.',
        PhraseGrammarDiagnosticCode.duplicateProduction =>
          'The production is duplicated$suffix.',
        PhraseGrammarDiagnosticCode.contextFreeLeftSide =>
          'The left-hand side must contain exactly one nonterminal$suffix.',
        PhraseGrammarDiagnosticCode.contextSensitiveContracting =>
          'The production contracts the sentential form$suffix.',
        PhraseGrammarDiagnosticCode.contextSensitiveEpsilonRestriction =>
          'Only the start symbol may produce the empty word$suffix.',
        PhraseGrammarDiagnosticCode.contextSensitiveStartOnRight =>
          'The start symbol occurs on a production right-hand side$suffix.',
        PhraseGrammarDiagnosticCode.leftSideMissingNonterminal =>
          'The left-hand side must contain a nonterminal$suffix.',
        PhraseGrammarDiagnosticCode.emptyLeftSide =>
          'The left-hand side cannot be empty$suffix.',
        PhraseGrammarDiagnosticCode.regularRightSide =>
          'The right-hand side is not regular$suffix.',
        PhraseGrammarDiagnosticCode.regularMixedOrientation =>
          'The grammar mixes left-linear and right-linear productions$suffix.',
        PhraseGrammarDiagnosticCode.undeclaredProductionSymbol =>
          'The production uses an undeclared symbol$suffix.',
        PhraseGrammarDiagnosticCode.declaredTypeMismatch =>
          'The declared grammar type does not match the inferred type$suffix.',
        PhraseGrammarDiagnosticCode.invalidInputSymbol =>
          'The input uses an undeclared terminal symbol.',
      };
    }
    return switch (diagnostic.code) {
      PhraseGrammarDiagnosticCode.emptyGrammar =>
        'A gramática não tem produções$suffix.',
      PhraseGrammarDiagnosticCode.emptySymbol =>
        'Um símbolo declarado está vazio$suffix.',
      PhraseGrammarDiagnosticCode.overlappingSymbolIdentity =>
        'Um símbolo foi declarado como terminal e não terminal$suffix.',
      PhraseGrammarDiagnosticCode.undeclaredStartSymbol =>
        'O símbolo inicial não foi declarado$suffix.',
      PhraseGrammarDiagnosticCode.emptyProductionId =>
        'O identificador de uma produção está vazio$suffix.',
      PhraseGrammarDiagnosticCode.duplicateProductionId =>
        'Os identificadores das produções devem ser únicos$suffix.',
      PhraseGrammarDiagnosticCode.duplicateProduction =>
        'A produção está duplicada$suffix.',
      PhraseGrammarDiagnosticCode.contextFreeLeftSide =>
        'O lado esquerdo deve conter exatamente um não terminal$suffix.',
      PhraseGrammarDiagnosticCode.contextSensitiveContracting =>
        'A produção contrai a forma sentencial$suffix.',
      PhraseGrammarDiagnosticCode.contextSensitiveEpsilonRestriction =>
        'Somente o símbolo inicial pode produzir vazio$suffix.',
      PhraseGrammarDiagnosticCode.contextSensitiveStartOnRight =>
        'O símbolo inicial aparece à direita de uma produção$suffix.',
      PhraseGrammarDiagnosticCode.leftSideMissingNonterminal =>
        'O lado esquerdo precisa conter um não terminal$suffix.',
      PhraseGrammarDiagnosticCode.emptyLeftSide =>
        'O lado esquerdo não pode ser vazio$suffix.',
      PhraseGrammarDiagnosticCode.regularRightSide =>
        'O lado direito não é regular$suffix.',
      PhraseGrammarDiagnosticCode.regularMixedOrientation =>
        'A gramática mistura produções lineares à esquerda e à direita$suffix.',
      PhraseGrammarDiagnosticCode.undeclaredProductionSymbol =>
        'A produção usa um símbolo não declarado$suffix.',
      PhraseGrammarDiagnosticCode.declaredTypeMismatch =>
        'O tipo declarado da gramática não corresponde ao tipo inferido$suffix.',
      PhraseGrammarDiagnosticCode.invalidInputSymbol =>
        'A entrada usa um símbolo terminal não declarado.',
    };
  }

  String orientation(PhraseGrammarRegularOrientation value) => usesPortuguese
      ? switch (value) {
          PhraseGrammarRegularOrientation.rightLinear => 'linear à direita',
          PhraseGrammarRegularOrientation.leftLinear => 'linear à esquerda',
          PhraseGrammarRegularOrientation.both => 'compatível com ambas',
          PhraseGrammarRegularOrientation.mixed => 'mistura não suportada',
          PhraseGrammarRegularOrientation.notRegular => 'não regular',
        }
      : switch (value) {
          PhraseGrammarRegularOrientation.rightLinear => 'right-linear',
          PhraseGrammarRegularOrientation.leftLinear => 'left-linear',
          PhraseGrammarRegularOrientation.both => 'compatible with both',
          PhraseGrammarRegularOrientation.mixed => 'unsupported mixture',
          PhraseGrammarRegularOrientation.notRegular => 'not regular',
        };

  String normalForm(PhraseGrammarNormalForm value) => switch (value) {
    PhraseGrammarNormalForm.strictChomsky =>
      usesPortuguese ? 'CNF estrita' : 'strict CNF',
    PhraseGrammarNormalForm.weakChomsky =>
      usesPortuguese ? 'CNF fraca' : 'weak CNF',
    PhraseGrammarNormalForm.greibach => 'GNF',
  };

  String predicate(PhraseGrammarPredicateCode value) => usesPortuguese
      ? switch (value) {
          PhraseGrammarPredicateCode.validPhraseRule =>
            'regra de estrutura de frase válida',
          PhraseGrammarPredicateCode.contextFreeLeftSide =>
            'lado esquerdo livre de contexto',
          PhraseGrammarPredicateCode.noncontractingRule =>
            'regra não contratora',
          PhraseGrammarPredicateCode.epsilonRestriction => 'restrição de ε',
          PhraseGrammarPredicateCode.rightLinearRule =>
            'regra linear à direita',
          PhraseGrammarPredicateCode.leftLinearRule =>
            'regra linear à esquerda',
          PhraseGrammarPredicateCode.strictChomskyRule => 'CNF estrita',
          PhraseGrammarPredicateCode.weakChomskyRule => 'CNF fraca',
          PhraseGrammarPredicateCode.greibachRule => 'GNF',
        }
      : switch (value) {
          PhraseGrammarPredicateCode.validPhraseRule => 'valid phrase rule',
          PhraseGrammarPredicateCode.contextFreeLeftSide =>
            'context-free left side',
          PhraseGrammarPredicateCode.noncontractingRule =>
            'non-contracting rule',
          PhraseGrammarPredicateCode.epsilonRestriction =>
            'epsilon restriction',
          PhraseGrammarPredicateCode.rightLinearRule => 'right-linear rule',
          PhraseGrammarPredicateCode.leftLinearRule => 'left-linear rule',
          PhraseGrammarPredicateCode.strictChomskyRule => 'strict CNF',
          PhraseGrammarPredicateCode.weakChomskyRule => 'weak CNF',
          PhraseGrammarPredicateCode.greibachRule => 'GNF',
        };

  String omittedWitnessSteps(int count) => usesPortuguese
      ? '$count etapas intermediárias omitidas'
      : '$count intermediate steps omitted';
}
