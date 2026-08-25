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
      'Oferece espaços de trabalho para autômatos finitos, gramáticas livres de contexto, autômatos com pilha, máquinas de Turing, expressões regulares e exercícios de pumping lemma.';

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
      'As ferramentas de gramática oferecem diagnósticos de parsing, conjuntos FIRST e FOLLOW, conflitos LL(1) e um pipeline de forma normal de Chomsky de melhor esforço.';

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
      'AP e MT: exportação SVG. Ida e volta em JFLAP XML e JSON ficam fora do escopo da versão atual.';

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
      'O autômato atual não contém transições λ.';

  @override
  String get automatonMustContainLambdaToRemove =>
      'O autômato atual precisa conter transições λ para removê-las.';

  @override
  String get lambdaTransitionsRemoved => 'Transições λ removidas com sucesso.';

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
  String get editProductionRule => 'Editar regra de produção';

  @override
  String get addProductionRule => 'Adicionar regra de produção';

  @override
  String get leftSideVariable => 'Lado esquerdo (variável)';

  @override
  String get rightSideProduction => 'Lado direito (produção)';

  @override
  String get leftSideHint => 'ex.: S, A, B';

  @override
  String get rightSideHint => 'ex.: aA, bB, ε';

  @override
  String get leftSideHelper => 'Informe exatamente um símbolo não terminal.';

  @override
  String get rightSideHelper => 'Use λ/ε para a cadeia vazia.';

  @override
  String get insertLambda => 'Inserir λ';

  @override
  String get insertEpsilon => 'Inserir ε';

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
  String get bothSidesRequired =>
      'Os lados esquerdo e direito devem ser informados';

  @override
  String get leftSideMustBeNonterminal =>
      'O lado esquerdo deve conter um símbolo não terminal';

  @override
  String get leftSideExactlyOneNonterminal =>
      'O lado esquerdo deve conter exatamente um símbolo não terminal';

  @override
  String get rightSideAtLeastOneSymbol =>
      'O lado direito deve conter pelo menos um símbolo (ou λ/ε)';

  @override
  String get rightSideSingleLambda =>
      'O lado direito pode conter apenas um símbolo λ/ε';

  @override
  String get lambdaMustBeOnlySymbol =>
      'λ/ε deve ser o único símbolo no lado direito';

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
  String get hideGame => 'Ocultar jogo';

  @override
  String get showGame => 'Mostrar jogo';

  @override
  String get showHelp => 'Mostrar ajuda';

  @override
  String get hideProgress => 'Ocultar progresso';

  @override
  String get showProgress => 'Mostrar progresso';

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
  String get exampleNfaLambdaAOrAb => 'AFNλ - A ou AB';

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
  String get tapeSymbols => 'Símbolos da fita';

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
  String get removeLambdaTitle => 'Remover transições λ';

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
      'Gerar tabela de análise LL(1) ou LR(1)';

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
    return 'Transições lambda presentes: $count';
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
  String get pdaAnalysisTitle => 'Análise do AP';

  @override
  String get tmAnalysisTitle => 'Análise da MT';

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
  String derivationTreesAmbiguous(int count) {
    return 'Árvores de derivação (mostrando as primeiras $count; ambígua)';
  }

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
      int transitions, int configurations) {
    return '$transitions transição(ões) • $configurations configuração(ões) exploradas';
  }

  @override
  String get explorationCancelledKept =>
      'Exploração cancelada. Os resultados avaliados foram mantidos.';

  @override
  String get spaceProfilingCancelledKept =>
      'Perfil de espaço cancelado. As linhas avaliadas foram mantidas.';
}
