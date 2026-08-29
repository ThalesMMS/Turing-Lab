import '../core/automaton_fragments/automaton_fragments.dart';
import '../core/interoperability/codec_outcome.dart';
import '../core/automaton_fragments/automaton_fragment_combiner.dart';
import 'app_localizations.dart';

/// Localizes diagnostics that are assembled by the fragment combiner.
///
/// The combiner deliberately keeps its messages locale-neutral. This adapter
/// translates the presentation copy without adding UI concerns to the core
/// operation or changing the diagnostic codes used by callers.
extension AppLocalizationsAutomatonFragments on AppLocalizations {
  String localizedAutomatonFragmentDiagnostic(
    AutomatonFragmentDiagnostic diagnostic,
  ) {
    if (!_isPortuguese) return diagnostic.message;

    switch (diagnostic.code) {
      case AutomatonFragmentDiagnosticCode.emptyFragment:
        return 'O fragmento selecionado não possui estados.';
      case AutomatonFragmentDiagnosticCode.incompatibleDocumentType:
        return 'Somente documentos do mesmo modelo de grafo podem ser combinados.';
      case AutomatonFragmentDiagnosticCode.unsupportedOperation:
        return 'Operações algébricas e substituição de documentos usam fluxos próprios.';
      case AutomatonFragmentDiagnosticCode.danglingTransition:
        final transitionId = diagnostic.transitionId;
        return transitionId == null
            ? 'O fragmento selecionado contém uma transição pendente.'
            : 'A transição $transitionId tem um ponto final fora do fragmento selecionado.';
      case AutomatonFragmentDiagnosticCode.initialStateConflict:
        return 'Os dois fragmentos declaram um estado inicial. Escolha qual estado inicial manter.';
      case AutomatonFragmentDiagnosticCode.pdaAcceptanceModeConflict:
        return diagnostic.normalized == true
            ? 'A aceitação do AP importado foi normalizada explicitamente para o modo do destino.'
            : 'Os modos de aceitação dos APs são diferentes e exigem um plano de conversão explícito.';
      case AutomatonFragmentDiagnosticCode.pdaInitialStackSymbolConflict:
        return diagnostic.normalized == true
            ? 'A inicialização da pilha do AP importado foi normalizada explicitamente para o símbolo do destino.'
            : 'Os símbolos iniciais da pilha dos APs são diferentes e exigem um plano de conversão explícito.';
      case AutomatonFragmentDiagnosticCode.tmTapeCountConflict:
        return 'Máquinas de Turing com quantidades diferentes de fitas não podem ser combinadas sem uma conversão explícita.';
      case AutomatonFragmentDiagnosticCode.tmBlankSymbolConflict:
        return 'Máquinas de Turing com símbolos brancos diferentes não podem ser combinadas sem uma conversão explícita.';
      case AutomatonFragmentDiagnosticCode.connectorUnsupported:
        return switch (diagnostic.connectorKind) {
          AutomatonFragmentKind.pda =>
            'As transições de conector do AP exigem um plano tipado de operações de pilha.',
          AutomatonFragmentKind.tm =>
            'As transições de conector da MT exigem um vetor de operações por fita.',
          AutomatonFragmentKind.mealy =>
            'Os conectores Mealy exigem uma regra explícita de entrada e saída.',
          AutomatonFragmentKind.moore =>
            'Os conectores Moore exigem uma regra explícita de entrada.',
          _ => 'O conector não é compatível com este modelo de grafo.',
        };
      case AutomatonFragmentDiagnosticCode.connectorEndpointMissing:
        return 'O conector deve referenciar um estado de destino e um estado importado.';
      case AutomatonFragmentDiagnosticCode.annotationLimit:
        return 'O documento combinado excederia o limite de anotações.';
      case AutomatonFragmentDiagnosticCode.configurationNormalized:
        return diagnostic.message;
    }
  }

  /// Localizes import diagnostics shown above the fragment review controls.
  ///
  /// Codec diagnostics are identified by stable codes. Unknown codes retain
  /// their original detail until a corresponding translation is added.
  String localizedAutomatonFragmentCodecDiagnostic(CodecDiagnostic diagnostic) {
    if (!_isPortuguese) return diagnostic.message;

    if (diagnostic.code == 'jflap.note-presentation-dropped') {
      final unsupported = diagnostic.sourceValue;
      if (unsupported is List && unsupported.isNotEmpty) {
        return 'O JFLAP não pode armazenar esta nota: '
            '${unsupported.join(', ')}.';
      }
      return 'O JFLAP não pode armazenar a apresentação desta nota.';
    }

    final translation = switch (diagnostic.code) {
      'jflap.canonical-order' ||
      'jflap.pda.canonical-order' ||
      'jflap.mealy.canonical-order' =>
        'A ordem de estados e transições foi padronizada.',
      'jflap.tm.canonical-order' =>
        'A ordem de estados e transições da MT foi padronizada.',
      'jflap.explicit-epsilon-alias-interpreted' =>
        'Um alias explícito de ε foi interpretado como leitura vazia.',
      'jflap.pda-stale-token-extension' =>
        'Uma extensão de tokens desatualizada foi ignorada porque o texto de push do JFLAP mudou.',
      'jflap.pda-pop-word-treated-as-atomic-token' =>
        'O JFLAP lê este texto como uma sequência de caracteres; o Turing Lab importou-o como um único token de pilha.',
      'jflap.pda-acceptance-mode-assumed-final-state' =>
        'O modo de aceitação do AP foi assumido como estado final.',
      'jflap.multi-symbol-transition-expanded' =>
        'Uma transição com vários símbolos foi expandida em transições individuais.',
      'jflap.state-type-dropped' =>
        'O JFLAP não pode armazenar o tipo de estado do Turing Lab.',
      'jflap.state-properties-dropped' =>
        'O JFLAP não pode armazenar as propriedades de estado do Turing Lab.',
      'jflap.transition-control-point-dropped' =>
        'O JFLAP não pode armazenar pontos de controle de transições.',
      'jflap.transition-display-label-dropped' =>
        'O JFLAP não pode armazenar um rótulo separado para a transição.',
      'jflap.explicit-epsilon-alias-exported-empty' =>
        'Aliases explícitos de ε foram exportados como leituras vazias.',
      'jflap.unknown-optional-element' =>
        'Dados XML opcionais desconhecidos foram preservados.',
      'jflap.unknown-optional-attribute' =>
        'Atributos XML opcionais desconhecidos foram preservados.',
      'jflap.pda-turing-lab-extension-portability' =>
        'Abrir e salvar no JFLAP descarta tokens, identidades e configurações de pilha e aceitação do Turing Lab.',
      'jflap.pda-initial-stack-symbol-not-portable' =>
        'A simulação do JFLAP inicializa a pilha do AP com Z.',
      'jflap.pda-acceptance-mode-not-portable' =>
        'O JFLAP solicita o modo de aceitação no início da simulação, em vez de armazená-lo no documento.',
      'jflap.pda-atomic-pop-token-not-portable' =>
        'O JFLAP lerá o texto serializado como uma sequência de caracteres, e não como um único token.',
      'jflap.pda-atomic-push-token-not-portable' =>
        'O JFLAP dividirá pelo menos um token de push serializado em caracteres.',
      'jflap.tm-turing-lab-extension-portability' =>
        'O JFLAP descarta extensões do Turing Lab ao abrir e salvar a máquina.',
      'jflap.tm.building-blocks' =>
        'Os blocos de construção da MT foram exportados sem achatamento.',
      'jflap.tm.shared-tapes' =>
        'Máquinas aninhadas compartilham fitas e posições dos cabeçotes.',
      'jflap.tm-transition-identities-reconstructed' =>
        'Identidades ausentes das transições da MT foram reconstruídas.',
      'jflap.mealy.machine-identity-not-portable' =>
        'O JFLAP não armazena o ID nem a revisão nativos da máquina.',
      'jflap.mealy.transition-identities-not-portable' =>
        'O JFLAP não armazena IDs nativos de transições.',
      'jflap.mealy.unused-alphabet-symbols-dropped' =>
        'Símbolos de alfabeto não utilizados foram descartados.',
      'jflap.mealy.output-token-boundaries-dropped' =>
        'As fronteiras dos tokens de saída foram descartadas.',
      'jflap.mealy.transition-ids-derived' =>
        'IDs das transições Mealy foram derivados do conteúdo da transição.',
      'jflap.moore.output-token-vector-restored' =>
        'As fronteiras dos tokens de saída Moore foram restauradas.',
      'jflap.moore.conflicting-transition-output-preserved' =>
        'Uma saída redundante de transição divergia da saída do estado de destino.',
      'jflap.moore.conflicting-transition-output-normalized' =>
        'Uma saída de transição conflitante foi normalizada para a saída do estado de destino.',
      'jflap.moore.output-token-vector-preserved' =>
        'As fronteiras dos tokens de saída Moore foram preservadas.',
      'jflap.note-invalid-position-preserved' =>
        'Uma nota com posição inválida foi preservada como XML bruto.',
      'jflap.notes-normalized' =>
        'As notas do JFLAP foram importadas com o estilo padrão do Turing Lab.',
      'jflap.unknown-grammar-type-preserved' =>
        'Um tipo de gramática desconhecido foi preservado para reexportação.',
      'jflap.grammar-tokenization-normalized' =>
        'O texto da gramática do JFLAP foi normalizado para vetores de tokens.',
      'jflap.grammar-token-boundaries-lossy' =>
        'O XML do JFLAP não pode preservar fronteiras de tokens com vários caracteres.',
      'jflap.grammar-classification-lossy' =>
        'O XML do JFLAP não armazena a classificação explícita da gramática.',
      'jflap.l-system.advanced-variant-preserved' =>
        'Produções avançadas não suportadas foram preservadas e desativadas.',
      'jflap.l-system.parameters-preserved' =>
        'Parâmetros de desenho desconhecidos do JFLAP foram preservados.',
      'jflap.l-system.execution-extension-restored' =>
        'Metadados de reescrita do Turing Lab foram restaurados dos parâmetros XML.',
      'jflap.l-system.elements-preserved' =>
        'Elementos XML desconhecidos do JFLAP foram preservados como extensões.',
      'jflap.l-system.execution-extension' =>
        'Semente, símbolos de contexto ignorados e escolhas ponderadas usam parâmetros XML do Turing Lab.',
      'jflap.l-system.advanced-variant-extension' =>
        'Variantes avançadas não suportadas foram preservadas em uma extensão do Turing Lab.',
      'jflap.pumping-lemma.character-tokenization' =>
        'Os deslocamentos de texto do JFLAP foram normalizados para índices de tokens explícitos.',
      'jflap.pumping-lemma.local-extension' =>
        'Tokens, problema, progresso e histórico locais exigem uma extensão XML do Turing Lab.',
      'jflap.regex-dialect-normalized' =>
        'A sintaxe de união e ε do JFLAP foi normalizada para o dialeto do Turing Lab.',
      'jflap.regex-empty-set-interoperability' =>
        'O símbolo ø gerado pelo JFLAP foi interpretado como linguagem vazia; a conversão do JFLAP 7.1 trata esse símbolo de forma inconsistente.',
      'jflap.regex-turing-lab-extension-portability' =>
        'O JFLAP preserva a linguagem da expressão, mas descarta identidade, alfabeto, tokenização e extensões desconhecidas do Turing Lab ao abrir e salvar.',
      'jflap.tm-incomplete-turing-lab-extension' =>
        'Metadados ausentes da MT do Turing Lab, incluindo eventual política de aceitação, foram reconstruídos.',
      'jflap.tm-building-block-unknown-extension-dropped' =>
        'Extensões XML opcionais desconhecidas dentro do projeto de blocos de construção não foram retidas.',
      'jflap.tm.extension-identities' =>
        'Revisões estáveis de blocos e IDs de invocação usam atributos XML ignorados.',
      'jflap.unrestricted-tokenization-inferred' =>
        'O texto do JFLAP foi normalizado para vetores de tokens escalares Unicode.',
      'jflap.unrestricted-turing-lab-extension-portability' =>
        'O JFLAP descarta extensões de tokens, IDs e metadados do Turing Lab ao abrir e salvar.',
      'json.document-schema-migrated' =>
        'O payload do documento foi migrado para um esquema mais recente.',
      'json.legacy-envelope-migrated' =>
        'O JSON sem versão foi migrado para o envelope v1.',
      'json.source-metadata-normalized' =>
        'Os metadados de origem foram atualizados para o documento exportado.',
      'json.tm-endpoints-migrated-to-ids' =>
        'Os estados dos pontos finais das transições foram resolvidos pelo mapa canônico de estados.',
      'json.tm-operation-vectors-migrated' =>
        'Operações escalares ou parciais das fitas foram expandidas para vetores completos.',
      'json.tm-variant-inferred' =>
        'A variante da MT foi inferida a partir de sua estrutura semântica.',
      'json.unknown-field-preserved' =>
        'Um campo desconhecido do JSON foi preservado.',
      'json.unknown-field-sidecar-normalized' =>
        'Campos JSON desconhecidos foram emitidos no conjunto de extensões.',
      _ => null,
    };
    return translation ?? diagnostic.message;
  }

  bool get _isPortuguese => localeName.toLowerCase().startsWith('pt');
}
