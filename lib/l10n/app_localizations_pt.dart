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
  String get workspaceStatusLambdaTransitions => 'Transições ε presentes';

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
    String id,
    String from,
    String to,
    String label,
  ) {
    return 'Transição $id de $from para $to com rótulo $label.';
  }

  @override
  String get canvasViewportEditHint =>
      'Use atalhos de teclado ou os controles da barra de ferramentas para editar o canvas.';

  @override
  String get canvasViewportReadOnlyHint =>
      'Este canvas é somente leitura. Desloque ou aplique zoom para inspecionar o autômato.';

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
  String get conversionReplaceTitle => 'Substituir resultado carregado?';

  @override
  String get conversionReplaceCancel => 'Cancelar';

  @override
  String get conversionReplaceConfirm => 'Substituir';

  @override
  String get conversionReplaceAutomatonMessage =>
      'Já existe um autômato carregado. Deseja substituí-lo?';

  @override
  String get conversionReplaceGrammarMessage =>
      'Já existe uma gramática carregada. Deseja substituí-la?';

  @override
  String get conversionReplacePushdownAutomatonMessage =>
      'Já existe um autômato de pilha carregado. Deseja substituí-lo?';

  @override
  String get conversionReplaceTuringMachineMessage =>
      'Já existe uma máquina de Turing carregada. Deseja substituí-la?';

  @override
  String get conversionReplaceRegexMessage =>
      'Já existe uma regex carregada. Deseja substituí-la?';

  @override
  String canvasActionSemantics(String action) {
    return 'Ação do canvas: $action';
  }

  @override
  String canvasDestructiveActionSemantics(String action) {
    return 'Ação do canvas: $action. Ação destrutiva.';
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
  String get canvasArrangeAutomatonAction => 'Organizar estados do autômato';

  @override
  String get canvasImportAutomatonAction => 'Importar autômato';

  @override
  String get canvasDocumentNotesAction => 'Notas do documento';

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
      'Ativa ou desativa o modo Adicionar estado; toque na tela para posicionar um estado.';

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
  String get canvasArrangeAutomatonHint =>
      'Mostra uma prévia do layout antes de aplicá-lo a este autômato.';

  @override
  String get canvasImportAutomatonHint =>
      'Mostra uma prévia e combina um autômato compatível com este documento.';

  @override
  String get canvasDocumentNotesHint => 'Abre as notas deste documento.';

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
  String get pdaLambdaInput => 'ε-entrada';

  @override
  String get pdaInputSymbolRequired => 'Insira um símbolo ou ative ε-entrada';

  @override
  String get pdaPopSymbol => 'Símbolo para desempilhar';

  @override
  String get pdaLambdaPop => 'ε-desempilhar';

  @override
  String get pdaPopSymbolRequired => 'Insira um símbolo ou ative ε-desempilhar';

  @override
  String get pdaPushSymbol => 'Símbolo para empilhar';

  @override
  String get pdaLambdaPush => 'ε-empilhar';

  @override
  String get pdaPushSymbolRequired => 'Insira um símbolo ou ative ε-empilhar';

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
  String get algorithmsAndExamples => 'Algoritmos e Exemplos';

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
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsAboutTileTitle => 'Sobre o Turing Lab';

  @override
  String get settingsAboutTileSubtitle =>
      'Visão geral do produto, plataformas e créditos';

  @override
  String get aboutPageTitle => 'Sobre o Turing Lab';

  @override
  String get aboutEyebrow => 'Linguagens formais e autômatos';

  @override
  String get aboutLead =>
      'Um conjunto de ferramentas em Flutter para construir, transformar e simular modelos de linguagens formais.';

  @override
  String get aboutDetail =>
      'Oferece espaços de trabalho para autômatos finitos, gramáticas livres de contexto, autômatos com pilha, máquinas de Turing, expressões regulares e exercícios sobre o lema do bombeamento.';

  @override
  String get aboutDevelopmentStatus =>
      'Status de desenvolvimento: as versões para Apple e Android estão em testes.';

  @override
  String get aboutViewSource => 'Ver código-fonte';

  @override
  String get aboutReadDocumentation => 'Ler documentação';

  @override
  String get aboutReportIssue => 'Relatar um problema';

  @override
  String get aboutCapabilitiesTitle => 'Modelos e fluxos suportados';

  @override
  String get aboutCapabilitiesIntro =>
      'O escopo atual está organizado em seis espaços de trabalho independentes. O suporte a arquivos e as transformações variam por modelo.';

  @override
  String get aboutCapabilityEditing => 'Edição';

  @override
  String get aboutCapabilitySimulation => 'Simulação';

  @override
  String get aboutCapabilityTransformations => 'Transformações';

  @override
  String get aboutCapabilityImportExport => 'Importação/exportação';

  @override
  String get aboutWorkspaceFsa => 'Autômatos finitos';

  @override
  String get aboutWorkspaceFsaEditing => 'Canvas de estados e transições';

  @override
  String get aboutWorkspaceFsaSimulation => 'Traços de aceitação passo a passo';

  @override
  String get aboutWorkspaceFsaTransformations =>
      'Conversão AFN/AFD/regex e minimização de AFD';

  @override
  String get aboutWorkspaceFsaFiles => 'JFLAP XML, JSON, SVG e PNG nativo';

  @override
  String get aboutWorkspaceGrammar => 'Gramáticas livres de contexto';

  @override
  String get aboutWorkspaceGrammarEditing => 'Editor de gramática e produções';

  @override
  String get aboutWorkspaceGrammarSimulation => 'Análise e validação';

  @override
  String get aboutWorkspaceGrammarTransformations =>
      'FIRST/FOLLOW, diagnósticos LL(1) e conversão para FNC';

  @override
  String get aboutWorkspaceGrammarFiles => 'Gramática JFLAP e SVG';

  @override
  String get aboutWorkspacePda => 'Autômatos com pilha';

  @override
  String get aboutWorkspacePdaEditing => 'Canvas de estados e transições';

  @override
  String get aboutWorkspacePdaSimulation => 'Traços de entrada e pilha';

  @override
  String get aboutWorkspacePdaTransformations => 'Não se aplica';

  @override
  String get aboutWorkspacePdaFiles => 'Exportação SVG';

  @override
  String get aboutWorkspaceTm => 'Máquinas de Turing';

  @override
  String get aboutWorkspaceTmEditing => 'Canvas de estados e transições';

  @override
  String get aboutWorkspaceTmSimulation => 'Traços de fita e transições';

  @override
  String get aboutWorkspaceTmTransformations => 'Não se aplica';

  @override
  String get aboutWorkspaceTmFiles => 'Exportação SVG';

  @override
  String get aboutWorkspaceRegex => 'Expressões regulares';

  @override
  String get aboutWorkspaceRegexEditing => 'Editor de expressões';

  @override
  String get aboutWorkspaceRegexSimulation =>
      'Teste de correspondência e comparação';

  @override
  String get aboutWorkspaceRegexTransformations =>
      'Simplificação e conversão para autômato';

  @override
  String get aboutWorkspaceRegexFiles => 'Não se aplica';

  @override
  String get aboutWorkspacePumping => 'Lema do bombeamento';

  @override
  String get aboutWorkspacePumpingEditing => 'Fluxo guiado de casos';

  @override
  String get aboutWorkspacePumpingSimulation => 'Validação da decomposição';

  @override
  String get aboutWorkspacePumpingTransformations => 'Não se aplica';

  @override
  String get aboutWorkspacePumpingFiles => 'Não se aplica';

  @override
  String get aboutFiniteAutomataTitle => 'Autômatos finitos';

  @override
  String get aboutFiniteAutomataBody =>
      'Os fluxos de autômatos finitos incluem conversão entre autômatos não determinísticos e determinísticos, conversão de expressões regulares, minimização de AFD e traços de aceitação.';

  @override
  String get aboutGrammarAnalysisTitle => 'Análise de gramáticas';

  @override
  String get aboutGrammarAnalysisBody =>
      'As ferramentas de gramática oferecem diagnósticos de análise sintática, conjuntos FIRST e FOLLOW, conflitos LL(1) e um pipeline de forma normal de Chomsky de melhor esforço.';

  @override
  String get aboutExecutionTracesTitle => 'Traços de execução';

  @override
  String get aboutExecutionTracesBody =>
      'As simulações de AF, AP e MT expõem configurações intermediárias por estado, transição, pilha ou fita, conforme o modelo.';

  @override
  String get aboutFormatsTitle =>
      'Execução local e compatibilidade limitada de arquivos';

  @override
  String get aboutFormatsIntro =>
      'O Turing Lab não exige conta nem backend operado pelo desenvolvedor. Edição, simulação, diagnósticos e exemplos empacotados rodam localmente.';

  @override
  String get aboutFormatFsa =>
      'AF: importação/exportação JFLAP XML e JSON, SVG e PNG em plataformas nativas.';

  @override
  String get aboutFormatGrammar =>
      'Gramática: importação/exportação JFLAP e SVG.';

  @override
  String get aboutFormatPdaTm =>
      'AP: exportação SVG. MT: importação/exportação em XML do JFLAP e JSON, além de exportação SVG.';

  @override
  String get aboutFormatWebLimitation =>
      'Limitação web: a exportação PNG não está disponível nas versões web.';

  @override
  String get aboutPlatformsTitle => 'Status atual de validação';

  @override
  String get aboutPlatformsIntro =>
      'As builds de teste passam por validação de plataforma e preparação de release. Alvos experimentais podem ter integração incompleta e não fazem parte do escopo de release atual.';

  @override
  String get aboutStatusTesting => 'Em teste';

  @override
  String get aboutStatusExperimental => 'Experimental';

  @override
  String get aboutPlatformIos => 'iOS e iPadOS';

  @override
  String get aboutPlatformMacos => 'macOS';

  @override
  String get aboutPlatformAndroid => 'Android';

  @override
  String get aboutPlatformWeb => 'Web';

  @override
  String get aboutPlatformWindows => 'Windows';

  @override
  String get aboutPlatformLinux => 'Linux';

  @override
  String get aboutScreenshotsTitle => 'Espaços de trabalho';

  @override
  String get aboutScreenshotsIntro =>
      'Capturas de configurações controladas de teste em celular e tablet.';

  @override
  String get aboutScreenshotFsa =>
      'Autômatos finitos. Canvas, resultado da simulação e traço passo a passo.';

  @override
  String get aboutScreenshotGrammar =>
      'Gramáticas livres de contexto. Edição de produções e transformações.';

  @override
  String get aboutScreenshotTm =>
      'Máquinas de Turing. Simulação de fita, edição de transições e análise específica.';

  @override
  String get aboutAttribution =>
      'O Turing Lab é inspirado no projeto original JFLAP. O Turing Lab não é afiliado, endossado nem um lançamento oficial do JFLAP, da Duke University ou de Susan H. Rodger.';

  @override
  String get aboutOpenLicenses => 'Licenças de código aberto';

  @override
  String get aboutOpenPrivacy => 'Política de privacidade';

  @override
  String get aboutOpenSupport => 'Suporte';

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
  String get homeNavigationRegularPumpingLabel => 'Bombeamento regular';

  @override
  String get homeNavigationRegularPumpingDescription =>
      'Lema do bombeamento regular';

  @override
  String get homeNavigationContextFreePumpingLabel =>
      'Bombeamento livre de contexto';

  @override
  String get homeNavigationContextFreePumpingDescription =>
      'Lema do bombeamento livre de contexto';

  @override
  String get choosePumpingLemmaEnvironment =>
      'Escolha um ambiente de lema do bombeamento';

  @override
  String get choosePumpingLemmaEnvironmentDescription =>
      'Os lemas do bombeamento regular e livre de contexto têm decomposições e obrigações de prova diferentes.';

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
  String get regexBatchTestingTitle => 'Testes em lote';

  @override
  String get regexBatchTestingSubtitle =>
      'Verifica casos de entrada ordenados e limitados';

  @override
  String get regexBatchExecutionTitle => 'Execução em lote de regex';

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
  String get originalLabel => 'Expressão original:';

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
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Passo $currentString de $totalString';
  }

  @override
  String stepNumber(int step) {
    final intl.NumberFormat stepNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String stepString = stepNumberFormat.format(step);

    return 'Passo $stepString';
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
  String playbackSpeedMultiplier(String speed) {
    return '${speed}x';
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
    String consumed,
    String state,
    String nextState,
    String remaining,
  ) {
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
  String get pdaAcceptanceModeTitle => 'Modo de aceitação';

  @override
  String get pdaAcceptanceFinalStateExplanation =>
      'A entrada completa deve terminar em um estado de aceitação. A pilha ainda pode conter símbolos.';

  @override
  String get pdaAcceptanceEmptyStackExplanation =>
      'A entrada completa deve deixar a pilha vazia. O estado atual não precisa ser de aceitação.';

  @override
  String get pdaAcceptanceBothExplanation =>
      'A entrada completa deve terminar em um estado de aceitação com a pilha vazia.';

  @override
  String get pdaAcceptanceFinalStateCompactExplanation =>
      'Entrada consumida; pilha ignorada.';

  @override
  String get pdaAcceptanceEmptyStackCompactExplanation =>
      'Entrada consumida; estado final ignorado.';

  @override
  String get pdaAcceptanceBothCompactExplanation =>
      'Entrada consumida; ambas exigidas.';

  @override
  String get executing => 'Executando';

  @override
  String get selected => 'Selecionado';

  @override
  String workflowLegacyText(String text) {
    return '$text';
  }

  @override
  String get retry => 'Tentar novamente';

  @override
  String get retrying => 'Tentando novamente...';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get dismissMessage => 'Dispensar mensagem';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loading => 'Carregando';

  @override
  String get doubleTapToRetry => 'Toque duas vezes para tentar novamente';

  @override
  String get successBannerSemantics => 'Banner de sucesso';

  @override
  String get errorBannerSemantics => 'Banner de erro';

  @override
  String get warningBannerSemantics => 'Banner de aviso';

  @override
  String get infoBannerSemantics => 'Banner de informação';

  @override
  String get ok => 'OK';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get add => 'Adicionar';

  @override
  String get update => 'Atualizar';

  @override
  String get undo => 'Desfazer';

  @override
  String get fileOperationsTitle => 'Operações de arquivo';

  @override
  String get fileSectionFsa => 'AF';

  @override
  String get fileSectionGrammar => 'Gramática';

  @override
  String get fileSectionPda => 'AP';

  @override
  String get fileSectionTm => 'Máquina de Turing';

  @override
  String get fileSectionRegex => 'Expressão regular';

  @override
  String get regexDocumentDialect => 'Dialeto';

  @override
  String get regexDocumentDialectTuringLab => 'Turing Lab v1';

  @override
  String get regexDocumentTokenization => 'Tokenização';

  @override
  String get regexDocumentTokenizationUnicodeScalar =>
      'Valores escalares Unicode';

  @override
  String get saveAsJflap => 'Salvar como JFLAP';

  @override
  String get downloadJflap => 'Baixar JFLAP';

  @override
  String get loadJflap => 'Carregar JFLAP';

  @override
  String get saveAsJson => 'Salvar como JSON';

  @override
  String get downloadJson => 'Baixar JSON';

  @override
  String get loadJson => 'Carregar JSON';

  @override
  String get exportSvg => 'Exportar SVG';

  @override
  String get downloadSvg => 'Baixar SVG';

  @override
  String get exportPng => 'Exportar PNG';

  @override
  String get jsonUnreadableFileMessage =>
      'O Turing Lab não conseguiu acessar os dados do arquivo JSON selecionado. Escolha o arquivo novamente e mantenha-o disponível até o fim da importação.';

  @override
  String get saveAutomatonAsJflap => 'Salvar autômato como JFLAP';

  @override
  String get saveAutomatonAsJson => 'Salvar autômato como JSON';

  @override
  String get loadJflapAutomaton => 'Carregar autômato JFLAP';

  @override
  String get loadAutomatonJson => 'Carregar JSON do autômato';

  @override
  String get exportAutomatonAsSvg => 'Exportar autômato como SVG';

  @override
  String get exportAutomatonAsPng => 'Exportar autômato como PNG';

  @override
  String get saveGrammarAsJflap => 'Salvar gramática como JFLAP';

  @override
  String get loadJflapGrammar => 'Carregar gramática JFLAP';

  @override
  String get exportGrammarAsSvg => 'Exportar gramática como SVG';

  @override
  String get exportPdaAsSvg => 'Exportar AP como SVG';

  @override
  String get exportTmAsSvg => 'Exportar máquina de Turing como SVG';

  @override
  String get automatonSavedSuccessfully => 'Autômato salvo com sucesso';

  @override
  String get automatonLoadedSuccessfully => 'Autômato carregado com sucesso';

  @override
  String get automatonExportedSuccessfully => 'Autômato exportado com sucesso';

  @override
  String get grammarSavedSuccessfully => 'Gramática salva com sucesso';

  @override
  String get grammarLoadedSuccessfully => 'Gramática carregada com sucesso';

  @override
  String get grammarExportedSuccessfully => 'Gramática exportada com sucesso';

  @override
  String get pdaExportedSuccessfully => 'AP exportado com sucesso';

  @override
  String get tmExportedSuccessfully =>
      'Máquina de Turing exportada com sucesso';

  @override
  String get saveCanceled => 'Salvamento cancelado.';

  @override
  String get exportCanceled => 'Exportação cancelada.';

  @override
  String get importCanceled => 'Importação cancelada.';

  @override
  String downloadStartedFor(String fileName) {
    return 'Download iniciado para $fileName';
  }

  @override
  String failedToSaveAutomaton(String error) {
    return 'Falha ao salvar o autômato: $error';
  }

  @override
  String errorSavingAutomaton(String error) {
    return 'Erro ao salvar o autômato: $error';
  }

  @override
  String errorLoadingAutomaton(String error) {
    return 'Erro ao carregar o autômato: $error';
  }

  @override
  String failedToExportAutomaton(String error) {
    return 'Falha ao exportar o autômato: $error';
  }

  @override
  String errorExportingAutomaton(String error) {
    return 'Erro ao exportar o autômato: $error';
  }

  @override
  String failedToSaveAutomatonJson(String error) {
    return 'Falha ao salvar o JSON do autômato: $error';
  }

  @override
  String errorSavingAutomatonJson(String error) {
    return 'Erro ao salvar o JSON do autômato: $error';
  }

  @override
  String errorLoadingAutomatonJson(String error) {
    return 'Erro ao carregar o JSON do autômato: $error';
  }

  @override
  String failedToExportAutomatonPng(String error) {
    return 'Falha ao exportar o PNG do autômato: $error';
  }

  @override
  String errorExportingAutomatonPng(String error) {
    return 'Erro ao exportar o PNG do autômato: $error';
  }

  @override
  String failedToSaveGrammar(String error) {
    return 'Falha ao salvar a gramática: $error';
  }

  @override
  String errorSavingGrammar(String error) {
    return 'Erro ao salvar a gramática: $error';
  }

  @override
  String errorLoadingGrammar(String error) {
    return 'Erro ao carregar a gramática: $error';
  }

  @override
  String failedToExportGrammar(String error) {
    return 'Falha ao exportar a gramática: $error';
  }

  @override
  String errorExportingGrammar(String error) {
    return 'Erro ao exportar a gramática: $error';
  }

  @override
  String failedToExportPda(String error) {
    return 'Falha ao exportar o AP: $error';
  }

  @override
  String errorExportingPda(String error) {
    return 'Erro ao exportar o AP: $error';
  }

  @override
  String failedToExportTm(String error) {
    return 'Falha ao exportar a máquina de Turing: $error';
  }

  @override
  String errorExportingTm(String error) {
    return 'Erro ao exportar a máquina de Turing: $error';
  }

  @override
  String get importErrorDialogSemantics => 'Diálogo de erro de importação';

  @override
  String get cancelImport => 'Cancelar importação';

  @override
  String get importErrorMalformedJff => 'Arquivo JFLAP malformado';

  @override
  String get importErrorInvalidJson => 'Estrutura JSON inválida';

  @override
  String get importErrorUnsupportedVersion => 'Versão de arquivo não suportada';

  @override
  String get importErrorInaccessibleFile => 'Acesso ao arquivo indisponível';

  @override
  String get importErrorCorruptedData => 'Dados corrompidos detectados';

  @override
  String get importErrorInvalidAutomaton => 'Definição de autômato inválida';

  @override
  String get importFriendlyMalformedJff =>
      'Não foi possível analisar o arquivo JFLAP selecionado. Verifique a integridade do arquivo e tente novamente.';

  @override
  String get importFriendlyInvalidJson =>
      'A importação contém seções JSON inválidas. Corrija a estrutura JSON e tente novamente.';

  @override
  String get importFriendlyUnsupportedVersion =>
      'Este arquivo usa uma versão mais nova do esquema JFLAP. Exporte-o novamente em uma versão compatível e tente novamente.';

  @override
  String get importFriendlyInaccessibleFile =>
      'O Turing Lab não conseguiu acessar o arquivo selecionado. Escolha-o novamente no diálogo do sistema e mantenha-o disponível até o fim da importação.';

  @override
  String get importFriendlyCorruptedData =>
      'O arquivo parece corrompido ou ilegível. Restaure um backup válido antes de importar novamente.';

  @override
  String get importFriendlyInvalidAutomaton =>
      'A definição do autômato está inconsistente. Revise as transições e os estados antes de tentar importar novamente.';

  @override
  String get hideTechnicalDetails => 'Ocultar detalhes técnicos';

  @override
  String get viewTechnicalDetails => 'Ver detalhes técnicos';

  @override
  String get svgNoStatesDefined => 'Nenhum estado definido';

  @override
  String get svgTmLegend => 'δ(q, s) = (q′, w, d) — leitura/escrita/movimento';

  @override
  String get loadAutomatonBeforeOperation =>
      'Carregue um autômato antes de executar esta operação.';

  @override
  String get operationRequiresDeterministicNoEpsilon =>
      'Esta operação exige um autômato determinístico sem transições ε.';

  @override
  String get automatonHasNoLambdaTransitions =>
      'O autômato atual não contém transições ε.';

  @override
  String get automatonMustContainLambdaToRemove =>
      'O autômato atual precisa conter transições ε para removê-las.';

  @override
  String get lambdaTransitionsRemoved => 'Transições ε removidas com sucesso.';

  @override
  String get complementComputed => 'Complemento calculado com sucesso.';

  @override
  String get complementRequiresDeterministic =>
      'O complemento só está disponível para autômatos determinísticos sem transições ε.';

  @override
  String get prefixClosureComputed =>
      'Fecho por prefixos calculado com sucesso.';

  @override
  String get prefixClosureRequiresDeterministic =>
      'O fecho por prefixos só está disponível para autômatos determinísticos sem transições ε.';

  @override
  String get suffixClosureComputed =>
      'Fecho por sufixos calculado com sucesso.';

  @override
  String get suffixClosureRequiresDeterministic =>
      'O fecho por sufixos só está disponível para autômatos determinísticos sem transições ε.';

  @override
  String get unionComputed => 'União calculada com sucesso.';

  @override
  String get binaryDfaRequiresDeterministic =>
      'Operações binárias de AFD exigem um autômato determinístico sem transições ε.';

  @override
  String get concatenationComputed => 'Concatenação calculada com sucesso.';

  @override
  String get loadFsaBeforeConcatenation =>
      'Carregue um AF antes de calcular a concatenação.';

  @override
  String get kleeneStarComputed => 'Estrela de Kleene calculada com sucesso.';

  @override
  String get loadFsaBeforeKleeneStar =>
      'Carregue um AF antes de aplicar a estrela de Kleene.';

  @override
  String get fsaLanguageReversed => 'Linguagem do AF invertida com sucesso.';

  @override
  String get loadFsaBeforeReverse =>
      'Carregue um AF antes de inverter a linguagem.';

  @override
  String get intersectionComputed => 'Interseção calculada com sucesso.';

  @override
  String get differenceComputed => 'Diferença calculada com sucesso.';

  @override
  String get convertedToRegexWorkspace =>
      'Autômato convertido em expressão regular. Trocado para o espaço Regex.';

  @override
  String get convertedToGrammarWorkspace =>
      'Autômato convertido em gramática. Trocado para o espaço Gramática.';

  @override
  String get grammarEditorTitle => 'Editor de gramática';

  @override
  String get defaultGrammarName => 'Minha gramática';

  @override
  String get grammarInformation => 'Informações da gramática';

  @override
  String get grammarNameLabel => 'Nome da gramática';

  @override
  String get startSymbolLabel => 'Símbolo inicial';

  @override
  String get editProductionRule => 'Editar alternativas';

  @override
  String get addProductionRule => 'Adicionar regra de produção';

  @override
  String get leftSideVariable => 'NT';

  @override
  String get rightSideProduction => 'Produção';

  @override
  String get leftSideHint => 'S';

  @override
  String get rightSideHint => 'ex.: aA | bB | ε';

  @override
  String get insertEpsilon => 'Inserir ε';

  @override
  String get symbolKindLegend =>
      'Toque em um símbolo para alternar não-terminal (amarelo) / terminal (verde). Toque no elo entre dois símbolos para juntá-los; segure para juntar ou separar a alternativa inteira.';

  @override
  String mergeSymbolsTooltip(String left, String right) {
    return 'Juntar $left e $right em um símbolo';
  }

  @override
  String get symbolChipNonterminalTooltip =>
      'Não-terminal. Toque para marcar como terminal.';

  @override
  String get symbolChipTerminalTooltip =>
      'Terminal. Toque para marcar como não-terminal.';

  @override
  String get noProductionRulesYet => 'Ainda não há regras de produção';

  @override
  String get addFirstProductionRule =>
      'Adicione a primeira regra de produção acima';

  @override
  String get clearAllProductionsTitle => 'Limpar todas as produções?';

  @override
  String get clearAllProductionsMessage =>
      'Isso removerá todas as regras de produção da gramática atual.';

  @override
  String get productionsCleared => 'Produções limpas.';

  @override
  String get bothSidesRequired => 'Informe a variável e a produção.';

  @override
  String get leftSideMustBeNonterminal =>
      'O lado esquerdo deve conter um símbolo não terminal';

  @override
  String get leftSideExactlyOneNonterminal =>
      'O lado esquerdo deve conter exatamente um símbolo não terminal';

  @override
  String get rightSideAtLeastOneSymbol =>
      'O lado direito deve conter pelo menos um símbolo (ou ε)';

  @override
  String get rightSideSingleLambda =>
      'O lado direito pode conter apenas um símbolo ε';

  @override
  String get lambdaMustBeOnlySymbol =>
      'ε deve ser o único símbolo no lado direito';

  @override
  String get rightSideEmptyAlternative =>
      'Informe um valor entre cada separador |';

  @override
  String get rightSideArrowNotAccepted =>
      'Informe somente alternativas do lado direito aqui, sem uma seta';

  @override
  String get editAlternatives => 'Editar alternativas';

  @override
  String get deleteGroup => 'Excluir grupo';

  @override
  String get productionGroupActions => 'Ações do grupo de produções';

  @override
  String get moveUp => 'Mover para cima';

  @override
  String get moveDown => 'Mover para baixo';

  @override
  String reorderProductionsFor(String leftSide) {
    return 'Reordenar produções de $leftSide';
  }

  @override
  String productionPosition(int position, int total) {
    return 'Posição $position de $total';
  }

  @override
  String productionGroupMoved(String leftSide, int position, int total) {
    return 'Produções de $leftSide movidas para a posição $position de $total';
  }

  @override
  String get deleteProductionGroupTitle => 'Excluir grupo de produções?';

  @override
  String deleteProductionGroupMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alternativas',
      one: '1 alternativa',
    );
    return 'Isso excluirá $_temp0.';
  }

  @override
  String productionAlternativesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alternativas',
      one: '1 alternativa',
    );
    return '$_temp0';
  }

  @override
  String productionAlternativesSkippedDuplicates(int added, int duplicates) {
    return 'Adicionadas: $added; ignoradas por já existirem: $duplicates.';
  }

  @override
  String productionAlternativesAlreadyExist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Essas $count alternativas já existem.',
      one: 'Essa alternativa já existe.',
    );
    return '$_temp0';
  }

  @override
  String get sampleStringsTitle => 'Cadeias de exemplo';

  @override
  String get hideSamples => 'Ocultar exemplos';

  @override
  String get showSamples => 'Mostrar exemplos';

  @override
  String get generateSampleStrings => 'Gerar cadeias de exemplo';

  @override
  String get generateMore => 'Gerar mais';

  @override
  String get noSampleStringsGenerated => 'Nenhuma cadeia de exemplo gerada';

  @override
  String get generatedSamples => 'Exemplos gerados:';

  @override
  String get copyAll => 'Copiar tudo';

  @override
  String get allSamplesCopied =>
      'Todos os exemplos copiados para a área de transferência';

  @override
  String get failedToCopyClipboard =>
      'Falha ao copiar para a área de transferência.';

  @override
  String get complexityAnalysisTitle => 'Análise de complexidade';

  @override
  String get hideDetails => 'Ocultar detalhes';

  @override
  String get showDetails => 'Mostrar detalhes';

  @override
  String get analyzeComplexity => 'Analisar complexidade';

  @override
  String get reanalyze => 'Reanalisar';

  @override
  String get noOperatorsUsed => 'Nenhum operador usado (expressão literal)';

  @override
  String get operatorUnion => 'União (|)';

  @override
  String get operatorConcatenation => 'Concatenação';

  @override
  String get operatorKleeneStar => 'Estrela de Kleene (*)';

  @override
  String get operatorPlus => 'Mais (+)';

  @override
  String get operatorOptional => 'Opcional (?)';

  @override
  String get openWitnessInSimulator => 'Abrir testemunha no Simulador';

  @override
  String get drawPdaBeforeConvertGrammar =>
      'Desenhe um AP antes de converter para uma gramática.';

  @override
  String get generatedGrammar => 'Gramática gerada';

  @override
  String get pumpingLemmaGameTitle => 'Jogo do Lema do Bombeamento';

  @override
  String get pumpingWelcome => 'Bem-vindo ao Jogo do Lema do Bombeamento!';

  @override
  String get pumpingWelcomeBody =>
      'Teste sua compreensão do lema do bombeamento decidindo se as linguagens dadas são regulares ou não.';

  @override
  String get startGame => 'Iniciar jogo';

  @override
  String get isLanguageRegular => 'Esta linguagem é regular?';

  @override
  String get yesItIsRegular => 'Sim, é regular';

  @override
  String get noItIsNotRegular => 'Não, não é regular';

  @override
  String get submitAnswer => 'Enviar resposta';

  @override
  String get correct => 'Correto!';

  @override
  String get incorrect => 'Incorreto';

  @override
  String get explanation => 'Explicação:';

  @override
  String get nextChallenge => 'Próximo desafio';

  @override
  String get finishGame => 'Terminar jogo';

  @override
  String get challengeComplete => 'Desafio concluído!';

  @override
  String get practiceAgain => 'Praticar novamente';

  @override
  String get performanceExpert => 'Especialista';

  @override
  String get performanceAdvanced => 'Avançado';

  @override
  String get performanceIntermediate => 'Intermediário';

  @override
  String get performanceBeginner => 'Iniciante';

  @override
  String get progressTitle => 'Progresso';

  @override
  String get overallProgress => 'Progresso geral';

  @override
  String get statistics => 'Estatísticas';

  @override
  String get accuracy => 'Precisão';

  @override
  String get correctCount => 'Corretas';

  @override
  String get attempts => 'Tentativas';

  @override
  String get challengeHistory => 'Histórico de desafios';

  @override
  String get noChallengesCompletedYet => 'Nenhum desafio concluído ainda';

  @override
  String get wrong => 'Errado';

  @override
  String get retrySelected => 'Repetir selecionados';

  @override
  String get exampleDfaEndsWithA => 'AFD - Termina com A';

  @override
  String get exampleDfaBinaryDivBy3 => 'AFD - Binário divisível por 3';

  @override
  String get exampleDfaParityAb => 'AFD - Paridade AB';

  @override
  String get exampleDfaContainsAb => 'AFD - Contém AB';

  @override
  String get exampleNfaLambdaAOrAb => 'AFNε - A ou AB';

  @override
  String get exampleCfgPalindrome => 'GLC - Palíndromo';

  @override
  String get exampleCfgBalancedParens => 'GLC - Parênteses balanceados';

  @override
  String get exampleCfgAnBn => 'GLC - a^n b^n';

  @override
  String get exampleCfgEvenZeros => 'GLC - Zeros em quantidade par';

  @override
  String get exampleCfgArithmetic => 'GLC - Expressões aritméticas';

  @override
  String get examplePdaBalancedParens => 'APD - Parênteses Balanceados';

  @override
  String get examplePdaAnBn => 'APD - a^n b^n';

  @override
  String get examplePdaPalindrome => 'APD - Palíndromo';

  @override
  String get examplePdaAnB2n => 'APD - a^n b^2n';

  @override
  String get examplePdaWHashReverseW => 'APD - w#reverse(w)';

  @override
  String get exampleTmAnBn => 'MT - a^n b^n';

  @override
  String get exampleTmBinaryToUnary => 'MT - Binário para unário';

  @override
  String get exampleTmCopyString => 'MT - Cópia de string';

  @override
  String get exampleTmBinaryIncrement => 'MT - Incremento binário';

  @override
  String get exampleTmPalindromeChecker => 'MT - Verificador de palíndromo';

  @override
  String get exampleRegexRepeatA => 'Regex - Repetição de A';

  @override
  String get exampleRegexEndsWithAb => 'Regex - Termina com AB';

  @override
  String get exampleRegexBinaryStarts0 => 'Regex - Binário iniciado por 0';

  @override
  String get exampleRegexPairsAbOrBa => 'Regex - Pares AB ou BA';

  @override
  String get exampleRegexBlocksAb => 'Regex - Blocos de A e B';

  @override
  String failedToLoadExample(String error) {
    return 'Falha ao carregar o exemplo: $error';
  }

  @override
  String exampleLoaded(String name) {
    return 'Exemplo carregado: $name';
  }

  @override
  String copiedQuoted(String value) {
    return 'Copiado: \"$value\"';
  }

  @override
  String startSymbolValue(String symbol) {
    return 'Símbolo inicial: $symbol';
  }

  @override
  String nonterminalsValue(String symbols) {
    return 'Não terminais: $symbols';
  }

  @override
  String terminalsValue(String symbols) {
    return 'Terminais: $symbols';
  }

  @override
  String productionsCountLabel(int count) {
    return 'Produções ($count):';
  }

  @override
  String pumpingLevelDifficulty(int level, String difficulty) {
    return 'Nível $level - $difficulty';
  }

  @override
  String challengeNumber(int number) {
    return 'Desafio $number';
  }

  @override
  String languageLabelValue(String language) {
    return 'Linguagem: $language';
  }

  @override
  String streakBonus(int points) {
    return 'Bônus de sequência! +$points pontos';
  }

  @override
  String levelLabelValue(String level) {
    return 'Nível: $level';
  }

  @override
  String challengeFallback(String id) {
    return 'Desafio $id';
  }

  @override
  String productionRulesCount(int count) {
    return 'Regras de produção ($count)';
  }

  @override
  String ruleNumber(int number) {
    return 'Regra $number';
  }

  @override
  String sampleStringsGeneratedCount(int count) {
    return '$count cadeia(s) de exemplo gerada(s)';
  }

  @override
  String get acceptsEpsilon => 'Aceita ε';

  @override
  String shortestSample(String value) {
    return 'Mais curta: \"$value\"';
  }

  @override
  String get complexityMetrics => 'Métricas de complexidade';

  @override
  String get complexityScore => 'Pontuação de complexidade';

  @override
  String get starHeightDescription =>
      'Aninhamento máximo de operadores estrela de Kleene (*)';

  @override
  String get nestingDepthDescription =>
      'Profundidade máxima de aninhamento de parênteses';

  @override
  String get complexityScoreDescription =>
      'Soma ponderada de todos os fatores de complexidade';

  @override
  String get operatorBreakdown => 'Distribuição de operadores';

  @override
  String get alphabetLabel => 'Alfabeto';

  @override
  String alphabetSizeCount(int count) {
    return 'Tamanho: $count símbolo(s)';
  }

  @override
  String get emptyAlphabetExpression =>
      'Alfabeto vazio (expressão apenas com épsilon)';

  @override
  String get nestingShort => 'Aninhamento';

  @override
  String get complexitySimple => 'Simples';

  @override
  String get complexityModerate => 'Moderada';

  @override
  String get complexityComplex => 'Complexa';

  @override
  String get complexitySimpleDescription =>
      'Fácil de entender, baixo custo computacional';

  @override
  String get complexityModerateDescription =>
      'Complexidade moderada, exige alguma análise';

  @override
  String get complexityComplexDescription =>
      'Alta complexidade, recomenda-se análise cuidadosa';

  @override
  String get tmOverviewTitle => 'Visão geral da máquina de Turing';

  @override
  String get tmOverviewBody =>
      'Acompanhe a estrutura da máquina e resolva problemas antes de executar simulações ou algoritmos.';

  @override
  String get tmBlockLibraryTitle => 'Biblioteca de blocos de construção';

  @override
  String get tmBlockLibraryDescription =>
      'Reutilize submáquinas tipadas com fitas compartilhadas e comportamento explícito de chamada e retorno.';

  @override
  String get tmBlockLibraryEmpty => 'Ainda não há blocos reutilizáveis.';

  @override
  String get tmBlockCreate => 'Criar bloco';

  @override
  String get tmBlockCreateTitle => 'Criar bloco de construção';

  @override
  String get tmBlockRenameTitle => 'Renomear bloco de construção';

  @override
  String get tmBlockNameLabel => 'Nome do bloco';

  @override
  String get tmBlockOpen => 'Abrir bloco';

  @override
  String get tmBlockInsert => 'Inserir na tela raiz';

  @override
  String get tmBlockRename => 'Renomear';

  @override
  String get tmBlockDuplicate => 'Duplicar';

  @override
  String get tmBlockDeleteReferencedTitle => 'O bloco está em uso';

  @override
  String get tmBlockDeleteReferencedMessage =>
      'Excluir este bloco converterá cada nó de invocação em um estado comum. As transições serão preservadas.';

  @override
  String get tmBlockDetachAndDelete => 'Desvincular e excluir';

  @override
  String get tmBlockSharedTapeNotice =>
      'As chamadas compartilham todas as fitas e posições das cabeças. Estados finais internos são ignorados; o bloco retorna quando para.';

  @override
  String get tmBlockRootBreadcrumb => 'Máquina raiz';

  @override
  String get tmBlockValid => 'Válido';

  @override
  String get tmBlockInvalid => 'Requer atenção';

  @override
  String tmBlockRevision(int revision) {
    return 'Revisão $revision';
  }

  @override
  String tmBlockMachineSummary(int states, int transitions) {
    return '$states estados, $transitions transições';
  }

  @override
  String get canvasManageBlocksAction => 'Blocos de construção';

  @override
  String get canvasManageBlocksHint =>
      'Abrir a biblioteca de blocos reutilizáveis de máquina de Turing';

  @override
  String get tapeSymbols => 'Símbolos da fita';

  @override
  String get tmTapeCount => 'Número de fitas';

  @override
  String get tmDocumentVariant => 'Variante';

  @override
  String get tmDocumentVariantSingleTape => 'Uma fita';

  @override
  String get tmDocumentVariantMultiTape => 'Múltiplas fitas';

  @override
  String get tmDocumentVariantBuildingBlocks => 'Blocos de construção';

  @override
  String get tmDecreaseTapeCount => 'Diminuir o número de fitas';

  @override
  String get tmIncreaseTapeCount => 'Aumentar o número de fitas';

  @override
  String get tmTapeCountShrinkBlocked =>
      'Remova as operações não vazias das fitas descartadas antes de reduzir o número de fitas.';

  @override
  String get moveDirections => 'Direções de movimento';

  @override
  String get simulationReady => 'Pronta para simulação';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get nondeterministicTransitions => 'Transições não determinísticas';

  @override
  String get resolveNondeterminism =>
      'Resolva o não determinismo antes de executar algoritmos determinísticos.';

  @override
  String editCell(int index) {
    return 'Editar célula $index';
  }

  @override
  String get tapeAlphabetLabel => 'Alfabeto da fita:';

  @override
  String get symbolLabel => 'Símbolo';

  @override
  String get enterASymbol => 'Informe um símbolo';

  @override
  String tapeHead(int position) {
    return 'Fita (cabeçote: $position)';
  }

  @override
  String tapeCellSemantics(int index) {
    return 'Célula $index da fita';
  }

  @override
  String tapeCellSymbolValue(String symbol) {
    return 'Símbolo $symbol';
  }

  @override
  String tapeCellBlankValue(String symbol) {
    return 'Símbolo branco $symbol';
  }

  @override
  String get tapeCellHeadState => 'sob o cabeçote da fita';

  @override
  String get tapeCellReadState => 'lida na última operação';

  @override
  String get tapeCellWrittenState => 'gravada na última operação';

  @override
  String get tapeCellEditHint =>
      'Abre a edição do símbolo desta célula da fita.';

  @override
  String emptyTape(String symbol) {
    return 'Vazia (□: $symbol)';
  }

  @override
  String get directionLeft => 'Esquerda (L)';

  @override
  String get directionRight => 'Direita (R)';

  @override
  String get directionStay => 'Permanecer (S)';

  @override
  String get egInitialStack => 'ex.: Z';

  @override
  String get currentStackState => 'Estado atual da pilha';

  @override
  String get emptyParen => '(vazia)';

  @override
  String highlightingStackCell(int index) {
    return 'Destacando a célula $index da pilha (de baixo)';
  }

  @override
  String get remainingInputColon => 'Entrada restante:';

  @override
  String get simulationFailed => 'Falha na simulação';

  @override
  String timeMs(int ms) {
    return 'Tempo: $ms ms';
  }

  @override
  String durationMillisecondsValue(String value) {
    return '$value ms';
  }

  @override
  String get simulationSteps => 'Passos da simulação:';

  @override
  String get pleaseEnterInitialStackSymbol =>
      'Informe um símbolo inicial da pilha';

  @override
  String get createPdaBeforeSimulating =>
      'Crie um AP no canvas antes de simular.';

  @override
  String get simulationCancelled => 'Simulação cancelada';

  @override
  String get pdaExamplesHint =>
      'Exemplos: aabb (parênteses balanceados), abab (palíndromos)';

  @override
  String stackCount(int count) {
    return 'Pilha ($count)';
  }

  @override
  String emptyStack(String symbol) {
    return 'Vazia\n(Z₀: $symbol)';
  }

  @override
  String stackCellSemantics(int position, int size) {
    return 'Célula $position de $size da pilha';
  }

  @override
  String stackCellSymbol(String symbol) {
    return 'símbolo $symbol';
  }

  @override
  String get topOfStack => 'topo da pilha';

  @override
  String get highlighted => 'destacada';

  @override
  String get beingRemoved => 'sendo removida';

  @override
  String get stackCellHintHighlight =>
      'Toque duas vezes para destacar esta célula da pilha. Deslize para a direita para destacá-la.';

  @override
  String get stackCellHintClear =>
      'Toque duas vezes para limpar o destaque. Deslize para a esquerda para remover o destaque desta célula.';

  @override
  String get clearStack => 'Limpar pilha';

  @override
  String get clearStackHint =>
      'Remove todos os símbolos da visualização da pilha.';

  @override
  String overflowMax(int max) {
    return 'Estouro!\nMáx.: $max';
  }

  @override
  String get underflowPopOnEmpty => 'Subfluxo!\nPop em pilha vazia';

  @override
  String get topLabel => 'Topo: ';

  @override
  String sizeLabel(int size) {
    return 'Tamanho: $size';
  }

  @override
  String opLabel(String operation) {
    return 'Op: $operation';
  }

  @override
  String get topBadge => 'TOPO';

  @override
  String get operationPreview => 'Prévia da operação';

  @override
  String get pop => 'Pop';

  @override
  String get push => 'Push';

  @override
  String get emptyStackParen => '(pilha vazia)';

  @override
  String get inputLabel => 'Entrada';

  @override
  String get previous => 'Anterior';

  @override
  String get next => 'Próximo';

  @override
  String get resetToFirstStep => 'Voltar ao primeiro passo';

  @override
  String get firstStep => 'Primeiro passo';

  @override
  String get lastStep => 'Último passo';

  @override
  String stepNumberLabel(int number) {
    return 'Passo $number';
  }

  @override
  String get determinismAnalysis => 'Análise de determinismo';

  @override
  String get typeLabel => 'Tipo: ';

  @override
  String get dfaHelpMessage =>
      'Autômato finito determinístico — cada estado tem no máximo uma transição por símbolo';

  @override
  String get epsilonNfaHelpMessage =>
      'Autômato finito não determinístico com transições ε';

  @override
  String get nfaHelpMessage =>
      'Autômato finito não determinístico — alguns estados têm várias transições para o mesmo símbolo';

  @override
  String get hasEpsilonTransitions => 'Possui transições ε (épsilon)';

  @override
  String get nondeterministicStates => 'Estados não determinísticos:';

  @override
  String get symbolsWithMultipleTransitions =>
      'Símbolos com várias transições:';

  @override
  String get allTransitionsDeterministic =>
      'Todas as transições são determinísticas';

  @override
  String get parser => 'Analisador';

  @override
  String get editGrammar => 'Editar gramática';

  @override
  String get transformationSteps => 'Passos de transformação';

  @override
  String get applyGrammarStep =>
      'Aplicar a gramática produzida por este passo.';

  @override
  String get apply => 'Aplicar';

  @override
  String get noProductions => '(sem produções)';

  @override
  String get beforeAfter => 'Antes / Depois';

  @override
  String challengesCompleted(int completed, int total) {
    return '$completed / $total desafios concluídos';
  }

  @override
  String get score => 'Pontuação';

  @override
  String get completeSomeChallengesHint =>
      'Conclua alguns desafios para ver o progresso aqui';

  @override
  String get correctShort => 'Correto';

  @override
  String get equivalent => 'EQUIVALENTES';

  @override
  String get notEquivalent => 'NÃO EQUIVALENTES';

  @override
  String get automatonA => 'Autômato A';

  @override
  String get automatonB => 'Autômato B';

  @override
  String get distinguishingStringFound => 'Cadeia distintiva encontrada';

  @override
  String get emptyStringEpsilon => 'ε (cadeia vazia)';

  @override
  String get emptyStringLambda => 'λ (cadeia vazia)';

  @override
  String get settingsEmptyStringNotationTitle => 'Notação da cadeia vazia';

  @override
  String get settingsEmptyStringNotationDescription =>
      'Escolha se a interface mostra a cadeia vazia e as transições vazias como ε ou λ.';

  @override
  String get distinguishingStringExplanation =>
      'Esta cadeia é aceita por um autômato e rejeitada pelo outro, o que prova que eles reconhecem linguagens diferentes.';

  @override
  String get statesA => 'Estados (A)';

  @override
  String get statesB => 'Estados (B)';

  @override
  String get transitionsA => 'Transições (A)';

  @override
  String get transitionsB => 'Transições (B)';

  @override
  String get productAutomaton => 'Autômato produto';

  @override
  String get optional => 'Opcional';

  @override
  String get algorithmSteps => 'Passos do algoritmo';

  @override
  String stepsCount(int count) {
    return '$count passos';
  }

  @override
  String stepNavigationPosition(int current, int total) {
    return '$current / $total';
  }

  @override
  String get collapseSidebar => 'Recolher barra lateral';

  @override
  String get info => 'Informações';

  @override
  String get untitledAutomaton => 'Autômato sem título';

  @override
  String get canvasPda => 'AP do canvas';

  @override
  String get canvasTm => 'MT do canvas';

  @override
  String get automatonHasNoStates => 'O autômato não possui estados';

  @override
  String get cannotSimulateEmptyAutomaton =>
      'Não é possível simular um autômato vazio';

  @override
  String get pdaHasNoStates => 'O AP não possui estados';

  @override
  String get tmHasNoStates => 'A MT não possui estados';

  @override
  String get automatonMustHaveAtLeastOneState =>
      'O autômato deve ter pelo menos um estado';

  @override
  String get cannotConvertEmptyAutomatonToRegex =>
      'Não é possível converter um autômato vazio em expressão regular';

  @override
  String get faMustHaveAtLeastOneState => 'O AF deve ter pelo menos um estado';

  @override
  String get nfaMustHaveAtLeastOneState =>
      'O AFN deve ter pelo menos um estado';

  @override
  String get dfaMustHaveAtLeastOneState =>
      'O AFD deve ter pelo menos um estado';

  @override
  String get pdaMustHaveAtLeastOneState => 'O AP deve ter pelo menos um estado';

  @override
  String get tmMustHaveAtLeastOneState =>
      'A máquina de Turing deve ter pelo menos um estado';

  @override
  String get tmMustHaveAtLeastOneStatePeriod =>
      'A máquina de Turing deve ter pelo menos um estado.';

  @override
  String get automatonAMustHaveAtLeastOneState =>
      'O autômato A deve ter pelo menos um estado';

  @override
  String get automatonBMustHaveAtLeastOneState =>
      'O autômato B deve ter pelo menos um estado';

  @override
  String get cannotCreateGameWithEmptyAutomaton =>
      'Não é possível criar o jogo com um autômato vazio';

  @override
  String get nfaToDfaTitle => 'AFN para AFD';

  @override
  String get nfaToDfaDescription =>
      'Converter autômato não determinístico em determinístico';

  @override
  String get removeLambdaTitle => 'Remover transições ε';

  @override
  String get removeLambdaDescription =>
      'Eliminar transições epsilon do autômato';

  @override
  String get minimizeDfaTitle => 'Minimizar AFD';

  @override
  String get minimizeDfaDescription =>
      'Minimizar o autômato finito determinístico';

  @override
  String get completeDfaTitle => 'Completar AFD';

  @override
  String get completeDfaDescription =>
      'Adicionar estado armadilha para completar o AFD';

  @override
  String get complementDfaTitle => 'Complemento do AFD';

  @override
  String get complementDfaDescription =>
      'Inverter estados de aceitação após completar';

  @override
  String get unionOfDfasTitle => 'União de AFDs';

  @override
  String get unionOfDfasDescription =>
      'Combinar este AFD com outro autômato de um arquivo';

  @override
  String get concatenationOfFsasTitle => 'Concatenação de AFs';

  @override
  String get concatenationOfFsasDescription =>
      'Anexar a linguagem de outro autômato usando transições ε';

  @override
  String get kleeneStarTitle => 'Estrela de Kleene';

  @override
  String get kleeneStarDescription =>
      'Aceitar zero ou mais repetições da linguagem deste AF';

  @override
  String get reverseFsaTitle => 'Reverso do AF';

  @override
  String get reverseFsaDescription =>
      'Aceitar o reverso de cada palavra desta linguagem';

  @override
  String get intersectionOfDfasTitle => 'Interseção de AFDs';

  @override
  String get intersectionOfDfasDescription =>
      'Interseccionar este AFD com outro autômato de um arquivo';

  @override
  String get differenceOfDfasTitle => 'Diferença de AFDs';

  @override
  String get differenceOfDfasDescription =>
      'Calcular a diferença de linguagens com outro AFD de um arquivo';

  @override
  String get prefixClosureTitle => 'Fecho por prefixos';

  @override
  String get prefixClosureDescription =>
      'Aceitar todos os prefixos da linguagem do AFD';

  @override
  String get suffixClosureTitle => 'Fecho por sufixos';

  @override
  String get suffixClosureDescription =>
      'Aceitar todos os sufixos da linguagem do AFD';

  @override
  String get faToRegexTitle => 'AF para expressão regular';

  @override
  String get faToRegexDescription =>
      'Converter autômato finito em expressão regular';

  @override
  String get fsaToGrammarTitle => 'AF para gramática';

  @override
  String get fsaToGrammarDescription =>
      'Converter autômato finito em gramática regular';

  @override
  String get autoLayoutTitle => 'Layout automático';

  @override
  String get autoLayoutDescription => 'Organizar estados em um círculo';

  @override
  String get automatonLayoutButtonSemantics => 'Organizar estados do autômato';

  @override
  String get automatonLayoutButtonHint =>
      'Visualize layouts e transformações determinísticos do grafo';

  @override
  String get automatonLayoutButtonTooltip => 'Organizar estados';

  @override
  String get automatonLayoutCannotArrange =>
      'Não foi possível organizar os estados';

  @override
  String get automatonLayoutApplyFailed => 'Não foi possível aplicar o layout.';

  @override
  String get automatonLayoutPreviewFailed => 'Falha na prévia do layout.';

  @override
  String get automatonLayoutDocumentChanged =>
      'O documento foi alterado enquanto a prévia do layout estava aberta.';

  @override
  String get automatonLayoutAnnotationsChanged =>
      'As anotações do documento foram alteradas enquanto a prévia do layout estava aberta.';

  @override
  String get automatonLayoutChoosePreview =>
      'Escolha um layout determinístico. As alterações permanecem como prévia até serem aplicadas.';

  @override
  String get automatonLayoutLabel => 'Layout';

  @override
  String get automatonLayoutApplyTo => 'Aplicar a';

  @override
  String get automatonLayoutCircle => 'Círculo';

  @override
  String get automatonLayoutTwoCircles => 'Dois círculos';

  @override
  String get automatonLayoutSpiral => 'Espiral';

  @override
  String get automatonLayoutHierarchical => 'Hierárquico';

  @override
  String get automatonLayoutSugiyama => 'Sugiyama em camadas';

  @override
  String get automatonLayoutPackComponents => 'Agrupar componentes';

  @override
  String get automatonLayoutSeededForce =>
      'Direcionado por forças (com semente)';

  @override
  String get automatonLayoutSeededRandom => 'Aleatório (com semente)';

  @override
  String get automatonLayoutReflectHorizontal => 'Refletir horizontalmente';

  @override
  String get automatonLayoutReflectVertical => 'Refletir verticalmente';

  @override
  String get automatonLayoutRotate90 => 'Girar 90 graus';

  @override
  String get automatonLayoutRotate180 => 'Girar 180 graus';

  @override
  String get automatonLayoutRotate270 => 'Girar 270 graus';

  @override
  String get automatonLayoutFitViewport => 'Ajustar à área visível';

  @override
  String get automatonLayoutFillViewport => 'Preencher a área visível';

  @override
  String get automatonLayoutRestoreSaved => 'Restaurar layout salvo';

  @override
  String get automatonLayoutAllStates => 'Todos os estados';

  @override
  String get automatonLayoutSelectedComponent => 'Componente selecionado';

  @override
  String get automatonLayoutSelectedStates => 'Estados selecionados';

  @override
  String get automatonLayoutKeepSelected =>
      'Manter os estados selecionados no lugar';

  @override
  String get automatonLayoutRootState => 'Estado raiz';

  @override
  String get automatonLayoutAutomatic => 'Automático';

  @override
  String get automatonLayoutSeed => 'Semente';

  @override
  String get automatonLayoutSeedHelp =>
      'A mesma semente produz o mesmo layout.';

  @override
  String get automatonLayoutTransformFreeNotes =>
      'Transformar notas livres com o grafo';

  @override
  String get automatonLayoutAttachedNotesHelp =>
      'Notas anexadas sempre acompanham seu estado ou transição.';

  @override
  String get automatonLayoutApply => 'Aplicar layout';

  @override
  String get automatonLayoutPreparingPreview => 'Preparando prévia';

  @override
  String get automatonLayoutValidatingGraph => 'Validando grafo';

  @override
  String get automatonLayoutComputing => 'Calculando layout';

  @override
  String get automatonLayoutMeasuring => 'Medindo resultado';

  @override
  String get automatonLayoutComplete => 'Concluído';

  @override
  String get automatonLayoutEmptyGraph => 'O grafo não tem nós para organizar.';

  @override
  String get automatonLayoutInvalidTopology =>
      'Os IDs de nós e arestas devem ser únicos e não vazios, e cada extremidade de aresta deve referenciar um nó.';

  @override
  String get automatonLayoutInvalidPosition =>
      'Toda posição de nó de entrada deve ser finita.';

  @override
  String get automatonLayoutInvalidBounds =>
      'Os limites e espaçamentos do layout devem ser finitos e positivos.';

  @override
  String get automatonLayoutCoordinatesClamped =>
      'Coordenadas extremas do layout foram limitadas a valores seguros.';

  @override
  String get automatonLayoutDenseGraph =>
      'Este é um grafo denso; as métricas de cruzamento são heurísticas.';

  @override
  String get automatonLayoutSelectNode =>
      'Selecione pelo menos um nó para o layout de nós selecionados.';

  @override
  String get automatonLayoutSelectComponent =>
      'Selecione um nó cujo componente conexo será organizado.';

  @override
  String get automatonLayoutNoRestore =>
      'Nenhum layout manual ou anterior salvo está disponível para restauração.';

  @override
  String get automatonLayoutCancelled => 'O cálculo do layout foi cancelado.';

  @override
  String automatonLayoutSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selecionados',
      one: '1 selecionado',
    );
    return '$_temp0';
  }

  @override
  String automatonLayoutStateSpacing(int spacing) {
    return 'Espaçamento entre estados: $spacing';
  }

  @override
  String automatonLayoutLayerSpacing(int spacing) {
    return 'Espaçamento entre camadas: $spacing';
  }

  @override
  String automatonLayoutForceIteration(int current, int total) {
    return 'Iteração de forças $current de $total';
  }

  @override
  String automatonLayoutProgressStatus(String stage, int percent) {
    return '$stage, $percent por cento';
  }

  @override
  String automatonLayoutResultSummary(
    int nodeCount,
    int componentCount,
    int overlapCount,
    String crossingMeasurement,
    int edgeCrossingCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      nodeCount,
      locale: localeName,
      other: '$nodeCount estados',
      one: '1 estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      componentCount,
      locale: localeName,
      other: '$componentCount componentes',
      one: '1 componente',
    );
    String _temp2 = intl.Intl.pluralLogic(
      overlapCount,
      locale: localeName,
      other: '$overlapCount sobreposições',
      one: '1 sobreposição',
    );
    String _temp3 = intl.Intl.pluralLogic(
      edgeCrossingCount,
      locale: localeName,
      other: '$edgeCrossingCount cruzamentos de arestas',
      one: '1 cruzamento de arestas',
    );
    String _temp4 = intl.Intl.selectLogic(crossingMeasurement, {
      'measured': '$_temp3',
      'notMeasured': 'cruzamentos de arestas não medidos',
      'other': 'cruzamentos de arestas não medidos',
    });
    return '$_temp0, $_temp1, $_temp2, $_temp4.';
  }

  @override
  String automatonLayoutArrangedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estados organizados. Desfazer restaura o layout anterior.',
      one: '1 estado organizado. Desfazer restaura o layout anterior.',
    );
    return '$_temp0';
  }

  @override
  String automatonLayoutUnsupportedVersion(int version) {
    return 'A versão $version do algoritmo de layout não é compatível.';
  }

  @override
  String automatonLayoutResourceLimit(
    int nodeCount,
    int maximumNodes,
    int edgeCount,
    int maximumEdges,
  ) {
    return 'O grafo excede o limite de layout configurado ($nodeCount/$maximumNodes nós, $edgeCount/$maximumEdges arestas).';
  }

  @override
  String automatonLayoutNonFiniteCoordinate(String nodeId) {
    return 'O layout produziu uma coordenada não finita para $nodeId.';
  }

  @override
  String automatonLayoutOverlapsRemain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Restam $count possíveis sobreposições de nós; revise a prévia antes de aplicar.',
      one:
          'Resta 1 possível sobreposição de nós; revise a prévia antes de aplicar.',
    );
    return '$_temp0';
  }

  @override
  String get compareEquivalenceDescription =>
      'Comparar dois AFDs quanto à equivalência';

  @override
  String get clearAutomatonDescription => 'Limpar o autômato atual';

  @override
  String get regexToNfaTitle => 'Expressão regular para AFN';

  @override
  String get regexExampleHint => 'ex.: (a|b)*';

  @override
  String get convertToCnfTitle => 'Converter para FNC';

  @override
  String get convertToCnfDescription =>
      'Converter gramática para a Forma Normal de Chomsky';

  @override
  String get convertToGnfTitle => 'Converter para FNG';

  @override
  String get convertToGnfDescription =>
      'Converter gramática para a Forma Normal de Greibach';

  @override
  String get removeLeftRecursionTitle => 'Remover recursão à esquerda';

  @override
  String get removeLeftRecursionDescription =>
      'Eliminar recursão direta e indireta à esquerda';

  @override
  String get leftFactorTitle => 'Fatorar à esquerda';

  @override
  String get leftFactorDescription =>
      'Aplicar fatoração à esquerda à gramática';

  @override
  String get findFirstSetsTitle => 'Calcular conjuntos FIRST';

  @override
  String get findFirstSetsDescription =>
      'Calcular conjuntos FIRST de todas as variáveis';

  @override
  String get findFollowSetsTitle => 'Calcular conjuntos FOLLOW';

  @override
  String get findFollowSetsDescription =>
      'Calcular conjuntos FOLLOW de todas as variáveis';

  @override
  String get buildParseTableTitle => 'Construir tabela de análise';

  @override
  String get buildParseTableDescription =>
      'Gerar uma tabela de análise preditiva LL(1)';

  @override
  String get checkAmbiguityTitle => 'Verificar ambiguidade';

  @override
  String get checkAmbiguityDescription => 'Detectar se a gramática é ambígua';

  @override
  String get convertRightLinearToFsaTitle =>
      'Converter gramática linear à direita em AF';

  @override
  String get convertRightLinearToFsaDescription =>
      'Construir um AF a partir de uma gramática linear à direita';

  @override
  String get convertGrammarToPdaGeneralTitle =>
      'Converter gramática em AP (geral)';

  @override
  String get convertGrammarToPdaGeneralDescription =>
      'Construir um AP equivalente a partir da gramática';

  @override
  String get convertGrammarToPdaStandardTitle =>
      'Converter gramática em AP (padrão)';

  @override
  String get convertGrammarToPdaStandardDescription =>
      'Construir um AP em forma padrão a partir da gramática';

  @override
  String get convertGrammarToPdaGreibachTitle =>
      'Converter gramática em AP (Greibach)';

  @override
  String get convertGrammarToPdaGreibachDescription =>
      'Construir um AP em forma de Greibach a partir da gramática';

  @override
  String get leftRecursionRemovalResultTitle =>
      'Remoção de recursão à esquerda direta e indireta';

  @override
  String get leftFactoringAnalysisTitle => 'Análise de fatoração à esquerda';

  @override
  String get firstSetsAnalysisTitle => 'Análise dos conjuntos FIRST';

  @override
  String get followSetsAnalysisTitle => 'Análise dos conjuntos FOLLOW';

  @override
  String get cnfConversionTitle =>
      'Conversão para Forma Normal de Chomsky (FNC)';

  @override
  String get gnfConversionTitle =>
      'Conversão para Forma Normal de Greibach (FNG)';

  @override
  String get convertToCfgTitle => 'Converter para GLC';

  @override
  String get convertToCfgDescription =>
      'Converter AP em gramática livre de contexto equivalente';

  @override
  String get checkDeterminismTitle => 'Verificar determinismo';

  @override
  String get checkDeterminismDescription =>
      'Determinar se o AP é determinístico';

  @override
  String get findReachableStatesTitle => 'Encontrar estados alcançáveis';

  @override
  String get findReachableStatesDescription =>
      'Identificar estados alcançáveis a partir do estado inicial';

  @override
  String get languageAnalysisTitle => 'Análise da linguagem';

  @override
  String get languageAnalysisDescription =>
      'Provar vacuidade e encontrar uma palavra aceita mais curta';

  @override
  String get stackOperationsTitle => 'Operações da pilha';

  @override
  String get stackOperationsDescription =>
      'Analisar operações e profundidade da pilha';

  @override
  String get pdaIsDeterministic =>
      'Resultado: o AP é determinístico (sem transições conflitantes).';

  @override
  String get pdaIsNondeterministic => 'Resultado: o AP NÃO é determinístico.';

  @override
  String get conflictingTransitions => 'Transições conflitantes:';

  @override
  String lambdaTransitionsPresent(int count) {
    return 'Transições ε presentes: $count';
  }

  @override
  String totalTransitionsCount(int count) {
    return 'Total de transições: $count';
  }

  @override
  String reachableStatesCount(int count) {
    return 'Estados alcançáveis ($count):';
  }

  @override
  String unreachableStatesCount(int count) {
    return 'Estados inalcançáveis ($count):';
  }

  @override
  String get languageIsEmptyProved => 'A linguagem é vazia (provado).';

  @override
  String get languageIsNonEmptyProved => 'A linguagem é não vazia (provado).';

  @override
  String acceptanceModeLabel(String mode) {
    return 'Modo de aceitação: $mode';
  }

  @override
  String get acceptanceModeFinalState => 'estado final';

  @override
  String get acceptanceModeEmptyStack => 'pilha vazia';

  @override
  String get acceptanceModeBoth => 'estado final e pilha vazia';

  @override
  String get pdaEmptinessProofLine =>
      'Prova: normalização do AP ciente do modo → ponto fixo de produtividade da GLC.';

  @override
  String productiveNonterminalsCount(int count) {
    return 'Não terminais produtivos: $count';
  }

  @override
  String shortestWitness(String witness) {
    return 'Testemunha mais curta: $witness';
  }

  @override
  String terminalSymbolLength(int length) {
    return 'Comprimento em símbolos terminais: $length (terminais com vários caracteres contam como um símbolo).';
  }

  @override
  String get equalLengthShortlex =>
      'Empates de mesmo comprimento usam ordem shortlex determinística.';

  @override
  String get leftmostCfgDerivation => 'Derivação mais à esquerda da GLC:';

  @override
  String moreDerivationSteps(int count) {
    return '  … mais $count passo(s)';
  }

  @override
  String emptinessProofUnavailable(String message) {
    return 'Prova de vacuidade indisponível: $message\nNenhuma conclusão sobre a vacuidade da linguagem foi feita.';
  }

  @override
  String get createPdaToAnalyzeDeterminism =>
      'Crie um AP para analisar o determinismo.';

  @override
  String get createPdaToAnalyzeReachability =>
      'Crie um AP para analisar a alcançabilidade.';

  @override
  String initialStateWithLabel(String label) {
    return 'Estado inicial: $label';
  }

  @override
  String initialStackSymbolWithValue(String symbol) {
    return 'Símbolo inicial da pilha: $symbol';
  }

  @override
  String get grammarAnalysisTitle => 'Análise da gramática';

  @override
  String get classifyGrammarTitle => 'Classificar gramática';

  @override
  String get classifyGrammarDescription =>
      'Infere a classe estrutural mais forte e mostra evidências das restrições que falharam.';

  @override
  String get copyClassificationReport => 'Copiar relatório de classificação';

  @override
  String get classificationReportCopied =>
      'Relatório de classificação copiado.';

  @override
  String get updateDeclaredGrammarType => 'Atualizar tipo declarado';

  @override
  String get updateDeclaredGrammarTypeTitle =>
      'Atualizar metadados da gramática?';

  @override
  String updateDeclaredGrammarTypeMessage(String type) {
    return 'Alterar o tipo declarado para $type? As produções não serão modificadas.';
  }

  @override
  String get grammarStructureNotLanguageClass =>
      'Este resultado classifica a gramática escrita, não a classe mínima de sua linguagem.';

  @override
  String get declaredGrammarType => 'Tipo declarado';

  @override
  String get inferredGrammarType => 'Tipo inferido';

  @override
  String get pdaAnalysisTitle => 'Análise do AP';

  @override
  String get noAnalysisResultsYet => 'Nenhum resultado de análise';

  @override
  String get selectAlgorithmToAnalyzePda =>
      'Selecione um algoritmo acima para analisar seu AP';

  @override
  String get selectAlgorithmToAnalyzeGrammar =>
      'Selecione um algoritmo acima para analisar sua gramática';

  @override
  String get selectAlgorithmToAnalyzeTm =>
      'Selecione um algoritmo acima para analisar sua MT.';

  @override
  String get addAtLeastOneProductionRule =>
      'Adicione ao menos uma regra de produção para habilitar as conversões.';

  @override
  String get convertingToFsa => 'Convertendo para AF...';

  @override
  String get convertingToPda => 'Convertendo para AP...';

  @override
  String get convertingStandard => 'Convertendo (padrão)...';

  @override
  String get convertingGreibach => 'Convertendo (Greibach)...';

  @override
  String get parseString => 'Analisar cadeia';

  @override
  String get noParseResultsYet => 'Nenhum resultado de análise';

  @override
  String get enterAStringAndClickParse =>
      'Informe uma cadeia e ative Analisar para ver os resultados';

  @override
  String get terminationAndCyclesTitle => 'Término e ciclos';

  @override
  String get terminationAndCyclesDescription =>
      'Classifique uma entrada com limites explícitos de execução';

  @override
  String get reachabilityTitle => 'Alcançabilidade';

  @override
  String get reachabilityDescription =>
      'Compare alcançabilidade estrutural com testemunhos limitados';

  @override
  String get languageExplorerTitle => 'Explorador de linguagem';

  @override
  String get languageExplorerDescription =>
      'Classifique uma amostra shortlex limitada em quatro resultados';

  @override
  String get tapeTraceTitle => 'Traço da fita';

  @override
  String get tapeTraceDescription =>
      'Meça operações em um ramo concreto de execução';

  @override
  String get timeProfileTitle => 'Perfil de tempo';

  @override
  String get timeProfileDescription =>
      'Meça passos de transição por comprimento de entrada dentro dos limites';

  @override
  String get spaceProfileTitle => 'Perfil de espaço';

  @override
  String get spaceProfileDescription =>
      'Meça o uso limitado de células da fita por comprimento da entrada';

  @override
  String get determinismCheckTitle => 'Verificação de determinismo';

  @override
  String get reachableStatesAnalysisTitle => 'Análise de estados alcançáveis';

  @override
  String get pdaToCfgConversionTitle => 'Conversão de AP para GLC';

  @override
  String pdaConversionFailure(String error) {
    return 'Falha na conversão: $error';
  }

  @override
  String get pdaConversionCanceledDocumentUnchanged =>
      'Conversão cancelada. O AP do editor não foi alterado.';

  @override
  String get pdaConversionCanceledPanelClosed =>
      'Conversão cancelada porque o painel foi fechado.';

  @override
  String get pdaConversionCanceledEditorChanged =>
      'Conversão cancelada porque o AP do editor mudou durante a revisão.';

  @override
  String pdaNormalizationAppliedSummary(
    int beforeStates,
    int afterStates,
    int beforeTransitions,
    int afterTransitions,
  ) {
    return 'Normalização aplicada: $beforeStates → $afterStates estados, $beforeTransitions → $afterTransitions transições.';
  }

  @override
  String pdaGeneratedGrammarSummary(int productions, int nonterminals) {
    return 'A gramática gerada possui $productions produções e $nonterminals não terminais.';
  }

  @override
  String get pdaToCfgInvalidProductionLimit =>
      'O limite de produções da conversão de AP para GLC deve ser maior que zero.';

  @override
  String get pdaToCfgCancelled => 'A conversão de AP para GLC foi cancelada.';

  @override
  String get pdaToCfgEmptyPda =>
      'Não é possível converter um AP vazio em uma gramática.';

  @override
  String get pdaToCfgMissingInitialState =>
      'O AP deve definir um estado inicial antes da conversão.';

  @override
  String get pdaToCfgInitialStateOutsideSet =>
      'O estado inicial do AP deve pertencer ao conjunto de estados do AP antes da conversão.';

  @override
  String get pdaToCfgMissingAcceptingState =>
      'O AP deve ter pelo menos um estado de aceitação para a conversão.';

  @override
  String get pdaToCfgAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao conjunto de estados do AP antes da conversão.';

  @override
  String pdaToCfgEpsilonPop(String transition) {
    return 'A conversão de AP para GLC exige que cada transição remova exatamente um símbolo da pilha. A transição $transition usa uma remoção ε. Normalize o AP antes da conversão.';
  }

  @override
  String pdaToCfgProductionLimit(int limit) {
    return 'A conversão de AP para GLC parou no limite de $limit produções.';
  }

  @override
  String get pdaToCfgNoProductions =>
      'Nenhuma produção pôde ser gerada para este AP.';

  @override
  String get stackOperationsAnalysisTitle => 'Análise de operações da pilha';

  @override
  String get createPdaToAnalyzeLanguage =>
      'Crie um AP para analisar a linguagem.';

  @override
  String get createPdaToInspectStack =>
      'Crie um AP para inspecionar as operações da pilha.';

  @override
  String get shortestWitnessOpened =>
      'Traço da testemunha mais curta aberto no painel do Simulador.';

  @override
  String pushOperationsCount(int count) {
    return 'Operações de empilhar ($count):';
  }

  @override
  String popOperationsCount(int count) {
    return 'Operações de desempilhar ($count):';
  }

  @override
  String stackSymbolsTouched(int count) {
    return 'Símbolos da pilha tocados ($count):';
  }

  @override
  String get noneValue => '  Nenhuma';

  @override
  String pdaTransitionsCount(int pdaCount, int fsaCount) {
    return 'Transições de AP: $pdaCount, transições de AF: $fsaCount';
  }

  @override
  String analysisFailedPrefix(String error) {
    return 'Falha na análise: $error';
  }

  @override
  String errorRunningAnalysis(String error) {
    return 'Erro ao executar a análise: $error';
  }

  @override
  String get repeatedCycleTrace => 'Traço do ciclo repetido';

  @override
  String get relatedExecutionTrace => 'Rastreamento da execução relacionado';

  @override
  String get noInputLengthGroupEvaluated =>
      'Nenhum grupo de comprimento de entrada foi avaliado.';

  @override
  String get noCandidatesEvaluated => 'Nenhuma candidata foi avaliada.';

  @override
  String get noTraceRecordedBoundedRun =>
      'Nenhum traço foi registrado para esta execução limitada.';

  @override
  String get maximumTransitionStepWitness =>
      'Testemunha de máximo de passos de transição';

  @override
  String get maximumExplorationDepthWitness =>
      'Testemunha de profundidade máxima de exploração';

  @override
  String get maximumExploredConfigurationsWitness =>
      'Testemunha de máximo de configurações exploradas';

  @override
  String get noTmAvailableToAnalyze =>
      'Nenhuma máquina de Turing disponível. Desenhe estados e transições no canvas para analisar.';

  @override
  String retainedConfigurations(int count) {
    return '$count configuração(ões) retida(s)';
  }

  @override
  String get initialConfiguration => 'Configuração inicial';

  @override
  String get grammarParserExamplesHint =>
      'Exemplos: aabb, abab, aabbb (para S → aSb | ab)';

  @override
  String get parsingEllipsis => 'Analisando...';

  @override
  String get derivationTree => 'Árvore de derivação';

  @override
  String derivationTreeLeafSemantics(String symbol, int level) {
    return '$symbol, folha no nível $level';
  }

  @override
  String derivationTreeBranchSemantics(
    String symbol,
    int level,
    int childCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      childCount,
      locale: localeName,
      other: '$childCount filhos',
      one: '1 filho',
    );
    return '$symbol, nível $level, $_temp0';
  }

  @override
  String derivationTreesAmbiguous(int count) {
    return 'Árvores de derivação (mostrando as primeiras $count; ambígua)';
  }

  @override
  String get derivationTreeFullscreen =>
      'Mostrar árvore de derivação em tela cheia';

  @override
  String get derivationTreeZoomIn => 'Ampliar';

  @override
  String get derivationTreeZoomOut => 'Reduzir';

  @override
  String get derivationTreeFitToScreen => 'Ajustar à tela';

  @override
  String get derivationTreePanZoomHint =>
      'Arraste para mover; faça pinça ou rolagem para ampliar.';

  @override
  String get cykSteps => 'Passos CYK';

  @override
  String get expectedColon => 'Esperado:';

  @override
  String get failedToParseString => 'Falha ao analisar a cadeia';

  @override
  String failedToParseStringError(String error) {
    return 'Falha ao analisar a cadeia: $error';
  }

  @override
  String executionTimeLabel(String time) {
    return 'Tempo de execução: $time';
  }

  @override
  String farthestPositionLabel(int position, int length) {
    return 'Posição mais distante: $position / $length';
  }

  @override
  String get examplesLabel => 'Exemplos:';

  @override
  String get hintForNextTime => 'Dica para a próxima vez:';

  @override
  String get pngExportNotSupportedOnWeb =>
      'A exportação PNG não é suportada na web.';

  @override
  String get documentsDirectoryNotAvailableOnWeb =>
      'O diretório de documentos não está disponível na web.';

  @override
  String get pumpingChallenge1Description => 'Cadeias somente de a\'s';

  @override
  String get pumpingChallenge1Explanation =>
      'Esta linguagem é regular. Pode ser reconhecida por um autômato simples que aceita qualquer quantidade de a\'s.';

  @override
  String get pumpingChallenge1Hint =>
      'Pense se uma máquina de estados finitos consegue reconhecer este padrão.';

  @override
  String get pumpingChallenge1Proof1 =>
      'Esta é uma linguagem regular porque segue um padrão simples.';

  @override
  String get pumpingChallenge1Proof2 =>
      'Um autômato finito pode aceitá-la com um único estado que faz um laço em \"a\".';

  @override
  String get pumpingChallenge1Proof3 =>
      'A condição do lema do bombeamento é satisfeita porque sempre podemos encontrar cadeias que podem ser bombeadas.';

  @override
  String get pumpingChallenge1Proof4 =>
      'Para qualquer comprimento de bombeamento p, podemos escolher x = ε, y = a^k (1 ≤ k ≤ p), z = a^(n-k) para n ≥ k.';

  @override
  String get pumpingChallenge1Proof5 =>
      'Então xy^iz ∈ L para todo i ≥ 0 porque continua sendo apenas a\'s.';

  @override
  String get pumpingChallenge2Description =>
      'Cadeias com a\'s seguidos de b\'s';

  @override
  String get pumpingChallenge2Explanation =>
      'Esta linguagem é regular. Pode ser reconhecida por um autômato que aceita qualquer quantidade de a\'s seguida de qualquer quantidade de b\'s.';

  @override
  String get pumpingChallenge2Hint =>
      'Considere se isso pode ser reconhecido contando estados ou por uma máquina de estados simples.';

  @override
  String get pumpingChallenge2Proof1 =>
      'Esta linguagem é regular porque as duas partes (a\'s e b\'s) são independentes.';

  @override
  String get pumpingChallenge2Proof2 =>
      'Um autômato finito pode rastrear se já vimos algum b.';

  @override
  String get pumpingChallenge2Proof3 =>
      'Depois que um b é visto, apenas b\'s são aceitos.';

  @override
  String get pumpingChallenge2Proof4 =>
      'O lema do bombeamento é satisfeito porque podemos bombear os a\'s ou os b\'s de forma independente.';

  @override
  String get pumpingChallenge3Description =>
      'Cadeias com o mesmo número de a\'s e b\'s';

  @override
  String get pumpingChallenge3Explanation =>
      'Esta linguagem não é regular. Para qualquer comprimento de bombeamento p, a cadeia a^p b^p pode ser bombeada, mas bombear os a\'s quebra o equilíbrio.';

  @override
  String get pumpingChallenge3Hint =>
      'Tente aplicar o lema do bombeamento com p = 2. O que acontece quando você bombeia?';

  @override
  String get pumpingChallenge3Proof1 =>
      'Esta é uma linguagem clássica não regular.';

  @override
  String get pumpingChallenge3Proof2 =>
      'O lema do bombeamento diz: para qualquer p ≥ 1, existe uma cadeia s = xyz onde |xy| ≤ p, |y| ≥ 1 e xy^iz ∈ L para todo i ≥ 0.';

  @override
  String get pumpingChallenge3Proof3 =>
      'Para s = a^p b^p, podemos escolher x = a^(p-1), y = a, z = b^p.';

  @override
  String get pumpingChallenge3Proof4 =>
      'Então xy^2z = a^(p+1) b^p, que tem mais a\'s do que b\'s, portanto não está em L.';

  @override
  String get pumpingChallenge3Proof5 =>
      'Isso mostra que nenhum autômato finito pode reconhecer esta linguagem.';

  @override
  String get pumpingChallenge4Description =>
      'Cadeias com o mesmo número de a\'s, b\'s e c\'s';

  @override
  String get pumpingChallenge4Explanation =>
      'Esta linguagem não é regular. Exige contar três símbolos diferentes, o que não pode ser feito com memória finita.';

  @override
  String get pumpingChallenge4Hint =>
      'Pense em quantos contadores independentes isso exigiria.';

  @override
  String get pumpingChallenge4Proof1 =>
      'Esta linguagem exige acompanhar três contadores independentes.';

  @override
  String get pumpingChallenge4Proof2 =>
      'Nenhuma máquina de estados finitos consegue acompanhar três contagens simultaneamente.';

  @override
  String get pumpingChallenge4Proof3 =>
      'Usando o lema do bombeamento: escolha uma cadeia com p a\'s, p b\'s e p c\'s.';

  @override
  String get pumpingChallenge4Proof4 =>
      'Bombear os a\'s quebra o equilíbrio entre a\'s, b\'s e c\'s.';

  @override
  String get pumpingChallenge4Proof5 =>
      'Para s = a^p b^p c^p, escolha x = a^(p-1), y = a, z = b^p c^p.';

  @override
  String get pumpingChallenge4Proof6 =>
      'Então xy^2z = a^(p+1) b^p c^p ∉ L porque p+1 ≠ p ≠ p.';

  @override
  String get pumpingChallenge5Description =>
      'Cadeias que são a concatenação de uma palavra consigo mesma';

  @override
  String get pumpingChallenge5Explanation =>
      'Esta linguagem não é regular. Exige lembrar a primeira metade da cadeia para corresponder à segunda, o que requer memória ilimitada.';

  @override
  String get pumpingChallenge5Hint =>
      'O que acontece se você escolher uma cadeia muito longa e tentar aplicar o lema do bombeamento?';

  @override
  String get pumpingChallenge5Proof1 =>
      'Esta linguagem exige lembrar a primeira metade inteira da cadeia.';

  @override
  String get pumpingChallenge5Proof2 =>
      'Por maior que seja o comprimento de bombeamento p, podemos escolher w com comprimento > p.';

  @override
  String get pumpingChallenge5Proof3 =>
      'Para s = ww onde |w| > p, a primeira metade tem comprimento > p.';

  @override
  String get pumpingChallenge5Proof4 =>
      'O lema do bombeamento não encontra uma decomposição adequada que preserve a propriedade.';

  @override
  String get pumpingChallenge5Proof5 =>
      'Esta é a linguagem de cadeias duplicadas, não a de palíndromos; palíndromos são cadeias iguais ao seu reverso.';

  @override
  String get pumpingChallenge6Description => 'Cadeias com número par de a\'s';

  @override
  String get pumpingChallenge6Explanation =>
      'Esta linguagem é regular. Pode ser reconhecida por um autômato finito que acompanha a paridade (número par/ímpar de a\'s).';

  @override
  String get pumpingChallenge6Hint =>
      'Pense em módulo 2 em vez de contar exatamente.';

  @override
  String get pumpingChallenge6Proof1 =>
      'Esta é, na verdade, uma linguagem regular!';

  @override
  String get pumpingChallenge6Proof2 =>
      'Um autômato de 2 estados pode rastrear se vimos um número par ou ímpar de a\'s.';

  @override
  String get pumpingChallenge6Proof3 =>
      'Comece em um estado \"par\", vá para \"ímpar\" a cada \"a\" e volte para \"par\" no próximo \"a\".';

  @override
  String get pumpingChallenge6Proof4 => 'Aceite apenas no estado \"par\".';

  @override
  String get pumpingChallenge6Proof5 =>
      'A ideia-chave é que só precisamos acompanhar a paridade, não a contagem exata.';

  @override
  String get pumpingChallenge7Description =>
      'União de a\'s e b\'s iguais com cadeias somente de a\'s';

  @override
  String get pumpingChallenge7Explanation =>
      'Esta linguagem não é regular, mas isso não se prova apenas apontando um subconjunto. É preciso um argumento do lema do bombeamento ou de propriedades de fechamento.';

  @override
  String get pumpingChallenge7Hint =>
      'Considere o que acontece ao aplicar o lema do bombeamento às cadeias da parte a^n b^n.';

  @override
  String get pumpingChallenge7Proof1 =>
      'Esta linguagem contém uma parte não regular (a^n b^n) e uma parte regular (a^m).';

  @override
  String get pumpingChallenge7Proof2 =>
      'A união de uma linguagem não regular com uma regular pode ou não ser regular.';

  @override
  String get pumpingChallenge7Proof3 =>
      'Encontrar um subconjunto não regular não basta para provar que a linguagem inteira não é regular.';

  @override
  String get pumpingChallenge7Proof4 =>
      'Uma prova válida pode usar o lema do bombeamento diretamente nas cadeias a^p b^p da linguagem mista.';

  @override
  String get pumpingChallenge7Proof5 =>
      'Para s = a^p b^p, o mesmo contraexemplo de antes se aplica.';

  @override
  String get pumpingChallenge8Description => 'Palíndromos sobre o alfabeto a,b';

  @override
  String get pumpingChallenge8Explanation =>
      'Palíndromos não são regulares porque exigem memória ilimitada para verificar a simetria.';

  @override
  String get pumpingChallenge8Hint =>
      'Pense no que acontece com o centro ao bombear um palíndromo longo.';

  @override
  String get pumpingChallenge8Proof1 =>
      'Palíndromos exigem verificar que a cadeia se lê igual de frente para trás e de trás para frente.';

  @override
  String get pumpingChallenge8Proof2 =>
      'Para palíndromos longos, é preciso lembrar a primeira metade para comparar com a segunda.';

  @override
  String get pumpingChallenge8Proof3 =>
      'Usando o lema do bombeamento: para s = a^p b a^p, escolha x = a^(p-1), y = a, z = b a^p.';

  @override
  String get pumpingChallenge8Proof4 =>
      'Então xy^2z = a^(p+1) b a^p, que não é um palíndromo.';

  @override
  String get pumpingChallenge8Proof5 =>
      'O b do meio deixa de ficar centralizado.';

  @override
  String get selectDfaForUnion => 'Selecione o AFD para a união';

  @override
  String get buildingUnionAutomaton => 'Construindo o autômato da união...';

  @override
  String get unionComplete => 'União concluída';

  @override
  String get loadDfaBeforeUnion => 'Carregue um AFD antes de calcular a união.';

  @override
  String get selectFsaForConcatenation => 'Selecione o AF para a concatenação';

  @override
  String get buildingConcatenationNfa => 'Construindo o AFN da concatenação...';

  @override
  String get concatenationComplete => 'Concatenação concluída';

  @override
  String get selectDfaForIntersection => 'Selecione o AFD para a interseção';

  @override
  String get buildingIntersectionAutomaton =>
      'Construindo o autômato da interseção...';

  @override
  String get intersectionComplete => 'Interseção concluída';

  @override
  String get loadDfaBeforeIntersection =>
      'Carregue um AFD antes de calcular a interseção.';

  @override
  String get selectDfaForDifference => 'Selecione o AFD para a diferença';

  @override
  String get buildingDifferenceAutomaton =>
      'Construindo o autômato da diferença...';

  @override
  String get differenceComplete => 'Diferença concluída';

  @override
  String get loadDfaBeforeDifference =>
      'Carregue um AFD antes de calcular a diferença.';

  @override
  String loadDfaBeforeExecuting(String algorithm) {
    return 'Carregue um AFD antes de executar $algorithm.';
  }

  @override
  String get loadDfaBeforeComparingEquivalence =>
      'Carregue um AFD antes de comparar a equivalência.';

  @override
  String get selectDfaToCompare => 'Selecione o AFD para comparar';

  @override
  String errorOpeningAutomatonFilePicker(String error) {
    return 'Não foi possível abrir o seletor de arquivos do autômato: $error';
  }

  @override
  String get loadingAutomatonEllipsis => 'Carregando autômato...';

  @override
  String get failedToLoadAutomatonStatus => 'Falha ao carregar o autômato';

  @override
  String get selectedFileUnreadable =>
      'O arquivo selecionado não continha dados legíveis.';

  @override
  String algorithmFailedStatus(String algorithm) {
    return '$algorithm falhou';
  }

  @override
  String algorithmFailedError(String algorithm, String error) {
    return '$algorithm falhou: $error';
  }

  @override
  String get comparingAutomata => 'Comparando autômatos...';

  @override
  String get languageComparisonTitle => 'Comparação de linguagens';

  @override
  String get currentAutomatonTitle => 'Autômato atual';

  @override
  String get comparedAutomatonTitle => 'Autômato comparado';

  @override
  String get grammarConvertedToAutomaton =>
      'Gramática convertida em autômato. Área de trabalho do AF aberta.';

  @override
  String get grammarConvertedToPdaGeneral =>
      'Gramática convertida em AP (geral). Área de trabalho do AP aberta.';

  @override
  String get grammarConvertedToPdaStandard =>
      'Gramática convertida em AP (padrão). Área de trabalho do AP aberta.';

  @override
  String get grammarConvertedToPdaGreibach =>
      'Gramática convertida em AP (Greibach). Área de trabalho do AP aberta.';

  @override
  String get failedToConvertGrammarToAutomaton =>
      'Falha ao converter a gramática em autômato.';

  @override
  String get failedToConvertGrammarToPda =>
      'Falha ao converter a gramática em AP.';

  @override
  String get originalGrammarLabel => 'Gramática original:';

  @override
  String get transformedGrammarLabel => 'Gramática transformada:';

  @override
  String get notesSection => 'Observações';

  @override
  String get derivationsSection => 'Derivações';

  @override
  String get conflictsSection => 'Conflitos';

  @override
  String get cnfConversionNote =>
      'Gramática convertida para a Forma Normal de Chomsky (FNC) com um pipeline de passos.';

  @override
  String get cnfRulesNote =>
      'Regras da FNC: A→BC (dois não terminais) ou A→a (um terminal).';

  @override
  String get gnfConversionNote =>
      'Gramática convertida para a Forma Normal de Greibach (FNG).';

  @override
  String get gnfRulesNote =>
      'Regras da FNG: A→aα (terminal seguido de não terminais).';

  @override
  String get diagnosticsHeading => 'Diagnósticos:';

  @override
  String cannotRunDueToValidation(String algorithm) {
    return 'Não é possível executar $algorithm devido a erros de validação da gramática';
  }

  @override
  String get ll1ParseTableAnalysis => 'Análise da tabela LL(1)';

  @override
  String get ll1NoConflicts => 'LL(1) (sem conflitos)';

  @override
  String get notLl1Conflicts => 'Não é LL(1) (há conflitos)';

  @override
  String get ll1Classification => 'Classificação LL(1)';

  @override
  String classificationLabel(String status) {
    return 'Classificação: $status';
  }

  @override
  String get cnfConversionFailed => 'Falha na conversão para FNC.';

  @override
  String scoreLabel(int score) {
    return 'Pontuação: $score';
  }

  @override
  String streakLabel(int count) {
    return 'Sequência: $count';
  }

  @override
  String challengeProgress(int current, int total) {
    return 'Desafio $current/$total';
  }

  @override
  String get finalScore => 'Pontuação final';

  @override
  String get learningProgress => 'Progresso de aprendizagem:';

  @override
  String get regularLanguagesTitle => 'Linguagens regulares';

  @override
  String get regularLanguagesProgressDesc =>
      'Você compreende padrões básicos de linguagens regulares';

  @override
  String get pumpingLemmaApplicationTitle => 'Aplicação do lema do bombeamento';

  @override
  String get pumpingLemmaApplicationDesc =>
      'Você consegue identificar quando as linguagens não são regulares';

  @override
  String get advancedPatternsTitle => 'Padrões avançados';

  @override
  String get advancedPatternsProgressDesc =>
      'Você reconhece linguagens não regulares complexas';

  @override
  String get pumpingPerformanceOutstanding =>
      'Excelente! Você dominou o lema do bombeamento e identifica linguagens regulares e não regulares com confiança. Você compreende os fundamentos teóricos e aplica o lema corretamente para provar a não regularidade.';

  @override
  String get pumpingPerformanceExcellent =>
      'Ótimo trabalho! Você tem uma compreensão sólida do lema do bombeamento. Identifica a maioria das linguagens regulares e não regulares, e sua aplicação do lema é em geral correta.';

  @override
  String get pumpingPerformanceGood =>
      'Bom progresso! Você está formando uma base sólida no lema do bombeamento. Consegue identificar padrões básicos e está aprendendo a aplicar o lema de forma sistemática. Continue praticando.';

  @override
  String get pumpingPerformanceFirstSteps =>
      'Você está dando os primeiros passos no lema do bombeamento. É um conceito exigente e pede prática. Foque na técnica básica de prova e em identificar quando a linguagem exige memória ilimitada.';

  @override
  String get pumpingDifficultyEasy => 'FÁCIL';

  @override
  String get pumpingDifficultyMedium => 'MÉDIO';

  @override
  String get pumpingDifficultyHard => 'DIFÍCIL';

  @override
  String evaluatedOf(int evaluated, int total) {
    return 'Avaliadas $evaluated de $total';
  }

  @override
  String get estimatedCandidatesInvalid =>
      'Candidatas estimadas: limites inválidos';

  @override
  String estimatedCandidatesScheduled(String requested, String scheduled) {
    return 'Candidatas estimadas: $requested; agendadas: $scheduled';
  }

  @override
  String stepStateTitle(int step, String state) {
    return 'Passo $step • $state';
  }

  @override
  String headTapeSubtitle(int head, String tape) {
    return 'cabeçote $head • fita $tape';
  }

  @override
  String initialConfigurationAtHead(int head) {
    return 'Configuração inicial no cabeçote $head';
  }

  @override
  String inputRetainedConfigurations(String input, int count) {
    return 'Entrada $input • $count configuração(ões) retida(s)';
  }

  @override
  String get words => 'Palavras';

  @override
  String transitionsConfigurationsProgress(
    int transitions,
    int configurations,
  ) {
    return '$transitions transição(ões) • $configurations configuração(ões) exploradas';
  }

  @override
  String get explorationCancelledKept =>
      'Exploração cancelada. Os resultados avaliados foram mantidos.';

  @override
  String get spaceProfilingCancelledKept =>
      'Perfil de espaço cancelado. As linhas avaliadas foram mantidas.';

  @override
  String get interoperabilityImportReviewTitle => 'Revisar importação';

  @override
  String get interoperabilityExportReviewTitle => 'Revisar exportação';

  @override
  String get interoperabilityReviewPrompt =>
      'Confira o documento detectado e o relatório de compatibilidade antes de continuar.';

  @override
  String get interoperabilityFileLabel => 'Arquivo';

  @override
  String get interoperabilityTypeLabel => 'Tipo';

  @override
  String get interoperabilityFormatLabel => 'Formato';

  @override
  String get interoperabilityVersionLabel => 'Versão';

  @override
  String get interoperabilityFidelityLabel => 'Fidelidade';

  @override
  String get interoperabilityFidelityExact => 'Exata';

  @override
  String get interoperabilityFidelityNormalized => 'Normalizada';

  @override
  String get interoperabilityFidelityLossy => 'Perda de dados';

  @override
  String get interoperabilityChangesTitle => 'Relatório por campo';

  @override
  String get interoperabilityLossyImportWarning =>
      'Alguns dados de origem não podem ser representados e serão perdidos se você substituir o documento atual.';

  @override
  String get interoperabilityLossyExportWarning =>
      'Alguns dados do documento não podem ser representados neste formato e serão omitidos do arquivo exportado.';

  @override
  String get interoperabilityReplaceDocument => 'Substituir documento';

  @override
  String get interoperabilityExportDocument => 'Exportar arquivo';

  @override
  String get interoperabilityImportWithLoss => 'Importar com perda de dados';

  @override
  String get interoperabilityExportWithLoss => 'Exportar com perda de dados';

  @override
  String interoperabilityDiagnosticPath(String path) {
    return 'Caminho: $path';
  }

  @override
  String interoperabilityDiagnosticLineColumn(int line, int column) {
    return 'Linha $line, coluna $column';
  }

  @override
  String interoperabilityDiagnosticLine(int line) {
    return 'Linha $line';
  }

  @override
  String get interoperabilityDiagnosticPreserved => 'Campo preservado';

  @override
  String get interoperabilityDiagnosticNormalized => 'Campo normalizado';

  @override
  String get interoperabilityDiagnosticDropped => 'Campo omitido';

  @override
  String get interoperabilityDiagnosticSourceValueRecorded =>
      'Valor de origem registrado, mas oculto por privacidade';

  @override
  String interoperabilityDiagnosticTechnicalCode(String code) {
    return 'Código de diagnóstico: $code';
  }

  @override
  String get interoperabilityUnsupportedTitle => 'Documento não compatível';

  @override
  String get interoperabilityAmbiguousTitle => 'O tipo do documento é ambíguo';

  @override
  String get interoperabilityMalformedTitle =>
      'Não foi possível ler o documento';

  @override
  String get interoperabilityResourceLimitTitle =>
      'O documento excede um limite de segurança';

  @override
  String get interoperabilityInternalFailureTitle =>
      'Falha na operação de documento';

  @override
  String get interoperabilityUnsupportedDocument =>
      'Nenhum codec registrado reconhece este documento.';

  @override
  String interopRegistrySniffIdentityMismatch(String codec) {
    return 'O codec $codec informou uma identidade de documento fora do seu registro.';
  }

  @override
  String interopRegistrySniffFailed(String codec) {
    return 'O codec $codec não conseguiu inspecionar o documento.';
  }

  @override
  String interopRegistryDecodedIdentityMismatch(String codec) {
    return 'O codec $codec retornou um documento fora da identidade registrada.';
  }

  @override
  String interopRegistryDecodeFailed(String codec) {
    return 'O codec $codec não conseguiu decodificar o documento.';
  }

  @override
  String interopRegistrySchemaIdentityUnregistered(
    String schema,
    String system,
  ) {
    return 'O schema $schema não está registrado para $system.';
  }

  @override
  String interopRegistryExportRouteUnavailable(
    String system,
    String format,
    int schemaVersion,
  ) {
    return 'Nenhum codec pode exportar $system como $format com a versão de schema $schemaVersion.';
  }

  @override
  String interopRegistryExportSchemaUnavailable(int schemaVersion) {
    return 'Nenhum codec pode exportar a versão de schema $schemaVersion.';
  }

  @override
  String interopRegistryEncodedMetadataMismatch(String codec) {
    return 'O codec $codec retornou metadados de arquivo fora do formato registrado.';
  }

  @override
  String interopRegistryEncodeFailed(String codec) {
    return 'O codec $codec não conseguiu codificar o documento.';
  }

  @override
  String get interoperabilityUnsupportedFeature =>
      'Este documento usa um recurso que ainda não é compatível.';

  @override
  String get interoperabilityUnsupportedSchema =>
      'Esta versão do documento não é compatível.';

  @override
  String get interoperabilityUnsupportedFormat =>
      'Este formato não é compatível com o documento atual.';

  @override
  String get interoperabilityUnsupportedDirection =>
      'Este formato não oferece a ação solicitada de importação ou exportação.';

  @override
  String interoperabilityAmbiguousDescription(String codecIds) {
    return 'Mais de um codec correspondeu: $codecIds';
  }

  @override
  String get interoperabilityMalformedSyntax =>
      'A sintaxe do documento é inválida ou está incompleta.';

  @override
  String get interoperabilityMalformedUtf8 =>
      'O documento não contém texto UTF-8 válido.';

  @override
  String get interoperabilityMalformedMissingField =>
      'Um campo obrigatório está ausente.';

  @override
  String get interoperabilityMalformedInvalidValue =>
      'Um campo contém um valor inválido.';

  @override
  String get interoperabilityMalformedDuplicateIdentity =>
      'O documento contém um identificador duplicado.';

  @override
  String interoperabilityResourceLimitDescription(
    String limit,
    int actual,
    int maximum,
  ) {
    return 'Limite de segurança $limit: encontrado $actual; máximo $maximum.';
  }

  @override
  String get interoperabilityInternalFailureDescription =>
      'O Turing Lab não concluiu esta operação. O documento ativo não foi alterado.';

  @override
  String interoperabilityDiagnosticOffset(int offset) {
    return 'Posição $offset';
  }

  @override
  String interoperabilityRoadmapIssue(int issue) {
    return 'Ver issue #$issue no roadmap';
  }

  @override
  String get interoperabilityLimitBytes => 'tamanho do arquivo';

  @override
  String get interoperabilityLimitXmlDepth => 'profundidade do XML';

  @override
  String get interoperabilityLimitXmlElements => 'quantidade de elementos XML';

  @override
  String get interoperabilityLimitXmlDtdOrEntity =>
      'DTD ou entidade externa em XML';

  @override
  String get interoperabilityLimitJsonDepth => 'profundidade do JSON';

  @override
  String get interoperabilityLimitCollectionEntries =>
      'quantidade de itens na coleção';

  @override
  String get interoperabilityImportDocument => 'Importar documento';

  @override
  String interoperabilityExportAs(String format) {
    return 'Exportar como $format';
  }

  @override
  String get interoperabilityImportSucceeded =>
      'Documento importado com sucesso.';

  @override
  String get interoperabilityExportSucceeded =>
      'Documento exportado com sucesso.';

  @override
  String get interoperabilityOperationFailed =>
      'Não foi possível concluir a operação com o documento.';

  @override
  String get interoperabilityFormatJflapXml => 'XML do JFLAP';

  @override
  String get interoperabilityFormatTuringLabJson => 'JSON do Turing Lab';

  @override
  String get interoperabilityActiveDocument => 'Documento ativo';

  @override
  String get homeNavigationMealyLabel => 'Mealy';

  @override
  String get homeNavigationMealyDescription =>
      'Edite e simule transdutores Mealy.';

  @override
  String get homeNavigationMooreLabel => 'Moore';

  @override
  String get homeNavigationMooreDescription =>
      'Edite e simule transdutores Moore.';

  @override
  String get homeNavigationUnrestrictedGrammarLabel => 'Gramática irrestrita';

  @override
  String get homeNavigationUnrestrictedGrammarDescription =>
      'Classifique gramáticas de estrutura de frase e explore derivações limitadas.';

  @override
  String get homeNavigationLSystemLabel => 'Sistema L';

  @override
  String get homeNavigationLSystemDescription =>
      'Expanda sistemas de reescrita paralela e renderize gráficos de tartaruga.';

  @override
  String get transducerInputSymbol => 'Símbolo de entrada';

  @override
  String get transducerInputRequired => 'Informe um símbolo de entrada.';

  @override
  String get transducerInputOutsideAlphabet =>
      'Escolha um símbolo do alfabeto de entrada.';

  @override
  String get transducerOutputOutsideAlphabet =>
      'Use apenas tokens do alfabeto de saída.';

  @override
  String get transducerDuplicateInput =>
      'Este estado já tem uma transição para essa entrada.';

  @override
  String get transducerInvalidTransition =>
      'A transição não é válida para esta máquina.';

  @override
  String get transducerOutputTokens => 'Tokens de saída';

  @override
  String get transducerOutputTokensHint =>
      'Um token por linha. Deixe em branco para saída vazia.';

  @override
  String get transducerEmptyOutput => 'saída vazia';

  @override
  String transducerTransitionSemantics(String input, String output) {
    return 'Entrada $input; saída $output';
  }

  @override
  String transducerInputOnlySemantics(String input) {
    return 'Entrada $input';
  }

  @override
  String transducerStateOutputSemantics(String output) {
    return 'Saída do estado $output';
  }

  @override
  String get transducerSimulationTitle => 'Simulação do transdutor';

  @override
  String get transducerInputTokens => 'Tokens de entrada';

  @override
  String get transducerInputTokensHint => 'Um token de entrada por linha';

  @override
  String get transducerRun => 'Executar';

  @override
  String get transducerCancel => 'Cancelar execução';

  @override
  String get transducerMaximumSteps => 'Máximo de passos';

  @override
  String get transducerMaximumStepsInvalid =>
      'Informe zero ou um número inteiro positivo.';

  @override
  String get transducerOutput => 'Saída';

  @override
  String get transducerInvalidMachine =>
      'A máquina é inválida. Corrija os estados ou as transições indicados.';

  @override
  String get transducerInvalidInput =>
      'A entrada contém um símbolo fora do alfabeto de entrada.';

  @override
  String get transducerUndefinedTransition =>
      'Não há transição definida para o próximo símbolo de entrada.';

  @override
  String get transducerSimulationCancelled => 'A simulação foi cancelada.';

  @override
  String get transducerSimulationBounded =>
      'A simulação parou no limite de passos configurado.';

  @override
  String transducerExecutionInvalidMachine(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A máquina é inválida: $count diagnósticos requerem atenção.',
      one: 'A máquina é inválida: um diagnóstico requer atenção.',
      zero: 'A máquina é inválida.',
    );
    return '$_temp0';
  }

  @override
  String transducerExecutionInvalidInputSymbol(String symbol) {
    return 'O símbolo de entrada \"$symbol\" não pertence ao alfabeto de entrada.';
  }

  @override
  String transducerExecutionTokenizationFailure(int offset) {
    return 'A entrada não pode ser tokenizada no deslocamento $offset.';
  }

  @override
  String transducerExecutionUndefinedTransition(String state, String symbol) {
    return 'Não há transição definida a partir do estado $state para o símbolo de entrada \"$symbol\".';
  }

  @override
  String transducerExecutionCancelled(int processed) {
    String _temp0 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: 'A simulação foi cancelada após $processed tokens de entrada.',
      one: 'A simulação foi cancelada após um token de entrada.',
      zero:
          'A simulação foi cancelada antes do processamento de qualquer token de entrada.',
    );
    return '$_temp0';
  }

  @override
  String transducerExecutionBounded(int limit, int processed) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit passos',
      one: 'um passo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: '$processed tokens de entrada',
      one: 'um token de entrada',
      zero: 'nenhum token de entrada',
    );
    return 'A simulação parou no limite de $_temp0 após processar $_temp1.';
  }

  @override
  String transducerExecutionSuccess(int processed, int outputCount) {
    String _temp0 = intl.Intl.pluralLogic(
      processed,
      locale: localeName,
      other: 'A simulação terminou após $processed tokens de entrada.',
      one: 'A simulação terminou após um token de entrada.',
      zero: 'A simulação terminou sem consumir entrada.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      outputCount,
      locale: localeName,
      other: '$outputCount tokens de saída foram produzidos.',
      one: 'Um token de saída foi produzido.',
      zero: 'Nenhum token de saída foi produzido.',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String get parserXmlMalformedDocument =>
      'O documento XML do JFLAP está malformado.';

  @override
  String get parserGrammarXmlMissingGrammarElement =>
      'O arquivo do JFLAP não contém um elemento de gramática.';

  @override
  String get parserGrammarXmlMissingStartElement =>
      'A gramática do JFLAP não declara um símbolo inicial.';

  @override
  String get parserGrammarXmlEmptyStartElement =>
      'A gramática do JFLAP tem um símbolo inicial vazio.';

  @override
  String parserGrammarXmlInvalidStartCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foram encontrados',
      one: 'um foi encontrado',
      zero: 'nenhum foi encontrado',
    );
    return 'A gramática do JFLAP deve declarar um símbolo inicial, mas $_temp0.';
  }

  @override
  String parserGrammarXmlIncompleteProduction(int index) {
    return 'A produção no índice $index deve conter os elementos esquerdo e direito.';
  }

  @override
  String get parserJflapXmlMissingAutomatonElement =>
      'O arquivo do JFLAP não contém um elemento de autômato.';

  @override
  String get parserJflapXmlEmptyAutomaton =>
      'O autômato do JFLAP não tem estados e não pode ser carregado no editor.';

  @override
  String parserJflapXmlIncompleteTransition(int index) {
    return 'A transição no índice $index deve conter estados de origem e destino.';
  }

  @override
  String parserJflapXmlUnknownTransitionEndpoints(
    String fromState,
    String toState,
  ) {
    return 'A transição de $fromState para $toState referencia um estado desconhecido.';
  }

  @override
  String parserJflapXmlUnexpectedRootElement(String actual) {
    return 'A raiz do documento JFLAP deve ser structure, não $actual.';
  }

  @override
  String structuredMessageUnknown(String code) {
    return 'Mensagem indisponível ($code).';
  }

  @override
  String get transducerNoTrace => 'Nenhum passo no traço';

  @override
  String get transducerEmptyInput => 'entrada vazia';

  @override
  String transducerRemainingInputPreview(String preview, int count) {
    return '$preview ($count tokens restantes)';
  }

  @override
  String transducerTraceStep(
    int step,
    String source,
    String target,
    String transition,
  ) {
    return 'Passo $step: $source para $target com $transition';
  }

  @override
  String transducerTraceDetails(
    String consumed,
    String remaining,
    String emitted,
    String cumulative,
  ) {
    return 'Consumido $consumed; restante $remaining; emitido $emitted; acumulado $cumulative';
  }

  @override
  String get transducerMachineInfo => 'Detalhes da máquina';

  @override
  String get transducerMachineValid => 'Máquina válida';

  @override
  String get transducerMachineInvalid => 'Máquina inválida';

  @override
  String get transducerMachineDeterministic => 'Determinística';

  @override
  String get transducerMachineNondeterministic => 'Não determinística';

  @override
  String get transducerMachineComplete => 'Função de transição completa';

  @override
  String get transducerMachinePartial => 'Função de transição parcial';

  @override
  String get transducerAnalysisMissingInitialState =>
      'Escolha um estado inicial.';

  @override
  String transducerAnalysisMultipleInitialStates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A máquina tem $count estados iniciais.',
      one: 'A máquina tem um estado inicial.',
    );
    return '$_temp0';
  }

  @override
  String transducerAnalysisDuplicateStateId(String state) {
    return 'O identificador de estado $state está duplicado.';
  }

  @override
  String transducerAnalysisDuplicateTransitionId(String transition) {
    return 'O identificador de transição $transition está duplicado.';
  }

  @override
  String transducerAnalysisDanglingSourceState(String transition) {
    return 'A transição $transition começa em um estado ausente.';
  }

  @override
  String transducerAnalysisDanglingTargetState(String transition) {
    return 'A transição $transition aponta para um estado ausente.';
  }

  @override
  String transducerAnalysisInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'A transição $transition usa a entrada $symbol, que está fora do alfabeto.';
  }

  @override
  String transducerAnalysisOutputSymbolOutsideAlphabet(
    String subject,
    String symbol,
  ) {
    return 'A saída de $subject usa $symbol, que está fora do alfabeto.';
  }

  @override
  String transducerAnalysisNondeterministicTransition(
    String state,
    String symbol,
  ) {
    return 'O estado $state tem mais de uma transição para a entrada $symbol.';
  }

  @override
  String transducerAnalysisIncompleteTransitionFunction(
    String state,
    String symbol,
  ) {
    return 'O estado $state não tem uma transição única para a entrada $symbol.';
  }

  @override
  String transducerAnalysisEmptyIdentifier(String entity) {
    String _temp0 = intl.Intl.selectLogic(entity, {
      'machine': 'O identificador da máquina não pode estar vazio.',
      'state': 'O identificador de estado não pode estar vazio.',
      'transition': 'O identificador de transição não pode estar vazio.',
      'other': 'Um identificador não pode estar vazio.',
    });
    return '$_temp0';
  }

  @override
  String transducerAnalysisEmptyInputSymbol(String subject) {
    return 'O símbolo de entrada de $subject não pode estar vazio.';
  }

  @override
  String transducerAnalysisEmptyOutputSymbol(String subject) {
    return 'O símbolo de saída de $subject não pode estar vazio.';
  }

  @override
  String transducerAnalysisNegativeRevision(int revision) {
    return 'A revisão $revision do documento é inválida.';
  }

  @override
  String get transducerInputAlphabet => 'Alfabeto de entrada';

  @override
  String get transducerOutputAlphabet => 'Alfabeto de saída';

  @override
  String get transducerAlphabetHint => 'Um símbolo por linha';

  @override
  String get transducerApplyAlphabets => 'Aplicar alfabetos';

  @override
  String get transducerEditTransition => 'Editar transição do transdutor';

  @override
  String get transducerDeleteTransition => 'Excluir transição';

  @override
  String get transducerDeleteState => 'Excluir estado';

  @override
  String get transducerEditState => 'Editar estado do transdutor';

  @override
  String get transducerStateName => 'Nome do estado';

  @override
  String get transducerInitialState => 'Estado inicial';

  @override
  String get transducerSave => 'Salvar';

  @override
  String get transducerExamples => 'Exemplos';

  @override
  String get transducerExamplesUnavailable =>
      'Não há exemplos disponíveis para este espaço de trabalho.';

  @override
  String get transducerExamplesLoadFailed =>
      'Não foi possível carregar os exemplos.';

  @override
  String get transducerExamplesEmpty => 'Ainda não há exemplos disponíveis.';

  @override
  String get mealyExampleIdentityName => 'Transdutor identidade';

  @override
  String get mealyExampleIdentityDescription =>
      'Emite cada símbolo binário de entrada sem alteração.';

  @override
  String get mealyExampleParityName => 'Saída de paridade';

  @override
  String get mealyExampleParityDescription =>
      'Emite a paridade após cada símbolo binário de entrada.';

  @override
  String get mealyExampleSequenceName => 'Detector de sequência';

  @override
  String get mealyExampleSequenceDescription =>
      'Emite 1 quando os dois símbolos mais recentes são ab.';

  @override
  String get mealyExamplePartialName => 'Transdutor parcial';

  @override
  String get mealyExamplePartialDescription =>
      'Para quando a entrada b não tem transição no estado atual.';

  @override
  String get mooreExampleParityName => 'Saída de paridade por estado';

  @override
  String get mooreExampleParityDescription =>
      'Informa a paridade par ou ímpar a partir do estado atual.';

  @override
  String get mooreExampleVendingName => 'Controle de venda';

  @override
  String get mooreExampleVendingDescription =>
      'Informa se o controlador de venda está pronto.';

  @override
  String get mooreExampleSequenceName => 'Detector de sequência';

  @override
  String get mooreExampleSequenceDescription =>
      'Informa quando o sufixo de entrada mais recente corresponde a 10.';

  @override
  String get mooreExamplePartialName => 'Máquina de Moore parcial';

  @override
  String get mooreExamplePartialDescription =>
      'Demonstra uma entrada indefinida sem tratá-la como inválida.';

  @override
  String exampleSuggestedSimulationLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Simulações sugeridas',
      one: 'Simulação sugerida',
    );
    return '$_temp0';
  }

  @override
  String exampleSuggestedSimulationSemantics(int count, String inputs) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Simulações sugeridas: $inputs.',
      one: 'Simulação sugerida: $inputs.',
    );
    return '$_temp0';
  }

  @override
  String get transducerBatch => 'Entradas em lote';

  @override
  String get transducerBatchHint =>
      'Um vetor JSON de tokens por linha, por exemplo [\"a\",\"b\"]';

  @override
  String get transducerBatchInputLabel => 'Vetores de tokens de entrada';

  @override
  String get transducerBatchEmpty => 'Nenhuma entrada em lote foi informada.';

  @override
  String get transducerBatchSuccess => 'Concluída';

  @override
  String get transducerRunBatch => 'Executar lote';

  @override
  String get transducerComparison => 'Comparar saídas';

  @override
  String get transducerComparisonMode => 'Modo de comparação';

  @override
  String get transducerComparisonExact => 'Exata';

  @override
  String get transducerComparisonBounded => 'Limitada';

  @override
  String get transducerComparisonBound => 'Comprimento máximo da entrada';

  @override
  String get transducerCompareWithExample => 'Comparar com exemplo';

  @override
  String get transducerCompare => 'Comparar';

  @override
  String transducerComparisonResult(String result) {
    return 'Resultado da comparação: $result';
  }

  @override
  String get transducerLoadExample => 'Carregar exemplo';

  @override
  String get transducerNoComparisonMachine => 'Escolha uma segunda máquina.';

  @override
  String get transducerExactEquivalent => 'Exatamente equivalentes';

  @override
  String get transducerExactDifferent => 'Diferentes, com testemunha exata';

  @override
  String get transducerBoundedDifferent =>
      'Diferentes dentro do limite escolhido';

  @override
  String get transducerBoundedInconclusive =>
      'Nenhuma diferença encontrada dentro do limite escolhido';

  @override
  String get transducerComparisonInvalid =>
      'As máquinas não podem ser comparadas neste modo.';

  @override
  String get transducerLeftOutput => 'Saída atual';

  @override
  String get transducerRightOutput => 'Saída comparada';

  @override
  String get transducerWitness => 'Entrada testemunha';

  @override
  String transducerInvalidBatchLine(int line) {
    return 'A linha $line deve ser um vetor JSON de strings.';
  }

  @override
  String transducerSelectedMachine(String name) {
    return 'Máquina selecionada: $name';
  }

  @override
  String transducerExploredPairs(int count) {
    return 'Pares explorados: $count';
  }

  @override
  String get initializationErrorTitle =>
      'O Turing Lab não conseguiu concluir a inicialização.';

  @override
  String get initializationErrorMessage =>
      'Reinicie o aplicativo. As configurações locais e a persistência de traços podem ficar indisponíveis até que a inicialização seja concluída.';

  @override
  String get helpRelatedTopics => 'Tópicos relacionados';

  @override
  String get helpTopicUnavailable =>
      'Este tópico de ajuda não está disponível.';

  @override
  String get helpTopicUnavailableDescription =>
      'Navegue pela árvore de ajuda ou pesquise outro tópico.';

  @override
  String get contextualHelpPanelLabel => 'Painel de ajuda contextual';

  @override
  String get closeHelpPanel => 'Fechar painel de ajuda';

  @override
  String get viewAllRelatedHelp => 'Ver toda a ajuda relacionada';

  @override
  String get moreHelp => 'Mais ajuda';

  @override
  String get helpCenter => 'Central de ajuda';

  @override
  String get workspaceSimulateTooltip => 'Simular';

  @override
  String get workspaceAlgorithmsTooltip => 'Algoritmos';

  @override
  String get workspaceAlgorithmsAndExamplesTooltip => 'Algoritmos e Exemplos';

  @override
  String get workspaceParserTooltip => 'Analisador';

  @override
  String get workspaceEditTooltip => 'Editar';

  @override
  String get workspaceMetricsTooltip => 'Métricas';

  @override
  String get workspaceMoreActionsTooltip => 'Mais ações do espaço de trabalho';

  @override
  String get workspaceExamplesTooltip => 'Exemplos';

  @override
  String get workspaceExamplesLoadingTooltip => 'Carregando exemplos';

  @override
  String get workspaceExamplesUnavailableTooltip => 'Exemplos indisponíveis';

  @override
  String get workspaceExamplesLoadFailed =>
      'Não foi possível carregar os exemplos.';

  @override
  String get workspaceExamplesEmpty => 'Ainda não há exemplos disponíveis.';

  @override
  String get keyboardShortcutsDialogLabel => 'Diálogo de atalhos de teclado';

  @override
  String get keyboardShortcutsTitle => 'Atalhos de teclado';

  @override
  String get keyboardShortcutsCanvasOperations => 'Operações do canvas';

  @override
  String get keyboardShortcutsSimulationControls => 'Controles de simulação';

  @override
  String get keyboardShortcutsDialogShortcuts => 'Atalhos de diálogos';

  @override
  String get closeShortcutsDialog => 'Fechar diálogo de atalhos';

  @override
  String get shortcutAlternativeSeparator => 'ou';

  @override
  String get aboutDeveloperLabel => 'Desenvolvedor';

  @override
  String get aboutProjectRepositoryLabel => 'Repositório do projeto';

  @override
  String get aboutProjectOpenError =>
      'Não foi possível abrir o repositório do projeto.';

  @override
  String get aboutOpenSourceLicenses => 'Licenças de código aberto';

  @override
  String get aboutLicensesIntro =>
      'O Turing Lab é uma reimplementação em Flutter inspirada no JFLAP e compatível com ele. Não é uma versão oficial do JFLAP.';

  @override
  String get aboutTuringLabLicenseSummary =>
      'O código Flutter original do Turing Lab é licenciado sob a Apache 2.0.';

  @override
  String get aboutJflapLicenseSummary =>
      'As partes derivadas do JFLAP permanecem sob a licença do JFLAP 7.1.';

  @override
  String get aboutGraphViewLicenseSummary =>
      'Biblioteca de visualização de grafos, bifurcada e modificada para o Turing Lab. Trabalho original de Nabil Mosharraf.';

  @override
  String get aboutAppleNoticesSummary =>
      'Avisos incluídos para o fork do GraphView e dependências de plugins das plataformas Apple.';

  @override
  String get aboutAppleNoticesTitle =>
      'Avisos de terceiros das plataformas Apple';

  @override
  String get aboutPackageLicenses => 'Licenças dos pacotes';

  @override
  String get aboutPackageLicensesDescription =>
      'Licenças informadas pelo Flutter para os pacotes Dart e Flutter incluídos.';

  @override
  String get aboutAcknowledgments => 'Agradecimentos ao JFLAP';

  @override
  String get aboutJflapCreator =>
      'Criadora e mantenedora original do JFLAP, Duke University.';

  @override
  String get aboutJflapTeam =>
      'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su e Henry Qin.';

  @override
  String get aboutOriginalProject => 'Site do JFLAP: http://www.jflap.org';

  @override
  String get aboutOriginalProjectTitle => 'Projeto original';

  @override
  String get aboutGraphViewFork =>
      'O Turing Lab inclui um fork mantido do GraphView sob a licença MIT; os avisos de terceiros das plataformas Apple estão incluídos aqui.';

  @override
  String get aboutGraphViewForkTitle => 'Fork do GraphView';

  @override
  String get aboutDistribution => 'Distribuição';

  @override
  String get aboutDistributionDescription =>
      'O Turing Lab é distribuído como um aplicativo educacional gratuito e não monetizado enquanto incluir material derivado do JFLAP.';

  @override
  String get aboutLicenseExpandPrompt =>
      'Expanda para carregar o texto da licença incluída.';

  @override
  String get aboutLicenseLoading => 'Carregando o texto da licença incluída...';

  @override
  String get aboutLicenseLoadFailed =>
      'Falha ao carregar a licença incluída no aplicativo. Tente novamente.';

  @override
  String helpDisclosureExpandSemanticLabel(String title) {
    return 'Expandir $title';
  }

  @override
  String helpDisclosureCollapseSemanticLabel(String title) {
    return 'Recolher $title';
  }

  @override
  String helpSearchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resultados',
      one: '1 resultado',
      zero: '0 resultados',
    );
    return '$_temp0';
  }

  @override
  String helpTopicSemanticLabel(String title) {
    return 'Tópico de ajuda: $title';
  }

  @override
  String showHelpFor(String title) {
    return 'Mostrar ajuda sobre $title';
  }

  @override
  String navigateTo(String label) {
    return 'Navegar para $label';
  }

  @override
  String workspaceSelectorLabel(String label) {
    return 'Espaço de trabalho: $label';
  }

  @override
  String get workspaceSelectorHint => 'Trocar espaço de trabalho';

  @override
  String workspaceDockShowPanel(String label) {
    return 'Mostrar $label';
  }

  @override
  String workspaceDockHidePanel(String label) {
    return 'Ocultar $label';
  }

  @override
  String get workspaceDockResizePanel => 'Redimensionar painel';

  @override
  String unableToLoadHelp(String category) {
    return 'Não foi possível carregar a ajuda para \"$category\".';
  }

  @override
  String noHelpItemsFound(String category) {
    return 'Nenhum item de ajuda encontrado para \"$category\".';
  }

  @override
  String get includeNotesInVisualExports =>
      'Incluir notas nas exportações visuais';

  @override
  String get includeNotesInVisualExportsDescription =>
      'Aplica-se a SVG e PNG. As exportações de documentos sempre preservam as notas.';

  @override
  String get documentNotesTitle => 'Notas do documento';

  @override
  String get documentNotesDescription =>
      'Notas e anotações sem significado formal';

  @override
  String get documentNoteUndo => 'Desfazer alteração na nota';

  @override
  String get documentNoteRedo => 'Refazer alteração na nota';

  @override
  String get documentNoteAdd => 'Adicionar nota';

  @override
  String get documentNoteSearch => 'Pesquisar notas';

  @override
  String get documentNoteNoMatches => 'Nenhuma nota correspondente.';

  @override
  String get documentNoteEmpty => 'Nota vazia';

  @override
  String get documentNoteFree => 'Nota livre';

  @override
  String documentNoteAttachment(String type, String target) {
    return '$type: $target';
  }

  @override
  String get documentNoteActions => 'Ações da nota';

  @override
  String get documentNoteDuplicate => 'Duplicar';

  @override
  String get documentNoteDeleteTitle => 'Excluir nota?';

  @override
  String get documentNoteDeleteMessage => 'Isso remove a nota deste documento.';

  @override
  String documentNoteSemantics(String text) {
    return 'Nota: $text';
  }

  @override
  String get documentNoteKeyboardHint =>
      'Pressione Enter para editar. Control D duplica. Control C recolhe.';

  @override
  String get documentNoteExpand => 'Expandir nota';

  @override
  String get documentNoteCollapse => 'Recolher nota';

  @override
  String get documentNoteResize => 'Redimensionar nota';

  @override
  String get documentNoteEditTitle => 'Editar nota';

  @override
  String get documentNoteTextLabel => 'Texto da nota';

  @override
  String get documentNoteTextHelp =>
      'Use **negrito**, _itálico_ ou `código`. Links e HTML não são interpretados.';

  @override
  String get documentNoteStyleLabel => 'Estilo';

  @override
  String get documentNoteAttachmentLabel => 'Anexo';

  @override
  String get documentNoteNoAttachment => 'Nenhum';

  @override
  String get documentNoteTargetIdLabel => 'ID do destino';

  @override
  String get documentNoteStyleNote => 'Nota';

  @override
  String get documentNoteStyleInformation => 'Informação';

  @override
  String get documentNoteStyleWarning => 'Aviso';

  @override
  String get documentNoteStyleQuestion => 'Pergunta';

  @override
  String get documentNoteStyleTodo => 'A fazer';

  @override
  String get documentNoteTargetCanvas => 'Canvas';

  @override
  String get documentNoteTargetState => 'Estado';

  @override
  String get documentNoteTargetTransition => 'Transição';

  @override
  String get documentNoteTargetProduction => 'Produção';

  @override
  String get documentNoteTargetTableCell => 'Célula da tabela';

  @override
  String get automatonFragmentFilePickerTitle => 'Importar autômato compatível';

  @override
  String get automatonFragmentUnreadableFile =>
      'Não foi possível ler o arquivo selecionado.';

  @override
  String automatonFragmentImportedSummary(int states, int transitions) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states estados',
      one: '1 estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transições',
      one: '1 transição',
    );
    return 'Foram importados $_temp0 e $_temp1.';
  }

  @override
  String automatonFragmentImportFailed(String error) {
    return 'Falha ao importar o autômato: $error';
  }

  @override
  String get automatonFragmentCannotImport =>
      'Não foi possível importar o autômato';

  @override
  String get automatonFragmentPreviewTitle =>
      'Prévia da importação do autômato';

  @override
  String automatonFragmentSourceFidelity(String fidelity) {
    return 'Fidelidade da origem: $fidelity. A origem e o destino permanecem inalterados até Aplicar.';
  }

  @override
  String get automatonFragmentStatesToImport => 'Estados a importar';

  @override
  String get automatonFragmentInsertionAnchor => 'Âncora de inserção';

  @override
  String get automatonFragmentInitialStateAfterImport =>
      'Estado inicial após a importação';

  @override
  String get automatonFragmentKeepCurrentInitialState =>
      'Manter o estado inicial atual';

  @override
  String get automatonFragmentUseImportedInitialState =>
      'Usar o estado inicial importado';

  @override
  String get automatonFragmentUseDestinationAcceptance =>
      'Usar o modo de aceitação do AP de destino';

  @override
  String get automatonFragmentSourceModeDiffers =>
      'Obrigatório porque o modo da origem é diferente.';

  @override
  String get automatonFragmentUseDestinationStackSymbol =>
      'Usar o símbolo inicial da pilha de destino';

  @override
  String get automatonFragmentSourceSymbolDiffers =>
      'Obrigatório porque o símbolo da origem é diferente.';

  @override
  String get automatonFragmentExactChanges => 'Alterações exatas';

  @override
  String automatonFragmentCloneSummary(
    int states,
    int transitions,
    int notes,
    int blocks,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states estados',
      one: '1 estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transições',
      one: '1 transição',
    );
    String _temp2 = intl.Intl.pluralLogic(
      notes,
      locale: localeName,
      other: '$notes notas',
      one: '1 nota',
    );
    String _temp3 = intl.Intl.pluralLogic(
      blocks,
      locale: localeName,
      other: '$blocks blocos reutilizáveis',
      one: '1 bloco reutilizável',
    );
    return 'Serão clonados $_temp0, $_temp1, $_temp2 e $_temp3.';
  }

  @override
  String get automatonFragmentStructuralImportExplanation =>
      'Esta é uma importação estrutural desconectada. Operações algébricas e a abertura ou substituição de documentos permanecem fluxos separados.';

  @override
  String get automatonFragmentInputAlphabet => 'Alfabeto de entrada';

  @override
  String get automatonFragmentOutputAlphabet => 'Alfabeto de saída';

  @override
  String get automatonFragmentStackAlphabet => 'Alfabeto da pilha';

  @override
  String get automatonFragmentTapeAlphabet => 'Alfabeto da fita';

  @override
  String automatonFragmentAcceptanceModeUnchanged(String mode) {
    return 'O modo de aceitação permanece $mode.';
  }

  @override
  String automatonFragmentInitialStackSymbolUnchanged(String symbol) {
    return 'O símbolo inicial da pilha permanece $symbol.';
  }

  @override
  String automatonFragmentTapeConfigurationUnchanged(int count, String symbol) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fitas',
      one: '1 fita',
    );
    return 'A configuração permanece com $_temp0 e símbolo branco $symbol.';
  }

  @override
  String automatonFragmentInitialStateUnchanged(String state) {
    return 'O estado inicial permanece $state.';
  }

  @override
  String automatonFragmentInitialStateChanged(String before, String after) {
    return 'O estado inicial muda de $before para $after.';
  }

  @override
  String get automatonFragmentUnset => 'não definido';

  @override
  String automatonFragmentSetUnchanged(String label) {
    return '$label não foi alterado.';
  }

  @override
  String automatonFragmentSetAdds(String label, String symbols) {
    return '$label adiciona: $symbols.';
  }

  @override
  String get unknownError => 'Erro desconhecido';

  @override
  String get fileReadFailed => 'Falha ao ler o arquivo.';

  @override
  String get selectedFileBytesUnavailable =>
      'Os bytes do arquivo selecionado não estão disponíveis.';

  @override
  String get attachedNotesTitle => 'Notas anexadas';

  @override
  String attachedNotesStateDeletionMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notas estão anexadas a este estado ou às suas transições incidentes. Escolha o que acontece antes da exclusão.',
      one:
          '1 nota está anexada a este estado ou a uma de suas transições incidentes. Escolha o que acontece antes da exclusão.',
    );
    return '$_temp0';
  }

  @override
  String attachedNotesTransitionDeletionMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count notas estão anexadas a esta transição. Escolha o que acontece antes da exclusão.',
      one:
          '1 nota está anexada a esta transição. Escolha o que acontece antes da exclusão.',
    );
    return '$_temp0';
  }

  @override
  String get keepNotesUnlinked => 'Manter sem vínculo';

  @override
  String get detachNotes => 'Desanexar notas';

  @override
  String get deleteNotes => 'Excluir notas';

  @override
  String grammarDependencySummaryCounts(int variableCount, int edgeCount) {
    String _temp0 = intl.Intl.pluralLogic(
      variableCount,
      locale: localeName,
      other: '$variableCount variáveis',
      one: '1 variável',
    );
    String _temp1 = intl.Intl.pluralLogic(
      edgeCount,
      locale: localeName,
      other: '$edgeCount arestas de dependência.',
      one: '1 aresta de dependência.',
    );
    return '$_temp0 e $_temp1';
  }

  @override
  String get grammarDependencyNoRecursionCycle =>
      'Nenhum ciclo de recursão foi encontrado neste modo do grafo.';

  @override
  String grammarDependencyRecursionCycleCount(int cycleCount) {
    String _temp0 = intl.Intl.pluralLogic(
      cycleCount,
      locale: localeName,
      other: 'Foram encontrados $cycleCount ciclos de recursão.',
      one: 'Foi encontrado 1 ciclo de recursão.',
    );
    return '$_temp0';
  }

  @override
  String grammarDependencyUnreachableVariable(String variable) {
    return 'Variável inalcançável: $variable.';
  }

  @override
  String grammarDependencyNonproductiveVariable(String variable) {
    return 'Variável não produtiva: $variable.';
  }

  @override
  String grammarLl1ConflictDetected(
    String conflictKind,
    String nonTerminal,
    String lookahead,
    String alternatives,
  ) {
    return 'Conflito $conflictKind em [$nonTerminal, $lookahead]: $alternatives.';
  }

  @override
  String get grammarAmbiguityNoLl1Conflicts =>
      'Nenhum conflito LL(1) detectado (a gramática parece ser LL(1) para esta análise).';

  @override
  String get grammarAmbiguityLl1ConflictsDetected =>
      'Conflitos LL(1) detectados (a gramática não é LL(1)).';

  @override
  String get grammarAmbiguityNonLl1DoesNotImplyAmbiguity =>
      'Observação: não ser LL(1) não significa necessariamente que a gramática seja ambígua; ela ainda pode ser não ambígua, mas exigir um analisador mais forte (por exemplo, LR/Earley).';

  @override
  String get grammarAnalysisEmptyProductions =>
      'A gramática não possui produções.';

  @override
  String get grammarAnalysisNoLeftRecursion =>
      'Nenhuma recursão à esquerda direta ou indireta foi detectada.';

  @override
  String get grammarStructuralStartSymbolMissing =>
      'A gramática não possui símbolo inicial.';

  @override
  String get grammarStructuralStartSymbolMissingReachability =>
      'A gramática não possui símbolo inicial; a análise de alcançabilidade foi omitida.';

  @override
  String grammarStructuralStartSymbolNotNonterminal(String symbol) {
    return 'O símbolo inicial $symbol não está declarado como não terminal.';
  }

  @override
  String grammarStructuralStartSymbolNotNonterminalReachability(String symbol) {
    return 'O símbolo inicial $symbol não está declarado como não terminal; a análise de alcançabilidade pode estar imprecisa.';
  }

  @override
  String get grammarStructuralNoProductions =>
      'A gramática não possui produções.';

  @override
  String get grammarStructuralNoProductionsProductivity =>
      'A gramática não possui produções; a análise de produtividade foi omitida.';

  @override
  String grammarStructuralProductionLeftSideEmpty(String productionId) {
    return 'A produção $productionId possui lado esquerdo vazio.';
  }

  @override
  String grammarStructuralProductionLeftSideNotSingleNonterminal(
    String productionId,
    String leftSide,
  ) {
    return 'O lado esquerdo da produção $productionId deve conter exatamente um não terminal para as ferramentas CFG; foi recebido $leftSide.';
  }

  @override
  String grammarStructuralProductionLeftSideEmptySymbol(String productionId) {
    return 'O lado esquerdo da produção $productionId contém um símbolo vazio.';
  }

  @override
  String grammarStructuralProductionLeftSideNotNonterminal(
    String productionId,
    String symbol,
  ) {
    return 'O lado esquerdo da produção $productionId contém $symbol, que não está declarado como não terminal.';
  }

  @override
  String grammarStructuralProductionUnknownSymbol(
    String productionId,
    String symbol,
  ) {
    return 'A produção $productionId faz referência ao símbolo desconhecido $symbol.';
  }

  @override
  String grammarStructuralUnknownSymbolReachability(String symbol) {
    return 'A produção faz referência ao símbolo desconhecido $symbol; ele será tratado como terminal para fins de alcançabilidade.';
  }

  @override
  String grammarStructuralUnknownSymbolProductivity(String symbol) {
    return 'A produção faz referência ao símbolo desconhecido $symbol; ele será tratado como terminal para fins de produtividade.';
  }

  @override
  String grammarStructuralLambdaProductionRhsNotEmpty(String productionId) {
    return 'A produção $productionId está marcada como lambda, mas possui lado direito não vazio.';
  }

  @override
  String grammarStructuralProductionRhsEmpty(String productionId) {
    return 'A produção $productionId possui lado direito vazio; use ε ou marque-a como epsilon.';
  }

  @override
  String grammarStructuralUnreachableNonterminals(int count, String symbols) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count não terminais inalcançáveis',
      one: 'Foi encontrado 1 não terminal inalcançável',
    );
    return '$_temp0: $symbols.';
  }

  @override
  String grammarStructuralUnproductiveNonterminals(int count, String symbols) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Foram encontrados $count não terminais não produtivos',
      one: 'Foi encontrado 1 não terminal não produtivo',
    );
    return '$_temp0: $symbols.';
  }

  @override
  String grammarStructuralUnproductiveProductions(String symbols) {
    return 'As produções de não terminais não produtivos ($symbols) não podem derivar cadeias terminais.';
  }

  @override
  String get grammarLl1ConflictKindFirstFirst => 'FIRST/FIRST';

  @override
  String get grammarLl1ConflictKindFirstFollow => 'FIRST/FOLLOW';

  @override
  String fsaDeterminizationFailed(String automaton) {
    return 'Não foi possível determinizar o autômato $automaton.';
  }

  @override
  String batchValidationNonEmpty(String field) {
    return '$field não pode estar vazio.';
  }

  @override
  String batchValidationPositive(String field) {
    return '$field deve ser positivo.';
  }

  @override
  String batchValidationNonNegative(String field) {
    return '$field não pode ser negativo.';
  }

  @override
  String batchValidationMaximum(String field, int bound) {
    return '$field não pode exceder $bound.';
  }

  @override
  String batchValidationCaseContext(int index, String caseId) {
    return 'Caso $index ($caseId):';
  }

  @override
  String batchValidationDuplicateCaseId(String caseId) {
    return 'ID de caso duplicado: $caseId.';
  }

  @override
  String batchValidationExplicitTokensRequired(String caseId) {
    return 'Caso $caseId: a tokenização explícita exige tokens.';
  }

  @override
  String batchValidationUnknownCaseLimits(String caseId) {
    return 'Os limites por caso referenciam o caso desconhecido $caseId.';
  }

  @override
  String get batchValidationSelectedTraceCaseRequired =>
      'A retenção de traço do caso selecionado exige um ID de caso conhecido.';

  @override
  String get batchExecutionScalarTokenizationRequired =>
      'Este simulador canônico exige tokens escalares Unicode.';

  @override
  String get batchExecutionKeyboardShortcuts =>
      'Executar: Ctrl+Enter. Cancelar: Escape.';

  @override
  String get batchExecutionGrammarTokenizationMismatch =>
      'O tokenizador canônico da gramática não pode preservar esta sequência explícita de tokens.';

  @override
  String batchExecutionTmPolicyReason(String policy, String reason) {
    return 'Política: $policy. Motivo: $reason.';
  }

  @override
  String batchImportCaseLimit(int count, int bound) {
    return 'O arquivo de entrada contém $count casos; o limite é $bound.';
  }

  @override
  String batchImportMissingInputColumn(int row) {
    return 'A linha $row do CSV não tem coluna de entrada.';
  }

  @override
  String batchImportDuplicateCaseId(String caseId) {
    return 'O CSV contém o ID de caso duplicado $caseId.';
  }

  @override
  String get batchImportCharactersAfterClosingQuote =>
      'O CSV tem caracteres após o fechamento de aspas.';

  @override
  String get batchImportQuoteRequiresEmptyField =>
      'As aspas do CSV devem iniciar um campo vazio.';

  @override
  String get batchImportUnclosedQuote => 'O CSV contém aspas não fechadas.';

  @override
  String get automataDiagnosticsCanvas => 'Diagnósticos da tela';

  @override
  String automataDiagnosticsConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Conflitos ($count)',
      one: 'Conflito (1)',
      zero: 'Conflitos (0)',
    );
    return '$_temp0';
  }

  @override
  String automataDiagnosticsConflictAction(String selected, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Limpar os destaques das transições conflitantes, $count encontradas',
      one: 'Limpar o destaque da transição conflitante, 1 encontrada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Destacar as transições conflitantes, $count encontradas',
      one: 'Destacar a transição conflitante, 1 encontrada',
    );
    String _temp2 = intl.Intl.selectLogic(selected, {
      'true': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String get automataDiagnosticsConflictHint =>
      'Mostra transições que competem pela mesma entrada';

  @override
  String automataDiagnosticsEpsilon(int count) {
    return 'Épsilon ($count)';
  }

  @override
  String automataDiagnosticsEpsilonAction(String selected, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limpar os destaques das transições épsilon, $count encontradas',
      one: 'Limpar o destaque da transição épsilon, 1 encontrada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Destacar as transições épsilon, $count encontradas',
      one: 'Destacar a transição épsilon, 1 encontrada',
    );
    String _temp2 = intl.Intl.selectLogic(selected, {
      'true': '$_temp0',
      'other': '$_temp1',
    });
    return '$_temp2';
  }

  @override
  String get automataDiagnosticsEpsilonHint =>
      'Mostra transições que usam a cadeia vazia';

  @override
  String get computationBranchesTitle => 'Ramos de computação';

  @override
  String get computationBranchesInspectorSemantic =>
      'Inspetor de ramos de computação';

  @override
  String get computationBranchesBranch => 'Ramo';

  @override
  String get computationBranchesConfigurations => 'Configurações';

  @override
  String get computationBranchesConfigurationDetails =>
      'Detalhes da configuração';

  @override
  String get computationBranchesConfiguration => 'Configuração';

  @override
  String get computationBranchesOutcome => 'Resultado';

  @override
  String get computationBranchesHighlight => 'Destacar ramo';

  @override
  String get computationBranchesSelectConfiguration =>
      'Selecione uma configuração para inspecioná-la.';

  @override
  String get computationBranchesNone =>
      'Nenhum ramo de computação foi registrado.';

  @override
  String get computationBranchesNoConfigurations =>
      'Este ramo não tem configurações registradas.';

  @override
  String get computationBranchesUnavailable => 'Inspeção de ramos indisponível';

  @override
  String get computationBranchesPreviousBranch => 'Ramo anterior';

  @override
  String get computationBranchesNextBranch => 'Próximo ramo';

  @override
  String get computationBranchesPreviousConfigurations =>
      'Configurações anteriores';

  @override
  String get computationBranchesNextConfigurations => 'Próximas configurações';

  @override
  String get computationBranchesAccepted => 'Aceito';

  @override
  String get computationBranchesRejected => 'Rejeitado';

  @override
  String get computationBranchesDead => 'Beco sem saída';

  @override
  String get computationBranchesBoundedUnknown =>
      'Desconhecido no limite de execução';

  @override
  String get computationBranchesCycle => 'Ciclo detectado';

  @override
  String get computationBranchesCancelled => 'Cancelado';

  @override
  String get computationBranchesFailed => 'Falhou';

  @override
  String get computationBranchesSimulationNotRun =>
      'Execute uma simulação para inspecionar seus ramos.';

  @override
  String get computationBranchesNotRecorded =>
      'Esta simulação registra um traço, mas não todos os ramos explorados.';

  @override
  String get computationBranchesDeterministic =>
      'Esta execução seguiu um único caminho determinístico.';

  @override
  String get computationBranchesUnsupported =>
      'Esta simulação não pode fornecer dados de ramos.';

  @override
  String get computationBranchesInspect => 'Inspecionar ramos de computação';

  @override
  String get computationBranchesHide => 'Ocultar ramos de computação';

  @override
  String get computationBranchesInspectHint =>
      'Revise cada caminho de execução não determinístico registrado';

  @override
  String computationBranchesBranchName(int index) {
    return 'Ramo $index';
  }

  @override
  String computationBranchesConfigurationName(int index) {
    return 'Configuração $index';
  }

  @override
  String computationBranchesBranchPosition(int index, int total) {
    return 'Ramo $index de $total';
  }

  @override
  String computationBranchesConfigurationRange(int start, int end, int total) {
    return 'Configurações $start-$end de $total';
  }

  @override
  String computationBranchesBranchOption(String branch, String outcome) {
    return '$branch · $outcome';
  }

  @override
  String computationBranchesBranchAnnouncement(
    String position,
    String branch,
    String outcome,
  ) {
    return '$position. $branch. $outcome.';
  }

  @override
  String computationBranchesConfigurationSemantic(
    String hasOutcome,
    String configuration,
    String outcome,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasOutcome, {
      'true': 'Configuração: $configuration, resultado: $outcome',
      'other': 'Configuração: $configuration',
    });
    return '$_temp0';
  }

  @override
  String computationBranchesOutcomeSemantic(String outcome) {
    return 'Resultado: $outcome';
  }

  @override
  String computationBranchesUnavailableSemantic(String reason) {
    return 'Inspeção de ramos indisponível. $reason';
  }

  @override
  String get languageComparisonInconclusive =>
      'Inconclusivo dentro dos limites';

  @override
  String get languageComparisonAnalysisFailed => 'A análise falhou';

  @override
  String get languageComparisonInvalidInput => 'Máquina ou entrada inválida';

  @override
  String languageComparisonValidationEmptyStateSet(String automaton) {
    return 'O $automaton deve ter pelo menos um estado';
  }

  @override
  String languageComparisonValidationMissingInitialState(String automaton) {
    return 'O $automaton deve ter um estado inicial';
  }

  @override
  String languageComparisonValidationInitialStateOutsideSet(String automaton) {
    return 'O estado inicial do $automaton deve pertencer ao conjunto de estados';
  }

  @override
  String get languageComparisonConversionFailed => 'A conversão falhou';

  @override
  String get languageComparisonLimitReached => 'Limite atingido';

  @override
  String languageComparisonStatusSemantic(String status) {
    return 'Comparação de linguagens: $status';
  }

  @override
  String languageComparisonWitnessSemantic(String value) {
    return 'Cadeia distintiva encontrada: $value';
  }

  @override
  String languageComparisonStatisticsSemantic(
    int statesA,
    int statesB,
    int transitionsA,
    int transitionsB,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      statesA,
      locale: localeName,
      other: '$statesA estados',
      one: '1 estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      statesB,
      locale: localeName,
      other: '$statesB estados',
      one: '1 estado',
    );
    String _temp2 = intl.Intl.pluralLogic(
      transitionsA,
      locale: localeName,
      other: '$transitionsA transições',
      one: '1 transição',
    );
    String _temp3 = intl.Intl.pluralLogic(
      transitionsB,
      locale: localeName,
      other: '$transitionsB transições',
      one: '1 transição',
    );
    return 'Autômato A: $_temp0, autômato B: $_temp1, autômato A: $_temp2, autômato B: $_temp3';
  }

  @override
  String languageComparisonCanvasSemantic(
    String title,
    int stateCount,
    int transitionCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount estados',
      one: '1 estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: '1 transição',
    );
    return '$title. $_temp0, $_temp1';
  }

  @override
  String languageComparisonStepSemantic(int step, String title) {
    return 'Etapa $step: $title';
  }

  @override
  String get languageComparisonFailureMalformedExplanation =>
      'Verifique se ambos os autômatos têm estados e um estado inicial.';

  @override
  String get languageComparisonFailureDeterminizationExplanation =>
      'Um dos autômatos não pôde ser convertido em um autômato determinístico.';

  @override
  String get languageComparisonFailureNormalizationExplanation =>
      'Não foi possível completar os autômatos sobre um alfabeto compartilhado.';

  @override
  String get languageComparisonFailureProductExplanation =>
      'Não foi possível construir o autômato produto.';

  @override
  String get languageComparisonFailureTimeoutExplanation =>
      'A comparação excedeu o limite de tempo sem decidir a equivalência.';

  @override
  String get languageComparisonFailureStateLimitExplanation =>
      'A comparação atingiu o limite de estados do produto sem decidir a equivalência.';

  @override
  String get languageComparisonFailureInternalExplanation =>
      'A comparação parou devido a um erro interno.';

  @override
  String languageComparisonFailureSemantic(String reason, String explanation) {
    return '$reason. $explanation';
  }

  @override
  String get languageComparisonStepValidation => 'Validação';

  @override
  String get languageComparisonStepInitialization => 'Inicialização';

  @override
  String get languageComparisonStepAlphabetNormalization =>
      'Normalização do alfabeto';

  @override
  String get languageComparisonStepDfaConversion => 'Conversão em AFD';

  @override
  String get languageComparisonStepDfaCompletion => 'Completude do AFD';

  @override
  String get languageComparisonStepProductConstruction =>
      'Construção do produto';

  @override
  String get languageComparisonStepProductStateCreated =>
      'Estado do produto criado';

  @override
  String get languageComparisonStepProductTransition => 'Transição do produto';

  @override
  String get languageComparisonStepProductComplete =>
      'Construção do produto concluída';

  @override
  String get languageComparisonStepBfsSearch => 'Busca em largura';

  @override
  String get languageComparisonStepInitialPairCheck =>
      'Verificação do par inicial';

  @override
  String get languageComparisonStepStatePairVisit => 'Visita ao par de estados';

  @override
  String get languageComparisonStepCounterexampleFound =>
      'Contraexemplo encontrado';

  @override
  String get languageComparisonStepBfsComplete => 'Busca em largura concluída';

  @override
  String get languageComparisonStepResult => 'Resultado da comparação';

  @override
  String get languageComparisonStepError => 'Erro de comparação';

  @override
  String get languageComparisonStepUnknown => 'Etapa desconhecida';

  @override
  String get languageComparisonDescriptionValidation =>
      'Validando os autômatos de entrada';

  @override
  String get languageComparisonDescriptionInitialization =>
      'Inicializando a construção do autômato produto';

  @override
  String get languageComparisonDescriptionAlphabet =>
      'Combinando os alfabetos dos dois autômatos';

  @override
  String languageComparisonDescriptionNfaToDfa(String automaton) {
    return 'Convertendo o autômato $automaton de AFN para AFD';
  }

  @override
  String languageComparisonDescriptionDfaCompletion(String automaton) {
    return 'Completando o AFD $automaton com um estado sumidouro, se necessário';
  }

  @override
  String get languageComparisonDescriptionProductStart =>
      'Iniciando a construção do autômato produto';

  @override
  String languageComparisonDescriptionProductState(String state) {
    return 'Estado do produto $state criado';
  }

  @override
  String languageComparisonDescriptionProductTransition(String symbol) {
    return 'Transição do produto criada com o símbolo $symbol';
  }

  @override
  String get languageComparisonDescriptionProductComplete =>
      'Construção do autômato produto concluída';

  @override
  String get languageComparisonDescriptionBfsStart =>
      'Iniciando a busca em largura por uma cadeia de distinção';

  @override
  String languageComparisonDescriptionInitialCheck(String different) {
    String _temp0 = intl.Intl.selectLogic(different, {
      'true':
          'Os estados iniciais têm aceitações diferentes; a cadeia vazia os distingue',
      'other': 'Os estados iniciais têm o mesmo estado de aceitação',
    });
    return '$_temp0';
  }

  @override
  String languageComparisonDescriptionExplorePair(
    String stateA,
    String stateB,
  ) {
    return 'Explorando o par de estados ($stateA, $stateB)';
  }

  @override
  String languageComparisonDescriptionCounterexample(String value) {
    return 'Cadeia de distinção encontrada: $value';
  }

  @override
  String get languageComparisonDescriptionBfsComplete =>
      'Busca em largura concluída; todos os pares de estados foram explorados';

  @override
  String languageComparisonDescriptionResult(String equivalent) {
    String _temp0 = intl.Intl.selectLogic(equivalent, {
      'true': 'Os autômatos são equivalentes e reconhecem a mesma linguagem',
      'other':
          'Os autômatos não são equivalentes; uma cadeia de distinção foi encontrada',
    });
    return '$_temp0';
  }

  @override
  String get languageComparisonDescriptionError =>
      'A comparação parou com um erro';

  @override
  String get languageComparisonDescriptionUnknown =>
      'Não há descrição localizada disponível para esta etapa do traço.';

  @override
  String get languageComparisonDetailAutomaton => 'Autômato';

  @override
  String get languageComparisonDetailAutomatonAAlphabet =>
      'Alfabeto do autômato A';

  @override
  String get languageComparisonDetailAutomatonBAlphabet =>
      'Alfabeto do autômato B';

  @override
  String get languageComparisonDetailSharedAlphabet => 'Alfabeto compartilhado';

  @override
  String get languageComparisonDetailSinkState => 'Estado sumidouro';

  @override
  String get languageComparisonDetailAlphabetSize => 'Tamanho do alfabeto';

  @override
  String get languageComparisonDetailStatePair => 'Par de estados';

  @override
  String get languageComparisonDetailProductState => 'Estado do produto';

  @override
  String get languageComparisonDetailAccepting => 'De aceitação';

  @override
  String get languageComparisonDetailTarget => 'Destino';

  @override
  String get languageComparisonDetailAcceptingStates => 'Estados de aceitação';

  @override
  String get languageComparisonDetailInitialPair => 'Par inicial';

  @override
  String get languageComparisonDetailAcceptance => 'Aceitação';

  @override
  String get languageComparisonDetailPath => 'Caminho';

  @override
  String get languageComparisonDetailPathLength => 'Comprimento do caminho';

  @override
  String get languageComparisonDetailDistinguishingString =>
      'Cadeia de distinção';

  @override
  String get languageComparisonDetailPairsExplored => 'Pares explorados';

  @override
  String get languageComparisonDetailEquivalent => 'Equivalentes';

  @override
  String get languageComparisonDetailReason => 'Motivo';

  @override
  String get languageComparisonDetailStage => 'Estágio';

  @override
  String get languageComparisonDetailMessage => 'Mensagem';

  @override
  String get languageComparisonDetailRawType => 'Tipo bruto';

  @override
  String get languageComparisonValueUnknown => 'Desconhecido';

  @override
  String get languageComparisonValueAdded => 'Adicionado';

  @override
  String get languageComparisonValueNotNeeded => 'Não necessário';

  @override
  String get languageComparisonValueNew => 'Novo';

  @override
  String get languageComparisonValueExisting => 'Existente';

  @override
  String languageComparisonValueBeforeAfter(String before, String after) {
    return '$before → $after';
  }

  @override
  String languageComparisonValueStatePair(String stateA, String stateB) {
    return '$stateA / $stateB';
  }

  @override
  String languageComparisonValueAcceptance(String acceptsA, String acceptsB) {
    String _temp0 = intl.Intl.selectLogic(acceptsA, {
      'true': 'aceita a entrada',
      'other': 'rejeita a entrada',
    });
    String _temp1 = intl.Intl.selectLogic(acceptsB, {
      'true': 'aceita a entrada',
      'other': 'rejeita a entrada',
    });
    return 'O autômato A $_temp0; o autômato B $_temp1';
  }

  @override
  String languageComparisonExecuting(String algorithm) {
    return 'Executando $algorithm';
  }

  @override
  String get languageComparisonComplete => 'Comparação concluída';

  @override
  String get languageComparisonLegacyTitle => 'Comparação de equivalência';

  @override
  String get languageComparisonLegacyEquivalent =>
      'Os autômatos são equivalentes';

  @override
  String get languageComparisonLegacyNotEquivalent =>
      'Os autômatos não são equivalentes';

  @override
  String get pumpingMessagePumpingLengthPositive =>
      'O comprimento de bombeamento deve ser positivo.';

  @override
  String get pumpingMessageExponentNonNegative =>
      'O expoente de bombeamento deve ser não negativo.';

  @override
  String get pumpingMessageMaximumTokensNonNegative =>
      'O limite de tokens deve ser não negativo.';

  @override
  String pumpingMessageRequiredTextNotEmpty(String field) {
    return 'O campo $field não pode ficar vazio.';
  }

  @override
  String get pumpingMessageSuggestedWitnessNotEmpty =>
      'A testemunha sugerida não pode ficar vazia.';

  @override
  String get pumpingMessageCustomTitleNotEmpty =>
      'O título personalizado não pode ficar vazio.';

  @override
  String get pumpingMessageWitnessRequiresPumpingLength =>
      'Uma testemunha exige um comprimento de bombeamento.';

  @override
  String pumpingMessageWitnessMinimumTokens(int minimum) {
    return 'A testemunha deve conter pelo menos $minimum tokens.';
  }

  @override
  String pumpingMessageDecompositionTheoremMismatch(
    String actual,
    String expected,
  ) {
    return 'A decomposição $actual não pode ser usada em uma sessão $expected.';
  }

  @override
  String get pumpingMessageDecompositionWitnessMismatch =>
      'A decomposição não reconstrói esta testemunha.';

  @override
  String get pumpingMessageDecompositionConstraintViolation =>
      'A decomposição viola as restrições do teorema.';

  @override
  String get pumpingMessageEnterPositivePumpingLength =>
      'Digite um inteiro positivo para p.';

  @override
  String get pumpingMessageEnterNonNegativeExponent =>
      'Digite um inteiro não negativo para i.';

  @override
  String get pumpingMessageInvalidTokenArray =>
      'Digite um vetor JSON de tokens textuais.';

  @override
  String get pumpingMessageNoValidDecomposition =>
      'Nenhuma decomposição válida está disponível.';

  @override
  String pumpingMessageDecompositionsEnumerated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count decomposições válidas enumeradas para esta testemunha finita.',
      one: '1 decomposição válida enumerada para esta testemunha finita.',
    );
    return '$_temp0';
  }

  @override
  String pumpingMessagePumpedWordBounded(int minimum, int maximum) {
    return 'A palavra bombeada precisa de pelo menos $minimum tokens; o limite é $maximum.';
  }

  @override
  String get pumpingMessageChooseBoundedExponent =>
      'Escolha um expoente cuja palavra bombeada caiba no limite de tokens.';

  @override
  String get pumpingMessageCounterexampleEvidence =>
      'Este expoente é uma evidência concreta de contraexemplo para a decomposição selecionada.';

  @override
  String get pumpingMessageFiniteCheckInconclusive =>
      'A palavra amostrada permaneceu na linguagem. Esta verificação finita não prova nenhuma afirmação universal.';

  @override
  String get pumpingMessageSessionImported => 'Sessão importada.';

  @override
  String get pumpingMessageTransitionWrongStage =>
      'Conclua primeiro a etapa atual dos quantificadores.';

  @override
  String get pumpingMessageTransitionWrongPlayer =>
      'Essa escolha pertence ao outro jogador.';

  @override
  String get pumpingMessageTransitionWitnessTooShort =>
      'A testemunha deve conter pelo menos p tokens.';

  @override
  String get pumpingMessageTransitionWitnessOutsideLanguage =>
      'A testemunha selecionada não pertence à linguagem.';

  @override
  String simulationOutcomeTimeout(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'O tempo limite da simulação foi atingido após $seconds segundos.',
      one: 'O tempo limite da simulação foi atingido após um segundo.',
      zero: 'O tempo limite da simulação foi atingido em menos de um segundo.',
    );
    return '$_temp0';
  }

  @override
  String simulationOutcomeProvenCycle(int steps) {
    String _temp0 = intl.Intl.pluralLogic(
      steps,
      locale: localeName,
      other:
          'A simulação detectou uma configuração repetida após $steps passos.',
      one: 'A simulação detectou uma configuração repetida após um passo.',
      zero:
          'A simulação detectou uma configuração repetida antes de registrar um passo.',
    );
    return '$_temp0';
  }

  @override
  String get simulationOutcomeLegacyFailure =>
      'Não foi possível concluir a simulação.';

  @override
  String get tmMultiTapeTraceTitle => 'Rastro sincronizado de múltiplas fitas';

  @override
  String get tmMultiTapeNoTransition => 'Nenhuma transição foi executada.';

  @override
  String tmMultiTapeStep(int step, String fromState, String toState) {
    return 'Passo $step: $fromState → $toState';
  }

  @override
  String tmMultiTapeAtomicTransition(String transitionId, int tapeCount) {
    String _temp0 = intl.Intl.pluralLogic(
      tapeCount,
      locale: localeName,
      other: '$tapeCount fitas atualizadas atomicamente',
      one: '1 fita atualizada atomicamente',
    );
    return 'Transição $transitionId; $_temp0';
  }

  @override
  String get tmMultiTapeSpaceMetricsSemantic =>
      'Métricas de espaço de múltiplas fitas';

  @override
  String get tmMultiTapeSpaceMetricsExplanation =>
      'O espaço é medido por fita como o intervalo visitado pela cabeça lógica e a quantidade máxima de células não brancas simultâneas.';

  @override
  String tmMultiTapeMetrics(int tapeNumber, int span, int nonblankCount) {
    return 'Fita $tapeNumber: intervalo $span, máximo de células não brancas $nonblankCount';
  }

  @override
  String tmMultiTapeTotalNonblank(int count) {
    return 'Máximo total de células não brancas simultâneas: $count';
  }

  @override
  String tmMultiTapeConfigurationSemantic(
    int tapeNumber,
    int head,
    String operation,
  ) {
    return 'Fita $tapeNumber, cabeça em $head, operação $operation';
  }

  @override
  String tmMultiTapeTitle(int tapeNumber) {
    return 'Fita $tapeNumber';
  }

  @override
  String tmMultiTapeHeadSummary(int head, String operation) {
    return 'Cabeça $head · $operation';
  }

  @override
  String tmMultiTapeCellSemantic(int position, String symbol) {
    return 'Célula $position, $symbol';
  }

  @override
  String tmMultiTapeHeadCellSemantic(int position, String symbol) {
    return 'Célula $position, $symbol, cabeça';
  }

  @override
  String tmMultiTapePosition(int position) {
    return '$position';
  }

  @override
  String get serviceSimulationRunnerStartFailed =>
      'Não foi possível iniciar o processo de simulação.';

  @override
  String get serviceSimulationRunnerExecutionFailed =>
      'Não foi possível concluir a simulação.';

  @override
  String get serviceSimulationRunnerWorkerFailed =>
      'O processo de simulação falhou.';

  @override
  String get serviceSimulationRunnerWorkerExitedUnexpectedly =>
      'O processo de simulação foi encerrado inesperadamente.';

  @override
  String get serviceSimulationRunnerInvalidWorkerResponse =>
      'O processo de simulação retornou uma resposta inválida.';

  @override
  String serviceTmBlockEditorDuplicateBlockId(String block) {
    return 'Uma máquina já usa o ID de bloco $block.';
  }

  @override
  String serviceTmBlockEditorDuplicateBlockName(String name) {
    return 'Um bloco já usa o nome $name.';
  }

  @override
  String get serviceTmBlockEditorInvalidBlockName =>
      'Os nomes dos blocos devem ser não vazios e únicos.';

  @override
  String serviceTmBlockEditorReferencedBlock(String block) {
    return 'O bloco $block ainda está referenciado. Escolha uma resolução explícita.';
  }

  @override
  String serviceTmBlockEditorMissingOwnerMachine(String machine) {
    return 'A máquina $machine não existe.';
  }

  @override
  String serviceTmBlockEditorMissingAnchorState(String state, String machine) {
    return 'O estado $state não existe em $machine.';
  }

  @override
  String serviceTmBlockEditorStateAlreadyInvokesBlock(String state) {
    return 'O estado $state já invoca um bloco.';
  }

  @override
  String serviceTmBlockEditorDuplicateRootState(String state) {
    return 'O estado $state já existe na máquina raiz.';
  }

  @override
  String serviceTmBlockEditorMissingInvocation(String invocation) {
    return 'A invocação $invocation não existe.';
  }

  @override
  String get serviceTmBlockEditorNothingToUndo =>
      'Não há nenhuma edição de bloco de construção para desfazer.';

  @override
  String get serviceTmBlockEditorNothingToRedo =>
      'Não há nenhuma edição de bloco de construção para refazer.';

  @override
  String serviceTmBlockEditorMissingBlock(String block) {
    return 'O bloco $block não existe.';
  }

  @override
  String serviceTmBlockEditorInvalidProject(String diagnostic) {
    String _temp0 = intl.Intl.selectLogic(diagnostic, {
      'duplicateMachineId': 'Um bloco reutiliza o ID da máquina raiz.',
      'duplicateBlockName':
          'Os nomes dos blocos devem ser não vazios e únicos.',
      'duplicateInvocationId': 'Um ID de invocação está duplicado.',
      'duplicateInvocationState': 'Um estado invoca mais de um bloco.',
      'missingReference': 'Uma invocação referencia um bloco ausente.',
      'revisionMismatch':
          'Uma invocação usa uma revisão desatualizada do bloco.',
      'missingAnchorState': 'Uma invocação não possui um estado no grafo.',
      'missingInitialState': 'Um bloco não possui estado inicial.',
      'tapeCountMismatch':
          'Um bloco usa uma quantidade de fitas diferente da máquina raiz.',
      'blankSymbolMismatch':
          'Um bloco usa um símbolo branco diferente da máquina raiz.',
      'nestedLibrary': 'Um bloco contém uma biblioteca incorporada.',
      'recursiveDependency': 'O grafo de dependências dos blocos é recursivo.',
      'other': 'O projeto de blocos de construção é inválido.',
    });
    return '$_temp0';
  }

  @override
  String get serviceManualConversionStoreMalformedPayload =>
      'A construção salva está malformada.';

  @override
  String serviceFileOperationsOperationFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read': 'Não foi possível ler o arquivo selecionado.',
      'write': 'Não foi possível salvar o arquivo.',
      'encodePng': 'Não foi possível codificar a imagem PNG.',
      'exportPng': 'Não foi possível exportar a imagem PNG.',
      'exportSvg': 'Não foi possível exportar o documento SVG.',
      'directory': 'A pasta de documentos do aplicativo não está disponível.',
      'create': 'Não foi possível criar um novo local de arquivo.',
      'list': 'Não foi possível listar os arquivos salvos.',
      'delete': 'Não foi possível excluir o arquivo selecionado.',
      'download': 'Não foi possível iniciar o download.',
      'other': 'Não foi possível concluir a operação de arquivo.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsAccessDenied(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'O Turing Lab não tem permissão para ler o arquivo selecionado. Selecione-o novamente e tente outra vez.',
      'write':
          'O Turing Lab não tem permissão para salvar no local selecionado. Escolha-o novamente e tente outra vez.',
      'other':
          'O Turing Lab não tem permissão para acessar o local selecionado. Escolha-o novamente e tente outra vez.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsLocationMissing(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'O arquivo selecionado não está mais disponível. Selecione-o novamente e tente outra vez.',
      'write':
          'O local de salvamento selecionado não está mais disponível. Escolha outro local e tente outra vez.',
      'delete': 'O arquivo selecionado não existe mais.',
      'other':
          'O local selecionado não está mais disponível. Escolha-o novamente e tente outra vez.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsAccessFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'Não foi possível acessar o arquivo selecionado para leitura. Selecione-o novamente e tente outra vez.',
      'write':
          'Não foi possível acessar o local selecionado para salvar. Escolha-o novamente e tente outra vez.',
      'other':
          'Não foi possível acessar o local selecionado. Escolha-o novamente e tente outra vez.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsWebUnsupported(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'read':
          'Não é possível ler um arquivo do navegador pelo caminho. Use o seletor de arquivos.',
      'exportPng':
          'A exportação para PNG não está disponível no aplicativo web.',
      'directory':
          'A pasta de documentos do aplicativo não está disponível no aplicativo web.',
      'create':
          'Não é possível criar um caminho de arquivo local no aplicativo web.',
      'list': 'Não é possível listar arquivos locais no aplicativo web.',
      'delete':
          'Não é possível excluir um arquivo local pelo caminho no aplicativo web.',
      'other':
          'Esta operação de arquivo não está disponível no aplicativo web.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecUnsupported(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'document': 'Este tipo de documento não é compatível.',
      'feature': 'Este documento usa um recurso sem suporte.',
      'schema': 'O esquema deste documento não é compatível.',
      'format': 'O formato deste documento não é compatível.',
      'direction': 'Esta operação não é compatível na direção solicitada.',
      'other': 'Esta operação de documento não é compatível.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecAmbiguous(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count codecs de documento compatíveis corresponderam. Escolha um formato específico.',
      one:
          'Um codec de documento compatível foi identificado, mas o formato continua ambíguo.',
      zero: 'Nenhum codec de documento compatível foi identificado.',
    );
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecMalformed(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'syntax': 'A sintaxe do documento está malformada.',
      'invalidUtf8': 'O documento não contém UTF-8 válido.',
      'missingField': 'Falta um campo obrigatório no documento.',
      'invalidValue': 'O documento contém um valor inválido.',
      'duplicateIdentity': 'O documento contém um identificador duplicado.',
      'other': 'O documento está malformado.',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecResourceLimit(
    String limit,
    int actual,
    int maximum,
  ) {
    String _temp0 = intl.Intl.selectLogic(limit, {
      'bytes': 'O documento usa $actual bytes; o limite é $maximum.',
      'xmlDepth':
          'A profundidade de aninhamento do XML é $actual; o limite é $maximum.',
      'xmlElements': 'O XML contém $actual elementos; o limite é $maximum.',
      'xmlDtdOrEntity':
          'O XML contém uma declaração DTD ou de entidade proibida.',
      'jsonDepth':
          'A profundidade de aninhamento do JSON é $actual; o limite é $maximum.',
      'collectionEntries':
          'O documento contém $actual itens em coleções; o limite é $maximum.',
      'other':
          'O documento excede um limite de recursos ($actual usados; máximo de $maximum).',
    });
    return '$_temp0';
  }

  @override
  String serviceFileOperationsCodecInternalFailure(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'sniff':
          'Não foi possível identificar o formato do documento devido a um erro interno.',
      'decode':
          'Não foi possível decodificar o documento devido a um erro interno.',
      'encode':
          'Não foi possível codificar o documento devido a um erro interno.',
      'unknown': 'A operação de documento falhou devido a um erro interno.',
      'other': 'A operação de documento falhou devido a um erro interno.',
    });
    return '$_temp0';
  }

  @override
  String get serviceFileOperationsInteroperabilityReviewRequired =>
      'Revise as alterações de compatibilidade antes de importar este documento.';

  @override
  String get serviceFileOperationsLossyExportRequiresConfirmation =>
      'Revise e confirme as alterações de compatibilidade antes de exportar este documento.';

  @override
  String get serviceFileOperationsInvalidModelType =>
      'O documento contém um modelo de sistema formal diferente do esperado.';

  @override
  String get regexSimplificationStartTitle =>
      'Iniciar simplificação da expressão regular';

  @override
  String regexSimplificationStartExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int operatorCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operadores',
      one: 'um operador',
      zero: 'nenhum operador',
    );
    return 'Começando com \"$regex\". Complexidade atual: altura de estrela $starHeight, profundidade de aninhamento $nestingDepth e $_temp0. Identidades algébricas serão aplicadas para encontrar uma forma equivalente mais simples.';
  }

  @override
  String get regexSimplificationAnalyzeTitle =>
      'Analisar complexidade da expressão regular';

  @override
  String regexSimplificationAnalyzeExplanation(
    String regex,
    int starHeight,
    int nestingDepth,
    int alphabetSize,
    int operatorCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      alphabetSize,
      locale: localeName,
      other: '$alphabetSize símbolos distintos',
      one: 'um símbolo distinto',
      zero: 'nenhum símbolo distinto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operadores',
      one: 'um operador',
      zero: 'nenhum operador',
    );
    return 'Analisando \"$regex\": altura de estrela $starHeight, profundidade de aninhamento $nestingDepth, $_temp0 e $_temp1.';
  }

  @override
  String regexSimplificationApplyTitle(String ruleName) {
    return 'Aplicar $ruleName';
  }

  @override
  String regexSimplificationApplyExplanation(
    String ruleName,
    String matched,
    String positionDescription,
    String replacement,
    String ruleDescription,
    String lengthChangeDescription,
  ) {
    return 'Aplicando $ruleName. O trecho \"$matched\" foi encontrado $positionDescription e substituído por \"$replacement\". $ruleDescription. $lengthChangeDescription';
  }

  @override
  String get regexSimplificationPositionUnavailable =>
      'em uma posição indisponível';

  @override
  String regexSimplificationPositionValue(int position) {
    return 'na posição $position';
  }

  @override
  String regexSimplificationLengthReduced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres foram economizados.',
      one: 'Um caractere foi economizado.',
    );
    return '$_temp0';
  }

  @override
  String get regexSimplificationLengthUnchanged =>
      'O comprimento da expressão não mudou.';

  @override
  String regexSimplificationLengthIncreased(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A expressão aumentou em $count caracteres.',
      one: 'A expressão aumentou em um caractere.',
    );
    return '$_temp0';
  }

  @override
  String get regexSimplificationGenerateSamplesTitle =>
      'Gerar cadeias de exemplo';

  @override
  String regexSimplificationGenerateSamplesEmptyExplanation(String regex) {
    return 'Nenhuma cadeia de exemplo foi gerada para \"$regex\". A expressão pode aceitar a linguagem vazia.';
  }

  @override
  String regexSimplificationGenerateSamplesExplanation(
    String regex,
    int count,
    String samples,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cadeias de exemplo',
      one: 'uma cadeia de exemplo',
    );
    return 'Foram geradas $_temp0 para \"$regex\": $samples. Essas cadeias pertencem à linguagem descrita pela expressão.';
  }

  @override
  String get regexSimplificationNoRuleTitle => 'Nenhuma outra simplificação';

  @override
  String regexSimplificationNoRuleExplanation(String regex, int ruleCount) {
    String _temp0 = intl.Intl.pluralLogic(
      ruleCount,
      locale: localeName,
      other: '$ruleCount regras foram aplicadas.',
      one: 'Uma regra foi aplicada.',
      zero: 'Nenhuma regra foi aplicada.',
    );
    return 'Todas as regras de simplificação foram verificadas em \"$regex\", e nenhuma se aplica. A expressão está na forma mais simples disponível por meio dessas identidades algébricas. $_temp0';
  }

  @override
  String get regexSimplificationCompletionTitle => 'Simplificação concluída';

  @override
  String regexSimplificationCompletionExplanation(
    String original,
    int originalLength,
    String simplified,
    int simplifiedLength,
    double reductionPercent,
    int ruleCount,
    int starHeight,
    int nestingDepth,
    int operatorCount,
  ) {
    final intl.NumberFormat reductionPercentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String reductionPercentString = reductionPercentNumberFormat.format(
      reductionPercent,
    );

    String _temp0 = intl.Intl.pluralLogic(
      ruleCount,
      locale: localeName,
      other: '$ruleCount regras foram aplicadas.',
      one: 'Uma regra foi aplicada.',
      zero: 'Nenhuma regra foi aplicada.',
    );
    String _temp1 = intl.Intl.pluralLogic(
      operatorCount,
      locale: localeName,
      other: '$operatorCount operadores',
      one: 'um operador',
      zero: 'nenhum operador',
    );
    return 'A simplificação alterou \"$original\" ($originalLength caracteres) para \"$simplified\" ($simplifiedLength caracteres), uma redução de $reductionPercentString%. $_temp0 Métricas finais: altura de estrela $starHeight, profundidade de aninhamento $nestingDepth e $_temp1.';
  }

  @override
  String get regexSimplificationNoRuleSummary => 'Nenhuma regra aplicada';

  @override
  String regexSimplificationRuleSummary(
    String ruleName,
    String matched,
    String replacement,
  ) {
    return '$ruleName: \"$matched\" → \"$replacement\"';
  }

  @override
  String regexSimplificationStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Início',
      'analyze': 'Análise',
      'applyRule': 'Aplicação de regra',
      'noRuleApplicable': 'Nenhuma regra aplicável',
      'generateSamples': 'Geração de exemplos',
      'completion': 'Conclusão',
      'other': 'Etapa desconhecida',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Inicia o processo de simplificação da expressão regular',
      'analyze': 'Analisa as métricas de complexidade da expressão regular',
      'applyRule': 'Aplica uma regra algébrica de simplificação',
      'noRuleApplicable':
          'Informa que nenhuma outra regra de simplificação se aplica',
      'generateSamples':
          'Gera cadeias de exemplo que correspondem à expressão regular',
      'completion': 'Conclui o processo de simplificação',
      'other': 'Etapa de simplificação desconhecida',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationRuleName(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'emptyUnion': 'União com conjunto vazio (r|∅ → r)',
      'emptyUnionLeft': 'União com conjunto vazio à esquerda (∅|r → r)',
      'emptySetConcatenation': 'Concatenação com conjunto vazio (r∅ → ∅)',
      'emptySetConcatenationLeft':
          'Concatenação com conjunto vazio à esquerda (∅r → ∅)',
      'emptyStringConcatenation': 'Concatenação com cadeia vazia (rε → r)',
      'emptyStringConcatenationLeft':
          'Concatenação com cadeia vazia à esquerda (εr → r)',
      'starIdempotence': 'Idempotência do fecho (r** → r*)',
      'emptySetStar': 'Fecho do conjunto vazio (∅* → ε)',
      'emptyStringStar': 'Fecho da cadeia vazia (ε* → ε)',
      'unionIdempotence': 'Idempotência da união (r|r → r)',
      'doubleStar': 'Fecho duplo ((r*)* → r*)',
      'plusToStar': 'Mais para fecho (ε|rr* → r*)',
      'plusToStarAlt': 'Forma alternativa de mais para fecho (ε|r*r → r*)',
      'plusExpansion': 'Expansão do operador mais (r+ → rr*)',
      'optionalExpansion': 'Expansão do operador opcional (r? → ε|r)',
      'optionalStarSimplification': 'Fecho de opcional ((ε|r)* → r*)',
      'starConcatenationIdempotence':
          'Idempotência da concatenação de fechos (r*r* → r*)',
      'unionStarDistribution': 'Distribuição do fecho sobre união',
      'redundantParentheses': 'Remover parênteses redundantes',
      'characterClassCreation': 'Criar uma classe de caracteres',
      'other': 'Regra de simplificação desconhecida',
    });
    return '$_temp0';
  }

  @override
  String regexSimplificationRuleDescription(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'emptyUnion':
          'A união com o conjunto vazio não tem efeito; o resultado é o outro operando',
      'emptyUnionLeft':
          'O conjunto vazio à esquerda de uma união não tem efeito',
      'emptySetConcatenation':
          'A concatenação com o conjunto vazio produz o conjunto vazio',
      'emptySetConcatenationLeft':
          'O conjunto vazio à esquerda de uma concatenação produz o conjunto vazio',
      'emptyStringConcatenation':
          'A concatenação com a cadeia vazia não tem efeito',
      'emptyStringConcatenationLeft':
          'A cadeia vazia à esquerda de uma concatenação não tem efeito',
      'starIdempotence':
          'Aplicar duas vezes o fecho de Kleene equivale a aplicá-lo uma vez',
      'emptySetStar': 'O fecho de Kleene do conjunto vazio é a cadeia vazia',
      'emptyStringStar': 'O fecho de Kleene da cadeia vazia é a cadeia vazia',
      'unionIdempotence':
          'A união de expressões idênticas se simplifica para uma cópia',
      'doubleStar':
          'O fecho de uma expressão com fecho se simplifica para um fecho',
      'plusToStar':
          'A união da cadeia vazia com uma ou mais repetições equivale a zero ou mais repetições',
      'plusToStarAlt':
          'A forma alternativa de uma ou mais repetições com a cadeia vazia equivale a zero ou mais repetições',
      'plusExpansion':
          'O operador mais se expande para uma concatenação com fecho',
      'optionalExpansion':
          'O operador opcional se expande para uma união com a cadeia vazia',
      'optionalStarSimplification':
          'O fecho de uma expressão opcional se simplifica para um fecho',
      'starConcatenationIdempotence':
          'A concatenação de fechos idênticos se simplifica para um fecho',
      'unionStarDistribution':
          'O fecho se distribui sobre uma união em padrões específicos',
      'redundantParentheses':
          'Parênteses que não afetam a precedência podem ser removidos',
      'characterClassCreation':
          'Várias alternativas de um único caractere podem formar uma classe de caracteres',
      'other': 'Regra de simplificação desconhecida',
    });
    return '$_temp0';
  }

  @override
  String get regexSimplificationEmptyInput =>
      'É necessária uma expressão regular.';

  @override
  String regexSimplificationUnmatchedClosingParenthesis(int position) {
    return 'Parêntese de fechamento sem correspondência na posição $position.';
  }

  @override
  String regexSimplificationUnclosedOpeningParentheses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parênteses de abertura não foram fechados.',
      one: 'Um parêntese de abertura não foi fechado.',
    );
    return '$_temp0';
  }

  @override
  String get tmTapeBranchDeterministic => 'Execução determinística';

  @override
  String get tmTapeBranchAcceptingNtm => 'Ramo aceitante da MTND';

  @override
  String get tmTapeBranchRejectingNtm => 'Ramo rejeitante da MTND';

  @override
  String get tmTapeBranchCyclicNtm => 'Ramo cíclico da MTND';

  @override
  String get tmTapeBranchLongestBoundedNtm =>
      'Ramo limitado mais longo da MTND';

  @override
  String get tmTapeInputLabel => 'Entrada';

  @override
  String get tmTapeSelectedBranchLabel => 'Ramo selecionado';

  @override
  String get tmTapeConclusionLabel => 'Conclusão';

  @override
  String get tmTapeConclusionExact => 'Exato para esta entrada';

  @override
  String get tmTapeConclusionBounded => 'Limitado';

  @override
  String get tmTapeExecutedTransitionsLabel => 'Transições executadas';

  @override
  String get tmTapeConfigurationsExploredLabel => 'Configurações exploradas';

  @override
  String get tmTapeStepLimitLabel => 'Limite de passos';

  @override
  String get tmTapeConfigurationLimitLabel => 'Limite de configurações';

  @override
  String get tmTapeTimeLimitLabel => 'Limite de tempo';

  @override
  String get tmTapeLimitReachedLabel => 'Limite atingido';

  @override
  String get tmTapeLimitSteps => 'Limite de passos';

  @override
  String get tmTapeLimitConfigurations => 'Limite de configurações';

  @override
  String get tmTapeLimitTimeout => 'Limite de tempo';

  @override
  String get tmTapeChangedWritesLabel => 'Escritas que alteraram uma célula';

  @override
  String get tmTapeHeadReversalsLabel => 'Inversões do cabeçote';

  @override
  String get tmTapeVisitedHeadIntervalLabel =>
      'Intervalo visitado pelo cabeçote';

  @override
  String get tmTapeDistinctCellsVisitedLabel => 'Células distintas visitadas';

  @override
  String get tmTapeMaximumNonblankLabel =>
      'Máximo simultâneo de células não vazias';

  @override
  String get tmTapeDeclaredAlphabetLabel => 'Alfabeto declarado da fita';

  @override
  String get tmTapeReadsBySymbolLabel => 'Leituras por símbolo';

  @override
  String get tmTapeWritesByOldSymbolLabel => 'Escritas por símbolo anterior';

  @override
  String get tmTapeWritesByNewSymbolLabel => 'Escritas por símbolo novo';

  @override
  String get tmTapeHeadMovementsLabel => 'Movimentos do cabeçote';

  @override
  String get tmTapeTransitionCountsLabel =>
      'Contagens de execução das transições';

  @override
  String get tmTapeUnexecutedTransitionsLabel =>
      'Transições definidas mas não executadas';

  @override
  String get tmTapeSparseDiffLabel =>
      'Diferenças esparsas entre a fita inicial e final';

  @override
  String get tmTapeCellTouchRangeLabel =>
      'Primeiro e último passo que tocou cada célula';

  @override
  String tmTapeDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String tmTapeNamedCount(String name, String count) {
    return '$name: $count';
  }

  @override
  String tmTapeHeadInterval(String minimum, String maximum) {
    return '$minimum…$maximum';
  }

  @override
  String tmTapeCellDiff(
    String position,
    String initialSymbol,
    String finalSymbol,
  ) {
    return '$position: $initialSymbol → $finalSymbol';
  }

  @override
  String tmTapeCellTouchRange(String position, String first, String last) {
    return '$position: $first…$last';
  }

  @override
  String tmTapeTraceSubtitle(String transition, String tape) {
    return '$transition\n$tape';
  }

  @override
  String get regexToNfaStartTitle => 'Iniciar construção de Thompson';

  @override
  String regexToNfaStartExplanation(String regex) {
    return 'Convertendo \"$regex\" em um AFN com a construção de Thompson. O algoritmo cria um fragmento para cada subexpressão e combina os fragmentos com transições ε.';
  }

  @override
  String regexToNfaBasicSymbolTitle(String symbol) {
    return 'Criar um AFN para \"$symbol\"';
  }

  @override
  String regexToNfaBasicSymbolExplanation(
    String symbol,
    String positionDescription,
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
    String transitions,
    int stackSize,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount estados',
      one: 'um estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
    );
    return 'Processando \"$symbol\" $positionDescription. Foi criado um fragmento de $startState até $acceptState com $_temp0 e $_temp1: $transitions. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaConcatenationTitle => 'Aplicar concatenação';

  @override
  String regexToNfaConcatenationExplanation(
    String positionDescription,
    String firstFragment,
    String secondFragment,
    String startState,
    String acceptStates,
    String transitions,
    int stackSize,
  ) {
    return 'Concatenando \"$firstFragment\" e \"$secondFragment\" $positionDescription. Foram adicionadas pontes ε: $transitions. O fragmento resultante começa em $startState e aceita em $acceptStates. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaUnionTitle => 'Aplicar união';

  @override
  String regexToNfaUnionExplanation(
    String positionDescription,
    String pattern,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Criando uma união para \"$pattern\" $positionDescription. Foram adicionados o estado inicial $startState, o estado de aceitação $acceptState e as transições ε: $transitions. Qualquer um dos ramos pode ser seguido. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaKleeneStarTitle => 'Aplicar estrela de Kleene (*)';

  @override
  String regexToNfaKleeneStarExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Aplicando a estrela de Kleene a \"$fragment\" $positionDescription. O fragmento agora começa em $startState, aceita em $acceptState e usa estas transições ε: $transitions. Ele aceita zero ou mais repetições. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaPlusTitle => 'Aplicar mais (+)';

  @override
  String regexToNfaPlusExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Aplicando o operador mais a \"$fragment\" $positionDescription. O fragmento agora começa em $startState, aceita em $acceptState e usa estas transições ε: $transitions. Ele exige pelo menos uma repetição. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaOptionalTitle => 'Aplicar opcional (?)';

  @override
  String regexToNfaOptionalExplanation(
    String fragment,
    String positionDescription,
    String startState,
    String acceptState,
    String transitions,
    int stackSize,
  ) {
    return 'Tornando \"$fragment\" opcional $positionDescription. O fragmento agora começa em $startState, aceita em $acceptState e usa estas transições ε: $transitions. Ele aceita zero ou uma ocorrência. Profundidade da pilha: $stackSize.';
  }

  @override
  String get regexToNfaCompleteTitle => 'Concluir construção do AFN';

  @override
  String regexToNfaCompleteExplanation(
    String startState,
    String acceptState,
    int stateCount,
    int transitionCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount estados',
      one: 'um estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
    );
    return 'A construção de Thompson foi concluída. O AFN começa em $startState, aceita em $acceptState e tem $_temp0 e $_temp1. Ele aceita a linguagem descrita pela expressão regular.';
  }

  @override
  String get regexToNfaPositionUnavailable => 'em uma posição implícita';

  @override
  String regexToNfaPositionValue(int position) {
    return 'na posição $position';
  }

  @override
  String regexToNfaStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Início',
      'basicSymbol': 'Símbolo básico',
      'concatenation': 'Concatenação',
      'union': 'União',
      'kleeneStar': 'Estrela de Kleene',
      'plus': 'Mais',
      'optional': 'Opcional',
      'complete': 'Conclusão',
      'other': 'Etapa desconhecida',
    });
    return '$_temp0';
  }

  @override
  String regexToNfaStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'start': 'Inicia a construção de Thompson',
      'basicSymbol': 'Cria um fragmento de AFN para um símbolo',
      'concatenation': 'Concatena dois fragmentos de AFN',
      'union': 'Cria a união de dois fragmentos de AFN',
      'kleeneStar': 'Aceita zero ou mais repetições',
      'plus': 'Aceita uma ou mais repetições',
      'optional': 'Aceita zero ou uma ocorrência',
      'complete': 'Conclui a construção do AFN',
      'other': 'Etapa de conversão desconhecida',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTitle(String type, String state) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validar autômato de entrada',
      'addInitialState': 'Adicionar novo estado inicial $state',
      'addFinalState': 'Adicionar novo estado final $state',
      'selectState': 'Selecionar $state para eliminação',
      'findIncoming': 'Encontrar transições de entrada',
      'findOutgoing': 'Encontrar transições de saída',
      'findSelfLoop': 'Verificar laços em $state',
      'createBypass': 'Criar transições de desvio',
      'combineTransitions': 'Combinar transições paralelas',
      'completeElimination': 'Concluir eliminação de $state',
      'extractRegex': 'Extrair expressão regular final',
      'completion': 'Conversão concluída',
      'other': 'Etapa de AF para expressão regular',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTypeLabel(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validação',
      'addInitialState': 'Adicionar estado inicial',
      'addFinalState': 'Adicionar estado final',
      'selectState': 'Selecionar estado',
      'findIncoming': 'Encontrar transições de entrada',
      'findOutgoing': 'Encontrar transições de saída',
      'findSelfLoop': 'Encontrar laço',
      'createBypass': 'Criar transições de desvio',
      'combineTransitions': 'Combinar transições',
      'completeElimination': 'Concluir eliminação',
      'extractRegex': 'Extrair expressão regular',
      'completion': 'Conclusão',
      'other': 'Etapa de AF para expressão regular',
    });
    return '$_temp0';
  }

  @override
  String faToRegexStepTypeDescription(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'validation': 'Validar o autômato de entrada.',
      'addInitialState': 'Adicionar um estado inicial único para normalização.',
      'addFinalState': 'Adicionar um estado final único para normalização.',
      'selectState': 'Selecionar o próximo estado a eliminar.',
      'findIncoming': 'Encontrar transições que entram no estado selecionado.',
      'findOutgoing': 'Encontrar transições que saem do estado selecionado.',
      'findSelfLoop': 'Encontrar e processar laços no estado selecionado.',
      'createBypass': 'Criar transições que desviam do estado selecionado.',
      'combineTransitions':
          'Combinar transições paralelas com união de expressões regulares.',
      'completeElimination':
          'Remover o estado selecionado após substituir seus caminhos.',
      'extractRegex':
          'Extrair a expressão regular final do autômato simplificado.',
      'completion': 'Concluir a conversão de AF para expressão regular.',
      'other': 'Processar uma etapa de AF para expressão regular.',
    });
    return '$_temp0';
  }

  @override
  String faToRegexEliminationSummary(
    String hasState,
    String state,
    int incomingStateCount,
    int outgoingStateCount,
    String hasSelfLoop,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      incomingStateCount,
      locale: localeName,
      other: '$incomingStateCount estados de entrada',
      one: '1 estado de entrada',
      zero: 'nenhum estado de entrada',
    );
    String _temp1 = intl.Intl.pluralLogic(
      outgoingStateCount,
      locale: localeName,
      other: '$outgoingStateCount estados de saída',
      one: '1 estado de saída',
      zero: 'nenhum estado de saída',
    );
    String _temp2 = intl.Intl.selectLogic(hasSelfLoop, {
      'true': 'um laço.',
      'other': 'nenhum laço.',
    });
    String _temp3 = intl.Intl.selectLogic(hasState, {
      'true': 'Eliminando $state: $_temp0, $_temp1 e $_temp2',
      'other': 'Nenhum estado está sendo eliminado.',
    });
    return '$_temp3';
  }

  @override
  String faToRegexValidationExplanation(
    int stateCount,
    int transitionCount,
    String hasInitialState,
    String hasAcceptingStates,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      stateCount,
      locale: localeName,
      other: '$stateCount estados',
      one: 'um estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
    );
    String _temp2 = intl.Intl.selectLogic(hasInitialState, {
      'true': 'Há um estado inicial.',
      'other': 'Nenhum estado inicial foi encontrado.',
    });
    String _temp3 = intl.Intl.selectLogic(hasAcceptingStates, {
      'true': 'Há estados de aceitação.',
      'other': 'Não há estados de aceitação, portanto a linguagem é vazia.',
    });
    return 'Validando o autômato finito de entrada. Ele tem $_temp0 e $_temp1. $_temp2 $_temp3';
  }

  @override
  String faToRegexAddInitialStateExplanation(String newState, String oldState) {
    return 'Adicionando o novo estado inicial $newState, com uma transição ε para o estado inicial original $oldState. Assim, resta um único estado inicial sem transições de entrada.';
  }

  @override
  String faToRegexAddFinalStateExplanation(String newState, String oldStates) {
    return 'Adicionando o novo estado final $newState. Os estados de aceitação originais, $oldStates, recebem transições ε para ele, deixando um único estado de aceitação sem transições de saída.';
  }

  @override
  String faToRegexSelectStateExplanation(
    String state,
    int remainingStateCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingStateCount,
      locale: localeName,
      other: 'restarão $remainingStateCount estados',
      one: 'restará um estado',
    );
    return 'Selecionando $state para eliminação. Transições diretas equivalentes substituirão os caminhos que passam por ele; $_temp0.';
  }

  @override
  String faToRegexFindIncomingExplanation(
    String state,
    int transitionCount,
    String states,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
      zero: 'nenhuma',
    );
    return 'Procurando transições que chegam a $state. Foram encontradas $_temp0 de: $states.';
  }

  @override
  String faToRegexFindOutgoingExplanation(
    String state,
    int transitionCount,
    String states,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
      zero: 'nenhuma',
    );
    return 'Procurando transições que saem de $state. Foram encontradas $_temp0 para: $states.';
  }

  @override
  String faToRegexFindSelfLoopExplanation(
    String hasLoop,
    String state,
    String selfLoopRegex,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasLoop, {
      'true':
          'Foi encontrado um laço em $state, combinado como $selfLoopRegex; essa expressão é inserida entre as transições de entrada e saída.',
      'other':
          'Nenhum laço foi encontrado em $state; as novas transições conectam diretamente os estados de entrada e saída.',
    });
    return '$_temp0';
  }

  @override
  String faToRegexCreateBypassExplanation(
    int transitionCount,
    String state,
    String pathRegex,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      transitionCount,
      locale: localeName,
      other: '$transitionCount transições',
      one: 'uma transição',
    );
    return 'Criando $_temp0 para desviar de $state. Cada uma combina um rótulo de entrada, o fecho do laço e um rótulo de saída; por exemplo: $pathRegex.';
  }

  @override
  String faToRegexCombineTransitionsExplanation(
    int regexCount,
    String fromState,
    String toState,
    String regexes,
    String resultingRegex,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      regexCount,
      locale: localeName,
      other: '$regexCount expressões',
      one: 'uma expressão',
    );
    return 'Combinando $_temp0 de $fromState para $toState com união: $regexes. Resultado: $resultingRegex.';
  }

  @override
  String faToRegexCompleteEliminationExplanation(
    String state,
    int remainingStateCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      remainingStateCount,
      locale: localeName,
      other: 'restam $remainingStateCount estados',
      one: 'resta um estado',
    );
    return 'O estado $state foi eliminado. Transições diretas equivalentes agora substituem todos os caminhos que passavam por ele; $_temp0.';
  }

  @override
  String faToRegexExtractRegexExplanation(
    String initialState,
    String finalState,
    String regex,
  ) {
    return 'Todos os estados intermediários foram eliminados. A leitura das transições do estado inicial $initialState ao estado final $finalState resulta em: $regex.';
  }

  @override
  String faToRegexCompletionExplanation(
    int originalStateCount,
    String regex,
    int stepCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      originalStateCount,
      locale: localeName,
      other: '$originalStateCount estados',
      one: 'um estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      stepCount,
      locale: localeName,
      other: '$stepCount etapas',
      one: 'uma etapa',
    );
    return 'O autômato de $_temp0 foi convertido em $regex em $_temp1. A expressão regular aceita a mesma linguagem.';
  }

  @override
  String bruteForceInvalidLimitNonNegative(String limit) {
    return '$limit não pode ser negativo.';
  }

  @override
  String bruteForceInvalidLimitPositive(String limit) {
    return '$limit deve ser positivo.';
  }

  @override
  String get bruteForceEmptyGrammar =>
      'A gramática deve ter pelo menos uma produção.';

  @override
  String get bruteForceInvalidStartSymbol =>
      'O símbolo inicial deve ser um não terminal declarado.';

  @override
  String bruteForceOverlappingSymbols(String symbols) {
    return 'Os símbolos da gramática não podem ser terminais e não terminais ao mesmo tempo: $symbols.';
  }

  @override
  String get bruteForceMalformedProduction =>
      'A busca por força bruta de GLC exige um único não terminal declarado no lado esquerdo de cada produção.';

  @override
  String get bruteForceDuplicateProductionId =>
      'A busca por força bruta de GLC exige IDs de produção únicos.';

  @override
  String bruteForceUndeclaredSymbol(String production, String symbol) {
    return 'A produção $production referencia o símbolo não declarado \"$symbol\".';
  }

  @override
  String bruteForceInvalidInputSymbol(String symbol) {
    return 'A cadeia de entrada contém um símbolo inválido: $symbol.';
  }

  @override
  String grammarInputTokenizationInvalidSymbol(String symbol, int position) {
    return 'A cadeia de entrada contém o símbolo inválido $symbol na posição $position.';
  }

  @override
  String get bruteForceCancelled =>
      'A busca por força bruta de GLC foi cancelada.';

  @override
  String get bruteForceRejectedExhausted =>
      'A fronteira finita de derivações da GLC foi esgotada de forma segura.';

  @override
  String bruteForceAcceptedAtLimit(String limit) {
    return 'Aceita, mas a enumeração de testemunhos parou no limite de $limit.';
  }

  @override
  String bruteForceBoundedAtLimit(String limit) {
    return 'Nenhum testemunho foi encontrado antes de o limite de $limit interromper a busca.';
  }

  @override
  String get pdaSimulationEmptyStateSet =>
      'Um AP deve ter pelo menos um estado.';

  @override
  String get pdaSimulationMissingInitialState =>
      'Um AP deve ter um estado inicial.';

  @override
  String get pdaSimulationInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao conjunto de estados do AP.';

  @override
  String get pdaSimulationAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao conjunto de estados do AP.';

  @override
  String get automatonSimulationDfaRequired =>
      'É necessário um AFD: o autômato deve ser determinístico e não ter transições ε.';

  @override
  String get automatonSimulationEmptyAutomaton =>
      'Não é possível simular um autômato vazio.';

  @override
  String get automatonSimulationMissingInitialState =>
      'O autômato deve ter um estado inicial.';

  @override
  String get automatonSimulationInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao conjunto de estados.';

  @override
  String get automatonSimulationAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao conjunto de estados.';

  @override
  String automatonSimulationInvalidInputSymbol(String symbol) {
    return 'A cadeia de entrada contém um símbolo inválido: $symbol.';
  }

  @override
  String automatonSimulationNoDfaTransition(String state, String symbol) {
    return 'Não há transição do estado $state com o símbolo $symbol.';
  }

  @override
  String get automatonSimulationRejectedNoAcceptingState =>
      'Rejeitada: nenhum estado de aceitação foi alcançado.';

  @override
  String automatonSimulationNoNfaTransition(String symbol) {
    return 'Nenhuma transição foi encontrada para o símbolo $symbol.';
  }

  @override
  String get automatonSimulationNfaNotAccepted =>
      'Entrada não aceita: nenhum estado de aceitação foi alcançado.';

  @override
  String automatonSimulationComputationTreeTimeout(int steps) {
    return 'A árvore de computação do AFN atingiu o tempo limite após $steps passos.';
  }

  @override
  String automatonSimulationComputationTreeInfiniteLoop(int steps) {
    return 'A árvore de computação do AFN detectou um loop infinito após $steps passos.';
  }

  @override
  String automatonSimulationDfaFailure(String error) {
    return 'Não foi possível simular o AFD: $error.';
  }

  @override
  String automatonSimulationNfaFailure(String error) {
    return 'Não foi possível simular o AFN: $error.';
  }

  @override
  String automatonSimulationAcceptedStringsFailure(String error) {
    return 'Não foi possível enumerar as cadeias aceitas: $error.';
  }

  @override
  String automatonSimulationRejectedStringsFailure(String error) {
    return 'Não foi possível enumerar as cadeias rejeitadas: $error.';
  }

  @override
  String get automatonSimulationTransitionAppliedTitle => 'Transição aplicada';

  @override
  String automatonSimulationReadSymbol(String symbol) {
    return 'Símbolo \"$symbol\" lido da entrada.';
  }

  @override
  String automatonSimulationTransitionDetail(
    String fromState,
    String symbol,
    String toState,
  ) {
    return 'Do estado $fromState, a transição com \"$symbol\" leva a $toState.';
  }

  @override
  String get automatonSimulationComputedEpsilonClosureTitle =>
      'Fecho ε calculado';

  @override
  String get automatonSimulationEpsilonClosureBeforeReading =>
      'Antes de ler a entrada, um AFN pode fazer transições ε (movimentos que não consomem entrada).';

  @override
  String automatonSimulationEpsilonClosureReached(
    String initialState,
    String stateSet,
  ) {
    return 'A partir de $initialState, as transições ε alcançam: $stateSet.';
  }

  @override
  String get automatonSimulationSymbolConsumedTitle => 'Símbolo consumido';

  @override
  String get automatonSimulationNondeterministicStep =>
      'Este passo de AFN pode ter vários estados ativos (não determinismo).';

  @override
  String automatonSimulationActiveSetAfterTransitions(
    String symbol,
    String stateSet,
  ) {
    return 'Após fazer todas as transições com \"$symbol\", o conjunto de estados ativos é $stateSet.';
  }

  @override
  String get automatonSimulationExpandedViaEpsilonTitle =>
      'Expandido por transições ε';

  @override
  String automatonSimulationEpsilonAfterConsuming(String symbol) {
    return 'Após consumir \"$symbol\", também seguimos quaisquer transições ε (movimentos que não consomem entrada).';
  }

  @override
  String automatonSimulationEpsilonClosureExpanded(
    String before,
    String after,
  ) {
    return 'O fecho ε expandiu o conjunto de estados ativos de $before para $after.';
  }

  @override
  String automatonSimulationInitialStateDescription(String state) {
    return 'Estado inicial $state';
  }

  @override
  String automatonSimulationConsumedSymbolDescription(
    String symbol,
    String state,
  ) {
    return 'Símbolo $symbol consumido; agora em $state';
  }

  @override
  String get automatonSimulationInitialEpsilonClosureDescription =>
      'Fecho ε inicial';

  @override
  String get fsaKleeneStarEmptyOperand =>
      'O operando da estrela de Kleene deve conter pelo menos um estado.';

  @override
  String get fsaKleeneStarMissingInitialState =>
      'O operando da estrela de Kleene deve ter um estado inicial.';

  @override
  String get fsaKleeneStarInitialStateOutsideSet =>
      'O operando da estrela de Kleene tem um estado inicial fora do conjunto de estados.';

  @override
  String get fsaKleeneStarAcceptingStateOutsideSet =>
      'O operando da estrela de Kleene tem um estado de aceitação fora do conjunto de estados.';

  @override
  String get fsaKleeneStarNonFsaTransition =>
      'O operando da estrela de Kleene contém uma transição que não é de AFN.';

  @override
  String get fsaKleeneStarUnknownTransitionEndpoint =>
      'O operando da estrela de Kleene contém uma transição com extremidade desconhecida.';

  @override
  String fsaKleeneStarInvalidTransition(String transition) {
    return 'O operando da estrela de Kleene contém uma transição inválida: $transition.';
  }

  @override
  String get fsaKleeneStarDuplicateStateIds =>
      'O resultado da estrela de Kleene contém IDs de estado duplicados.';

  @override
  String get fsaKleeneStarDuplicateTransitionIds =>
      'O resultado da estrela de Kleene contém IDs de transição duplicados.';

  @override
  String get fsaKleeneStarInvalidResult =>
      'O resultado da estrela de Kleene não é um autômato finito válido.';

  @override
  String get fsaKleeneStarInternalFailure =>
      'A construção da estrela de Kleene falhou.';

  @override
  String get fsaKleeneStarCloneTitle => 'Clonar o operando';

  @override
  String get fsaKleeneStarEntryTitle => 'Adicionar a entrada épsilon';

  @override
  String get fsaKleeneStarRepeatTitle => 'Adicionar transições de repetição';

  @override
  String get fsaKleeneStarExitTitle => 'Adicionar transições de saída';

  @override
  String get fsaKleeneStarCloneExplanation =>
      'Copie cada estado do operando para um namespace de IDs separado e determinístico.';

  @override
  String get fsaKleeneStarEntryExplanation =>
      'Crie um estado inicial de aceitação para que o resultado aceite épsilon e conecte-o ao operando clonado.';

  @override
  String get fsaKleeneStarRepeatExplanation =>
      'Conecte cada antigo estado de aceitação de volta ao estado inicial clonado com épsilon.';

  @override
  String get fsaKleeneStarRepeatEmptyExplanation =>
      'A linguagem do operando é vazia, portanto não há estados de aceitação para repetir.';

  @override
  String get fsaKleeneStarExitExplanation =>
      'Crie uma saída de aceitação distinta e conecte cada antigo estado de aceitação a ela com épsilon.';

  @override
  String get fsaKleeneStarExitEmptyExplanation =>
      'A saída de aceitação distinta permanece inalcançável porque a linguagem do operando é vazia.';

  @override
  String get fsaReversalEmptyOperand =>
      'O operando da inversão deve conter pelo menos um estado.';

  @override
  String get fsaReversalMissingInitialState =>
      'O operando da inversão deve ter um estado inicial.';

  @override
  String get fsaReversalInitialStateOutsideSet =>
      'O operando da inversão tem um estado inicial fora do conjunto de estados.';

  @override
  String get fsaReversalAcceptingStateOutsideSet =>
      'O operando da inversão tem um estado de aceitação fora do conjunto de estados.';

  @override
  String get fsaReversalNonFsaTransition =>
      'O operando da inversão contém uma transição que não é de AFN.';

  @override
  String get fsaReversalUnknownTransitionEndpoint =>
      'O operando da inversão contém uma transição com extremidade desconhecida.';

  @override
  String fsaReversalInvalidTransition(String transition) {
    return 'O operando da inversão contém uma transição inválida: $transition.';
  }

  @override
  String get fsaReversalDuplicateStateIds =>
      'O resultado da inversão contém IDs de estado duplicados.';

  @override
  String get fsaReversalDuplicateTransitionIds =>
      'O resultado da inversão contém IDs de transição duplicados.';

  @override
  String get fsaReversalInvalidResult =>
      'O resultado da inversão não é um autômato finito válido.';

  @override
  String get fsaReversalInternalFailure => 'A construção da inversão falhou.';

  @override
  String get fsaReversalCloneTitle => 'Clonar e espelhar os estados';

  @override
  String get fsaReversalReverseTitle => 'Inverter cada transição';

  @override
  String get fsaReversalEntryTitle => 'Adicionar a nova entrada';

  @override
  String get fsaReversalAcceptingTitle =>
      'Definir o estado de aceitação invertido';

  @override
  String get fsaReversalCloneExplanation =>
      'Copie cada estado para um namespace de IDs determinístico e espelhe o layout para o fluxo invertido.';

  @override
  String get fsaReversalReverseExplanation =>
      'Troque a origem e o destino de cada transição de símbolo e epsilon.';

  @override
  String get fsaReversalEntryExplanation =>
      'Crie um novo estado inicial e conecte-o por epsilon a cada antigo estado de aceitação.';

  @override
  String get fsaReversalEntryEmptyExplanation =>
      'Crie um novo estado inicial. O operando não possui estados de aceitação, portanto não há arestas de entrada epsilon.';

  @override
  String get fsaReversalAcceptingExplanation =>
      'Torne o clone do antigo estado inicial o único estado de aceitação.';

  @override
  String get fsaConcatenationLeftOperand => 'operando esquerdo';

  @override
  String get fsaConcatenationRightOperand => 'operando direito';

  @override
  String fsaConcatenationEmptyOperand(String operand) {
    return 'O $operand deve conter pelo menos um estado.';
  }

  @override
  String fsaConcatenationMissingInitialState(String operand) {
    return 'O $operand deve ter um estado inicial.';
  }

  @override
  String fsaConcatenationInitialStateOutsideSet(String operand) {
    return 'O $operand tem um estado inicial fora do conjunto de estados.';
  }

  @override
  String fsaConcatenationAcceptingStateOutsideSet(String operand) {
    return 'O $operand tem um estado de aceitação fora do conjunto de estados.';
  }

  @override
  String fsaConcatenationNonFsaTransition(String operand) {
    return 'O $operand contém uma transição que não é de AFN.';
  }

  @override
  String fsaConcatenationUnknownTransitionEndpoint(String operand) {
    return 'O $operand contém uma transição com extremidade desconhecida.';
  }

  @override
  String fsaConcatenationInvalidTransition(String operand, String transition) {
    return 'O $operand contém uma transição inválida: $transition.';
  }

  @override
  String get fsaConcatenationDuplicateStateIds =>
      'O resultado da concatenação contém IDs de estado duplicados.';

  @override
  String get fsaConcatenationDuplicateTransitionIds =>
      'O resultado da concatenação contém IDs de transição duplicados.';

  @override
  String get fsaConcatenationInvalidResult =>
      'O resultado da concatenação não é um autômato finito válido.';

  @override
  String get fsaConcatenationInternalFailure =>
      'A construção da concatenação falhou.';

  @override
  String fsaConcatenationCloneTitle(String operand) {
    return 'Clonar o $operand';
  }

  @override
  String get fsaConcatenationConnectTitle => 'Conectar os operandos';

  @override
  String fsaConcatenationCloneExplanation(String operand) {
    return 'Copie cada estado do $operand para um namespace de IDs separado.';
  }

  @override
  String get fsaConcatenationConnectExplanation =>
      'Adicione uma ponte epsilon de cada antigo estado de aceitação do operando esquerdo ao estado inicial do operando direito.';

  @override
  String get fsaConcatenationConnectEmptyExplanation =>
      'A linguagem do operando esquerdo é vazia, portanto nenhuma ponte epsilon é necessária.';

  @override
  String get faToRegexEmptyAutomaton =>
      'O autômato finito deve conter pelo menos um estado.';

  @override
  String get faToRegexMissingInitialState =>
      'O autômato finito deve ter um estado inicial.';

  @override
  String get faToRegexInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao conjunto de estados do autômato finito.';

  @override
  String get faToRegexAcceptingStateOutsideSet =>
      'Cada estado de aceitação deve pertencer ao conjunto de estados do autômato finito.';

  @override
  String get faToRegexSimplificationFailed =>
      'A etapa de simplificação da expressão regular falhou após a conversão.';

  @override
  String get faToRegexInternalFailure =>
      'A conversão de AF para expressão regular falhou.';

  @override
  String get grammarCnfTypeRegular => 'regular';

  @override
  String get grammarCnfTypeContextFree => 'livre de contexto';

  @override
  String get grammarCnfTypeContextSensitive => 'sensível ao contexto';

  @override
  String get grammarCnfTypeUnrestricted => 'irrestrita';

  @override
  String grammarCnfGrammarNotCfg(String type) {
    return 'A conversão para FNC espera uma gramática livre de contexto; foi recebido o tipo de gramática $type. A conversão será tentada mesmo assim.';
  }

  @override
  String get grammarCnfStartSymbolRenameFailed =>
      'Não foi possível introduzir um novo símbolo inicial para a conversão para FNC porque nenhum nome livre estava disponível.';

  @override
  String grammarCnfNotStrictCnf(String violations) {
    return 'A conversão para FNC produziu produções que não têm forma estrita de FNC: $violations';
  }

  @override
  String grammarCnfNullableSubsetLimitExceeded(
    String production,
    int nullablePositions,
    int subsets,
    int limit,
  ) {
    return 'A expansão de epsilon da produção $production foi ignorada: $nullablePositions posições anuláveis exigiriam $subsets subconjuntos, acima do limite de $limit.';
  }

  @override
  String grammarCnfNewSymbolLimitReached(int limit) {
    return 'A conversão para FNC atingiu o limite de $limit não terminais gerados.';
  }

  @override
  String get grammarCnfStartSymbolTitle => 'Introduzir um novo símbolo inicial';

  @override
  String get grammarCnfStartSymbolRationale =>
      'Um símbolo inicial livre mantém o símbolo inicial fora dos lados direitos sem alterar a linguagem.';

  @override
  String get grammarCnfEpsilonTitle => 'Remover produções epsilon';

  @override
  String get grammarCnfEpsilonRationale =>
      'As produções anuláveis são expandidas e as produções epsilon são removidas, exceto quando a linguagem exige epsilon.';

  @override
  String get grammarCnfUnitTitle => 'Remover produções unitárias';

  @override
  String get grammarCnfUnitRationale =>
      'As cadeias de produções unitárias são substituídas pelas produções que alcançam.';

  @override
  String get grammarCnfUselessTitle => 'Remover símbolos inúteis';

  @override
  String get grammarCnfUselessRationale =>
      'Símbolos improdutivos e inalcançáveis são removidos da gramática.';

  @override
  String get grammarCnfBinarizeTitle => 'Substituir terminais e binarizar';

  @override
  String get grammarCnfBinarizeRationale =>
      'Terminais em lados direitos longos são isolados e as produções são divididas em forma binária.';

  @override
  String get pdaNormalizationEmptyPda =>
      'Não é possível normalizar um AP vazio.';

  @override
  String get pdaNormalizationMissingInitialState =>
      'O AP deve definir um estado inicial antes da normalização.';

  @override
  String get pdaNormalizationInitialStateOutsideSet =>
      'O estado inicial do AP deve pertencer ao conjunto de estados do AP.';

  @override
  String pdaNormalizationInitialStackSymbolOutsideAlphabet(String symbol) {
    return 'O símbolo inicial de pilha $symbol deve pertencer ao alfabeto da pilha.';
  }

  @override
  String get pdaNormalizationMissingAcceptingState =>
      'O modo de origem selecionado exige pelo menos um estado de aceitação.';

  @override
  String get pdaNormalizationAcceptingStateOutsideSet =>
      'Cada estado de aceitação deve pertencer ao conjunto de estados do AP.';

  @override
  String get pdaNormalizationNonPdaTransition =>
      'A normalização de AP aceita apenas transições de AP.';

  @override
  String pdaNormalizationTransitionEndpointOutsideSet(String transition) {
    return 'A transição $transition referencia um estado fora do AP.';
  }

  @override
  String pdaNormalizationTransitionPopSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'A transição $transition retira o símbolo de pilha $symbol, que está fora do alfabeto da pilha.';
  }

  @override
  String pdaNormalizationTransitionPushSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'A transição $transition empilha o símbolo $symbol, que está fora do alfabeto da pilha.';
  }

  @override
  String pdaNormalizationGrowthWarningSummary(int states, int transitions) {
    String _temp0 = intl.Intl.pluralLogic(
      states,
      locale: localeName,
      other: '$states estados',
      one: 'um estado',
      zero: 'nenhum estado',
    );
    String _temp1 = intl.Intl.pluralLogic(
      transitions,
      locale: localeName,
      other: '$transitions transições',
      one: 'uma transição',
      zero: 'nenhuma transição',
    );
    return 'A normalização pode aumentar a quantidade de estados e transições. Foram gerados $_temp0 e $_temp1.';
  }

  @override
  String get pdaNormalizationIntroducedNondeterminism =>
      'A conversão transformou uma origem determinística em um AP não determinístico.';

  @override
  String pdaNormalizationInitialStateDescription(String state) {
    return 'Novo estado inicial que instala o marcador de fundo a partir do estado de origem $state.';
  }

  @override
  String get pdaNormalizationAcceptanceStateDescription =>
      'Estado alcançado depois que a pilha de origem simulada fica vazia.';

  @override
  String get pdaNormalizationDrainStateDescription =>
      'Estado que esvazia o conteúdo residual da pilha após a aceitação.';

  @override
  String pdaNormalizationInitializeTransitionDescription(String state) {
    return 'Instala a pilha inicial de origem acima do marcador de fundo antes de entrar no estado $state.';
  }

  @override
  String pdaNormalizationSinglePopTransitionDescription(String transition) {
    return 'Expansão de retirada única da transição de origem $transition.';
  }

  @override
  String pdaNormalizationAcceptEmptyTransitionDescription(
    String state,
    String mode,
  ) {
    return 'Converte uma pilha de origem vazia do estado $state para aceitação por $mode.';
  }

  @override
  String pdaNormalizationEnterDrainTransitionDescription(String state) {
    return 'Começa a esvaziar a pilha a partir do estado de aceitação $state.';
  }

  @override
  String get pdaNormalizationDrainTransitionDescription =>
      'Retira um símbolo residual da pilha no estado de drenagem.';

  @override
  String get grammarGnfTransformFailed =>
      'Não foi possível converter a gramática para a Forma Normal de Greibach.';

  @override
  String get grammarGnfNotGnf =>
      'O resultado da conversão não satisfaz a Forma Normal de Greibach.';

  @override
  String get grammarGnfConvertTitle =>
      'Converter para a Forma Normal de Greibach';

  @override
  String get grammarGnfConvertRationale =>
      'Cada produção é reescrita como A → aα: um terminal seguido por zero ou mais não-terminais.';

  @override
  String get grammarToPdaEmptyGrammar =>
      'A gramática deve conter pelo menos uma produção.';

  @override
  String get grammarToPdaMissingStartSymbol =>
      'A gramática deve ter um símbolo inicial.';

  @override
  String grammarToPdaUndeclaredStartSymbol(String symbol) {
    return 'O símbolo inicial $symbol deve ser declarado como não-terminal.';
  }

  @override
  String grammarToPdaDuplicateProductionId(String production) {
    return 'O ID de produção $production está duplicado.';
  }

  @override
  String get grammarToPdaNotContextFree =>
      'A gramática não é livre de contexto.';

  @override
  String grammarToPdaConversionTimedOut(int timeout) {
    return 'A conversão de gramática para AP excedeu o limite de $timeout segundos.';
  }

  @override
  String get grammarToPdaInternalConversionFailure =>
      'A conversão de gramática para AP falhou.';

  @override
  String get grammarToPdaGnfConversionFailed =>
      'Não foi possível converter a gramática para a Forma Normal de Greibach necessária à construção do AP.';

  @override
  String get grammarToPdaInvalidGnfResult =>
      'A conversão de Greibach não produziu uma gramática FNG válida.';

  @override
  String get grammarToPdaAnalysisFailed =>
      'A análise da conversão de gramática para AP falhou.';

  @override
  String grammarToPdaAnalysisTimedOut(int timeout) {
    return 'A análise de gramática para AP excedeu o limite de $timeout segundos.';
  }

  @override
  String get grammarToPdaValidateGrammarStep => 'Validar a gramática';

  @override
  String get grammarToPdaCreateInitialStateStep => 'Criar o estado inicial';

  @override
  String get grammarToPdaCreateProcessingStateStep =>
      'Criar o estado de processamento';

  @override
  String get grammarToPdaCreateAcceptingStateStep =>
      'Criar o estado de aceitação';

  @override
  String get grammarToPdaAddTransitionsStep => 'Adicionar transições';

  @override
  String get pdaSimplificationEmptyPda =>
      'Não é possível simplificar um AP vazio.';

  @override
  String get pdaSimplificationMissingInitialState =>
      'O AP deve definir um estado inicial antes da simplificação.';

  @override
  String get pdaSimplificationInitialStateOutsideSet =>
      'O estado inicial do AP deve pertencer ao conjunto de estados do AP.';

  @override
  String get pdaSimplificationAcceptingStateOutsideSet =>
      'Cada estado de aceitação deve pertencer ao conjunto de estados do AP.';

  @override
  String pdaSimplificationMissingAcceptingState(String mode) {
    return 'O modo de aceitação $mode exige pelo menos um estado de aceitação.';
  }

  @override
  String get pdaSimplificationInvalidPda =>
      'O AP não é válido para simplificação.';

  @override
  String get pdaSimplificationNonPdaTransition =>
      'A simplificação de AP aceita apenas transições de AP.';

  @override
  String pdaSimplificationTransitionEndpointOutsideSet(String transition) {
    return 'A transição $transition referencia um estado fora do AP.';
  }

  @override
  String pdaSimplificationInvalidTransition(String transition) {
    return 'A transição $transition não é válida para simplificação de AP.';
  }

  @override
  String get pdaSimplificationInputAlphabetEmptySymbol =>
      'O alfabeto de entrada do AP não pode conter um símbolo vazio.';

  @override
  String get pdaSimplificationStackAlphabetEmptySymbol =>
      'O alfabeto da pilha do AP não pode conter um símbolo vazio.';

  @override
  String pdaSimplificationTransitionInputSymbolOutsideAlphabet(
    String transition,
    String symbol,
  ) {
    return 'A transição $transition lê o símbolo de entrada $symbol, que está fora do alfabeto de entrada.';
  }

  @override
  String pdaSimplificationDuplicateTransitionIds(String transition) {
    return 'O ID de transição $transition está duplicado.';
  }

  @override
  String get pdaSimplificationBoundedLengthNegative =>
      'O comprimento da comparação limitada não pode ser negativo.';

  @override
  String get pdaSimplificationBoundedSymbolsEmpty =>
      'O alfabeto da comparação limitada não pode conter um símbolo vazio.';

  @override
  String pdaSimplificationBoundedSymbolOutsideAlphabet(String symbol) {
    return 'O símbolo $symbol da comparação limitada está fora do alfabeto de entrada do AP.';
  }

  @override
  String get pdaSimplificationValidationComplete =>
      'A validação do AP foi concluída.';

  @override
  String get pdaSimplificationEveryStateReachable =>
      'Todos os estados do AP são alcançáveis estruturalmente.';

  @override
  String pdaSimplificationRemovedUnreachableStates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count estados inalcançáveis',
      one: 'um estado inalcançável',
    );
    return 'Foram removidos $_temp0.';
  }

  @override
  String get pdaSimplificationSemanticUsefulnessUnavailable =>
      'A utilidade semântica exata não está disponível para NPDAs gerais; estados incertos foram mantidos.';

  @override
  String get pdaSimplificationSemanticUsefulnessDisabled =>
      'A análise de utilidade semântica foi desativada.';

  @override
  String get pdaSimplificationStrongBisimulationComputed =>
      'Os grupos de bissimulação forte foram calculados.';

  @override
  String get pdaSimplificationStrongBisimulationDisabled =>
      'A análise de bissimulação forte foi desativada.';

  @override
  String get pdaSimplificationRebuildValidationComplete =>
      'O AP reconstruído passou na validação.';

  @override
  String pdaSimplificationBoundedSamplePassed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count palavras',
      one: 'uma palavra',
    );
    return 'A comparação limitada verificou $_temp0 com sucesso.';
  }

  @override
  String get pdaSimplificationBoundedComparisonDisabled =>
      'A comparação limitada de linguagens foi desativada.';

  @override
  String get pdaSimplificationInvalidRebuiltPda =>
      'O AP reconstruído falhou na validação.';

  @override
  String pdaSimplificationBoundedComparisonInconclusive(String word) {
    return 'A comparação limitada foi inconclusiva para a palavra de entrada $word.';
  }

  @override
  String pdaSimplificationBoundedComparisonSimulationLimit(String word) {
    return 'A comparação limitada atingiu um limite de simulação para a palavra de entrada $word; o resultado é inconclusivo.';
  }

  @override
  String pdaSimplificationBoundedComparisonAcceptanceMismatch(String word) {
    return 'Os APs original e simplificado discordam sobre a palavra de entrada $word.';
  }

  @override
  String get fsaToGrammarEmptyAutomaton =>
      'O autômato deve conter pelo menos um estado.';

  @override
  String get fsaToGrammarMissingInitialState =>
      'O autômato deve ter um estado inicial.';

  @override
  String get fsaToGrammarInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao autômato.';

  @override
  String get fsaToGrammarAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao autômato.';

  @override
  String get grammarToFsaMissingNonterminals =>
      'A gramática deve declarar pelo menos um não terminal.';

  @override
  String get grammarToFsaUndeclaredStartSymbol =>
      'O símbolo inicial deve ser um não terminal declarado.';

  @override
  String grammarToFsaLeftSideNotSingle(String production) {
    return 'A produção $production deve ter exatamente um não terminal no lado esquerdo.';
  }

  @override
  String grammarToFsaUnknownLeftNonterminal(String production, String symbol) {
    return 'A produção $production usa o não terminal desconhecido $symbol.';
  }

  @override
  String grammarToFsaUnknownRightNonterminal(String production, String symbol) {
    return 'A produção $production referencia o não terminal não definido $symbol.';
  }

  @override
  String grammarToFsaTooManyRightSymbols(String production) {
    return 'A produção $production não é linear à direita porque seu lado direito tem símbolos demais.';
  }

  @override
  String grammarToFsaFirstSymbolNotTerminal(String production) {
    return 'A produção $production deve começar com um símbolo terminal.';
  }

  @override
  String grammarToFsaLastSymbolNotNonterminal(String production) {
    return 'A produção $production deve terminar com um símbolo não terminal.';
  }

  @override
  String dfaOperationsMissingInitialState(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'AFD',
      'complementDfa': 'AFD do complemento',
      'prefixClosure': 'AFD do fecho por prefixos',
      'suffixClosure': 'AFD do fecho por sufixos',
      'operandA': 'operando A',
      'operandB': 'operando B',
      'other': 'AFD',
    });
    return 'O $_temp0 deve ter um estado inicial definido.';
  }

  @override
  String dfaOperationsNondeterministic(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'AFD',
      'complementDfa': 'AFD do complemento',
      'prefixClosure': 'AFD do fecho por prefixos',
      'suffixClosure': 'AFD do fecho por sufixos',
      'operandA': 'operando A',
      'operandB': 'operando B',
      'other': 'AFD',
    });
    return 'O $_temp0 deve ser determinístico (sem transições não determinísticas).';
  }

  @override
  String dfaOperationsEpsilonTransitionsNotAllowed(String context) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'AFD',
      'complementDfa': 'AFD do complemento',
      'prefixClosure': 'AFD do fecho por prefixos',
      'suffixClosure': 'AFD do fecho por sufixos',
      'operandA': 'operando A',
      'operandB': 'operando B',
      'other': 'AFD',
    });
    return 'O $_temp0 não pode conter transições ε (epsilon).';
  }

  @override
  String dfaOperationsSymbolOutsideAlphabet(String context, String symbol) {
    String _temp0 = intl.Intl.selectLogic(context, {
      'dfa': 'AFD',
      'complementDfa': 'AFD do complemento',
      'prefixClosure': 'AFD do fecho por prefixos',
      'suffixClosure': 'AFD do fecho por sufixos',
      'operandA': 'operando A',
      'operandB': 'operando B',
      'other': 'AFD',
    });
    return 'O $_temp0 tem uma transição com símbolo fora do alfabeto: \"$symbol\".';
  }

  @override
  String dfaOperationsEmptyAlphabetWithLabeledTransitions(String operand) {
    String _temp0 = intl.Intl.selectLogic(operand, {
      'a': 'O operando A',
      'b': 'O operando B',
      'other': 'O operando',
    });
    return '$_temp0 tem transições rotuladas, mas o alfabeto está vazio.';
  }

  @override
  String get dfaOperationsBothOperandsMissingInitialState =>
      'Ambos os AFDs devem ter um estado inicial definido.';

  @override
  String dfaOperationsOperationFailed(String operation) {
    String _temp0 = intl.Intl.selectLogic(operation, {
      'union': 'união',
      'intersection': 'interseção',
      'difference': 'diferença',
      'complement': 'complemento',
      'prefixClosure': 'fecho por prefixos',
      'suffixClosure': 'fecho por sufixos',
      'removeLambda': 'remoção de transições epsilon',
      'other': 'operação',
    });
    return 'Erro ao calcular a operação de AFD $_temp0.';
  }

  @override
  String get dfaOperationsEpsilonRemovalFailed =>
      'Erro ao remover transições ε.';

  @override
  String get dfaMinimizationEmptyDfa =>
      'Não é possível minimizar um AFD vazio.';

  @override
  String get dfaMinimizationMissingInitialState =>
      'O AFD deve ter um estado inicial.';

  @override
  String get dfaMinimizationInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao conjunto de estados do AFD.';

  @override
  String get dfaMinimizationAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao conjunto de estados do AFD.';

  @override
  String get dfaMinimizationNondeterministicInput =>
      'A entrada deve ser um autômato determinístico.';

  @override
  String get dfaMinimizationFailed => 'Erro ao minimizar o AFD.';

  @override
  String get dfaMinimizationWithStepsFailed =>
      'Erro ao minimizar o AFD com passos.';

  @override
  String get cfgToolkitReduceFailed => 'A redução da GLC falhou.';

  @override
  String get cfgToolkitToCnfFailed => 'A conversão de GLC para FNC falhou.';

  @override
  String get cfgToolkitToGnfFailed => 'A conversão de GLC para FNG falhou.';

  @override
  String get cykTimedOut => 'A análise CYK atingiu o tempo limite.';

  @override
  String cykInputRejected(String input) {
    return 'A cadeia de entrada $input não pode ser derivada pela gramática.';
  }

  @override
  String get cykParseFailed => 'A análise CYK falhou.';

  @override
  String get grammarParserEmptyGrammar =>
      'A gramática deve conter pelo menos uma produção.';

  @override
  String get grammarParserMissingStartSymbol =>
      'A gramática deve ter um símbolo inicial.';

  @override
  String get grammarParserStartSymbolNotNonterminal =>
      'O símbolo inicial deve ser um não terminal.';

  @override
  String grammarParserInputRejected(String input) {
    return 'A cadeia de entrada $input não pode ser derivada pela gramática.';
  }

  @override
  String grammarParserAllStrategiesFailed(String strategy) {
    String _temp0 = intl.Intl.selectLogic(strategy, {
      'auto': 'disponíveis',
      'bruteForce': 'de força bruta',
      'cyk': 'CYK',
      'll': 'LL(1)',
      'lr': 'LR(1)',
      'other': 'disponíveis',
    });
    return 'Todas as estratégias de análise $_temp0 falharam.';
  }

  @override
  String get grammarParserGeneratedStringsFailed =>
      'A geração de cadeias da gramática falhou.';

  @override
  String grammarParserLl1StepLimitInvalid(int limit) {
    return 'O limite de passos LL(1) deve ser maior que zero (recebido $limit).';
  }

  @override
  String grammarParserLl1Conflict(
    String nonTerminal,
    String lookahead,
    String alternatives,
  ) {
    return 'Conflito LL(1) para o não terminal $nonTerminal com lookahead $lookahead: $alternatives.';
  }

  @override
  String get grammarParserLl1Cancelled => 'A análise LL(1) foi cancelada.';

  @override
  String grammarParserLl1TimedOut(int timeout) {
    return 'A análise LL(1) atingiu o tempo limite de $timeout ms.';
  }

  @override
  String grammarParserLl1StepLimitReached(int limit) {
    return 'A análise LL(1) atingiu o limite de $limit passos.';
  }

  @override
  String grammarParserLl1TrailingInput(String lookahead, int position) {
    return 'Símbolo de entrada inesperado $lookahead na posição $position.';
  }

  @override
  String grammarParserLl1UnexpectedEnd(String expected) {
    return 'Fim inesperado da entrada; esperava-se $expected.';
  }

  @override
  String grammarParserLl1TerminalMismatch(
    String expected,
    String found,
    int position,
  ) {
    return 'Esperava-se $expected na posição $position, mas foi encontrado $found.';
  }

  @override
  String grammarParserLl1EmptyTableCell(
    String nonTerminal,
    String lookahead,
    String expected,
  ) {
    return 'A tabela LL(1) não tem entrada para $nonTerminal com lookahead $lookahead; esperava-se $expected.';
  }

  @override
  String get grammarParserLl1EmptyStack =>
      'A pilha do analisador LL(1) ficou vazia antes do fim da análise.';

  @override
  String get grammarParserEarleyMalformedProduction =>
      'A gramática contém uma produção malformada para a análise de Earley.';

  @override
  String get grammarParserEarleyMissingStartSymbol =>
      'A análise de Earley exige um símbolo inicial não terminal declarado.';

  @override
  String grammarParserEarleyTimedOut(int timeout) {
    return 'A análise de Earley atingiu o tempo limite de $timeout ms.';
  }

  @override
  String get grammarParserRecursiveDescentTimedOut =>
      'A análise por descida recursiva atingiu o tempo limite.';

  @override
  String get grammarParserRecursiveDescentFailed =>
      'A análise por descida recursiva falhou.';

  @override
  String get lr1ParserStaleConstruction =>
      'A construção LR(1) está desatualizada; reconstrua a tabela de análise.';

  @override
  String get lr1ParserInvalidGrammar =>
      'A gramática é inválida para análise LR(1).';

  @override
  String get lr1ParserMissingStartSymbol =>
      'A gramática deve ter símbolo inicial para análise LR(1).';

  @override
  String get lr1ParserMalformedProduction =>
      'A gramática contém produção malformada para análise LR(1).';

  @override
  String lr1ParserDuplicateProductionId(String production) {
    return 'A produção $production tem um identificador duplicado.';
  }

  @override
  String lr1ParserUndeclaredSymbol(String production, String symbol) {
    return 'A produção $production usa o símbolo não declarado $symbol.';
  }

  @override
  String get lr1ParserConstructionCancelled =>
      'A construção da tabela LR(1) foi cancelada.';

  @override
  String lr1ParserConstructionTimedOut(int timeout) {
    return 'A construção da tabela LR(1) atingiu o tempo limite de $timeout ms.';
  }

  @override
  String get lr1ParserConstructionStateLimit =>
      'A construção da tabela LR(1) atingiu o limite de estados.';

  @override
  String get lr1ParserConstructionItemLimit =>
      'A construção da tabela LR(1) atingiu o limite de itens.';

  @override
  String lr1ParserConflict(String state, String lookahead) {
    return 'Conflito LR(1) no estado $state com lookahead $lookahead.';
  }

  @override
  String get lr1ParserCancelled => 'A análise LR(1) foi cancelada.';

  @override
  String lr1ParserTimedOut(int timeout) {
    return 'A análise LR(1) atingiu o tempo limite de $timeout ms.';
  }

  @override
  String lr1ParserStepLimitReached(int limit) {
    return 'A análise LR(1) atingiu o limite de $limit passos.';
  }

  @override
  String lr1ParserEmptyActionCell(String state, String lookahead) {
    return 'Não há ação LR(1) para o estado $state com lookahead $lookahead.';
  }

  @override
  String lr1ParserActionConflict(String state, String lookahead) {
    return 'Várias ações LR(1) entram em conflito no estado $state com lookahead $lookahead.';
  }

  @override
  String get lr1ParserInvalidParserState =>
      'O estado do analisador LR(1) é inválido.';

  @override
  String lr1ParserMissingGoto(String state, String nonTerminal) {
    return 'Não há entrada goto LR(1) para o estado $state e o não terminal $nonTerminal.';
  }

  @override
  String lr1ParserShifted(String symbol, String targetState) {
    return 'Desloque $symbol e entre no estado $targetState do analisador.';
  }

  @override
  String lr1ParserReduced(
    String production,
    String leftSide,
    String rightSide,
  ) {
    return 'Reduza por $production: $leftSide → $rightSide.';
  }

  @override
  String get lr1ParserAccepted => 'O analisador LR(1) aceitou a entrada.';

  @override
  String get tmSimulationEmptyMachine =>
      'Não é possível simular uma máquina de Turing vazia.';

  @override
  String get tmSimulationMissingInitialState =>
      'A máquina de Turing deve ter um estado inicial.';

  @override
  String get tmSimulationInitialStateOutsideSet =>
      'O estado inicial deve pertencer à máquina de Turing.';

  @override
  String get tmSimulationAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer à máquina de Turing.';

  @override
  String tmSimulationInvalidInputSymbol(String symbol) {
    return 'A entrada contém símbolo fora do alfabeto da máquina de Turing: $symbol.';
  }

  @override
  String get tmSimulationOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String tmSimulationNondeterministicConflict(
    int count,
    String state,
    String symbol,
  ) {
    return 'A máquina tem $count transições para o estado $state com o símbolo $symbol.';
  }

  @override
  String get tmSimulationRejectedNoAcceptingConfiguration =>
      'Nenhuma configuração de aceitação foi encontrada.';

  @override
  String get tmSimulationInputNotAccepted => 'A entrada não foi aceita.';

  @override
  String get tmSimulationTimeout =>
      'A simulação da máquina de Turing atingiu o tempo limite.';

  @override
  String get tmSimulationInfiniteLoop => 'Um laço infinito foi detectado.';

  @override
  String get tmSimulationStepLimit =>
      'Limite de passos atingido; o resultado é inconclusivo';

  @override
  String get tmSimulationConfigurationLimit =>
      'Limite de configurações atingido; o resultado é inconclusivo';

  @override
  String get tmSimulationAcceptanceUnresolved =>
      'A simulação limitada não determinou a aceitação.';

  @override
  String tmSimulationDtmFailure(String error) {
    return 'A simulação da MTD falhou: $error';
  }

  @override
  String tmSimulationNtmFailure(String error) {
    return 'A simulação da MTN falhou: $error';
  }

  @override
  String tmSimulationGenericFailure(String error) {
    return 'A simulação da máquina de Turing falhou: $error';
  }

  @override
  String tmSimulationAcceptedStringsFailure(String error) {
    return 'Falha ao encontrar cadeias aceitas: $error';
  }

  @override
  String tmSimulationRejectedStringsFailure(String error) {
    return 'Falha ao encontrar cadeias rejeitadas: $error';
  }

  @override
  String tmSimulationAnalysisFailure(String error) {
    return 'A análise da máquina de Turing falhou: $error';
  }

  @override
  String get tmSimulationTransitionTitle => 'Transição da máquina de Turing';

  @override
  String tmSimulationReadSymbol(String symbol, int position, String state) {
    return 'Leu $symbol na posição $position da fita no estado $state.';
  }

  @override
  String tmSimulationAppliedRule(
    String fromState,
    String readSymbol,
    String toState,
    String writeSymbol,
    String direction,
  ) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'L': 'esquerda',
      'R': 'direita',
      'S': 'parada',
      'other': '$direction',
    });
    return 'Regra aplicada: $fromState,$readSymbol → $toState,$writeSymbol,$_temp0.';
  }

  @override
  String tmSimulationWroteSymbol(String symbol, int position) {
    return 'Escreveu $symbol na posição $position da fita.';
  }

  @override
  String tmSimulationMovedHead(String direction, int position) {
    String _temp0 = intl.Intl.selectLogic(direction, {
      'L': 'esquerda',
      'R': 'direita',
      'S': 'mesma posição',
      'other': '$direction',
    });
    return 'Moveu a cabeça para a $_temp0, posição $position.';
  }

  @override
  String get tmExecutionEmptyMachine =>
      'A máquina de Turing deve ter pelo menos um estado.';

  @override
  String get tmExecutionMissingInitialState =>
      'A máquina de Turing deve definir um estado inicial válido.';

  @override
  String get tmExecutionStepLimitInvalid =>
      'O limite de passos deve ser maior que zero.';

  @override
  String get tmExecutionConfigurationLimitInvalid =>
      'O limite de configurações deve ser maior que zero.';

  @override
  String get tmExecutionTimeoutInvalid =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get tmExecutionOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String tmExecutionInvalidInputSymbol(String symbol) {
    return 'A entrada contém símbolo fora do alfabeto da máquina de Turing: $symbol.';
  }

  @override
  String tmExecutionInvalidMachine(String detail) {
    return 'A máquina de Turing é inválida: $detail';
  }

  @override
  String get tmExecutionCancelled =>
      'A análise de execução de MT foi cancelada.';

  @override
  String get tmExecutionTimeoutBeforeResolution =>
      'O tempo limite foi atingido antes de resolver a execução.';

  @override
  String tmExecutionEnteredFinalState(String policy) {
    String _temp0 = intl.Intl.selectLogic(policy, {
      'finalState': 'estado final',
      'halting': 'parada',
      'finalStateOrHalting': 'estado final ou parada',
      'other': 'selecionada',
    });
    return 'A máquina entrou em um estado final sob a política $_temp0.';
  }

  @override
  String tmExecutionHaltedAccepted(String policy) {
    String _temp0 = intl.Intl.selectLogic(policy, {
      'finalState': 'estado final',
      'halting': 'parada',
      'finalStateOrHalting': 'estado final ou parada',
      'other': 'selecionada',
    });
    return 'A máquina parou sob a política $_temp0.';
  }

  @override
  String get tmExecutionHaltedRejected =>
      'A máquina parou fora de um estado final.';

  @override
  String tmExecutionDeterministicConflict(
    int count,
    String state,
    String symbol,
  ) {
    return 'A máquina determinística tem $count transições para o estado $state com o símbolo $symbol.';
  }

  @override
  String get tmExecutionStepLimit =>
      'O limite de passos foi atingido sem resultado resolvido.';

  @override
  String get tmExecutionConfigurationLimit =>
      'O limite de configurações foi atingido sem resultado resolvido.';

  @override
  String get tmExecutionDeterministicCycle =>
      'Um ciclo determinístico foi detectado.';

  @override
  String get tmExecutionBranchStepLimit =>
      'Pelo menos um ramo atingiu o limite de passos.';

  @override
  String get tmExecutionEveryBranchRejected =>
      'Todos os ramos alcançáveis pararam sem aceitação.';

  @override
  String get tmExecutionExploredGraphRejected =>
      'O grafo de configurações explorado não contém configuração de aceitação.';

  @override
  String get tmSpaceProfileEmptyMachine =>
      'A máquina de Turing deve ter pelo menos um estado.';

  @override
  String get tmSpaceProfileMissingInitialState =>
      'A máquina de Turing deve definir um estado inicial válido.';

  @override
  String get tmSpaceProfileMaxInputLengthInvalid =>
      'O comprimento máximo da entrada deve ser não negativo.';

  @override
  String get tmSpaceProfileCandidateCapInvalid =>
      'O limite de candidatos por comprimento deve ser maior que zero.';

  @override
  String get tmSpaceProfileStepLimitInvalid =>
      'O limite de passos deve ser maior que zero.';

  @override
  String get tmSpaceProfileConfigurationLimitInvalid =>
      'O limite de configurações deve ser maior que zero.';

  @override
  String get tmSpaceProfileTimeoutInvalid =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get tmSpaceProfileOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String get tmSpaceProfileMissingSpaceMetrics =>
      'A execução limitada não retornou métricas de espaço da fita.';

  @override
  String get tmTimeProfileMaxLengthInvalid =>
      'O comprimento máximo da entrada deve ser não negativo.';

  @override
  String get tmTimeProfileCandidateCapInvalid =>
      'O limite de candidatos por comprimento deve ser maior que zero.';

  @override
  String get tmTimeProfileStepLimitInvalid =>
      'O limite de passos deve ser maior que zero.';

  @override
  String get tmTimeProfileConfigurationLimitInvalid =>
      'O limite de configurações deve ser maior que zero.';

  @override
  String get tmTimeProfileTimeoutInvalid =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get tmTimeProfileOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String get tmTimeProfileComplete => 'O perfil de tempo foi concluído.';

  @override
  String get tmTimeProfileIncomplete =>
      'O perfil limitado está incompleto porque uma linha foi amostrada ou uma execução permaneceu desconhecida.';

  @override
  String get tmTimeProfileCancelled =>
      'A criação do perfil de tempo foi cancelada.';

  @override
  String get tmTimeProfileInvalidMachine => 'A máquina de Turing é inválida.';

  @override
  String get tmReachabilityEmptyMachine =>
      'A máquina de Turing deve ter pelo menos um estado.';

  @override
  String get tmReachabilityInvalidInitialState =>
      'A máquina de Turing deve definir um estado inicial válido.';

  @override
  String get tmReachabilityInputsRequired =>
      'É necessária pelo menos uma entrada para a análise de alcançabilidade.';

  @override
  String get tmReachabilityStepLimitInvalid =>
      'O limite de passos deve ser maior que zero.';

  @override
  String get tmReachabilityConfigurationLimitInvalid =>
      'O limite de configurações deve ser maior que zero.';

  @override
  String get tmReachabilityTimeoutInvalid =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get tmReachabilityOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String get tmReachabilityNonTmTransition =>
      'A máquina contém uma transição que não é de máquina de Turing.';

  @override
  String tmReachabilityTransitionEndpointOutsideSet(String transition) {
    return 'A transição $transition tem uma extremidade fora do conjunto de estados da máquina.';
  }

  @override
  String tmReachabilityInputSymbolOutsideAlphabet(String input, String symbol) {
    return 'A entrada $input contém o símbolo $symbol, que está fora do alfabeto da máquina.';
  }

  @override
  String get tmReachabilityCancelled =>
      'A análise de alcançabilidade foi cancelada.';

  @override
  String get tmReachabilityTimeout =>
      'A análise de alcançabilidade atingiu o tempo limite.';

  @override
  String get tmReachabilityConfigurationLimit =>
      'A análise de alcançabilidade atingiu o limite de configurações.';

  @override
  String get tmReachabilityStepLimit =>
      'A análise de alcançabilidade atingiu o limite de passos.';

  @override
  String get tmReachabilityComplete =>
      'A análise de alcançabilidade foi concluída.';

  @override
  String get tmLanguageExplorerMaxInputLengthInvalid =>
      'O comprimento máximo da entrada deve ser não negativo.';

  @override
  String get tmLanguageExplorerCandidateCapInvalid =>
      'O limite de candidatos por comprimento deve ser maior que zero.';

  @override
  String get tmLanguageExplorerStepLimitInvalid =>
      'O limite de passos deve ser maior que zero.';

  @override
  String get tmLanguageExplorerConfigurationLimitInvalid =>
      'O limite de configurações deve ser maior que zero.';

  @override
  String get tmLanguageExplorerTimeoutInvalid =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get tmLanguageExplorerOperationsPerBatchInvalid =>
      'As operações por lote devem ser maiores que zero.';

  @override
  String get nfaToDfaEmptyAutomaton =>
      'O autômato deve conter pelo menos um estado.';

  @override
  String get nfaToDfaMissingInitialState =>
      'O autômato deve ter um estado inicial.';

  @override
  String get nfaToDfaInitialStateOutsideSet =>
      'O estado inicial deve pertencer ao conjunto de estados do autômato.';

  @override
  String get nfaToDfaAcceptingStateOutsideSet =>
      'Todo estado de aceitação deve pertencer ao conjunto de estados do autômato.';

  @override
  String nfaToDfaStateLimitExceeded(int limit) {
    return 'A conversão de AFN para AFD atingiu o limite de $limit estados do AFD.';
  }

  @override
  String nfaToDfaConversionFailed(String error, String withSteps) {
    String _temp0 = intl.Intl.selectLogic(withSteps, {
      'true': ' (ao registrar passos)',
      'other': '',
    });
    return 'A conversão de AFN para AFD falhou: $error$_temp0.';
  }

  @override
  String get pdaSimulationSearchLimitsNegative =>
      'Os limites de busca não podem ser negativos.';

  @override
  String get pdaSimulationMemoryLimitNegative =>
      'O limite de memória do AP não pode ser negativo.';

  @override
  String get pdaSimulationConfigurationsPerBatchInvalid =>
      'As configurações por lote devem ser maiores que zero.';

  @override
  String pdaSimulationFailure(String operation, String error) {
    return 'A operação de AP $operation falhou: $error.';
  }

  @override
  String pdaSimulationAcceptedStringsFailure(String error) {
    return 'A busca de cadeias aceitas falhou: $error.';
  }

  @override
  String pdaSimulationRejectedStringsFailure(String error) {
    return 'A busca de cadeias rejeitadas falhou: $error.';
  }

  @override
  String get pdaSimulationTimeout =>
      'A simulação do AP atingiu o tempo limite.';

  @override
  String get pdaSimulationInfiniteLoop =>
      'A simulação do AP detectou um laço infinito.';

  @override
  String get pdaSimulationConfigurationLimit =>
      'A simulação do AP atingiu o limite de configurações.';

  @override
  String get pdaSimulationDepthLimit =>
      'A simulação do AP atingiu o limite de profundidade da busca.';

  @override
  String get pdaSimulationMemoryLimit =>
      'A simulação do AP atingiu o limite de memória.';

  @override
  String get pdaSimulationStaleRequest =>
      'O resultado da simulação do AP está desatualizado e foi descartado.';

  @override
  String get pdaSimulationRejectedNoAcceptingConfiguration =>
      'Nenhuma configuração de aceitação do AP foi encontrada.';

  @override
  String get pdaSimulationTransitionTitle => 'Transição do AP';

  @override
  String pdaSimulationReadInput(String symbol) {
    return 'Símbolo de entrada lido: $symbol.';
  }

  @override
  String pdaSimulationStackAction(String pop, String push) {
    return 'Retira $pop e empilha $push na pilha.';
  }

  @override
  String pdaSimulationStackTopChange(String before, String after) {
    return 'O topo da pilha muda de $before para $after.';
  }

  @override
  String pdaSimulationPopMatches(String symbol) {
    return 'A retirada da pilha corresponde a $symbol.';
  }

  @override
  String get pdaSimulationNoPop => 'Nenhum símbolo é retirado da pilha.';

  @override
  String pdaSimulationPushed(String symbol) {
    return 'Símbolo $symbol empilhado.';
  }

  @override
  String get pdaSimulationNoPush => 'Nenhum símbolo é empilhado.';

  @override
  String get pdaSimulationEpsilonMove => 'Este é um movimento ε.';

  @override
  String get pdaAnalysisEmptyPda => 'O AP deve conter pelo menos um estado.';

  @override
  String get pdaAnalysisInvalidMaxInputLength =>
      'O comprimento máximo da entrada não pode ser negativo.';

  @override
  String get pdaAnalysisInvalidTimeout =>
      'O tempo limite deve ser maior que zero.';

  @override
  String get pdaAnalysisTimedOut => 'A análise do AP atingiu o tempo limite.';

  @override
  String pdaAnalysisFailure(String error) {
    return 'A análise do AP falhou: $error.';
  }

  @override
  String get cfgToPdaEmptyGrammar =>
      'A gramática deve conter pelo menos uma produção.';

  @override
  String get cfgToPdaMissingStartSymbol =>
      'A gramática deve ter um símbolo inicial.';

  @override
  String cfgToPdaUndeclaredStartSymbol(String symbol) {
    return 'O símbolo inicial $symbol não foi declarado como não terminal.';
  }

  @override
  String cfgToPdaMalformedProduction(String production) {
    return 'A produção $production está malformada.';
  }

  @override
  String cfgToPdaDuplicateProductionId(String production) {
    return 'O ID de produção $production está duplicado.';
  }

  @override
  String cfgToPdaUndeclaredSymbol(String production, String symbol) {
    return 'A produção $production usa o símbolo não declarado $symbol.';
  }

  @override
  String get cfgToPdaLlAnalysisFailed =>
      'A análise LL falhou durante a construção do AP.';

  @override
  String cfgToPdaLlConflict(
    String nonterminal,
    String lookahead,
    String productions,
  ) {
    return 'Conflito LL para $nonterminal com lookahead $lookahead: $productions.';
  }

  @override
  String get cfgToPdaLrConstructionUnavailable =>
      'A construção LR não está disponível para esta gramática.';

  @override
  String cfgToPdaLrConflict(int state, String lookahead, String productions) {
    return 'Conflito LR no estado $state com lookahead $lookahead: $productions.';
  }

  @override
  String get cfgToPdaOutputInvalid =>
      'A construção de GLC para AP produziu uma saída inválida.';

  @override
  String get tmMultiTapeCancelled =>
      'A execução de múltiplas fitas foi cancelada.';

  @override
  String get tmMultiTapeTimeout =>
      'A execução de múltiplas fitas atingiu o tempo limite.';

  @override
  String get tmMultiTapeConfigurationLimit =>
      'A execução de múltiplas fitas atingiu o limite de configurações.';

  @override
  String tmMultiTapeEnteredFinalState(String policy) {
    return 'A execução de múltiplas fitas entrou em estado final sob a política $policy.';
  }

  @override
  String tmMultiTapeBranchEnteredFinalState(String policy) {
    return 'Um ramo da execução de múltiplas fitas entrou em estado final sob a política $policy.';
  }

  @override
  String tmMultiTapeHaltedAccepted(String policy) {
    return 'A execução de múltiplas fitas parou com aceitação sob a política $policy.';
  }

  @override
  String tmMultiTapeBranchHaltedAccepted(String policy) {
    return 'Um ramo da execução de múltiplas fitas parou com aceitação sob a política $policy.';
  }

  @override
  String get tmMultiTapeDeterministicConflict =>
      'A máquina de múltiplas fitas tem transições determinísticas conflitantes.';

  @override
  String get tmMultiTapeDeterministicCycle =>
      'Um ciclo determinístico foi detectado durante a execução de múltiplas fitas.';

  @override
  String get tmMultiTapeStepLimit =>
      'A execução de múltiplas fitas atingiu o limite de passos.';

  @override
  String get tmMultiTapeHaltedRejected =>
      'A execução de múltiplas fitas parou sem aceitação.';

  @override
  String get tmMultiTapeEveryBranchRejected =>
      'Todos os ramos da execução de múltiplas fitas foram rejeitados.';

  @override
  String tmBuildingBlockDuplicateMachineId(String block) {
    return 'O bloco de construção $block reutiliza o ID da máquina raiz.';
  }

  @override
  String tmBuildingBlockEmptyBlockName(String block) {
    return 'O bloco de construção $block tem nome vazio.';
  }

  @override
  String tmBuildingBlockDuplicateBlockName(
    String firstBlock,
    String secondBlock,
  ) {
    return 'Os IDs de blocos $firstBlock e $secondBlock usam o mesmo nome.';
  }

  @override
  String tmBuildingBlockMissingInitialState(String block) {
    return 'O bloco de construção $block não tem estado inicial.';
  }

  @override
  String get tmBuildingBlockMissingRootInitialState =>
      'A máquina raiz não tem estado inicial.';

  @override
  String tmBuildingBlockTapeCountMismatch(
    String block,
    int blockTapes,
    int rootTapes,
  ) {
    return 'O bloco $block usa $blockTapes fitas, mas a máquina raiz usa $rootTapes.';
  }

  @override
  String tmBuildingBlockBlankSymbolMismatch(String block) {
    return 'O bloco de construção $block usa símbolo branco diferente da máquina raiz.';
  }

  @override
  String tmBuildingBlockNestedLibrary(String block) {
    return 'O bloco de construção $block contém uma biblioteca de blocos aninhada.';
  }

  @override
  String tmBuildingBlockRecursiveDependency(String cycle) {
    return 'O grafo de dependências dos blocos é recursivo: $cycle.';
  }

  @override
  String tmBuildingBlockDuplicateInvocationId(String invocation) {
    return 'O ID de invocação $invocation está duplicado.';
  }

  @override
  String tmBuildingBlockDuplicateInvocationState(String state) {
    return 'O estado $state invoca mais de um bloco de construção.';
  }

  @override
  String tmBuildingBlockMissingAnchorState(String invocation) {
    return 'A invocação $invocation não tem estado âncora.';
  }

  @override
  String tmBuildingBlockMissingReference(String invocation, String block) {
    return 'A invocação $invocation referencia o bloco ausente $block.';
  }

  @override
  String tmBuildingBlockRevisionMismatch(
    String invocation,
    int expected,
    String block,
    int actual,
  ) {
    return 'A invocação $invocation espera a revisão $expected do bloco $block, mas encontrou a revisão $actual.';
  }

  @override
  String tmBuildingBlockAcceptingRootInvocation(
    String invocation,
    String block,
  ) {
    return 'A invocação raiz $invocation do bloco $block não pode ser de aceitação.';
  }

  @override
  String get tmBuildingBlockInvalidProject =>
      'O projeto de blocos de construção é inválido.';

  @override
  String get tmBuildingBlockCancelled =>
      'A execução de blocos de construção foi cancelada.';

  @override
  String get tmBuildingBlockTimeout =>
      'A execução de blocos de construção atingiu o tempo limite.';

  @override
  String get tmBuildingBlockConfigurationLimit =>
      'A execução de blocos de construção atingiu o limite de configurações.';

  @override
  String get tmBuildingBlockCallDepthLimit =>
      'A execução de blocos de construção atingiu o limite de profundidade de chamadas.';

  @override
  String get tmBuildingBlockStepLimit =>
      'A execução de blocos de construção atingiu o limite de passos.';

  @override
  String tmBuildingBlockEnteredFinalState(String policy) {
    return 'A execução entrou em estado final sob a política $policy.';
  }

  @override
  String tmBuildingBlockHaltedAccepted(String policy) {
    return 'A execução de blocos parou com aceitação sob a política $policy.';
  }

  @override
  String get tmBuildingBlockHaltedRejected =>
      'A execução de blocos parou sem aceitação.';

  @override
  String get tmBuildingBlockFiniteGraphRejected =>
      'O grafo finito de blocos rejeitou a entrada.';

  @override
  String get tmBuildingBlockRepeatedConfiguration =>
      'A execução de blocos repetiu uma configuração.';

  @override
  String get tmToGrammarInvalidMachine =>
      'A máquina de Turing é inválida para conversão em gramática irrestrita.';

  @override
  String tmToGrammarInvalidMachineDetail(String detail) {
    return 'A máquina de Turing é inválida para conversão: $detail.';
  }

  @override
  String get tmToGrammarMissingInitialState =>
      'A máquina de Turing deve ter um estado inicial.';

  @override
  String get tmToGrammarNoAcceptingState =>
      'A máquina de Turing não tem estado de aceitação; a linguagem convertida é vazia.';

  @override
  String tmToGrammarMultiTapeUnsupported(int tapes) {
    return 'A conversão de MT para gramática não aceita $tapes fitas.';
  }

  @override
  String get tmToGrammarMultiTapeUnsupportedGeneric =>
      'A conversão de MT para gramática não aceita máquinas com múltiplas fitas.';

  @override
  String tmToGrammarBuildingBlocksUnsupported(String blocks) {
    return 'A conversão de MT para gramática não aceita blocos de construção: $blocks.';
  }

  @override
  String get tmToGrammarBuildingBlocksUnsupportedGeneric =>
      'A conversão de MT para gramática não aceita blocos de construção.';

  @override
  String tmToGrammarBlankInInputAlphabet(String symbol) {
    return 'O símbolo branco $symbol não pode estar no alfabeto de entrada.';
  }

  @override
  String get tmToGrammarBlankInInputAlphabetGeneric =>
      'O símbolo branco não pode estar no alfabeto de entrada.';

  @override
  String tmToGrammarInputOutsideTapeAlphabet(String symbol) {
    return 'O símbolo de entrada $symbol está fora do alfabeto da fita.';
  }

  @override
  String get tmToGrammarInputOutsideTapeAlphabetGeneric =>
      'Um símbolo de entrada está fora do alfabeto da fita.';

  @override
  String tmToGrammarConstructionLimit(int limit) {
    return 'A construção de MT para gramática atingiu o limite de $limit produções.';
  }

  @override
  String tmToGrammarConstructionLimitDetail(String detail) {
    return 'A construção de MT para gramática parou: $detail.';
  }

  @override
  String get tmToGrammarConstructionLimitGeneric =>
      'A construção de MT para gramática atingiu seu limite.';

  @override
  String tmToGrammarOutputInvalid(String detail) {
    return 'A conversão de MT para gramática produziu saída inválida: $detail.';
  }

  @override
  String get tmToGrammarOutputInvalidGeneric =>
      'A conversão de MT para gramática produziu saída inválida.';

  @override
  String tmToGrammarUnreachableState(String state) {
    return 'O estado $state é inalcançável a partir do estado inicial.';
  }

  @override
  String get tmToGrammarUnreachableStateGeneric =>
      'Foi encontrado um estado inalcançável.';

  @override
  String get dfaMinimizationStepInitialPartitionTitle =>
      'Criar a partição inicial';

  @override
  String dfaMinimizationStepInitialPartitionExplanation(
    String acceptingStates,
    String nonAcceptingStates,
  ) {
    return 'Partição inicial: estados de aceitação [$acceptingStates] e estados sem aceitação [$nonAcceptingStates].';
  }

  @override
  String get dfaMinimizationStepRemoveUnreachableTitle =>
      'Remover estados inalcançáveis';

  @override
  String dfaMinimizationStepRemoveUnreachableExplanation(
    String unreachableStates,
    int reachableStateCount,
  ) {
    return 'Estados inalcançáveis removidos [$unreachableStates]; restam $reachableStateCount estados alcançáveis.';
  }

  @override
  String get dfaMinimizationStepSelectSetTitle =>
      'Selecionar um conjunto da partição';

  @override
  String dfaMinimizationStepSelectSetExplanation(String states) {
    return 'Conjunto da partição selecionado [$states] para refinamento.';
  }

  @override
  String dfaMinimizationStepFindPredecessorsTitle(String symbol) {
    return 'Encontrar predecessores em $symbol';
  }

  @override
  String dfaMinimizationStepFindPredecessorsExplanation(
    String states,
    String symbol,
    String predecessors,
    String hasPredecessors,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasPredecessors, {
      'true': '.',
      'other': '; nenhum predecessor foi encontrado.',
    });
    return 'Os estados [$states] têm predecessores [$predecessors] em $symbol$_temp0';
  }

  @override
  String get dfaMinimizationStepSplitClassTitle =>
      'Dividir uma classe da partição';

  @override
  String dfaMinimizationStepSplitClassExplanation(
    String splitStates,
    String symbol,
    String intersectionStates,
    String differenceStates,
    int oldPartitionSize,
    int newPartitionSize,
  ) {
    return 'Divisão de [$splitStates] em $symbol: interseção [$intersectionStates] e diferença [$differenceStates] ($oldPartitionSize classes tornaram-se $newPartitionSize).';
  }

  @override
  String dfaMinimizationStepNoSplitTitle(String symbol) {
    return 'Manter a classe da partição para $symbol';
  }

  @override
  String dfaMinimizationStepNoSplitExplanation(String states, String symbol) {
    return 'A classe [$states] permanece estável para o símbolo $symbol.';
  }

  @override
  String get dfaMinimizationStepPartitionStableTitle =>
      'A partição está estável';

  @override
  String dfaMinimizationStepPartitionStableExplanation(int partitionSize) {
    return 'A partição está estável com $partitionSize classes.';
  }

  @override
  String dfaMinimizationStepCreateMinimizedStateTitle(String state) {
    return 'Criar estado minimizado $state';
  }

  @override
  String dfaMinimizationStepCreateMinimizedStateExplanation(
    String state,
    String equivalenceClass,
    String isInitial,
    String isAccepting,
  ) {
    String _temp0 = intl.Intl.selectLogic(isInitial, {
      'true': 'sim',
      'other': 'não',
    });
    String _temp1 = intl.Intl.selectLogic(isAccepting, {
      'true': 'sim',
      'other': 'não',
    });
    return 'O estado $state representa [$equivalenceClass]; inicial: $_temp0, aceitação: $_temp1.';
  }

  @override
  String dfaMinimizationStepCreateMinimizedTransitionTitle(String symbol) {
    return 'Criar transição minimizada em $symbol';
  }

  @override
  String dfaMinimizationStepCreateMinimizedTransitionExplanation(
    String fromState,
    String toState,
    String symbol,
  ) {
    return 'Transição de $fromState para $toState em $symbol.';
  }

  @override
  String get dfaMinimizationStepCompletionTitle =>
      'Concluir minimização do AFD';

  @override
  String dfaMinimizationStepCompletionExplanation(
    int originalStateCount,
    int minimizedStateCount,
    int transitionCount,
    int reduction,
    String hasReduction,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasReduction, {
      'true': ' e redução de $reduction estados',
      'other': '',
    });
    return 'Minimização concluída: $originalStateCount estados tornaram-se $minimizedStateCount, com $transitionCount transições$_temp0.';
  }

  @override
  String fsaDeterminizerFailed(String automaton) {
    return 'A determinização falhou para $automaton.';
  }

  @override
  String get validationFsaEmpty => 'O autômato não tem estados.';

  @override
  String get validationFsaNoInitial => 'O autômato não tem estado inicial.';

  @override
  String validationFsaInvalidInitial(String state) {
    return 'O estado inicial $state não está no conjunto de estados.';
  }

  @override
  String get validationFsaEmptyAlphabet => 'O autômato não tem alfabeto.';

  @override
  String validationFsaInvalidAccepting(String state) {
    return 'O estado de aceitação $state não está no conjunto de estados.';
  }

  @override
  String validationFsaBadFrom(String state) {
    return 'O estado de origem $state da transição é desconhecido.';
  }

  @override
  String validationFsaBadTo(String state) {
    return 'O estado de destino $state da transição é desconhecido.';
  }

  @override
  String validationFsaBadSymbol(String symbol) {
    return 'O símbolo de transição $symbol está fora do alfabeto.';
  }

  @override
  String validationFsaNondeterministic(String state, int count, String symbol) {
    return 'O estado $state tem $count transições em $symbol.';
  }

  @override
  String get validationPdaEmpty => 'O PDA não tem estados.';

  @override
  String get validationPdaNoInitial => 'O PDA não tem estado inicial.';

  @override
  String validationPdaInvalidInitial(String state) {
    return 'O estado inicial $state não está no conjunto de estados.';
  }

  @override
  String get validationPdaNoAccepting => 'O PDA não tem estados de aceitação.';

  @override
  String get validationPdaEmptyInputAlphabet =>
      'O PDA não tem alfabeto de entrada.';

  @override
  String get validationPdaEmptyStackAlphabet =>
      'O PDA não tem alfabeto da pilha.';

  @override
  String validationPdaInvalidInitialStack(String symbol) {
    return 'O símbolo inicial da pilha $symbol está fora do alfabeto da pilha.';
  }

  @override
  String validationPdaInvalidAccepting(String state) {
    return 'O estado de aceitação $state não está no conjunto de estados.';
  }

  @override
  String validationPdaBadFrom(String state) {
    return 'O estado de origem $state da transição é desconhecido.';
  }

  @override
  String validationPdaBadTo(String state) {
    return 'O estado de destino $state da transição é desconhecido.';
  }

  @override
  String validationPdaBadInputSymbol(String symbol) {
    return 'O símbolo de entrada $symbol está fora do alfabeto de entrada.';
  }

  @override
  String validationPdaBadStackSymbol(String symbol) {
    return 'O símbolo da pilha $symbol está fora do alfabeto da pilha.';
  }

  @override
  String validationPdaBadPushSymbol(String symbol) {
    return 'O símbolo empilhado $symbol está fora do alfabeto da pilha.';
  }

  @override
  String get nfaToDfaStepInitialEpsilonClosureTitle =>
      'Calcular o fecho-ε inicial';

  @override
  String nfaToDfaStepInitialEpsilonClosureExplanation(
    String initialState,
    String epsilonClosure,
    String containsAcceptingState,
  ) {
    String _temp0 = intl.Intl.selectLogic(containsAcceptingState, {
      'true': ' e contém um estado de aceitação',
      'other': '',
    });
    return 'O fecho-ε de $initialState é $epsilonClosure$_temp0.';
  }

  @override
  String get nfaToDfaStepInitialEpsilonClosureStepTitle => 'Fecho-ε inicial';

  @override
  String nfaToDfaStepInitialState(String state) {
    return 'Comece no estado $state.';
  }

  @override
  String nfaToDfaStepEpsilonClosureReached(String stateSet) {
    return 'Alcance $stateSet por transições ε.';
  }

  @override
  String get nfaToDfaStepInitialStateIsAccepting =>
      'O estado inicial do AFD é de aceitação.';

  @override
  String nfaToDfaStepProcessSymbolTitle(String symbol) {
    return 'Processar o símbolo $symbol';
  }

  @override
  String nfaToDfaStepProcessSymbolExplanation(
    String currentStates,
    String symbol,
    String reachableStates,
  ) {
    return 'A partir de $currentStates, ler $symbol alcança $reachableStates antes do fecho-ε.';
  }

  @override
  String get nfaToDfaStepProcessSymbolStepTitle =>
      'Processar um símbolo de entrada';

  @override
  String nfaToDfaStepCurrentDfaStateSet(String stateSet) {
    return 'Use o conjunto de estados do AFD $stateSet.';
  }

  @override
  String nfaToDfaStepCollectSymbolDestinations(String symbol) {
    return 'Siga as transições do AFN rotuladas $symbol.';
  }

  @override
  String nfaToDfaStepReachableBeforeEpsilonClosure(String stateSet) {
    return 'Alcance os estados do AFN $stateSet.';
  }

  @override
  String get nfaToDfaStepEpsilonClosureOfReachableTitle =>
      'Calcular o fecho-ε dos estados alcançáveis';

  @override
  String nfaToDfaStepEpsilonClosureOfReachableExplanation(
    String reachableStates,
    String epsilonClosure,
    String isNewState,
    String containsAcceptingState,
  ) {
    String _temp0 = intl.Intl.selectLogic(isNewState, {
      'true': 'cria um novo',
      'other': 'reutiliza um',
    });
    String _temp1 = intl.Intl.selectLogic(containsAcceptingState, {
      'true': ', que é de aceitação',
      'other': '',
    });
    return 'O fecho-ε de $reachableStates é $epsilonClosure; ele $_temp0 estado do AFD$_temp1.';
  }

  @override
  String get nfaToDfaStepEpsilonClosureOfReachableStepTitle =>
      'Fechar estados alcançáveis sob ε';

  @override
  String get nfaToDfaStepEpsilonTransitionsDoNotConsumeInput =>
      'Transições ε não consomem entrada.';

  @override
  String nfaToDfaStepEpsilonClosureReachedFromStates(
    String reachableStates,
    String epsilonClosure,
  ) {
    return 'O fecho-ε a partir de $reachableStates é $epsilonClosure.';
  }

  @override
  String get nfaToDfaStepNewDfaStateSet =>
      'Este conjunto se torna um novo estado do AFD.';

  @override
  String get nfaToDfaStepExistingDfaStateSet =>
      'Este conjunto corresponde a um estado existente do AFD.';

  @override
  String get nfaToDfaStepAcceptingDfaStateSet =>
      'O conjunto de estados do AFD é de aceitação.';

  @override
  String nfaToDfaStepCreateDfaStateTitle(String state) {
    return 'Criar o estado $state do AFD';
  }

  @override
  String nfaToDfaStepCreateDfaStateExplanation(
    String state,
    String stateSet,
    String isAccepting,
  ) {
    String _temp0 = intl.Intl.selectLogic(isAccepting, {
      'true': 'é de aceitação',
      'other': 'não é de aceitação',
    });
    return 'O estado $state do AFD representa $stateSet e $_temp0.';
  }

  @override
  String get nfaToDfaStepCreateDfaStateStepTitle => 'Criar um estado do AFD';

  @override
  String get nfaToDfaStepSubsetConstructionDistinctStateSets =>
      'Cada conjunto distinto de estados do AFN se torna um estado do AFD.';

  @override
  String nfaToDfaStepDfaStateRepresentsNfaSet(String stateSet) {
    return 'O estado do AFD representa o conjunto do AFN $stateSet.';
  }

  @override
  String get nfaToDfaStepAcceptingDfaState =>
      'Marque o estado do AFD como de aceitação.';

  @override
  String get nfaToDfaStepNonAcceptingDfaState =>
      'O estado do AFD não é de aceitação.';

  @override
  String nfaToDfaStepCreateDfaTransitionTitle(String symbol) {
    return 'Criar transição do AFD em $symbol';
  }

  @override
  String nfaToDfaStepCreateDfaTransitionExplanation(
    String fromState,
    String symbol,
    String toState,
    String fromStates,
    String toStates,
  ) {
    return 'Adicione $fromState —$symbol→ $toState para $fromStates até $toStates.';
  }

  @override
  String get nfaToDfaStepCreateDfaTransitionStepTitle =>
      'Criar uma transição do AFD';

  @override
  String nfaToDfaStepNfaTransitionReachability(
    String fromStates,
    String symbol,
    String toStates,
  ) {
    return 'Os estados do AFN $fromStates em $symbol alcançam $toStates.';
  }

  @override
  String get nfaToDfaStepSingleDeterministicTransition =>
      'Registre uma única transição determinística para este conjunto e símbolo.';

  @override
  String get nfaToDfaStepCompletionTitle =>
      'Concluir conversão de AFN para AFD';

  @override
  String nfaToDfaStepCompletionExplanation(
    int stateCount,
    int transitionCount,
    int acceptingStateCount,
  ) {
    return 'O AFD tem $stateCount estados, $transitionCount transições e $acceptingStateCount estados de aceitação.';
  }

  @override
  String get nfaToDfaStepCompletionStepTitle => 'Conversão concluída';

  @override
  String nfaToDfaStepCreatedStateCount(int count) {
    return 'Foram criados $count estados do AFD.';
  }

  @override
  String nfaToDfaStepCreatedTransitionCount(int count) {
    return 'Foram criadas $count transições do AFD.';
  }

  @override
  String nfaToDfaStepMarkedAcceptingStateCount(int count) {
    return '$count estados do AFD foram marcados como de aceitação.';
  }

  @override
  String get cykStepInitializeTitle => 'Inicializar a tabela CYK';

  @override
  String cykStepInitializeExplanation(String input, int tableSize) {
    return 'Inicialize uma tabela para a entrada $input com $tableSize tokens.';
  }

  @override
  String get cykStepInitializeStepTitle => 'Inicializar a tabela CYK';

  @override
  String cykStepInitializeInputBullet(String input, int tableSize) {
    return 'Tokenize a entrada $input ($tableSize tokens).';
  }

  @override
  String get cykStepInitializeTableBullet => 'Crie a tabela triangular CYK.';

  @override
  String cykStepFillBaseCaseTitle(String terminal) {
    return 'Preencher o caso-base para $terminal';
  }

  @override
  String cykStepFillBaseCaseExplanation(
    int position,
    String terminal,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'nenhum não terminal',
    });
    return 'Na posição de entrada $position, o terminal $terminal é derivado por $_temp0.';
  }

  @override
  String cykStepFillBaseCaseStepTitle(String terminal) {
    return 'Preencher o caso-base para $terminal';
  }

  @override
  String cykStepFillBaseCaseFragmentBullet(int position, String terminal) {
    return 'O fragmento de entrada na posição $position é $terminal.';
  }

  @override
  String get cykStepFillBaseCaseProductionBullet =>
      'Encontre produções que derivam este terminal.';

  @override
  String cykStepFillBaseCaseEmptyBullet(String terminal) {
    return 'Nenhum não terminal deriva o terminal $terminal.';
  }

  @override
  String cykStepFillBaseCaseAddedBullet(String variables) {
    return 'Adicione os não terminais $variables à célula.';
  }

  @override
  String cykStepProcessCellTitle(int row, int column) {
    return 'Processar célula [$row][$column]';
  }

  @override
  String cykStepProcessCellExplanation(
    int row,
    int column,
    String substring,
    int length,
  ) {
    return 'Processe a substring $substring em [$row][$column] com comprimento $length.';
  }

  @override
  String cykStepProcessCellStepTitle(String substring) {
    return 'Processar a célula CYK $substring';
  }

  @override
  String cykStepProcessCellLocationBullet(int row, int column, int length) {
    return 'Localize a substring de comprimento $length na célula [$row][$column].';
  }

  @override
  String get cykStepProcessCellSplitBullet =>
      'Teste cada ponto de divisão da substring.';

  @override
  String cykStepCheckSplitTitle(int splitPoint) {
    return 'Verificar a divisão na posição $splitPoint';
  }

  @override
  String cykStepCheckSplitExplanation(
    String substring,
    String leftSubstring,
    String rightSubstring,
    int leftRow,
    int leftColumn,
    int rightRow,
    int rightColumn,
    String leftVariables,
    String rightVariables,
    String hasLeftVariables,
    String hasRightVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasLeftVariables, {
      'true': '$leftVariables',
      'other': 'vazia',
    });
    String _temp1 = intl.Intl.selectLogic(hasRightVariables, {
      'true': '$rightVariables',
      'other': 'vazia',
    });
    return 'Divida $substring em $leftSubstring e $rightSubstring; inspecione [$leftRow][$leftColumn] e [$rightRow][$rightColumn]. Esquerda: $_temp0; direita: $_temp1.';
  }

  @override
  String cykStepCheckSplitStepTitle(
    String leftSubstring,
    String rightSubstring,
  ) {
    return 'Verificar a divisão $leftSubstring | $rightSubstring';
  }

  @override
  String cykStepCheckSplitLeftBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'vazia',
    });
    return 'Leia a célula esquerda [$row][$column]: $_temp0.';
  }

  @override
  String cykStepCheckSplitRightBullet(
    int row,
    int column,
    String variables,
    String hasVariables,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasVariables, {
      'true': '$variables',
      'other': 'vazia',
    });
    return 'Leia a célula direita [$row][$column]: $_temp0.';
  }

  @override
  String cykStepCheckSplitProductionBullet(int row, int column) {
    return 'Em [$row][$column], procure uma produção que combine as duas células.';
  }

  @override
  String cykStepApplyProductionTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  ) {
    return 'Aplicar $variable → $leftVariable $rightVariable';
  }

  @override
  String cykStepApplyProductionExplanation(
    int row,
    int column,
    String variable,
    String leftVariable,
    String rightVariable,
    String substring,
  ) {
    return 'Em [$row][$column], aplique $variable → $leftVariable $rightVariable a $substring.';
  }

  @override
  String cykStepApplyProductionStepTitle(
    String variable,
    String leftVariable,
    String rightVariable,
  ) {
    return 'Aplicar $variable → $leftVariable $rightVariable';
  }

  @override
  String get cykStepApplyProductionCombineBullet =>
      'Combine os não terminais das células esquerda e direita.';

  @override
  String cykStepApplyProductionDerivationBullet(
    String leftVariable,
    String rightVariable,
    String variable,
    String substring,
  ) {
    return 'Use $leftVariable e $rightVariable para derivar $variable para $substring.';
  }

  @override
  String cykStepApplyProductionAddBullet(int row, int column, String variable) {
    return 'Adicione $variable à célula [$row][$column].';
  }

  @override
  String cykStepCompleteCellTitle(int row, int column) {
    return 'Concluir célula [$row][$column]';
  }

  @override
  String cykStepCompleteCellExplanation(
    int row,
    int column,
    String substring,
    String nonterminals,
    String hasNonterminals,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasNonterminals, {
      'true': '$nonterminals',
      'other': 'nenhum não terminal',
    });
    return 'A célula [$row][$column] para $substring contém $_temp0.';
  }

  @override
  String cykStepCompleteCellStepTitle(int row, int column) {
    return 'Concluir a célula [$row][$column]';
  }

  @override
  String cykStepCompleteCellSubstringBullet(String substring) {
    return 'A célula cobre a substring $substring.';
  }

  @override
  String get cykStepCompleteCellEmptyBullet =>
      'A célula não contém não terminais.';

  @override
  String cykStepCompleteCellNonterminalsBullet(String nonterminals) {
    return 'A célula contém os não terminais $nonterminals.';
  }

  @override
  String get cykStepCheckAcceptanceTitle => 'Verificar aceitação CYK';

  @override
  String cykStepCheckAcceptanceExplanation(
    String input,
    String startSymbol,
    String nonterminals,
    String hasNonterminals,
    String accepted,
  ) {
    String _temp0 = intl.Intl.selectLogic(hasNonterminals, {
      'true': '$nonterminals',
      'other': 'nenhum não terminal',
    });
    String _temp1 = intl.Intl.selectLogic(accepted, {
      'true': 'está presente',
      'other': 'está ausente',
    });
    return 'Para a entrada $input, a célula final tem $_temp0; o símbolo inicial $startSymbol $_temp1.';
  }

  @override
  String get cykStepCheckAcceptanceStepTitle => 'Verificar aceitação';

  @override
  String cykStepCheckAcceptanceFinalCellBullet(String nonterminals) {
    return 'Inspecione os não terminais da célula final $nonterminals.';
  }

  @override
  String cykStepCheckAcceptanceAcceptedBullet(String startSymbol) {
    return 'O símbolo inicial $startSymbol está na célula final.';
  }

  @override
  String cykStepCheckAcceptanceRejectedBullet(String startSymbol) {
    return 'O símbolo inicial $startSymbol não está na célula final.';
  }

  @override
  String get cykStepCompletionTitle => 'Concluir análise CYK';

  @override
  String cykStepCompletionExplanation(
    String input,
    int totalCells,
    int filledCells,
    String accepted,
  ) {
    String _temp0 = intl.Intl.selectLogic(accepted, {
      'true': 'a entrada é aceita',
      'other': 'a entrada é rejeitada',
    });
    return 'Análise de $input: $filledCells de $totalCells células preenchidas; $_temp0.';
  }

  @override
  String get cykStepCompletionStepTitle => 'Análise concluída';

  @override
  String cykStepCompletionFilledCellsBullet(int totalCells, int filledCells) {
    return 'Preencha $filledCells de $totalCells células da tabela.';
  }

  @override
  String get cykStepCompletionAcceptedBullet =>
      'A entrada é aceita pela gramática.';

  @override
  String get cykStepCompletionRejectedBullet =>
      'A entrada é rejeitada pela gramática.';

  @override
  String get pdaLanguageEmptinessInvalidLimits =>
      'Os limites da análise de vacuidade do AP devem ser maiores que zero.';

  @override
  String get pdaLanguageEmptinessCancelled =>
      'A análise de vacuidade da linguagem do AP foi cancelada.';

  @override
  String get pdaLanguageEmptinessWitnessReplayFailed =>
      'A testemunha da GLC não pôde ser reproduzida pelo AP de origem.';

  @override
  String get pdaLanguageEmptinessCfgInvalidLimits =>
      'Os limites da análise de testemunha mínima da GLC devem ser maiores que zero.';

  @override
  String get pdaLanguageEmptinessCfgMissingStartSymbol =>
      'O símbolo inicial da GLC deve ser um não terminal declarado.';

  @override
  String get pdaLanguageEmptinessCfgOverlappingSymbolSets =>
      'Os terminais e não terminais da GLC devem ser disjuntos.';

  @override
  String pdaLanguageEmptinessCfgInvalidProductionLeft(String production) {
    return 'A produção $production deve ter um não terminal declarado no lado esquerdo.';
  }

  @override
  String pdaLanguageEmptinessCfgInconsistentLambdaMetadata(String production) {
    return 'A produção $production tem metadados de lambda inconsistentes.';
  }

  @override
  String pdaLanguageEmptinessCfgEpsilonMixed(String production) {
    return 'A produção $production mistura épsilon com outros símbolos.';
  }

  @override
  String pdaLanguageEmptinessCfgUndeclaredSymbol(
    String production,
    String symbol,
  ) {
    return 'A produção $production usa o símbolo não declarado $symbol.';
  }

  @override
  String get pdaLanguageEmptinessCfgCancelled =>
      'A análise de testemunha mínima da GLC foi cancelada.';

  @override
  String pdaLanguageEmptinessCfgProductivityLimit(int limit) {
    return 'O limite de atualizações de produtividade da GLC foi excedido ($limit).';
  }

  @override
  String pdaLanguageEmptinessCfgDerivationLimit(int limit) {
    return 'O limite de etapas da derivação da GLC foi excedido ($limit).';
  }

  @override
  String get pdaLanguageEmptinessCfgWitnessMismatch =>
      'A derivação reconstruída da GLC não corresponde à sua testemunha.';

  @override
  String pdaLanguageEmptinessCfgMissingProductiveChoice(String symbol) {
    return 'Não existe uma escolha produtiva para $symbol durante a reconstrução da derivação.';
  }

  @override
  String get validationTmEmpty => 'A MT não tem estados.';

  @override
  String get validationTmNoInitial => 'A MT não tem estado inicial.';

  @override
  String validationTmInvalidInitial(String state) {
    return 'O estado inicial $state não está no conjunto de estados.';
  }

  @override
  String get validationTmNoAccepting => 'A MT não tem estados de aceitação.';

  @override
  String get validationTmEmptyInputAlphabet =>
      'A MT não tem alfabeto de entrada.';

  @override
  String get validationTmEmptyTapeAlphabet => 'A MT não tem alfabeto da fita.';

  @override
  String get validationTmEmptyBlank => 'O símbolo branco está vazio.';

  @override
  String validationTmBlankNotInTape(String symbol) {
    return 'O símbolo branco $symbol não está no alfabeto da fita.';
  }

  @override
  String validationTmInputNotInTape(String symbol) {
    return 'O símbolo de entrada $symbol não está no alfabeto da fita.';
  }

  @override
  String validationTmInvalidAccepting(String state) {
    return 'O estado de aceitação $state não está no conjunto de estados.';
  }

  @override
  String validationTmBadFrom(String state) {
    return 'O estado de origem $state da transição é desconhecido.';
  }

  @override
  String validationTmBadTo(String state) {
    return 'O estado de destino $state da transição é desconhecido.';
  }

  @override
  String validationTmBadReadSymbol(String symbol) {
    return 'A transição lê o símbolo $symbol, que não está no alfabeto da fita.';
  }

  @override
  String validationTmBadWriteSymbol(String symbol) {
    return 'A transição escreve o símbolo $symbol, que não está no alfabeto da fita.';
  }

  @override
  String validationTmBadMove(String direction) {
    return 'A transição tem direção de movimento inválida: $direction.';
  }

  @override
  String get validationCfgEmpty => 'A gramática não tem produções.';

  @override
  String get validationCfgNoNonterminals =>
      'A gramática não tem não terminais.';

  @override
  String get validationCfgNoTerminals => 'A gramática não tem terminais.';

  @override
  String get validationCfgEmptyStart => 'O símbolo inicial está vazio.';

  @override
  String validationCfgBadStart(String symbol) {
    return 'O símbolo inicial $symbol deve ser um não terminal.';
  }

  @override
  String validationCfgEmptyLeft(int production) {
    return 'A produção $production tem o lado esquerdo vazio.';
  }

  @override
  String validationCfgBadLeft(int production, String symbol) {
    return 'O lado esquerdo da produção $production, $symbol, não é um não terminal.';
  }

  @override
  String validationCfgEmptyRight(int production) {
    return 'A produção $production tem o lado direito vazio.';
  }

  @override
  String validationCfgBadSymbol(int production, String symbol) {
    return 'A produção $production contém o símbolo desconhecido $symbol.';
  }

  @override
  String get validationInputEmpty => 'A cadeia de entrada está vazia.';

  @override
  String validationInputInvalidSymbol(String symbol, int position) {
    return 'A entrada contém o símbolo inválido $symbol na posição $position.';
  }

  @override
  String tmBuildingBlockEnterBlock(String machine) {
    return 'Entrar na máquina de bloco de construção $machine.';
  }

  @override
  String tmBuildingBlockTransition(String transition) {
    return 'Aplicar a transição $transition.';
  }

  @override
  String tmBuildingBlockReturnFromBlock(String machine) {
    return 'Retornar da máquina de bloco de construção $machine.';
  }

  @override
  String get codecFsaJflapInvalidRoot =>
      'A raiz XML do JFLAP deve ser <structure>.';

  @override
  String codecFsaJflapUnsupportedDocumentType(String type) {
    return 'O tipo de documento JFLAP $type não é um documento FSA.';
  }

  @override
  String get codecFsaJflapBuildingBlocksUnsupported =>
      'Blocos de construção JFLAP exigem o codec dedicado de MT.';

  @override
  String get codecFsaJflapMissingAutomaton =>
      'O FSA JFLAP não contém <automaton>.';

  @override
  String get codecFsaJflapMissingStateId =>
      'O estado JFLAP não tem um ID não vazio.';

  @override
  String codecFsaJflapDuplicateStateId(String state) {
    return 'O estado $state tem um ID duplicado.';
  }

  @override
  String codecFsaJflapInvalidStateCoordinate(String state) {
    return 'O estado $state tem uma coordenada inválida.';
  }

  @override
  String get codecFsaJflapMultipleInitialStates =>
      'O FSA contém vários estados iniciais.';

  @override
  String get codecFsaJflapInvalidDocument => 'O documento FSA é inválido.';

  @override
  String codecFsaJflapUnsupportedSchema(int version) {
    return 'A versão de esquema FSA $version não é compatível.';
  }

  @override
  String get codecFsaJflapRequiresFsaDocument =>
      'O codec JFLAP exige um documento FSA.';

  @override
  String get codecFsaJflapCanonicalOrderImport =>
      'Estados e transições foram ordenados de forma canônica durante a importação.';

  @override
  String get codecFsaJflapCanonicalOrderExport =>
      'Estados e transições foram ordenados de forma canônica durante a exportação.';

  @override
  String codecFsaJflapStateTypeDropped(String state) {
    return 'O estado $state usa um tipo que o FSA JFLAP não pode armazenar.';
  }

  @override
  String codecFsaJflapStatePropertiesDropped(String state) {
    return 'O estado $state tem propriedades que o FSA JFLAP não pode armazenar.';
  }

  @override
  String codecFsaJflapTransitionControlPointDropped(
    String transition,
    String controlPoint,
  ) {
    return 'O ponto de controle da transição $transition foi descartado em $controlPoint.';
  }

  @override
  String codecFsaJflapTransitionDisplayLabelDropped(String transition) {
    return 'O rótulo de exibição separado da transição $transition foi descartado.';
  }

  @override
  String codecFsaJflapExplicitEpsilonAliasInterpreted(String symbol) {
    return 'O alias explícito de epsilon $symbol foi interpretado como leitura vazia.';
  }

  @override
  String codecFsaJflapExplicitEpsilonAliasExportedEmpty(
    String aliases,
    String transition,
  ) {
    return 'Os aliases explícitos de epsilon $aliases foram exportados como leituras vazias para a transição $transition.';
  }

  @override
  String codecFsaJflapMultiSymbolTransitionExpanded(
    String transition,
    int count,
  ) {
    return 'A transição $transition foi expandida em $count transições de um símbolo.';
  }

  @override
  String codecFsaJflapUnknownOptionalElement(String extension) {
    return 'O elemento XML opcional desconhecido $extension foi ignorado.';
  }

  @override
  String codecFsaJflapUnknownOptionalAttribute(String extension) {
    return 'O atributo XML opcional desconhecido $extension foi ignorado.';
  }

  @override
  String grammarAnalysisFirstProductionLhsUndeclared(String nonTerminal) {
    return 'FIRST não pode ser calculado porque o lado esquerdo $nonTerminal não é um não terminal declarado.';
  }

  @override
  String grammarAnalysisFirstEpsilonEmptyProduction(String nonTerminal) {
    return 'FIRST($nonTerminal) ganha epsilon de uma produção vazia.';
  }

  @override
  String grammarAnalysisFirstEpsilonProduction(
    String nonTerminal,
    String production,
  ) {
    return 'FIRST($nonTerminal) ganha epsilon porque $production contém epsilon.';
  }

  @override
  String grammarAnalysisFirstTerminalProduction(
    String nonTerminal,
    String symbol,
    String production,
  ) {
    return 'FIRST($nonTerminal) ganha o terminal $symbol de $production.';
  }

  @override
  String grammarAnalysisFirstAbsorbsFirst(
    String nonTerminal,
    String source,
    String production,
  ) {
    return 'FIRST($nonTerminal) absorve FIRST($source) menos epsilon por meio de $production.';
  }

  @override
  String grammarAnalysisFirstEpsilonNullableProduction(
    String nonTerminal,
    String production,
  ) {
    return 'FIRST($nonTerminal) ganha epsilon porque todos os símbolos de $production são anuláveis.';
  }

  @override
  String grammarAnalysisFirstSetsComputed(int count) {
    return 'Conjuntos FIRST calculados para $count não terminais.';
  }

  @override
  String grammarAnalysisFollowStartSymbolUndeclared(String symbol) {
    return 'FOLLOW não pode ser calculado porque o símbolo inicial $symbol não é um não terminal declarado.';
  }

  @override
  String grammarAnalysisFollowStartSymbolMissingEntry(String symbol) {
    return 'FOLLOW não tem uma entrada para o símbolo inicial $symbol.';
  }

  @override
  String grammarAnalysisFollowStartIncludesEndMarker(String symbol) {
    return 'FOLLOW($symbol) inclui o marcador de fim.';
  }

  @override
  String grammarAnalysisFollowProductionLhsUndeclared(String nonTerminal) {
    return 'FOLLOW não pode ser calculado porque o lado esquerdo $nonTerminal não é um não terminal declarado.';
  }

  @override
  String grammarAnalysisFollowGainsFromSuffix(
    String nonTerminal,
    String symbols,
    String production,
  ) {
    return 'FOLLOW($nonTerminal) ganha $symbols do sufixo em $production.';
  }

  @override
  String grammarAnalysisFollowAbsorbsFollow(
    String nonTerminal,
    String source,
    String production,
  ) {
    return 'FOLLOW($nonTerminal) absorve FOLLOW($source) porque o sufixo em $production é anulável.';
  }

  @override
  String grammarAnalysisFollowSetsComputed(int count) {
    return 'Conjuntos FOLLOW calculados para $count não terminais.';
  }

  @override
  String grammarAnalysisProcessingOrder(String nonTerminals) {
    return 'Não terminais processados nesta ordem: $nonTerminals.';
  }

  @override
  String grammarAnalysisSubstitutionNote(String production, String via) {
    return 'Substituir $production usando $via.';
  }

  @override
  String grammarAnalysisSubstitutionDerivation(
    String production,
    String replacements,
  ) {
    return 'A substituição de $production produz $replacements.';
  }

  @override
  String grammarAnalysisSubstitutionOperation(String nonTerminal, String via) {
    return 'Substituir produções de $nonTerminal por meio de $via.';
  }

  @override
  String grammarAnalysisSubstitutionRationale(String nonTerminal, String via) {
    return 'Substituir o $via inicial em $nonTerminal pelas alternativas atuais.';
  }

  @override
  String grammarAnalysisRemoveVacuousRecursionRationale(String nonTerminal) {
    return 'Remover alternativas $nonTerminal → $nonTerminal vazias, pois elas não adicionam cadeias.';
  }

  @override
  String grammarAnalysisVacuousRecursionDerivation(String productions) {
    return 'Alternativas recursivas vazias removidas: $productions.';
  }

  @override
  String grammarAnalysisRecursiveOnlyRationale(String nonTerminal) {
    return 'Remover alternativas somente recursivas de $nonTerminal, pois não geram cadeias terminais.';
  }

  @override
  String grammarAnalysisRecursiveOnlyDerivation(String nonTerminal) {
    return 'Alternativas somente recursivas de $nonTerminal removidas.';
  }

  @override
  String grammarAnalysisDirectRecursionIntroduced(
    String introduced,
    String nonTerminal,
  ) {
    return '$introduced foi introduzido para remover a recursão direta de $nonTerminal.';
  }

  @override
  String grammarAnalysisMoveRecursiveSuffixesRationale(
    String nonTerminal,
    String introduced,
  ) {
    return 'Mover os sufixos recursivos de $nonTerminal para $introduced e adicionar uma alternativa epsilon terminadora.';
  }

  @override
  String grammarAnalysisDirectRecursionRewritten(
    String nonTerminal,
    String introduced,
  ) {
    return 'A recursão direta de $nonTerminal foi reescrita usando $introduced.';
  }

  @override
  String grammarAnalysisDirectRecursionOperation(String nonTerminal) {
    return 'Remover a recursão direta de $nonTerminal.';
  }

  @override
  String get grammarAnalysisLeftCornerCycleRemains =>
      'Um ciclo de canto esquerdo permanece após a transformação.';

  @override
  String get grammarAnalysisLeftRecursionRemoved =>
      'A recursão à esquerda foi removida.';

  @override
  String grammarPredictiveFactoringIntroduced(
    String introduced,
    String prefix,
    String nonTerminal,
    int productionCount,
  ) {
    return 'O não terminal $introduced foi introduzido para fatorar o prefixo $prefix de $nonTerminal ($productionCount produções).';
  }

  @override
  String grammarPredictiveFactoringDerivation(
    int productionCount,
    String nonTerminal,
    String prefix,
    String introduced,
  ) {
    return 'As $productionCount produções de $nonTerminal foram fatoradas como $nonTerminal → $prefix$introduced.';
  }

  @override
  String grammarPredictiveFactoringSuffix(String introduced, String suffix) {
    return 'O sufixo restante de $introduced é $suffix.';
  }

  @override
  String get grammarPredictiveNoFactoringNeeded =>
      'Nenhum prefixo comum que exigisse fatoração foi encontrado.';

  @override
  String grammarPredictiveProductionLhsUndeclared(String nonTerminal) {
    return 'O lado esquerdo $nonTerminal não é um não terminal declarado; a tabela LL(1) não pode ser construída.';
  }

  @override
  String grammarPredictiveMissingTableRow(String nonTerminal) {
    return 'A tabela LL(1) não possui uma linha para o não terminal $nonTerminal.';
  }

  @override
  String grammarPredictiveMissingFollowOrTableEntry(String nonTerminal) {
    return 'Falta o conjunto FOLLOW ou a entrada da tabela LL(1) para o não terminal $nonTerminal.';
  }

  @override
  String grammarPredictiveTablePlacementFirst(
    String production,
    String nonTerminal,
    String lookahead,
  ) {
    return '$production foi colocado na tabela LL(1)[$nonTerminal, $lookahead] usando FIRST.';
  }

  @override
  String grammarPredictiveTablePlacementFollow(
    String production,
    String nonTerminal,
    String lookahead,
  ) {
    return '$production foi colocado na tabela LL(1)[$nonTerminal, $lookahead] usando FOLLOW.';
  }

  @override
  String grammarPredictiveTableConstructed(int count) {
    return 'Uma tabela de análise LL(1) foi construída com $count não terminais.';
  }

  @override
  String get grammarPredictiveTableNoConflicts =>
      'Nenhum conflito foi detectado na tabela de análise LL(1).';

  @override
  String grammarPredictiveTableConflictsDetected(int count) {
    return 'Foram detectados $count conflito(s) na tabela de análise LL(1).';
  }

  @override
  String codecGrammarJflapUnsupportedDocumentType(String type) {
    return 'O tipo de documento JFLAP $type não é um documento de gramática.';
  }

  @override
  String get codecGrammarJflapEmptyGrammar =>
      'A gramática JFLAP não contém produções.';

  @override
  String codecGrammarJflapMissingProductionSide(int index) {
    return 'A produção $index não contém um lado esquerdo ou direito não vazio.';
  }

  @override
  String get codecGrammarJflapStartSymbolUndetermined =>
      'Não foi possível determinar o símbolo inicial da gramática.';

  @override
  String codecGrammarJflapUnknownGrammarTypePreserved(String type) {
    return 'O tipo de gramática desconhecido $type foi preservado para reexportação.';
  }

  @override
  String codecGrammarJflapUnknownOptionalElement(String extension) {
    return 'Os dados XML opcionais desconhecidos $extension foram preservados com sua proveniência.';
  }

  @override
  String get codecGrammarJflapTokenizationNormalized =>
      'O texto da gramática JFLAP foi normalizado para arrays de tokens.';

  @override
  String get codecGrammarJflapRequiresGrammarDocument =>
      'O codec de gramática JFLAP exige um documento de Gramática.';

  @override
  String codecGrammarJflapUnsupportedSchema(int version) {
    return 'A versão de esquema da gramática $version não é compatível.';
  }

  @override
  String get codecGrammarJflapInvalidDocument =>
      'O documento de Gramática é inválido.';

  @override
  String codecGrammarJflapTokenBoundariesLossy(String tokens) {
    return 'Os limites dos tokens $tokens não podem ser preservados no XML de gramática JFLAP.';
  }

  @override
  String codecGrammarJflapClassificationLossy(String classification) {
    return 'A classificação de gramática $classification não pode ser preservada no XML JFLAP.';
  }

  @override
  String get codecGrammarJflapStartOrderNormalized =>
      'A exportação JFLAP moveu para o início as produções do símbolo inicial para que outras ferramentas JFLAP possam inferi-lo.';

  @override
  String get codecLSystemJflapInvalidRoot =>
      'O documento L-system JFLAP deve ter uma raiz <structure>.';

  @override
  String codecLSystemJflapUnsupportedDocumentType(String type) {
    return 'O tipo de documento JFLAP $type não é um documento L-system.';
  }

  @override
  String get codecLSystemJflapMissingAxiom =>
      'O documento L-system JFLAP não contém um axioma.';

  @override
  String get codecLSystemJflapMalformedXml =>
      'O XML L-system JFLAP está malformado.';

  @override
  String get codecLSystemJflapInvalidUtf8 =>
      'O documento L-system JFLAP não está em UTF-8 válido.';

  @override
  String get codecLSystemJflapEmptyPredecessor =>
      'Uma produção L-system tem um predecessor vazio.';

  @override
  String codecLSystemJflapInvalidContextPredecessor(String production) {
    return 'O predecessor sensível ao contexto $production é inválido.';
  }

  @override
  String codecLSystemJflapInvalidParameter(String parameter) {
    return 'O parâmetro L-system $parameter é inválido.';
  }

  @override
  String codecLSystemJflapInvalidParameterValue(
    String parameter,
    String value,
  ) {
    return 'O parâmetro L-system $parameter tem o valor inválido $value.';
  }

  @override
  String codecLSystemJflapInvalidExtension(String extension) {
    return 'A extensão L-system $extension é inválida.';
  }

  @override
  String codecLSystemJflapInvalidProductionMetadata(String field) {
    return 'O campo de metadados de produção L-system $field é inválido.';
  }

  @override
  String get codecLSystemJflapInvalidCommandMapping =>
      'O mapeamento de comandos L-system é inválido.';

  @override
  String get codecLSystemJflapInvalidDocument =>
      'O documento L-system é inválido.';

  @override
  String get codecLSystemJflapRequiresLSystemDocument =>
      'O codec JFLAP exige um documento L-system.';

  @override
  String codecLSystemJflapUnsupportedSchema(int version) {
    return 'A versão de esquema L-system $version não é compatível.';
  }

  @override
  String get codecLSystemJflapDecodeFailed =>
      'Não foi possível decodificar o documento L-system JFLAP.';

  @override
  String get codecLSystemJflapEncodeFailed =>
      'Não foi possível codificar o L-system como XML JFLAP.';

  @override
  String codecLSystemJflapAdvancedVariantPreserved(String variants) {
    return 'As variantes L-system não compatíveis $variants foram preservadas para reexportação.';
  }

  @override
  String codecLSystemJflapParametersPreserved(String parameters) {
    return 'Os parâmetros L-system $parameters foram preservados.';
  }

  @override
  String codecLSystemJflapExecutionExtensionRestored(String features) {
    return 'As extensões de execução L-system $features foram restauradas.';
  }

  @override
  String get codecLSystemJflapElementsPreserved =>
      'Elementos XML adicionais do L-system foram preservados.';

  @override
  String codecLSystemJflapExecutionExtension(String features) {
    return 'Os detalhes da extensão de execução L-system $features estão armazenados nos parâmetros do Turing Lab.';
  }

  @override
  String codecLSystemJflapAdvancedVariantExtension(String variants) {
    return 'As variantes avançadas de L-system $variants estão armazenadas na extensão do Turing Lab.';
  }

  @override
  String get codecVersionedJsonInvalidUtf8 =>
      'O documento JSON não está em UTF-8 válido.';

  @override
  String get codecVersionedJsonRootMustBeObject =>
      'A raiz do documento JSON deve ser um objeto.';

  @override
  String get codecVersionedJsonMalformedJson =>
      'O documento JSON está malformado.';

  @override
  String get codecVersionedJsonUnsupportedDocument =>
      'O payload JSON não é um documento Turing Lab reconhecido.';

  @override
  String get codecVersionedJsonLegacyEnvelopeMigrated =>
      'O JSON legado foi migrado para o envelope de documento atual.';

  @override
  String codecVersionedJsonUnknownFieldPreserved(String scope, String field) {
    return 'O campo desconhecido $field de $scope foi preservado.';
  }

  @override
  String get codecVersionedJsonEnvelopeVersionInvalid =>
      'A versão do envelope JSON deve ser um inteiro positivo.';

  @override
  String codecVersionedJsonUnsupportedEnvelopeVersion(int version) {
    return 'A versão $version do envelope JSON não é compatível.';
  }

  @override
  String get codecVersionedJsonMissingDocument =>
      'O envelope JSON não contém seu objeto de documento.';

  @override
  String codecVersionedJsonDocumentKeyMismatch(String system) {
    return 'O envelope JSON não descreve o documento $system esperado.';
  }

  @override
  String get codecVersionedJsonMissingSchema =>
      'O envelope JSON não contém seu objeto de esquema.';

  @override
  String get codecVersionedJsonSchemaIdentityInvalid =>
      'A identidade do esquema no envelope JSON é inválida.';

  @override
  String codecVersionedJsonUnsupportedSchemaVersion(int version) {
    return 'A versão $version do esquema JSON não é compatível.';
  }

  @override
  String get codecVersionedJsonMissingPayload =>
      'O envelope JSON não contém seu objeto de payload.';

  @override
  String get codecVersionedJsonSourceMetadataInvalid =>
      'Os metadados de origem JSON devem ser um objeto.';

  @override
  String codecVersionedJsonSourceFieldInvalid(String field) {
    return 'O campo de origem JSON $field deve ser uma string.';
  }

  @override
  String get codecVersionedJsonExtensionsInvalid =>
      'O valor de extensões JSON deve ser um objeto.';

  @override
  String codecVersionedJsonMigrationPathMissing(int version) {
    return 'Não há caminho de migração JSON da versão de esquema $version.';
  }

  @override
  String get codecVersionedJsonMigrationRejected =>
      'A migração de esquema JSON rejeitou o payload.';

  @override
  String get codecVersionedJsonMigrationInvalidValue =>
      'A migração de esquema JSON recebeu um valor inválido.';

  @override
  String get codecVersionedJsonMigrationFailed =>
      'A migração de esquema JSON falhou.';

  @override
  String codecVersionedJsonSchemaMigrated(int from, int to) {
    return 'O payload JSON foi migrado do esquema $from para o esquema $to.';
  }

  @override
  String get codecVersionedJsonExtensionKeysInvalid =>
      'As chaves de extensão JSON devem ser strings.';

  @override
  String get codecVersionedJsonPayloadValueTypeInvalid =>
      'O payload do documento JSON contém um tipo de valor inválido.';

  @override
  String get codecVersionedJsonDecoderValueTypeInvalid =>
      'O decodificador do documento JSON recebeu um valor inválido.';

  @override
  String get codecVersionedJsonDecoderFailed =>
      'Não foi possível decodificar o modelo do documento JSON.';

  @override
  String codecVersionedJsonEncodeDocumentMismatch(String system) {
    return 'Este codec JSON não pode codificar o documento $system.';
  }

  @override
  String get codecVersionedJsonEncodeSchemaUnsupported =>
      'A versão do esquema do documento JSON não é compatível com a exportação.';

  @override
  String get codecVersionedJsonEncodeValueInvalid =>
      'O documento contém dados que não podem ser representados em JSON.';

  @override
  String get codecVersionedJsonEncoderFailed =>
      'Não foi possível codificar o modelo do documento JSON.';

  @override
  String get codecVersionedJsonSourceMetadataNormalized =>
      'Os metadados de origem foram normalizados no documento JSON exportado.';

  @override
  String get codecVersionedJsonUnknownFieldsSidecarNormalized =>
      'Campos JSON desconhecidos foram emitidos no sidecar de extensões.';

  @override
  String get codecVersionedJsonEnvelopeSerializationFailed =>
      'Não foi possível serializar o envelope do documento JSON.';

  @override
  String get codecRegexJflapUnsupportedDocument =>
      'O payload JFLAP não é um documento de expressão regular.';

  @override
  String get codecRegexJflapMultipleExpressions =>
      'O documento JFLAP contém várias expressões regulares.';

  @override
  String get codecRegexJflapMultipleExtensions =>
      'O documento JFLAP contém várias extensões do Turing Lab.';

  @override
  String get codecRegexJflapInvalidExtension =>
      'A extensão de expressão regular do Turing Lab é inválida.';

  @override
  String get codecRegexJflapExtensionMismatch =>
      'A extensão de expressão regular do Turing Lab não corresponde à origem.';

  @override
  String get codecRegexJflapDialectNormalized =>
      'O dialeto da expressão regular foi normalizado durante a importação.';

  @override
  String get codecRegexJflapUnsupportedDialect =>
      'A exportação JFLAP aceita apenas o dialeto de expressão regular Turing Lab v1 com escalares Unicode.';

  @override
  String get codecRegexJflapNonBmpSymbol =>
      'O JFLAP não preserva com segurança símbolos de expressão regular fora do Plano Multilíngue Básico.';

  @override
  String codecRegexJflapEscapeUnsupported(String symbol) {
    return 'O JFLAP não possui sintaxe de escape para o literal \"$symbol\".';
  }

  @override
  String get codecRegexJflapEmptyLanguageUnsupported =>
      'O JFLAP 7.1 não reabre o símbolo de linguagem vazia com semântica equivalente.';

  @override
  String codecRegexJflapReservedLiteral(String symbol) {
    return 'O literal \"$symbol\" tem significado reservado ou dependente do perfil no JFLAP.';
  }

  @override
  String codecRegexJflapUnsupportedConstruct(String symbol) {
    return 'O dialeto de expressão regular do JFLAP não aceita a construção \"$symbol\".';
  }

  @override
  String codecRegexJflapProfileDependentSymbol(String symbol) {
    return 'O símbolo \"$symbol\" do JFLAP depende de um perfil global. Use ! para representar épsilon de forma portátil.';
  }

  @override
  String get codecRegexJflapInvalidDocument =>
      'O documento de expressão regular é inválido.';

  @override
  String get codecRegexJflapMalformedDocument =>
      'O documento de expressão regular JFLAP está malformado.';

  @override
  String get codecRegexJflapExpectedRegexDocument =>
      'O codec JFLAP exige um documento de expressão regular.';

  @override
  String get codecRegexJflapTuringLabExtensionPortability =>
      'Os dados da extensão de expressão regular do Turing Lab não podem ser representados em JFLAP e foram descartados.';

  @override
  String get codecRegexJflapEmptySetInteroperability =>
      'O símbolo de conjunto vazio foi normalizado para interoperabilidade com JFLAP.';

  @override
  String get codecRegexJflapUnbalancedParentheses =>
      'Os parênteses da expressão regular JFLAP estão desequilibrados.';

  @override
  String get codecRegexJflapMalformedOperators =>
      'Os operadores da expressão regular JFLAP estão malformados.';

  @override
  String get codecRegexJflapUnionMissingOperand =>
      'A união da expressão regular JFLAP não tem um operando.';

  @override
  String get codecRegexJflapEpsilonLeftConcatenation =>
      'Épsilon JFLAP não pode ser concatenado à esquerda.';

  @override
  String get codecRegexJflapEpsilonRightConcatenation =>
      'Épsilon JFLAP não pode ser concatenado à direita.';

  @override
  String get codecRegexJflapEscapeMissingSymbol =>
      'O escape da expressão regular JFLAP deve ser seguido por um símbolo.';

  @override
  String get codecRegexJflapInvalidSource =>
      'A origem da expressão regular é inválida.';

  @override
  String get codecRegexJsonUnexpectedDecoderType =>
      'O decodificador JSON de expressão regular recebeu um tipo de valor inesperado.';

  @override
  String get codecRegexJsonSourceOfTruthInvalid =>
      'A fonte de verdade JSON da expressão regular é inválida.';

  @override
  String get codecRegexJsonCanonicalAstMismatch =>
      'A origem JSON da expressão regular não corresponde à sua AST canônica.';

  @override
  String get codecRegexJsonExpectedRegexDocument =>
      'O codec JSON exige um documento de expressão regular.';

  @override
  String get codecRegexJsonInvalidDocument =>
      'O documento JSON de expressão regular é inválido.';

  @override
  String get codecRegexJsonUnsupportedDialect =>
      'O dialeto JSON de expressão regular não é compatível.';

  @override
  String get codecRegexJsonInvalidSource =>
      'A origem JSON da expressão regular é inválida.';

  @override
  String get codecRegexJsonUnexpectedValidationOutcome =>
      'A validação JSON da expressão regular retornou um resultado inesperado.';

  @override
  String get codecPdaJflapInvalidUtf8 =>
      'O documento PDA JFLAP não está em UTF-8 válido.';

  @override
  String get codecPdaJflapMalformedXml => 'O XML PDA JFLAP está malformado.';

  @override
  String get codecPdaJflapInvalidRoot =>
      'A raiz XML PDA JFLAP deve ser <structure>.';

  @override
  String codecPdaJflapUnsupportedDocumentType(String type) {
    return 'O tipo de documento JFLAP $type não é um documento PDA.';
  }

  @override
  String get codecPdaJflapMissingAutomaton =>
      'O documento PDA JFLAP não contém <automaton>.';

  @override
  String get codecPdaJflapMissingStateId =>
      'Um estado PDA JFLAP não contém um ID não vazio.';

  @override
  String codecPdaJflapDuplicateStateId(String state) {
    return 'O estado PDA $state tem um ID duplicado.';
  }

  @override
  String codecPdaJflapInvalidStateCoordinate(String state) {
    return 'O estado PDA $state tem uma coordenada inválida.';
  }

  @override
  String get codecPdaJflapInvalidDocument => 'O documento PDA é inválido.';

  @override
  String codecPdaJflapUnknownTransitionEndpoints(String from, String to) {
    return 'Uma transição PDA referencia estados desconhecidos $from e $to.';
  }

  @override
  String get codecPdaJflapInvalidTransitionId =>
      'O ID da transição PDA é inválido.';

  @override
  String get codecPdaJflapDuplicateTransitionId =>
      'O ID da transição PDA está duplicado.';

  @override
  String get codecPdaJflapInvalidAcceptanceMode =>
      'O modo de aceitação PDA é inválido.';

  @override
  String get codecPdaJflapMalformedExtension =>
      'A extensão PDA do Turing Lab está malformada.';

  @override
  String get codecPdaJflapCanonicalOrderImport =>
      'Estados e transições PDA foram ordenados canonicamente na importação.';

  @override
  String get codecPdaJflapStaleTokenExtension =>
      'A extensão de tokens PDA estava obsoleta e foi ignorada.';

  @override
  String get codecPdaJflapExplicitEpsilonAliasInterpreted =>
      'Um alias explícito de épsilon foi interpretado como entrada vazia.';

  @override
  String get codecPdaJflapPopWordTreatedAsAtomicToken =>
      'Uma palavra de pop com vários caracteres foi tratada como um token de pilha.';

  @override
  String get codecPdaJflapAcceptanceModeAssumedFinalState =>
      'O modo de aceitação JFLAP foi assumido como modo de estado final.';

  @override
  String get codecPdaJflapRequiresPdaDocument =>
      'O codec JFLAP exige um documento PDA.';

  @override
  String codecPdaJflapUnsupportedSchema(int version) {
    return 'A versão de esquema PDA $version não é compatível.';
  }

  @override
  String get codecPdaJflapExtensionPortability =>
      'Os dados da extensão PDA não podem ser representados no JFLAP padrão e foram descartados.';

  @override
  String get codecPdaJflapInitialStackSymbolNotPortable =>
      'O símbolo inicial da pilha PDA não é portável para o JFLAP padrão.';

  @override
  String get codecPdaJflapAcceptanceModeNotPortable =>
      'O modo de aceitação PDA não é portável para o JFLAP padrão.';

  @override
  String get codecPdaJflapAtomicPopTokenNotPortable =>
      'Um token atômico de pop PDA não é portável para o JFLAP padrão.';

  @override
  String get codecPdaJflapAtomicPushTokenNotPortable =>
      'Um token atômico de push PDA não é portável para o JFLAP padrão.';

  @override
  String codecPdaJflapUnknownOptionalElement(String extension) {
    return 'O elemento XML opcional desconhecido $extension foi preservado.';
  }

  @override
  String codecPdaJflapUnknownOptionalAttribute(String extension) {
    return 'O atributo XML opcional desconhecido $extension foi preservado.';
  }

  @override
  String get codecPdaJflapInvalidNotePosition =>
      'Uma anotação PDA tem uma posição inválida.';

  @override
  String get codecPdaJflapNotesNormalized =>
      'As anotações PDA foram normalizadas na importação.';

  @override
  String get codecPdaJflapNotePresentationDropped =>
      'Os dados de apresentação da anotação PDA foram descartados.';

  @override
  String get codecPdaJflapUnknownDiagnostic =>
      'O documento PDA contém um diagnóstico desconhecido.';

  @override
  String get codecPdaJsonUnexpectedDocumentType =>
      'O decodificador JSON PDA retornou um tipo de documento inesperado.';

  @override
  String get codecPdaJsonInvalidDocument => 'O documento JSON PDA é inválido.';

  @override
  String get codecTmJflapInvalidUtf8 =>
      'O documento TM JFLAP não está em UTF-8 válido.';

  @override
  String get codecTmJflapMalformedXml => 'O XML TM JFLAP está malformado.';

  @override
  String get codecTmJflapInvalidRoot =>
      'A raiz XML TM JFLAP deve ser <structure>.';

  @override
  String codecTmJflapUnsupportedDocumentType(String type) {
    return 'O tipo de documento JFLAP $type não é um documento de máquina de Turing.';
  }

  @override
  String get codecTmJflapUnsupportedFeature =>
      'O documento TM JFLAP usa um recurso não compatível.';

  @override
  String get codecTmJflapInvalidTapeCount =>
      'A quantidade de fitas TM é inválida.';

  @override
  String get codecTmJflapMissingAutomaton =>
      'O documento TM JFLAP não contém <automaton>.';

  @override
  String get codecTmJflapMalformedExtension =>
      'A extensão TM do Turing Lab está malformada.';

  @override
  String get codecTmJflapCanonicalOrderImport =>
      'Estados e transições TM foram ordenados canonicamente na importação.';

  @override
  String get codecTmJflapCanonicalOrderExport =>
      'Estados e transições TM foram ordenados canonicamente na exportação.';

  @override
  String get codecTmJflapVariantMismatch =>
      'A variante TM não corresponde ao documento.';

  @override
  String get codecTmJflapTapeCountMismatch =>
      'A quantidade de fitas TM não corresponde ao documento.';

  @override
  String get codecTmJflapBlankSymbolInvalid =>
      'O símbolo branco TM é inválido.';

  @override
  String get codecTmJflapAcceptancePolicyInvalid =>
      'A política de aceitação TM é inválida.';

  @override
  String get codecTmJflapIncompleteExtension =>
      'A extensão TM do Turing Lab está incompleta.';

  @override
  String get codecTmJflapExtensionSchemaInvalid =>
      'O esquema da extensão TM do Turing Lab é inválido.';

  @override
  String get codecTmJflapMissingStateId =>
      'Um estado TM JFLAP não contém um ID não vazio.';

  @override
  String codecTmJflapDuplicateStateId(String state) {
    return 'O estado TM $state tem um ID duplicado.';
  }

  @override
  String codecTmJflapInvalidStateCoordinate(String state) {
    return 'O estado TM $state tem uma coordenada inválida.';
  }

  @override
  String codecTmJflapInvalidStateType(String state) {
    return 'O estado TM $state tem um tipo inválido.';
  }

  @override
  String codecTmJflapInvalidStateProperties(String state) {
    return 'O estado TM $state tem propriedades inválidas.';
  }

  @override
  String get codecTmJflapInvalidInitialStateCount =>
      'O documento TM deve conter exatamente um estado inicial.';

  @override
  String codecTmJflapUnknownTransitionEndpoints(String from, String to) {
    return 'Uma transição TM referencia estados desconhecidos $from e $to.';
  }

  @override
  String get codecTmJflapInvalidTapeIndex => 'O índice de fita TM é inválido.';

  @override
  String codecTmJflapDuplicateTapeOperation(String operation) {
    return 'A transição TM contém uma operação de fita duplicada: $operation.';
  }

  @override
  String get codecTmJflapUnsupportedReadPredicate =>
      'O predicado de leitura TM não é compatível com JFLAP.';

  @override
  String get codecTmJflapInvalidReadSymbol =>
      'O símbolo de leitura TM é inválido.';

  @override
  String get codecTmJflapInvalidWriteSymbol =>
      'O símbolo de escrita TM é inválido.';

  @override
  String get codecTmJflapInvalidMove => 'O movimento TM deve ser L, R ou S.';

  @override
  String get codecTmJflapInvalidTransitionExtension =>
      'A extensão de transição TM do Turing Lab é inválida.';

  @override
  String get codecTmJflapInvalidTransitionId =>
      'O ID da transição TM é inválido.';

  @override
  String get codecTmJflapDuplicateTransitionId =>
      'O ID da transição TM está duplicado.';

  @override
  String codecTmJflapInvalidTransitionLabel(String transition) {
    return 'A transição TM $transition tem um rótulo inválido.';
  }

  @override
  String codecTmJflapInvalidTransitionType(String transition) {
    return 'A transição TM $transition tem um tipo inválido.';
  }

  @override
  String get codecTmJflapInvalidControlPoint =>
      'Uma transição TM tem um ponto de controle inválido.';

  @override
  String get codecTmJflapTransitionIdentitiesReconstructed =>
      'As identidades das transições TM foram reconstruídas na importação.';

  @override
  String get codecTmJflapInvalidMetadata => 'Os metadados TM são inválidos.';

  @override
  String get codecTmJflapInvalidDocument => 'O documento TM é inválido.';

  @override
  String get codecTmJflapRequiresTmDocument =>
      'O codec JFLAP exige um documento de máquina de Turing.';

  @override
  String codecTmJflapUnsupportedSchema(int version) {
    return 'A versão de esquema TM $version não é compatível.';
  }

  @override
  String get codecTmJflapUnsupportedTapeCount =>
      'A quantidade de fitas TM não é compatível.';

  @override
  String codecTmJflapUnsupportedOperation(
    String transition,
    String operation,
    String symbol,
  ) {
    return 'A transição TM $transition usa a operação não compatível $operation em $symbol.';
  }

  @override
  String get codecTmJflapBuildingBlockVariantMismatch =>
      'A variante TM do bloco reutilizável não corresponde ao XML.';

  @override
  String codecTmJflapRecursiveDependency(String block) {
    return 'Os blocos TM contêm uma dependência recursiva em $block.';
  }

  @override
  String codecTmJflapMissingBlockDefinition(String block) {
    return 'Falta a definição de bloco TM $block.';
  }

  @override
  String codecTmJflapAmbiguousBlockDefinition(String block) {
    return 'A definição de bloco TM $block é ambígua.';
  }

  @override
  String get codecTmJflapAcceptancePolicyConflict =>
      'As políticas de aceitação da raiz e da máquina TM entram em conflito.';

  @override
  String get codecTmJflapMachineSchemaInvalid =>
      'A máquina do bloco tem um esquema Turing Lab inválido.';

  @override
  String get codecTmJflapMachineVariantInvalid =>
      'A máquina do bloco tem uma variante TM inválida.';

  @override
  String get codecTmJflapMachineTapeCountMismatch =>
      'A máquina do bloco tem uma quantidade de fitas divergente.';

  @override
  String get codecTmJflapMachineBlankSymbolMismatch =>
      'A máquina do bloco tem um símbolo branco divergente.';

  @override
  String codecTmJflapMissingBlockTag(String block) {
    return 'O bloco TM $block não contém sua tag.';
  }

  @override
  String get codecTmJflapInvalidNodeId =>
      'O ID de um nó de bloco TM é inválido.';

  @override
  String get codecTmJflapDuplicateNodeId =>
      'O ID de um nó de bloco TM está duplicado.';

  @override
  String codecTmJflapInvalidNodeCoordinate(String node) {
    return 'O nó TM $node tem uma coordenada inválida.';
  }

  @override
  String codecTmJflapInvalidNodeStateType(String node) {
    return 'O nó TM $node tem um tipo de estado inválido.';
  }

  @override
  String codecTmJflapInvalidNodeProperties(String node) {
    return 'O nó TM $node tem propriedades inválidas.';
  }

  @override
  String codecTmJflapMissingBlockTagReference(String block) {
    return 'O bloco TM $block não tem referência de tag.';
  }

  @override
  String get codecTmJflapInvalidOrDuplicateTapeIndex =>
      'Um índice de fita TM é inválido ou duplicado.';

  @override
  String get codecTmJflapTransitionIdentityConflict =>
      'As extensões de identidade de transição TM divergem.';

  @override
  String get codecTmJflapBuildingBlocksImported =>
      'Os blocos TM foram importados.';

  @override
  String get codecTmJflapSharedTapes =>
      'Os blocos TM usam fitas compartilhadas.';

  @override
  String get codecTmJflapUnknownBuildingBlockExtensionDropped =>
      'Uma extensão desconhecida de bloco TM foi descartada.';

  @override
  String get codecTmJflapBuildingBlocksExported =>
      'Os blocos TM foram exportados.';

  @override
  String get codecTmJflapExtensionIdentities =>
      'As identidades das extensões TM foram normalizadas.';

  @override
  String get codecTmJflapExtensionPortability =>
      'Os dados da extensão TM não podem ser representados no JFLAP padrão e foram descartados.';

  @override
  String codecTmJflapUnknownOptionalElement(String extension) {
    return 'O elemento XML opcional desconhecido $extension foi preservado.';
  }

  @override
  String codecTmJflapUnknownOptionalAttribute(String extension) {
    return 'O atributo XML opcional desconhecido $extension foi preservado.';
  }

  @override
  String get codecTmJflapInvalidNotePosition =>
      'Uma anotação TM tem uma posição inválida.';

  @override
  String get codecTmJflapNotesNormalized =>
      'As anotações TM foram normalizadas na importação.';

  @override
  String get codecTmJflapNotePresentationDropped =>
      'Os dados de apresentação da anotação TM foram descartados.';

  @override
  String get codecTmJflapUnknownDiagnostic =>
      'O documento TM contém um diagnóstico desconhecido.';

  @override
  String get codecTmJsonUnexpectedDocumentType =>
      'O decodificador JSON TM retornou um tipo de documento inesperado.';

  @override
  String get codecTmJsonInvalidDocument => 'O documento JSON TM é inválido.';

  @override
  String get codecTmJsonVariantMismatch =>
      'A variante JSON TM não corresponde ao documento.';

  @override
  String get codecTmJsonVariantInferred =>
      'A variante TM foi inferida do documento JSON.';

  @override
  String get codecTmJsonOperationVectorsMigrated =>
      'Os vetores de operações TM foram migrados para o formato atual.';

  @override
  String get codecTmJsonEndpointsMigratedToIds =>
      'Os endpoints das transições TM foram migrados para IDs estáveis.';
}
