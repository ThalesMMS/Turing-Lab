// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get selectTransition => 'Selecione a transição';

  @override
  String get createNewTransition => 'Criar nova transição';

  @override
  String canvasViewportStateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estados',
      one: '1 estado',
      zero: '0 estados',
    );
    return '$_temp0';
  }

  @override
  String canvasViewportTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transições',
      one: '1 transição',
      zero: '0 transições',
    );
    return '$_temp0';
  }

  @override
  String get workspaceStatusNoAutomaton => 'Nenhum autômato definido';

  @override
  String get workspaceStatusMissingInitialState => 'Estado inicial ausente';

  @override
  String get workspaceStatusNoAcceptingStates => 'Sem estados de aceitação';

  @override
  String get workspaceStatusNondeterministic =>
      'Transições não determinísticas';

  @override
  String get workspaceStatusLambdaTransitions => 'Transições λ presentes';

  @override
  String workspaceStatusCounts(String states, String transitions) {
    return '$states · $transitions';
  }

  @override
  String workspaceStatusWithWarnings(String warnings, String counts) {
    return '⚠ $warnings · $counts';
  }

  @override
  String get workspaceHelpUnavailable =>
      'O conteúdo de ajuda não está disponível no momento.';

  @override
  String collapseCanvasPanel(String label) {
    return 'Recolher painel $label';
  }

  @override
  String expandCanvasPanel(String label) {
    return 'Expandir painel $label';
  }

  @override
  String canvasViewportSemantics(String states, String transitions) {
    return 'Área de visualização do canvas de autômato. $states, $transitions.';
  }

  @override
  String canvasStateSemantics(String name) {
    return 'Estado $name.';
  }

  @override
  String get canvasInitialStateSemantics => 'Estado inicial.';

  @override
  String get canvasAcceptingStateSemantics => 'Estado de aceitação.';

  @override
  String canvasOutgoingTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transições de saída.',
      one: '1 transição de saída.',
      zero: '0 transições de saída.',
    );
    return '$_temp0';
  }

  @override
  String canvasIncomingTransitionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transições de entrada.',
      one: '1 transição de entrada.',
      zero: '0 transições de entrada.',
    );
    return '$_temp0';
  }

  @override
  String get canvasUnlabeledTransition => 'sem rótulo';

  @override
  String get canvasSelectedTransitionSemantics => 'Transição selecionada.';

  @override
  String canvasTransitionSemantics(
      String id, String from, String to, String label) {
    return 'Transição $id de $from para $to com rótulo $label.';
  }

  @override
  String get canvasViewportEditHint =>
      'Use atalhos de teclado ou os controles da barra de ferramentas para editar o canvas.';

  @override
  String get canvasStateEditHint =>
      'Ative para editar os detalhes do estado. Arraste para mover no modo de seleção.';

  @override
  String get canvasStateReadOnlyHint => 'Estado somente leitura.';

  @override
  String get canvasAddTransitionPrompt => 'Adicionar transição...';

  @override
  String get canvasChooseTargetState => 'Escolha o estado de destino';

  @override
  String get dismissTransitionEditor => 'Fechar editor de transição';

  @override
  String get stateLabel => 'Rótulo do estado';

  @override
  String get initialState => 'Estado inicial';

  @override
  String get acceptingState => 'Estado de aceitação';

  @override
  String get deleteState => 'Excluir estado';

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get close => 'Fechar';

  @override
  String canvasActionSemantics(String action) {
    return 'Ação do canvas: $action';
  }

  @override
  String get canvasSelectAction => 'Selecionar';

  @override
  String get canvasAddStateAction => 'Adicionar estado';

  @override
  String get canvasAddTransitionAction => 'Adicionar transição';

  @override
  String get canvasUndoAction => 'Desfazer';

  @override
  String get canvasRedoAction => 'Refazer';

  @override
  String get canvasZoomOutAction => 'Diminuir zoom';

  @override
  String get canvasZoomInAction => 'Aumentar zoom';

  @override
  String get canvasFitToContentAction => 'Ajustar ao conteúdo';

  @override
  String get canvasResetViewAction => 'Redefinir visualização';

  @override
  String get canvasClearAction => 'Limpar canvas';

  @override
  String get canvasHelpAction => 'Ajuda';

  @override
  String get canvasHelpShortcutsAction => 'Ajuda e atalhos';

  @override
  String get canvasExpandToolbarAction => 'Expandir barra de ferramentas';

  @override
  String get canvasCollapseToolbarAction => 'Recolher barra de ferramentas';

  @override
  String get canvasMoreActions => 'Mais ações do canvas';

  @override
  String canvasZoomLevel(int percent) {
    return 'Zoom $percent%';
  }

  @override
  String get canvasSelectHint =>
      'Ativa o modo de seleção para mover e editar estados.';

  @override
  String get canvasAddStateHint =>
      'Adiciona um estado no centro da área visível e mantém o modo Adicionar estado ativo.';

  @override
  String get canvasAddTransitionHint =>
      'Ativa o modo de transição para conectar dois estados.';

  @override
  String get canvasUndoHint => 'Desfaz a alteração mais recente no canvas.';

  @override
  String get canvasRedoHint =>
      'Refaz a alteração desfeita mais recentemente no canvas.';

  @override
  String get canvasZoomOutHint => 'Diminui o nível de zoom do canvas.';

  @override
  String get canvasZoomInHint => 'Aumenta o nível de zoom do canvas.';

  @override
  String get canvasFitToContentHint =>
      'Ajusta o zoom e a posição para mostrar o autômato inteiro.';

  @override
  String get canvasResetViewHint => 'Redefine o zoom e a posição do canvas.';

  @override
  String get canvasClearHint =>
      'Remove todos os estados e transições do canvas.';

  @override
  String get canvasHelpShortcutsHint =>
      'Abre a ajuda do canvas e as informações sobre atalhos de teclado.';

  @override
  String get canvasExpandToolbarHint =>
      'Mostra ações de histórico, visualização, limpeza e ajuda.';

  @override
  String get canvasCollapseToolbarHint =>
      'Oculta as ações secundárias do canvas.';

  @override
  String get canvasMoreActionsHint =>
      'Abre o menu de ações secundárias do canvas.';

  @override
  String get pdaInputSymbol => 'Símbolo de entrada';

  @override
  String get pdaLambdaInput => 'λ-entrada';

  @override
  String get pdaInputSymbolRequired => 'Insira um símbolo ou ative λ-entrada';

  @override
  String get pdaPopSymbol => 'Símbolo para desempilhar';

  @override
  String get pdaLambdaPop => 'λ-desempilhar';

  @override
  String get pdaPopSymbolRequired => 'Insira um símbolo ou ative λ-desempilhar';

  @override
  String get pdaPushSymbol => 'Símbolo para empilhar';

  @override
  String get pdaLambdaPush => 'λ-empilhar';

  @override
  String get pdaPushSymbolRequired => 'Insira um símbolo ou ative λ-empilhar';

  @override
  String get tmReadSymbol => 'Símbolo lido';

  @override
  String get tmReadSymbolRequired => 'Insira um símbolo de leitura';

  @override
  String get tmWriteSymbol => 'Símbolo escrito';

  @override
  String get tmWriteSymbolRequired => 'Insira um símbolo de escrita';

  @override
  String get tmDirection => 'Direção';

  @override
  String get transitionEditorCancel => 'Cancelar';

  @override
  String get transitionEditorDelete => 'Excluir';

  @override
  String get transitionEditorSave => 'Salvar';

  @override
  String get transitionLabel => 'Rótulo';

  @override
  String get transitionEditLabelSemantics => 'Editar rótulo da transição';

  @override
  String get contextAwareHelp => 'Ajuda contextual';

  @override
  String get algorithms => 'Algoritmos';

  @override
  String get settingsPageTitle => 'Configurações';

  @override
  String get settingsSaveTooltip => 'Salvar configurações';

  @override
  String get settingsResetTooltip => 'Restaurar padrões';

  @override
  String get settingsLoadError =>
      'Não foi possível carregar as configurações. Tente novamente.';

  @override
  String get settingsSaveSuccess => 'Configurações salvas.';

  @override
  String get settingsSaveError =>
      'Não foi possível salvar as configurações. Tente novamente.';

  @override
  String get settingsApplyError =>
      'As configurações foram salvas, mas não puderam ser aplicadas. Reinicie o Turing Lab para atualizá-las.';

  @override
  String get settingsResetSuccess =>
      'Configurações restauradas para os padrões.';

  @override
  String get settingsSectionSymbols => 'Símbolos';

  @override
  String get settingsSectionTheme => 'Tema';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionCanvas => 'Canvas';

  @override
  String get settingsSectionGeneral => 'Geral';

  @override
  String get settingsSectionActions => 'Ações';

  @override
  String get settingsEmptyStringTitle => 'Símbolo da cadeia vazia';

  @override
  String get settingsEmptyStringDescription =>
      'Símbolo usado para representar a cadeia vazia (λ ou ε)';

  @override
  String get settingsLambdaOption => 'λ (Lambda)';

  @override
  String get settingsEpsilonOption => 'ε (Epsilon)';

  @override
  String get settingsThemeModeTitle => 'Modo do tema';

  @override
  String get settingsThemeModeDescription =>
      'Escolha o tema de sua preferência';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Escuro';

  @override
  String get settingsLanguageTitle => 'Idioma do aplicativo';

  @override
  String get settingsLanguageDescription =>
      'Escolha o idioma usado pelo Turing Lab';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguagePortuguese => 'Português';

  @override
  String get settingsShowGridTitle => 'Mostrar grade';

  @override
  String get settingsShowGridDescription => 'Exibir linhas de grade no canvas';

  @override
  String get settingsShowCoordinatesTitle => 'Mostrar coordenadas';

  @override
  String get settingsShowCoordinatesDescription =>
      'Exibir informações de coordenadas';

  @override
  String get settingsGridSizeTitle => 'Tamanho da grade';

  @override
  String get settingsGridSizeDescription => 'Tamanho das células da grade';

  @override
  String get settingsNodeSizeTitle => 'Tamanho dos estados';

  @override
  String get settingsNodeSizeDescription => 'Tamanho dos estados do autômato';

  @override
  String get settingsFontSizeTitle => 'Tamanho da fonte';

  @override
  String get settingsFontSizeDescription => 'Tamanho do texto na interface';

  @override
  String get settingsAutoSaveTitle => 'Salvamento automático';

  @override
  String get settingsAutoSaveDescription => 'Salvar alterações automaticamente';

  @override
  String get settingsShowTooltipsTitle => 'Mostrar dicas';

  @override
  String get settingsShowTooltipsDescription => 'Exibir dicas de ajuda';

  @override
  String get homeHelpTooltip => 'Ajuda';

  @override
  String get homeSettingsTooltip => 'Configurações';

  @override
  String get homeNavigationFsaLabel => 'AF';

  @override
  String get homeNavigationFsaDescription => 'Autômatos finitos';

  @override
  String get homeNavigationGrammarLabel => 'Gramática';

  @override
  String get homeNavigationGrammarDescription =>
      'Gramáticas livres de contexto';

  @override
  String get homeNavigationPdaLabel => 'AP';

  @override
  String get homeNavigationPdaDescription => 'Autômatos com pilha';

  @override
  String get homeNavigationTmLabel => 'MT';

  @override
  String get homeNavigationTmDescription => 'Máquinas de Turing';

  @override
  String get homeNavigationRegexLabel => 'Regex';

  @override
  String get homeNavigationRegexDescription => 'Expressões regulares';

  @override
  String get homeNavigationPumpingLabel => 'Bombeamento';

  @override
  String get homeNavigationPumpingDescription => 'Lema do bombeamento';

  @override
  String get helpPageTitle => 'Ajuda e documentação';

  @override
  String get helpSearchTooltip => 'Pesquisar ajuda';

  @override
  String get helpQuickStartTitle => 'Guia rápido';

  @override
  String get helpQuickStartBody =>
      'Bem-vindo ao Turing Lab. Comece com este fluxo básico:\n\n1. Escolha um espaço de trabalho, como AF, Gramática, AP, MT ou Regex.\n2. Inicie em branco ou abra um exemplo ou arquivo compatível.\n3. Use o editor para criar sua máquina ou gramática. Toque duas vezes em um estado para ações rápidas.\n4. Execute simulações para testar seu trabalho.\n5. Use os algoritmos para transformar estruturas.\n\nDicas:\n• Use as abas de navegação ou chips de seção para trocar de espaço rapidamente.\n• Toque duas vezes em um estado para abrir o menu de ações rápidas.\n• Faça pinça para ampliar ou reduzir o canvas.\n• Toque no ícone de guia rápido quando precisar relembrar o fluxo.';

  @override
  String get helpGotIt => 'Entendi!';

  @override
  String get helpSearchFieldLabel => 'Pesquisar ajuda...';

  @override
  String get helpSearchClear => 'Limpar pesquisa';

  @override
  String get helpSearchClose => 'Fechar pesquisa';

  @override
  String get helpSearchTitle => 'Pesquisar ajuda';

  @override
  String get helpSearchSubtitle =>
      'Encontre tutoriais, atalhos e explicações de teoria';

  @override
  String get helpSearchNoResults => 'Nenhum resultado encontrado';

  @override
  String get helpSearchNoResultsDescription =>
      'Tente outras palavras-chave ou confira a ortografia';

  @override
  String get helpSectionGettingStarted => 'Primeiros passos';

  @override
  String get helpSectionFsa => 'AF';

  @override
  String get helpSectionGrammar => 'Gramática';

  @override
  String get helpSectionPda => 'AP';

  @override
  String get helpSectionTm => 'Máquina de Turing';

  @override
  String get helpSectionRegex => 'Expressão regular';

  @override
  String get helpSectionPumping => 'Lema do bombeamento';

  @override
  String get helpSectionFileOperations => 'Operações de arquivo';

  @override
  String get helpSectionTroubleshooting => 'Solução de problemas';

  @override
  String get helpSectionAbout => 'Sobre';

  @override
  String get regularExpressionTitle => 'Expressão regular';

  @override
  String get regularExpressionLabel => 'Expressão regular:';

  @override
  String get regularExpressionHint => 'Digite a expressão regular (ex.: a*b+)';

  @override
  String get validateRegex => 'Validar regex';

  @override
  String get enterRegexToValidate =>
      'Digite uma expressão regular para validar.';

  @override
  String get validRegex => 'Regex válida';

  @override
  String get invalidRegex => 'Regex inválida';

  @override
  String get testStringLabel => 'Cadeia de teste:';

  @override
  String get testStringHint => 'Digite a cadeia para testar';

  @override
  String get testStringTooltip => 'Testar cadeia';

  @override
  String get matches => 'Aceita!';

  @override
  String get doesNotMatch => 'Não aceita';

  @override
  String get convertToAutomaton => 'Converter para autômato:';

  @override
  String get convertToNfa => 'Converter para AFN';

  @override
  String get convertToDfa => 'Converter para AFD';

  @override
  String get simplifyOutput => 'Simplificar saída';

  @override
  String get simplifyOutputSubtitle =>
      'Aplicar simplificações algébricas aos autômatos convertidos';

  @override
  String get compareRegularExpressions => 'Comparar expressões regulares:';

  @override
  String get comparisonRegexHint => 'Digite a segunda expressão regular';

  @override
  String get compareEquivalence => 'Comparar equivalência';

  @override
  String get regexHelp => 'Ajuda de regex';

  @override
  String get regexHelpPatterns =>
      'Padrões comuns:\n• a* - zero ou mais a\n• a+ - um ou mais a\n• a? - zero ou um a\n• a|b - a ou b\n• (ab)* - zero ou mais ab\n• [abc] - qualquer um entre a, b ou c';

  @override
  String get convertedRegexSimplified => 'Regex convertida (simplificada)';

  @override
  String get convertedRegexRaw => 'Regex convertida (bruta)';

  @override
  String get regexCopiedToClipboard =>
      'Regex copiada para a área de transferência';

  @override
  String get copyToClipboard => 'Copiar para a área de transferência';

  @override
  String get toggleOffRawOutput => 'Desative para ver a saída bruta';

  @override
  String get toggleOnSimplifiedOutput => 'Ative para ver a saída simplificada';

  @override
  String get enterValidRegexFirst =>
      'Digite primeiro uma expressão regular válida';

  @override
  String get failedConvertRegexToNfa => 'Falha ao converter regex para AFN';

  @override
  String get convertedRegexToNfa =>
      'Regex convertida para AFN. Veja no espaço de trabalho de AFD/AFN.';

  @override
  String get failedConvertNfaToDfa => 'Falha ao converter AFN para AFD';

  @override
  String get convertedRegexToDfa =>
      'Regex convertida para AFD. Abrindo o AFD no espaço de trabalho.';

  @override
  String get failedSimplifyRegex => 'Falha ao simplificar regex';

  @override
  String get failedAnalyzeRegex => 'Falha ao analisar regex';

  @override
  String get failedGenerateSampleStrings => 'Falha ao gerar cadeias de exemplo';

  @override
  String get simplificationSteps => 'Passos de simplificação';

  @override
  String get hideSteps => 'Ocultar passos';

  @override
  String get showSteps => 'Mostrar passos';

  @override
  String get simplifyWithSteps => 'Simplificar com passos';

  @override
  String get clear => 'Limpar';

  @override
  String get resimplify => 'Simplificar novamente';

  @override
  String get originalLabel => 'Original:';

  @override
  String get rulesAppliedLabel => 'regra(s) aplicada(s)';

  @override
  String get simplifiedLabel => 'Simplificada:';

  @override
  String get simplifiedRegexCopiedToClipboard =>
      'Regex simplificada copiada para a área de transferência';

  @override
  String get copySimplifiedRegex => 'Copiar regex simplificada';

  @override
  String get saved => 'Economia';

  @override
  String get charactersAbbreviation => 'caracteres';

  @override
  String get reduction => 'Redução';

  @override
  String get time => 'Tempo';

  @override
  String get stepLabel => 'Passo';

  @override
  String get ofLabel => 'de';

  @override
  String get previousStep => 'Passo anterior';

  @override
  String get nextStep => 'Próximo passo';

  @override
  String get allSteps => 'Todos os passos:';

  @override
  String get transformation => 'Transformação';

  @override
  String get before => 'Antes';

  @override
  String get after => 'Depois';

  @override
  String get rule => 'Regra';

  @override
  String get starHeight => 'Altura de estrela';

  @override
  String get nestingDepth => 'Profundidade de aninhamento';

  @override
  String get operators => 'Operadores';

  @override
  String get conversionComparisonUnavailable =>
      'Comparação de conversão indisponível. Os snapshots salvos não puderam ser lidos.';

  @override
  String get conversionComparisonResult => 'Resultado da conversão';

  @override
  String get simulation => 'Simulação';

  @override
  String get viewOnCanvas => 'Visualizar no Canvas';

  @override
  String get inputString => 'Cadeia de entrada';

  @override
  String get simulationInputHint =>
      'Deixe em branco para ε; os espaços são preservados';

  @override
  String get simulationInputString => 'Cadeia de entrada da simulação';

  @override
  String get simulate => 'Simular';

  @override
  String get simulating => 'Simulando...';

  @override
  String get cancelSimulation => 'Cancelar simulação';

  @override
  String get runSimulation => 'Executar simulação';

  @override
  String get runSimulationHint =>
      'Executa a máquina usando a cadeia de entrada informada.';

  @override
  String simulationInputSemantics(String label) {
    return 'Entrada da simulação: $label';
  }

  @override
  String simulationEditHint(String hint) {
    return '$hint. Toque duas vezes para editar.';
  }

  @override
  String get simulationResult => 'Resultado da simulação';

  @override
  String get regexResult => 'Resultado da expressão regular';

  @override
  String get regularExpression => 'Expressão regular';

  @override
  String get stepByStepMode => 'Modo passo a passo';

  @override
  String get stepByStepModeSemantics => 'Modo passo a passo';

  @override
  String get stepByStepExecution => 'Execução passo a passo';

  @override
  String get play => 'Reproduzir';

  @override
  String get pause => 'Pausar';

  @override
  String get reset => 'Reiniciar';

  @override
  String get expand => 'Expandir';

  @override
  String get collapse => 'Recolher';

  @override
  String get noStepsRecorded => 'Nenhum passo registrado';

  @override
  String get noStepsAvailable => 'Nenhum passo disponível';

  @override
  String get noSteps => 'Sem passos';

  @override
  String get timeline => 'Linha do tempo';

  @override
  String get timelineScrubber => 'Controle da linha do tempo';

  @override
  String get timelineNavigationHint =>
      'Arraste para navegar pelos passos da simulação';

  @override
  String stepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String activeStepOf(int current, int total) {
    return 'Passo ativo $current de $total';
  }

  @override
  String pdaTrace(int count) {
    return 'Traço do AP ($count passos)';
  }

  @override
  String tmTrace(int count) {
    return 'Traço da MT ($count passos)';
  }

  @override
  String get traceRemaining => 'restante';

  @override
  String get traceStack => 'pilha';

  @override
  String get traceTape => 'fita';

  @override
  String get pdaStackPanelLabel => 'Pilha';

  @override
  String get timeout => 'Tempo limite excedido';

  @override
  String get infiniteLoop => 'Laço infinito';

  @override
  String get steps => 'Passos';

  @override
  String get states => 'Estados';

  @override
  String get executionPath => 'Caminho da execução';

  @override
  String get transitions => 'Transições';

  @override
  String get animationSpeed => 'Velocidade da animação';

  @override
  String get selectPlaybackSpeed => 'Selecione a velocidade de reprodução';

  @override
  String get speed => 'Velocidade:';

  @override
  String slowSpeed(String speed) {
    return 'Lenta $speed';
  }

  @override
  String get normalSpeed => 'Velocidade normal';

  @override
  String fastSpeed(String speed) {
    return 'Rápida $speed';
  }

  @override
  String get on => 'Ativado';

  @override
  String get off => 'Desativado';

  @override
  String get stepByStepToggleHint =>
      'Ativa ou desativa a revisão manual da simulação atual.';

  @override
  String simulationStartDescription(String state, String input) {
    return 'Comece em $state com a entrada $input.';
  }

  @override
  String simulationFinalDescription(String state, String verdict) {
    return 'Configuração final $state – entrada $verdict.';
  }

  @override
  String simulationReadDescription(
      String consumed, String state, String nextState, String remaining) {
    return 'Leia \"$consumed\" de $state → $nextState com $remaining.';
  }

  @override
  String get noInputRemaining => 'nenhuma entrada restante';

  @override
  String remainingQuoted(String input) {
    return 'restante \"$input\"';
  }

  @override
  String consumedValue(String value) {
    return 'Consumido: \"$value\"';
  }

  @override
  String nextStateValue(String state) {
    return 'Próximo estado: $state';
  }

  @override
  String remainingInputValue(String input) {
    return 'Entrada restante: $input';
  }

  @override
  String get previousSimulationStep => 'Passo anterior da simulação';

  @override
  String get previousSimulationStepHint =>
      'Move para o passo anterior registrado.';

  @override
  String get nextSimulationStep => 'Próximo passo da simulação';

  @override
  String get nextSimulationStepHint =>
      'Avança para o próximo passo registrado.';

  @override
  String get playSimulationSteps => 'Reproduzir passos da simulação';

  @override
  String get pauseSimulationPlayback => 'Pausar reprodução da simulação';

  @override
  String get playSimulationHint =>
      'Avança automaticamente pelos passos registrados.';

  @override
  String get pauseSimulationHint => 'Pausa a reprodução automática dos passos.';

  @override
  String get resetSimulationSteps => 'Reiniciar passos da simulação';

  @override
  String get resetSimulationStepsHint =>
      'Retorna a visualização ao primeiro passo registrado.';

  @override
  String get resetToFirst => 'Reiniciar no primeiro';

  @override
  String get jumpToLast => 'Ir para o último';

  @override
  String get previousStepLower => 'Passo anterior';

  @override
  String get nextStepLower => 'Próximo passo';

  @override
  String hiddenStepsSummary(int before, int after) {
    return '$before anteriores e $after posteriores ocultos';
  }

  @override
  String get noSimulationResults => 'Nenhum resultado de simulação';

  @override
  String get simulationEmptyHint =>
      'Informe uma cadeia e ative Simular para ver os resultados';

  @override
  String get accepted => 'Aceita';

  @override
  String get rejected => 'Rejeitada';

  @override
  String get acceptedLower => 'aceita';

  @override
  String get rejectedLower => 'rejeitada';

  @override
  String get regexAlphabetLabel => 'Alfabeto / universo';

  @override
  String get regexAlphabetHelper =>
      'Caracteres usados por ., \\D, \\W e \\S (espaços contam).';

  @override
  String get regexAlphabetEmptyError => 'O alfabeto não pode ficar vazio.';

  @override
  String get suggestedFixes => 'Correções sugeridas';

  @override
  String algorithmAction(String title) {
    return 'Ação de algoritmo: $title';
  }

  @override
  String algorithmUnavailableHint(String description) {
    return 'Indisponível. $description';
  }

  @override
  String algorithmStartHint(String description) {
    return 'Toque duas vezes para iniciar. $description';
  }

  @override
  String get pdaNormalizationReviewTitle => 'Revisar normalização do AP';

  @override
  String pdaNormalizationSourceAcceptance(String mode) {
    return 'Aceitação de origem: $mode';
  }

  @override
  String pdaNormalizationTargetAcceptance(String mode) {
    return 'Aceitação de destino: $mode';
  }

  @override
  String pdaNormalizationStateCount(int before, int after) {
    return 'Estados: $before → $after';
  }

  @override
  String pdaNormalizationTransitionCount(int before, int after) {
    return 'Transições: $before → $after';
  }

  @override
  String pdaNormalizationNewStackSymbol(String symbol) {
    return 'Novo símbolo de pilha: $symbol';
  }

  @override
  String get pdaNormalizationGrowthWarning =>
      'A normalização pode aumentar a quantidade de estados e transições. A conversão do modo de aceitação também pode introduzir não determinismo.';

  @override
  String get pdaNormalizationCancelHint =>
      'Revise as quantidades antes de aplicar. Cancelar mantém o AP do editor inalterado.';

  @override
  String get pdaNormalizationCancel => 'Cancelar';

  @override
  String get pdaNormalizationApplyAndConvert => 'Aplicar e converter';

  @override
  String get pdaSimplificationButtonTitle => 'Simplificar AP';

  @override
  String get pdaSimplificationButtonDescription =>
      'Remover com segurança estados de controle inalcançáveis ou fortemente bissimilares';

  @override
  String get pdaSimplificationAnalysisTitle => 'Simplificação de AP';

  @override
  String get pdaSimplificationMissingPda =>
      'Crie uma AP antes de simplificá-la.';

  @override
  String get pdaSimplificationReviewTitle => 'Revisar simplificação do AP';

  @override
  String pdaSimplificationActiveAcceptance(String mode) {
    return 'Aceitação ativa: $mode';
  }

  @override
  String get pdaSimplificationScope =>
      'Esta é uma redução estrutural conservadora, não um APND globalmente mínimo.';

  @override
  String get pdaSimplificationSkippedSemantic =>
      'A utilidade semântica exata não está disponível para APNDs gerais; por isso, estados incertos foram mantidos.';

  @override
  String get pdaSimplificationChangesHeading => 'Alterações propostas';

  @override
  String pdaSimplificationUnreachableChange(int count) {
    return 'Estados inalcançáveis removidos: $count';
  }

  @override
  String pdaSimplificationMergeChange(int count) {
    return 'Grupos unidos por bissimulação forte: $count';
  }

  @override
  String pdaSimplificationDuplicateChange(int count) {
    return 'Transições redundantes removidas: $count';
  }

  @override
  String get pdaSimplificationCancelHint =>
      'Revise antes de aplicar. Cancelar mantém o AP do editor inalterado.';

  @override
  String get pdaSimplificationCancel => 'Cancelar';

  @override
  String get pdaSimplificationApply => 'Aplicar simplificação';

  @override
  String get pdaSimplificationNoChange =>
      'Nenhuma simplificação compatível foi encontrada. O AP foi copiado sem alterações estruturais.';

  @override
  String get pdaSimplificationCanceled =>
      'Simplificação cancelada. O AP do editor não foi alterado.';

  @override
  String get pdaSimplificationApplied => 'Simplificação do AP aplicada.';

  @override
  String get pdaSimplificationEditorChanged =>
      'A simplificação foi cancelada porque o AP do editor mudou durante a revisão.';

  @override
  String pdaSimplificationFailed(String error) {
    return 'Falha na simplificação: $error';
  }

  @override
  String get pdaAcceptanceFinalState => 'estado final';

  @override
  String get pdaAcceptanceEmptyStack => 'pilha vazia';

  @override
  String get pdaAcceptanceBoth => 'estado final e pilha vazia';

  @override
  String get executing => 'Executando';

  @override
  String get selected => 'Selecionado';

  @override
  String workflowLegacyText(String text) {
    return '$text';
  }
}
