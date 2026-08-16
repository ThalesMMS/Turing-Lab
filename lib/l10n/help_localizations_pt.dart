const ptHelpUiCopy = {
  'homeHelpTooltip': 'Ajuda',
  'homeSettingsTooltip': 'Configurações',
  'helpPageTitle': 'Ajuda e documentação',
  'helpSearchTooltip': 'Pesquisar ajuda',
  'helpQuickStartTitle': 'Guia rápido',
  'helpQuickStartBody': 'Bem-vindo ao Turing Lab. Comece com este fluxo básico:\n\n'
      '1. Escolha um espaço de trabalho, como AF, Gramática, AP, MT ou Regex.\n'
      '2. Inicie em branco ou abra um exemplo ou arquivo compatível.\n'
      '3. Use o editor para criar sua máquina ou gramática. Toque duas vezes em um estado para ações rápidas.\n'
      '4. Execute simulações para testar seu trabalho.\n'
      '5. Use os algoritmos para transformar estruturas.\n\n'
      'Dicas:\n'
      '• Use as abas de navegação ou chips de seção para trocar de espaço rapidamente.\n'
      '• Toque duas vezes em um estado para abrir o menu de ações rápidas.\n'
      '• Faça pinça para ampliar ou reduzir o canvas.\n'
      '• Toque no ícone de guia rápido quando precisar relembrar o fluxo.',
  'helpGotIt': 'Entendi!',
  'helpSearchFieldLabel': 'Pesquisar ajuda...',
  'helpSearchClear': 'Limpar pesquisa',
  'helpSearchClose': 'Fechar pesquisa',
  'helpSearchTitle': 'Pesquisar ajuda',
  'helpSearchSubtitle': 'Encontre tutoriais, atalhos e explicações de teoria',
  'helpSearchNoResults': 'Nenhum resultado encontrado',
  'helpSearchNoResultsDescription':
      'Tente outras palavras-chave ou confira a ortografia',
  'contextualHelpPanelLabel': 'Painel de ajuda contextual',
  'closeHelpPanel': 'Fechar painel de ajuda',
  'close': 'Fechar',
  'viewAllRelatedHelp': 'Ver toda a ajuda relacionada',
  'moreHelp': 'Mais ajuda',
  'relatedConcepts': 'Conceitos relacionados',
  'hideExamples': 'Ocultar exemplos',
  'viewExamples': 'Ver exemplos',
  'keyboardShortcutsDialogLabel': 'Diálogo de atalhos de teclado',
  'keyboardShortcutsTitle': 'Atalhos de teclado',
  'keyboardShortcutsCanvasOperations': 'Operações do canvas',
  'keyboardShortcutsSimulationControls': 'Controles de simulação',
  'keyboardShortcutsDialogShortcuts': 'Atalhos de diálogos',
  'closeShortcutsDialog': 'Fechar diálogo de atalhos',
  'shortcutAlternativeSeparator': 'ou',
  'aboutDeveloperLabel': 'Desenvolvedor',
  'aboutProjectRepositoryLabel': 'Repositório do projeto',
  'aboutProjectOpenError': 'Não foi possível abrir o repositório do projeto.',
  'aboutOpenSourceLicenses': 'Licenças de código aberto',
  'aboutLicensesIntro':
      'O Turing Lab é uma reimplementação em Flutter inspirada no JFLAP e compatível com ele. Não é uma versão oficial do JFLAP.',
  'aboutTuringLabLicenseSummary':
      'O código Flutter original do Turing Lab é licenciado sob a Apache 2.0.',
  'aboutJflapLicenseSummary':
      'As partes derivadas do JFLAP permanecem sob a licença do JFLAP 7.1.',
  'aboutGraphViewLicenseSummary':
      'Biblioteca de visualização de grafos, bifurcada e modificada para o Turing Lab. Trabalho original de Nabil Mosharraf.',
  'aboutAppleNoticesSummary':
      'Avisos incluídos para o fork do GraphView e dependências de plugins das plataformas Apple.',
  'aboutAppleNoticesTitle': 'Avisos de terceiros das plataformas Apple',
  'aboutPackageLicenses': 'Licenças dos pacotes',
  'aboutPackageLicensesDescription':
      'Licenças informadas pelo Flutter para os pacotes Dart e Flutter incluídos.',
  'aboutAcknowledgments': 'Agradecimentos ao JFLAP',
  'aboutJflapCreator':
      'Criadora e mantenedora original do JFLAP, Duke University.',
  'aboutJflapTeam':
      'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su e Henry Qin.',
  'aboutOriginalProject': 'Site do JFLAP: http://www.jflap.org',
  'aboutOriginalProjectTitle': 'Projeto original',
  'aboutGraphViewFork':
      'O Turing Lab inclui um fork mantido do GraphView sob a licença MIT; os avisos de terceiros das plataformas Apple estão incluídos aqui.',
  'aboutGraphViewForkTitle': 'Fork do GraphView',
  'aboutDistribution': 'Distribuição',
  'aboutDistributionDescription':
      'O Turing Lab é distribuído como um aplicativo educacional gratuito e não monetizado enquanto incluir material derivado do JFLAP.',
  'aboutLicenseExpandPrompt':
      'Expanda para carregar o texto da licença incluída.',
  'aboutLicenseLoading': 'Carregando o texto da licença incluída...',
  'aboutLicenseLoadFailed': 'Falha ao carregar a licença',
};

const ptHelpArticleBodies = {
  'gettingStarted':
      'O Turing Lab é um aplicativo interativo para estudantes e educadores que estudam linguagens formais e teoria dos autômatos.\n\n'
          'Use a barra de navegação ou as abas inferiores para alternar entre AF, Gramática, AP, MT, Regex e Lema do Bombeamento. '
          'Crie estruturas, edite-as diretamente, execute simulações, converta representações e salve ou carregue arquivos compatíveis.',
  'fsa': 'Autômatos finitos são modelos computacionais com um número finito de estados. Eles reconhecem linguagens regulares.\n\n'
      'Crie estados com a ferramenta de adicionar estado, toque duas vezes para editar marcadores inicial ou final e crie transições escolhendo origem e destino. '
      'Use o painel de simulação para testar cadeias e execute algoritmos como AFN para AFD, minimização, complemento, operações de produto, AF para Regex e AF para Gramática.',
  'grammar':
      'Gramáticas livres de contexto usam variáveis, terminais, símbolo inicial e regras de produção para descrever linguagens livres de contexto.\n\n'
          'Adicione produções com um não terminal à esquerda e uma sequência de terminais ou não terminais à direita. Use λ ou ε para a cadeia vazia. '
          'As ferramentas de análise incluem LL, LR e o algoritmo CYK.',
  'pda': 'Autômatos com pilha estendem autômatos finitos com uma pilha e reconhecem linguagens livres de contexto.\n\n'
      'Uma transição de AP lê um símbolo de entrada, consulta ou remove o topo da pilha, empilha símbolos de substituição e muda de estado. '
      'Durante a simulação, o Turing Lab mostra como entrada, estado e pilha evoluem até consumir a entrada ou não haver transição válida.',
  'tm': 'Máquinas de Turing usam fita, cabeçote de leitura/escrita e estados de controle. Elas modelam computação geral.\n\n'
      'Transições leem um símbolo, escrevem outro, movem o cabeçote para a esquerda, direita ou ficam paradas, e entram em um novo estado. '
      'Configure aceitação por estado final ou parada em Configurações quando o espaço de trabalho oferecer suporte.',
  'regex':
      'Expressões regulares descrevem linguagens regulares com literais, concatenação, união, agrupamento, estrela de Kleene, mais e opcional.\n\n'
          'Valide uma regex, teste cadeias, compare equivalência, analise complexidade, simplifique expressões e converta regexes para AFN ou AFD equivalentes.',
  'pumping':
      'O jogo do Lema do Bombeamento ajuda a explicar por que algumas linguagens não são regulares.\n\n'
          'Escolha uma linguagem, encontre um comprimento de bombeamento, escolha uma cadeia longa o bastante, decomponha-a em xyz e mostre que bombear y leva para fora da linguagem.',
  'fileOperations': 'O Turing Lab oferece fluxos de arquivo por espaço de trabalho.\n\n'
      'AF suporta XML do JFLAP, JSON, SVG e exportação PNG em plataformas nativas. Gramática suporta importação/exportação de gramáticas JFLAP e SVG. '
      'AP e Máquina de Turing atualmente suportam apenas exportação SVG. Regex opera diretamente sobre expressões digitadas.',
  'troubleshooting':
      'Se o app ficar lento, reduza autômatos muito grandes ou simplifique grafos com muitas transições.\n\n'
          'Se a simulação demorar demais, procure laços ou caminhos não determinísticos que crescem rapidamente. '
          'Se um arquivo não carregar, confirme se o formato é compatível com o espaço atual e se o arquivo não está corrompido. '
          'Use os controles de zoom quando elementos do canvas estiverem pequenos demais para tocar.',
};

const ptHelpSearchSuggestions = {
  'canvasTools': 'Ferramentas do canvas',
  'shortcuts': 'Atalhos',
  'dfa': 'AFD',
  'nfa': 'AFN',
  'algorithms': 'Algoritmos',
};

const ptHelpCategories = {
  'canvas': 'canvas',
  'automata': 'autômatos',
  'grammar': 'gramática',
  'regex': 'regex',
  'algorithms': 'algoritmos',
  'shortcuts': 'atalhos',
  'general': 'geral',
};

const ptHelpTitles = {
  'tool_select': 'Ferramenta de seleção',
  'tool_add_state': 'Adicionar estado',
  'tool_add_transition': 'Adicionar transição',
  'tool_undo': 'Desfazer',
  'tool_redo': 'Refazer',
  'tool_zoom_out': 'Reduzir zoom',
  'tool_zoom_in': 'Aumentar zoom',
  'tool_fit_content': 'Ajustar ao conteúdo',
  'tool_reset_view': 'Redefinir visualização',
  'tool_clear': 'Limpar canvas',
  'concept_dfa': 'Autômato finito determinístico (AFD)',
  'concept_nfa': 'Autômato finito não determinístico (AFN)',
  'concept_state': 'Estados',
  'concept_transition': 'Transições',
  'concept_epsilon': 'Transições epsilon (ε)',
  'concept_pda': 'Autômato com pilha (AP)',
  'concept_stack': 'Operações de pilha',
  'concept_tm': 'Máquina de Turing (MT)',
  'concept_decidable': 'Linguagens decidíveis',
  'concept_tape': 'Fita da máquina de Turing',
  'concept_cfg': 'Gramática livre de contexto (GLC)',
  'concept_derivation': 'Derivações',
  'concept_ambiguity': 'Ambiguidade de gramática',
  'concept_regex': 'Expressões regulares',
  'algo_nfa_to_dfa': 'Conversão de AFN para AFD',
  'algo_dfa_minimize': 'Minimização de AFD',
  'algo_epsilon_closure': 'Fechamento epsilon',
  'algo_regex_to_nfa': 'Expressão regular para AFN',
  'algo_cfg_to_pda': 'GLC para AP',
  'shortcut_canvas_general': 'Atalhos de teclado do canvas',
  'shortcut_simulation': 'Atalhos de simulação',
  'shortcut_dialogs': 'Atalhos de diálogos',
  'usage_getting_started': 'Primeiros passos',
  'usage_test_input': 'Testar cadeias de entrada',
  'usage_import_export': 'Importar e exportar',
};

const ptHelpBodies = {
  'tool_select':
      'Use esta ferramenta para selecionar, mover e editar estados e transições. Toque em um estado para selecioná-lo, arraste para mover ou toque duas vezes para editar propriedades. Toque em uma transição para selecioná-la e editar o rótulo.',
  'tool_add_state':
      'Toque em qualquer ponto do canvas para criar um novo estado nessa posição. O primeiro estado criado é marcado automaticamente como inicial. Depois, edite as propriedades para alterar estados inicial e finais.',
  'tool_add_transition':
      'Toque no estado de origem e depois no estado de destino para criar uma transição. Depois informe o rótulo da transição, como símbolos, epsilon ou operações de pilha, conforme o tipo de autômato.',
  'tool_undo':
      'Desfaz a última ação no canvas. Você pode desfazer várias ações em sequência, incluindo adicionar ou remover estados, adicionar ou remover transições e mover estados.',
  'tool_redo':
      'Refaz uma ação que foi desfeita. O botão fica disponível depois de usar Desfazer e pode restaurar várias ações em sequência.',
  'tool_zoom_out':
      'Reduz o zoom do canvas em um passo para ver mais do autômato de uma vez. Use junto com Aumentar zoom e Ajustar ao conteúdo para alternar entre visão geral e visão detalhada.',
  'tool_zoom_in':
      'Aumenta o zoom do canvas em um passo para inspecionar estados e rótulos de transição de perto. Use junto com Reduzir zoom e Ajustar ao conteúdo para alternar entre visão detalhada e visão geral.',
  'tool_fit_content':
      'Ajusta zoom e pan para mostrar todos os estados e transições. Use quando perder o foco do autômato ou quiser ver toda a estrutura.',
  'tool_reset_view':
      'Restaura zoom e pan para a visualização padrão, voltando a 100% e centralizando a origem.',
  'tool_clear':
      'Remove todos os estados e transições do canvas e cria um espaço em branco. A ação pode ser desfeita se necessário.',
  'concept_dfa':
      'Um AFD é uma máquina de estados finita em que cada estado tem exatamente uma transição para cada símbolo de entrada. Ele reconhece linguagens regulares e aceita uma cadeia quando termina em estado final.',
  'concept_nfa':
      'Um AFN é uma máquina de estados finita em que um estado pode ter zero, uma ou várias transições para o mesmo símbolo. Também pode usar transições epsilon e aceita se algum caminho chegar a um estado final.',
  'concept_state':
      'Estados representam configurações do autômato durante a computação. Há estado inicial, estados finais/de aceitação e estados intermediários. No Turing Lab, toque duas vezes em um estado para editar suas propriedades.',
  'concept_transition':
      'Transições conectam estados e definem como o autômato muda de estado com base nos símbolos de entrada. Cada transição tem origem, destino e rótulo.',
  'concept_epsilon':
      'Uma transição epsilon permite que um AFN mude de estado sem consumir símbolo de entrada. Ela pode ser escrita como ε ou λ e é usada para criar caminhos de computação simultâneos.',
  'concept_pda':
      'Um AP é um autômato finito com memória de pilha. Ele reconhece linguagens livres de contexto e usa transições baseadas em estado atual, símbolo de entrada e topo da pilha.',
  'concept_stack':
      'A pilha em um AP é uma memória LIFO. Operações comuns incluem push, pop e peek. Símbolos na pilha permitem representar estruturas aninhadas.',
  'concept_tm':
      'Uma Máquina de Turing é um modelo computacional com fita, cabeçote de leitura/escrita, estados e função de transição. Ela modela computações algoritmicamente descritíveis.',
  'concept_decidable':
      'Uma linguagem é decidível quando existe uma Máquina de Turing que sempre para e aceita exatamente as cadeias da linguagem. Linguagens recursivamente enumeráveis podem não parar para algumas entradas.',
  'concept_tape':
      'A fita é uma sequência de células usada como memória da Máquina de Turing. O cabeçote lê, escreve e move para esquerda ou direita, oferecendo memória ilimitada para a computação.',
  'concept_cfg':
      'Uma GLC possui variáveis, terminais, regras de produção e símbolo inicial. Ela gera linguagens livres de contexto e é equivalente a autômatos com pilha.',
  'concept_derivation':
      'Uma derivação é uma sequência de aplicações de regras que transforma o símbolo inicial em uma cadeia de terminais. Pode ser mais à esquerda, mais à direita ou representada por árvore de derivação.',
  'concept_ambiguity':
      'Uma gramática é ambígua quando alguma cadeia possui duas ou mais árvores de derivação distintas. Ambiguidade pode causar problemas em análise sintática e compiladores.',
  'concept_regex':
      'Expressões regulares descrevem linguagens regulares usando concatenação, união, estrela de Kleene, mais, agrupamento e cadeia vazia. Elas são equivalentes a AFDs e AFNs.',
  'algo_nfa_to_dfa':
      'Converte um AFN em AFD equivalente usando construção por subconjuntos: calcule fechamentos epsilon, crie estados do AFD a partir de conjuntos de estados do AFN e marque como finais os conjuntos que contêm algum estado final.',
  'algo_dfa_minimize':
      'Reduz um AFD ao menor AFD equivalente. O algoritmo remove estados inalcançáveis, particiona finais e não finais, refina partições e mescla estados equivalentes.',
  'algo_epsilon_closure':
      'O fechamento epsilon de um estado é o conjunto de estados alcançáveis usando apenas transições epsilon. Ele é essencial para simulação de AFN e conversão de AFN para AFD.',
  'algo_regex_to_nfa':
      'Converte uma expressão regular em AFN equivalente com a construção de Thompson. Símbolos são casos base; concatenação, união e estrela combinam AFNs com transições epsilon.',
  'algo_cfg_to_pda':
      'Converte uma GLC em AP equivalente criando um AP de um estado com pilha. O símbolo inicial é empilhado, variáveis são expandidas por produções e terminais são consumidos da entrada.',
  'shortcut_canvas_general':
      'Atalhos gerais do canvas:\nA: adicionar estado no centro do canvas\nT: ativar modo de transição\nV: ativar modo de seleção\nDelete ou Backspace: remover transição selecionada\nCtrl/Cmd + Z: desfazer\nCtrl/Cmd + Y ou Ctrl/Cmd + Shift + Z: refazer\n• Tab: mover foco entre ações da barra do canvas\n• Shift + Tab: voltar foco\n• Enter ou Espaço: ativar ação em foco\n• Escape: cancelar diálogo ou editor atual',
  'shortcut_simulation':
      'Atalhos durante simulação:\n• Enter: enviar o campo em foco e executar a simulação\n• Tab: mover foco entre entrada, opções e controles\n• Shift + Tab: voltar para o controle anterior\n• Enter ou Espaço: ativar o botão de simulação em foco',
  'shortcut_dialogs':
      'Atalhos em diálogos e editores:\n• Enter: confirmar ou enviar\n• Escape: cancelar ou fechar\n• Tab: próximo campo\n• Shift + Tab: campo anterior',
  'usage_getting_started':
      'Para criar seu primeiro autômato: escolha um tipo na página inicial, adicione estados no canvas, conecte-os com transições, marque estados inicial/finais e use a simulação para testar cadeias.',
  'usage_test_input':
      'Para testar se um autômato aceita uma cadeia, construa o autômato, acione Testar Entrada ou Executar, informe a cadeia e observe o caminho destacado até o resultado de aceitação ou rejeição.',
  'usage_import_export':
      'Salve e carregue seu trabalho com os formatos suportados. Exporte para compartilhar ou criar backups, importe arquivos salvos e use JFLAP quando precisar compatibilidade com materiais de curso.',
};
