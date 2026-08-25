import '../core/constants/help_topic_ids.dart';
import 'help_catalog_copy.dart';

final _fsaSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute e inspecione uma simulação'),
  HelpOrderedStepsBlock([
    'Confirme que o autômato tem estado inicial válido e informe a Cadeia de entrada.',
    'Selecione Simular e aguarde a conclusão da execução atual.',
    'Leia Aceita ou Rejeitada, inspecione o traço e use Ver no canvas quando disponível.',
  ]),
  const HelpCalloutBlock(
    'Marcadores de estado ausentes, transições inválidas ou limites de computação podem impedir um resultado confiável; siga a mensagem exibida pelo espaço de trabalho.',
  ),
];

final _fsaAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute um algoritmo de autômatos finitos'),
  HelpOrderedStepsBlock([
    'Abra Algoritmos e confirme que o autômato atual atende aos requisitos da ação.',
    'Selecione o algoritmo desejado e forneça um segundo autômato ou opção quando solicitado.',
    'Revise o resultado, o visualizador de passos e Ver no canvas ou a ação de conversão quando oferecida.',
  ]),
  const HelpCalloutBlock(
    'Uma ação desativada ou mensagem de validação indica requisitos não atendidos; o autômato de origem só muda quando o fluxo de resultado o aplica ou substitui explicitamente.',
  ),
];

final _grammarParserBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Analise uma cadeia de entrada'),
  HelpOrderedStepsBlock([
    'Confirme que a gramática tem produções e símbolo inicial válido e informe a Cadeia de teste.',
    'Escolha um Algoritmo de análise disponível e selecione Analisar cadeia.',
    'Leia Aceita ou Rejeitada e inspecione a derivação, os diagnósticos ou os Passos CYK registrados.',
  ]),
  const HelpCalloutBlock(
    'Estratégias indisponíveis não aparecem no menu, e símbolos inválidos ou o limite de cinco segundos podem encerrar a execução sem resultado.',
  ),
];

final _grammarAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute uma análise ou transformação de gramática'),
  HelpOrderedStepsBlock([
    'Resolva os diagnósticos de produção e confirme um símbolo inicial válido.',
    'Abra Análise de gramática e selecione a análise ou transformação desejada.',
    'Inspecione conjuntos, tabela, gramática ou passos; use Aplicar somente quando o controle estiver presente.',
  ]),
  const HelpCalloutBlock(
    'Controles desativados, relatórios de validação e diagnósticos de erro mantêm a gramática do editor inalterada.',
  ),
];

final _pdaSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute e inspecione uma simulação de AP'),
  HelpOrderedStepsBlock([
    'Valide o estado inicial e o símbolo inicial da pilha e informe a entrada da simulação.',
    'Inicie a execução e use Cancelar quando precisar interromper a computação registrada.',
    'Inspecione a pilha atual, a entrada restante, o resultado e o traço em Ver no canvas.',
  ]),
  const HelpCalloutBlock(
    'Ramos não determinísticos e limites de pilha podem interromper ou rejeitar a execução; leia o traço antes de alterar a AP.',
  ),
];

final _pdaAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute uma análise de AP'),
  HelpOrderedStepsBlock([
    'Abra Algoritmos e confira os requisitos de estados, transições e pilha da AP.',
    'Selecione o controle de conversão ou análise desejado.',
    'Revise a GLC gerada, o resultado de estados, o relatório de linguagem ou as métricas de operações da pilha.',
  ]),
  const HelpCalloutBlock(
    'Uma análise indisponível ou malsucedida mantém a AP inalterada e informa o requisito a resolver.',
  ),
];

final _tmSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute e inspecione uma simulação de MT'),
  HelpOrderedStepsBlock([
    'Valide o estado inicial, o símbolo branco e os campos de transição e informe a entrada da fita.',
    'Inicie a execução e use Cancelar quando precisar interromper a computação.',
    'Inspecione a projeção da fita, a posição da cabeça, o resultado e o traço em Ver no canvas.',
  ]),
  const HelpCalloutBlock(
    'A máquina pode executar até o limite configurado de passos ou recursos; atingir um limite não equivale a um resultado de aceitação com parada.',
  ),
];

final _tmAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Execute uma análise de máquina de Turing'),
  HelpOrderedStepsBlock([
    'Abra Algoritmos e confirme que a máquina tem os estados e transições exigidos pela análise.',
    'Configure a entrada e os limites de execução quando a ação escolhida os solicitar e selecione o controle desejado.',
    'Revise o relatório de alcançabilidade, linguagem, operações da fita, tempo limitado ou espaço limitado exibido.',
  ]),
  const HelpCalloutBlock(
    'A análise limitada descreve somente o escopo e os orçamentos exibidos; ela não prova parada nem complexidade para todas as entradas possíveis.',
  ),
];

final ptHelpCatalogCopy = HelpCatalogCopy({
  HelpTopicIds.gettingStarted: HelpNodeCopy(
    title: 'Primeiros passos',
    keywords: ['começar', 'guia', 'navegação'],
  ),
  HelpTopicIds.gettingStartedQuickStart: HelpNodeCopy(
    title: 'Guia rápido',
    body: 'O guia rápido mostra o menor caminho entre a tela inicial e um '
        'modelo formal testado. Use-o ao abrir o Turing Lab pela primeira vez '
        'ou quando quiser relembrar o fluxo. Use as abas de navegação ou chips '
        'de seção para escolher um espaço de trabalho, comece com um documento '
        'vazio ou exemplo ou abra um arquivo compatível e construa o modelo. '
        'Toque duas vezes em um estado '
        'para ações rápidas. Faça pinça para ampliar o canvas e então informe '
        'uma entrada e execute-a; o ícone de guia rápido abre novamente este '
        'lembrete. Use algoritmos para transformar estruturas após a primeira '
        'execução. O editor exibirá o modelo, o estado de validação e o '
        'resultado da simulação. Em geral, o modelo precisa de '
        'um estado inicial e de pelo menos um estado de aceitação; corrija as '
        'mensagens de estado antes de confiar no resultado. Continue em '
        'Escolher um espaço de trabalho ou Testar a primeira entrada.',
    keywords: ['guia rápido', 'primeiro modelo', 'fluxo', 'início'],
  ),
  HelpTopicIds.gettingStartedNavigation: HelpNodeCopy(
    title: 'Navegar pelo Turing Lab',
    body: 'A navegação principal alterna entre os espaços AF, Gramática, AP, '
        'MT, Regex e Bombeamento. Use-a para mudar o tipo de modelo de linguagem '
        'que você edita ou estuda. Selecione o destino na tela inicial, na barra '
        'de navegação ou no controle de seção disponível para o tamanho da '
        'tela. O Turing Lab abrirá esse espaço com as ferramentas próximas ao '
        'canvas ou à área de entrada. Os rótulos e as posições se adaptam a '
        'celular, tablet e desktop; oriente-se pelo rótulo visível, não por uma '
        'posição fixa. Leia Escolher um espaço de trabalho antes de criar um '
        'novo modelo.',
    keywords: [
      'navegação',
      'AF',
      'Gramática',
      'AP',
      'MT',
      'Regex',
      'Bombeamento'
    ],
  ),
  HelpTopicIds.gettingStartedChooseWorkspace: HelpNodeCopy(
    title: 'Escolher um espaço de trabalho',
    body: 'Cada espaço representa um modelo de linguagem formal ou uma '
        'atividade de aprendizagem. Use AF para linguagens regulares e memória '
        'finita, Gramática para produções, AP para memória em pilha, MT para '
        'computação em fita, Regex para expressões regulares e Bombeamento para '
        'praticar provas. Selecione o cartão ou rótulo correspondente na tela '
        'inicial. O editor escolhido abrirá com controles, simulação, algoritmos '
        'e teoria próprios. Conversões podem levar um resultado a outro espaço, '
        'mas uma estrutura não suportada não cabe em um modelo menos expressivo. '
        'Continue na visão geral do editor escolhido.',
    keywords: [
      'espaço de trabalho',
      'linguagem formal',
      'autômato',
      'gramática'
    ],
  ),
  HelpTopicIds.gettingStartedFilesAndExamples: HelpNodeCopy(
    title: 'Arquivos e exemplos',
    body: 'Arquivos e exemplos permitem começar com material salvo ou incluído '
        'no aplicativo. Use um exemplo para aprender um recurso e a importação '
        'ou exportação para continuar seu próprio trabalho. Abra o painel de '
        'exemplos ou uma ação de arquivo e selecione o item solicitado quando '
        'o seletor de arquivos da plataforma aparecer; na Web, downloads '
        'substituem as caixas nativas de salvamento. Uma importação bem-sucedida '
        'carrega o modelo e uma exportação cria o formato indicado na ação. '
        'Somente os formatos oferecidos no espaço atual são compatíveis, e '
        'cancelar a seleção não altera o modelo. Consulte Arquivos e exemplos '
        'do espaço para ver os formatos exatos.',
    keywords: ['arquivos', 'exemplos', 'importar', 'exportar', 'seletor'],
  ),
  HelpTopicIds.gettingStartedFirstInput: HelpNodeCopy(
    title: 'Testar a primeira entrada',
    body: 'Uma simulação verifica como o modelo atual processa uma cadeia de '
        'entrada. Use-a quando o editor indicar um modelo utilizável e sempre '
        'que quiser testar se uma cadeia pertence à linguagem. Digite a cadeia '
        'em Cadeia de entrada, deixe o campo vazio para ε quando isso for '
        'aceito e selecione Simular ou Executar simulação. O resultado informa '
        'Aceita ou Rejeitada e pode incluir um traço de passos. A ausência de '
        'estado inicial, transições inválidas ou limites de computação podem '
        'impedir a execução; siga a mensagem exibida. Continue no tópico de '
        'simulação do espaço atual.',
    keywords: ['entrada', 'simulação', 'aceita', 'rejeitada', 'epsilon'],
  ),
  HelpTopicIds.gettingStartedFindHelp: HelpNodeCopy(
    title: 'Encontrar ajuda e atalhos',
    body:
        'A Ajuda reúne instruções, orientação da tela atual, teoria e atalhos '
        'em uma árvore pesquisável. Use-a quando um controle, resultado, '
        'requisito ou conceito não estiver claro. Selecione uma ação de Ajuda '
        'com ponto de interrogação para abrir o tópico atual, abra Ajuda na '
        'barra do aplicativo para ver a árvore ou pesquise por um rótulo ou '
        'conceito. O tópico correspondente aparecerá com seus níveis anteriores '
        'e próximos passos relacionados. Dicas curtas apenas identificam '
        'controles, e os atalhos dependem da plataforma e da disponibilidade de '
        'teclado físico. Continue em Navegar pelo Turing Lab ou na visão geral '
        'do editor relevante.',
    keywords: ['ajuda', 'pesquisa', 'atalhos', 'interrogação', 'dica'],
  ),
  'fsa': HelpNodeCopy(
    title: 'Autômatos finitos',
    keywords: ['AF', 'autômatos finitos', 'AFD', 'AFN'],
  ),
  'fsa.editor': HelpNodeCopy(
    title: 'Editor e canvas',
    keywords: ['editor', 'canvas', 'simulação', 'algoritmos'],
  ),
  HelpTopicIds.fsaEditorOverview: HelpNodeCopy(
    title: 'Visão geral do editor de autômatos finitos',
    body: 'O espaço de autômatos finitos reúne o canvas de estados, os painéis '
        'de simulação e algoritmos, o estado de validação e as ações de arquivo. '
        'Use-o para construir ou examinar um AFD, AFN ou AFN-ε. Comece com '
        'Adicionar estado, conecte os estados com Adicionar transição, marque '
        'os estados inicial e de aceitação e execute uma entrada de teste. A '
        'área de estado informa marcadores ausentes e não determinismo. Uma '
        'simulação ou algoritmo exclusivo de AFD pode ficar indisponível até '
        'que os requisitos estruturais sejam cumpridos. Abra Edição, Simulação '
        'ou Algoritmos para continuar.',
    keywords: ['AF', 'editor', 'canvas', 'AFD', 'AFN'],
  ),
  'fsa.editor.editing': HelpNodeCopy(
    title: 'Editar um autômato',
    keywords: ['editar', 'estado', 'transição', 'histórico'],
  ),
  HelpTopicIds.fsaEditorSelection: HelpNodeCopy(
    title: 'Selecionar e mover itens',
    body: 'O modo Selecionar permite examinar, mover, editar ou excluir itens '
        'existentes no canvas. Use-o depois de criar estados ou quando outra '
        'ferramenta de edição estiver ativa. Escolha Selecionar e selecione um '
        'estado ou transição; arraste um estado com o ponteiro ou um dedo e '
        'toque duas vezes nele para abrir ações rápidas. O item selecionado '
        'ganha a aparência ativa e as arestas acompanham um estado movido. Uma '
        'pinça com dois dedos controla o zoom, e canvases de resultado somente '
        'leitura não aceitam edições. Continue em Estados ou Transições.',
    keywords: ['selecionar', 'mover', 'arrastar', 'toque duplo', 'toque'],
  ),
  HelpTopicIds.fsaEditorStates: HelpNodeCopy(
    title: 'Adicionar e editar estados',
    body: 'Estados representam as posições da memória finita de um autômato. '
        'Use-os para indicar onde o processamento começa, quais situações podem '
        'ocorrer e onde a entrada é aceita. Escolha Adicionar estado e '
        'posicione-o; depois, selecione-o para editar Rótulo do estado, Estado '
        'inicial ou Estado de aceitação e para excluí-lo. O canvas atualiza o '
        'marcador e todas as transições conectadas ao estado alterado. Use '
        'rótulos claros, mantenha apenas um estado inicial e lembre que excluir '
        'um estado também remove suas transições. Continue em Adicionar e '
        'editar transições.',
    keywords: ['estado', 'Adicionar estado', 'inicial', 'aceitação', 'excluir'],
  ),
  HelpTopicIds.fsaEditorTransitions: HelpNodeCopy(
    title: 'Adicionar e editar transições',
    body: 'Transições descrevem qual estado sucede o atual para um símbolo de '
        'entrada. Use-as para definir o comportamento do autômato para cada '
        'símbolo relevante. Escolha Adicionar transição, selecione origem e '
        'destino e informe um símbolo ou a opção λ; selecione uma aresta para '
        'editá-la ou excluí-la. O canvas desenha uma aresta direcionada com '
        'rótulo e recalcula alfabeto e determinismo. Um AFD não aceita '
        'transições λ nem dois destinos para o mesmo estado e símbolo, enquanto '
        'um AFN aceita. Continue em Determinismo e validação.',
    keywords: [
      'transição',
      'Adicionar transição',
      'símbolo',
      'lambda',
      'aresta'
    ],
  ),
  HelpTopicIds.fsaEditorDeterminism: HelpNodeCopy(
    title: 'Determinismo e validação',
    body: 'O indicador de determinismo e o estado de validação resumem se o '
        'autômato atual cumpre regras estruturais importantes. Consulte-os '
        'antes da simulação e de algoritmos que exigem um AFD. Examine o texto '
        'de estado e abra os detalhes de determinismo para localizar estados '
        'inicial ou de aceitação ausentes, transições λ ou transições '
        'concorrentes. Os indicadores mudam durante a edição e distinguem AFD '
        'de AFN. O indicador apenas diagnostica; alguns algoritmos continuam '
        'indisponíveis ou exibem erro até a correção do modelo. Continue em '
        'AFD, AFN ou edição de transições.',
    keywords: ['determinismo', 'validação', 'AFD', 'AFN', 'diagnóstico'],
  ),
  HelpTopicIds.fsaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Desfazer, refazer e limpar',
    body: 'Os controles de histórico revertem ou restauram edições, enquanto '
        'Limpar canvas remove o autômato atual. Use Desfazer após uma edição '
        'indesejada, Refazer se recuar demais e Limpar canvas somente para '
        'recomeçar. Selecione Desfazer ou pressione Ctrl+Z; nas plataformas '
        'Apple com teclado físico, Cmd+Z também funciona. Para Refazer, use '
        'Ctrl+Y ou Ctrl+Shift+Z, ou use Cmd+Y ou Cmd+Shift+Z nas plataformas '
        'Apple com teclado físico. O canvas e a validação retornam ao estado de '
        'edição correspondente. O histórico abrange apenas alterações '
        'registradas e Limpar canvas é destrutivo, embora possa ser desfeito '
        'enquanto o histórico existir. Continue em Selecionar ou Arquivos e '
        'exemplos antes de substituir um trabalho importante.',
    keywords: ['desfazer', 'refazer', 'Limpar canvas', 'Ctrl Z', 'Cmd Z'],
  ),
  'fsa.editor.viewport': HelpNodeCopy(
    title: 'Visualização do canvas',
    keywords: ['visualização', 'zoom', 'ajustar', 'layout'],
  ),
  HelpTopicIds.fsaEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom e deslocamento',
    body: 'Zoom e deslocamento mudam a visualização sem alterar o autômato. '
        'Use-os para examinar transições densas ou percorrer um canvas maior. '
        'Selecione Aumentar zoom ou Diminuir zoom, use o gesto do ponteiro '
        'quando disponível, faça pinça com dois dedos em telas sensíveis ao '
        'toque e arraste uma área vazia para deslocar. Estados e transições '
        'mantêm suas posições no modelo enquanto escala e deslocamento mudam. '
        'Arrastar um estado com um dedo o move no modo Selecionar; por isso, '
        'comece o deslocamento em uma área vazia. Continue em Ajustar ao '
        'conteúdo e Redefinir visualização.',
    keywords: ['zoom', 'deslocar', 'pinça', 'toque', 'visualização'],
  ),
  HelpTopicIds.fsaEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Ajustar ao conteúdo e redefinir visualização',
    body: 'Ajustar ao conteúdo enquadra todo o autômato, enquanto Redefinir '
        'visualização restaura zoom e posição padrão. Use Ajustar ao conteúdo '
        'quando houver estados fora da tela e Redefinir visualização para '
        'voltar a uma vista neutra. Selecione a ação correspondente nos '
        'controles do canvas. Somente a visualização muda; as posições salvas '
        'dos estados permanecem iguais. Um canvas vazio não tem conteúdo para '
        'enquadrar, e nenhuma das ações corrige elementos sobrepostos. Continue '
        'em Layout automático quando precisar reorganizar os estados.',
    keywords: ['Ajustar ao conteúdo', 'Redefinir visualização', 'enquadrar'],
  ),
  HelpTopicIds.fsaEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Layout automático',
    body: 'Layout automático reorganiza os estados atuais em um círculo. Use-o '
        'quando posições manuais se sobrepuserem ou dificultarem a leitura das '
        'transições. Abra Algoritmos e selecione Layout automático. As '
        'coordenadas dos estados mudam e as transições são redesenhadas para o '
        'novo arranjo. O comando não altera rótulos, marcadores, transições nem '
        'a linguagem, e grafos complexos ainda podem exigir ajustes manuais. '
        'Continue em Selecionar e mover itens para refinar o resultado.',
    keywords: ['Layout automático', 'organizar', 'círculo', 'sobreposição'],
  ),
  'fsa.editor.simulation': HelpNodeCopy(
    title: 'Simulação',
    keywords: ['simulação', 'entrada', 'resultado', 'traço'],
  ),
  HelpTopicIds.fsaEditorSimulationInputAndRun: HelpNodeCopy(
    blocks: _fsaSimulationBlocks,
    title: 'Informar entrada e executar a simulação',
    body: 'A entrada da simulação é a cadeia que o autômato tentará consumir. '
        'Use-a para verificar se uma cadeia específica pertence à linguagem '
        'modelada. Digite o texto em Cadeia de entrada, deixe-o vazio para ε, '
        'ative Modo passo a passo se quiser um traço e selecione Simular; '
        'durante a execução, Simulando... substitui e desativa a ação porque o '
        'painel de AF não oferece cancelamento. O painel mostra o progresso e '
        'então produz o resultado. O autômato precisa de um estado inicial '
        'utilizável, espaços são '
        'preservados e limites de busca podem interromper AFNs muito ramificados. '
        'Continue em Resultados e reprodução.',
    keywords: [
      'Cadeia de entrada',
      'Simular',
      'Executar simulação',
      'cancelar'
    ],
  ),
  HelpTopicIds.fsaEditorSimulationResultsAndPlayback: HelpNodeCopy(
    blocks: _fsaSimulationBlocks,
    title: 'Ler resultados e reproduzir passos',
    body: 'Os resultados informam se a entrada foi Aceita ou Rejeitada e podem '
        'mostrar o caminho percorrido. Use o traço para estudar a execução ou '
        'investigar um resultado inesperado. Ative Modo passo a passo antes de '
        'simular e depois use Passo anterior, Próximo passo, Reproduzir, Pausar, '
        'Reiniciar, a linha do tempo, a velocidade ou Visualizar no Canvas. O '
        'passo selecionado destaca o estado e a transição ativos e indica a '
        'entrada consumida e restante. Em um AFN rejeitado, as alternativas '
        'podem ter se esgotado sem formar um único caminho de falha, e não há '
        'traço se o registro estava desativado. Continue em Alfabeto e '
        'aceitação ou edite a transição indicada.',
    keywords: [
      'Aceita',
      'Rejeitada',
      'Visualizar no Canvas',
      'reprodução',
      'traço'
    ],
  ),
  'fsa.editor.algorithms': HelpNodeCopy(
    title: 'Algoritmos',
    keywords: ['algoritmos', 'conversão', 'operações', 'passos'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Visão geral dos algoritmos de autômatos finitos',
    body: 'O painel Algoritmos converte, combina, simplifica e analisa '
        'autômatos finitos. Use-o após construir ou carregar um autômato quando '
        'precisar de uma forma equivalente ou linguagem derivada. Abra '
        'Algoritmos e selecione Expressão regular para AFN, AFN para AFD, '
        'Remover transições λ, Minimizar AFD, Completar AFD, Complemento do AFD, '
        'União de AFDs, Interseção de AFDs, Diferença de AFDs, Fecho por '
        'prefixos, Fecho por sufixos, AF para expressão regular, AF para '
        'gramática ou Comparar equivalência. O painel mostra progresso, estado '
        'e o resultado gerado ou a comparação. Cada comando valida seus '
        'próprios requisitos de AFD, AFN, arquivo ou estrutura e exibe uma '
        'mensagem quando não forem cumpridos. Abra o tópico do algoritmo '
        'escolhido ou Modo passo a passo.',
    keywords: ['Algoritmos', 'operações de AFD', 'conversão', 'comparação'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsRegexToNfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Expressão regular para AFN',
    body: 'Expressão regular para AFN constrói um autômato não determinístico '
        'para uma expressão regular. Use essa conversão quando for mais fácil '
        'escrever a expressão do que desenhar o grafo equivalente. Em '
        'Algoritmos, digite um valor válido em Expressão regular e ative a seta '
        'ao lado de Expressão regular para AFN. O AFN gerado aparece no canvas '
        'com estados e transições para a mesma linguagem. Sintaxe inválida ou '
        'entrada vazia impede a conversão, e o resultado pode conter transições '
        'λ. Continue em AFN para AFD ou no tópico teórico AFN.',
    keywords: ['expressão regular para AFN', 'regex', 'conversão', 'lambda'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsNfaToDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'AFN para AFD',
    body: 'AFN para AFD aplica a construção de subconjuntos para criar um '
        'autômato determinístico da mesma linguagem. Use-a quando uma simulação '
        'ou operação exigir AFD. Construa ou carregue um AFN, abra Algoritmos e '
        'selecione AFN para AFD. O resultado representa conjuntos de estados do '
        'AFN como estados do AFD e preserva a aceitação. A falta de estado '
        'inicial ou uma transição inválida impede a conversão, e a quantidade '
        'de subconjuntos alcançáveis pode crescer rapidamente. Continue em '
        'Minimizar AFD ou na teoria de AFD.',
    keywords: ['AFN para AFD', 'subconjuntos', 'determinizar', 'AFD'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsRemoveLambda: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Remover transições λ',
    body: 'Remover transições λ cria um autômato equivalente sem movimentos '
        'epsilon. Use o comando antes de operações que exigem uma transição '
        'consumindo símbolo em cada passo. Abra Algoritmos e selecione Remover '
        'transições λ para o autômato atual. O resultado propaga alcance e '
        'aceitação pelos fechos epsilon e elimina as arestas λ. O autômato '
        'precisa de uma estrutura inicial válida, e o grafo transformado pode '
        'ter mais transições com símbolos. Continue em Fecho epsilon ou AFN '
        'para AFD.',
    keywords: ['remover lambda', 'epsilon', 'transição lambda', 'fecho'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsMinimizeDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Minimizar AFD',
    body: 'Minimizar AFD reúne estados indistinguíveis de um autômato '
        'determinístico. Use-o para obter um AFD menor que reconhece a mesma '
        'linguagem. Torne o autômato determinístico, abra Algoritmos e selecione '
        'Minimizar AFD. O resultado remove distinções inalcançáveis e combina '
        'classes de estados equivalentes. Transições λ, não determinismo ou '
        'estrutura inicial inválida impedem a minimização, e os rótulos dos '
        'estados podem mudar. Continue em Equivalência para comparar as '
        'linguagens.',
    keywords: ['Minimizar AFD', 'redução', 'estados equivalentes', 'AFD'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsCompleteDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Completar AFD',
    body: 'Completar AFD adiciona as transições ausentes para cada estado e '
        'símbolo do alfabeto. Use-o quando precisar de uma função de transição '
        'total ou quiser examinar a forma usada no complemento. Abra Algoritmos '
        'e selecione Completar AFD. O resultado inclui um estado armadilha e '
        'direciona para ele os casos antes ausentes. A entrada deve ser '
        'determinística e não ter transições λ; um AFD já completo pode mudar '
        'pouco ou nada. Continue em Complemento do AFD.',
    keywords: [
      'Completar AFD',
      'estado armadilha',
      'transição total',
      'alfabeto'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsComplementDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Complemento do AFD',
    body: 'Complemento do AFD constrói um autômato que aceita exatamente as '
        'cadeias rejeitadas pelo AFD original sobre seu alfabeto. Use-o para '
        'negar uma linguagem regular. Abra Algoritmos e selecione Complemento '
        'do AFD; o comando completa internamente as transições ausentes antes '
        'de mudar a aceitação. O resultado troca estados de aceitação e não '
        'aceitação sem deixar casos de entrada indefinidos. A origem deve ser '
        'determinística e não ter transições λ, mas não precisa ser completada '
        'manualmente. Continue em Completar AFD ou Equivalência.',
    keywords: ['complemento do AFD', 'negação', 'aceitação', 'AFD completo'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsUnion: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'União de AFDs',
    body: 'União de AFDs aceita cadeias reconhecidas por qualquer um de dois '
        'autômatos. Use-a para combinar duas linguagens regulares com OU lógico. '
        'Abra Algoritmos, selecione União de AFDs e escolha o segundo AFD no '
        'seletor de arquivos da plataforma. No produto, um par será de '
        'aceitação quando pelo menos um componente for de aceitação. As duas '
        'entradas devem ser AFDs carregáveis; a operação reúne seus alfabetos e '
        'completa casos ausentes, enquanto cancelar a seleção mantém o autômato '
        'atual. Continue em Operações de fecho ou Equivalência.',
    keywords: [
      'União de AFDs',
      'união',
      'OU',
      'seletor de arquivos',
      'produto'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsIntersection: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Interseção de AFDs',
    body:
        'Interseção de AFDs aceita cadeias reconhecidas pelos dois autômatos. '
        'Use-a para combinar requisitos de linguagens regulares com E lógico. '
        'Abra Algoritmos, selecione Interseção de AFDs e escolha o segundo AFD '
        'no seletor de arquivos da plataforma. No produto, um par será de '
        'aceitação somente quando ambos os componentes forem de aceitação. As '
        'duas entradas devem ser AFDs carregáveis; a operação reúne seus '
        'alfabetos e completa casos ausentes, enquanto cancelar a seleção não '
        'altera o modelo. Continue em Operações de fecho ou Equivalência.',
    keywords: ['Interseção de AFDs', 'interseção', 'E', 'seletor de arquivos'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsDifference: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Diferença de AFDs',
    body:
        'Diferença de AFDs aceita cadeias do AFD atual que não pertencem a um '
        'segundo AFD. Use-a para subtrair uma linguagem regular de outra. Abra '
        'Algoritmos, selecione Diferença de AFDs e escolha no seletor o AFD que '
        'será subtraído. O produto combina a aceitação do primeiro com a '
        'rejeição do segundo. Os arquivos devem descrever AFDs válidos; seus '
        'alfabetos são reunidos, e a ordem dos operandos muda o resultado. '
        'Continue em Operações de fecho ou Equivalência.',
    keywords: ['Diferença de AFDs', 'diferença', 'subtrair', 'seletor'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsPrefixClosure: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Fecho por prefixos',
    body: 'Fecho por prefixos cria um autômato que aceita todo prefixo de uma '
        'cadeia da linguagem do AFD atual. Use-o quando qualquer começo válido '
        'de uma palavra aceita também deva ser aceito. Abra Algoritmos e '
        'selecione Fecho por prefixos. O resultado altera a aceitação para que '
        'estados capazes de alcançar um estado de aceitação reconheçam prefixos '
        'válidos. A operação espera um AFD válido, e os prefixos incluem a '
        'palavra completa e podem incluir ε. Continue em Operações de fecho ou '
        'Fecho por sufixos.',
    keywords: [
      'Fecho por prefixos',
      'prefixo',
      'linguagem regular',
      'aceitação'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsSuffixClosure: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Fecho por sufixos',
    body: 'Fecho por sufixos cria um autômato que aceita todo sufixo de uma '
        'cadeia da linguagem do AFD atual. Use-o quando os finais válidos das '
        'palavras aceitas devam formar a nova linguagem. Abra Algoritmos e '
        'selecione Fecho por sufixos. O resultado introduz possibilidades '
        'iniciais não determinísticas e constrói o autômato derivado. O modelo '
        'atual deve ser válido, e o resultado pode precisar de mais estados '
        'depois da determinização. Continue em Operações de fecho ou AFN para '
        'AFD.',
    keywords: ['Fecho por sufixos', 'sufixo', 'linguagem regular', 'AFN'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsFaToRegex: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'AF para expressão regular',
    body: 'AF para expressão regular deriva uma expressão para a linguagem do '
        'autômato finito atual. Use-o quando precisar de uma representação '
        'textual equivalente ao grafo de estados. Abra Algoritmos e selecione '
        'AF para expressão regular. O painel retorna uma expressão obtida pela '
        'eliminação de estados com preservação dos caminhos aceitos. São '
        'necessários estado inicial e estrutura de aceitação válidos, e '
        'expressões equivalentes podem ter formas muito diferentes ou extensas. '
        'Continue em Equivalência ou Expressão regular para AFN.',
    keywords: ['AF para expressão regular', 'regex', 'eliminação de estados'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsFsaToGrammar: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'AF para gramática',
    body: 'AF para gramática converte o autômato em uma gramática linear à '
        'direita equivalente. Use-o para estudar a relação entre gramáticas '
        'regulares e autômatos finitos. Abra Algoritmos e selecione AF para '
        'gramática. O resultado transforma estados em variáveis, transições '
        'rotuladas em produções e aceitação em produções terminais. O autômato '
        'precisa de estado inicial válido, e os nomes das variáveis geradas '
        'podem diferir dos rótulos dos estados. Continue no espaço Gramática ou '
        'leia Equivalência.',
    keywords: [
      'AF para gramática',
      'gramática regular',
      'produção',
      'conversão'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsEquivalence: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Comparar equivalência',
    body: 'Comparar equivalência verifica se dois autômatos finitos aceitam a '
        'mesma linguagem. Use-o para validar uma conversão, simplificação ou '
        'modelo construído separadamente. Abra Algoritmos, selecione Comparar '
        'equivalência e escolha o outro autômato no seletor de arquivos da '
        'plataforma. A comparação informa equivalência ou diferença e pode '
        'mostrar detalhes ou uma entrada que distingue os modelos. Os dois '
        'autômatos precisam ser carregados com estados iniciais; a comparação '
        'reúne alfabetos diferentes e determiniza quando necessário, enquanto '
        'estruturas inválidas impedem a análise. Continue na teoria de '
        'Equivalência.',
    keywords: ['Comparar equivalência', 'mesma linguagem', 'contraexemplo'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsStepMode: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Modo passo a passo',
    body: 'Modo passo a passo registra etapas intermediárias dos algoritmos '
        'compatíveis. Use-o para aprender uma transformação ou conferir como o '
        'resultado foi produzido. Ative Modo passo a passo antes de selecionar '
        'o algoritmo e use Passo anterior, Próximo passo, Reproduzir, Pausar, '
        'Reiniciar ou o navegador de passos. O visualizador mostra a explicação '
        'e a representação ativas em cada etapa registrada. Alguns comandos '
        'não produzem passos detalhados, e executar outro algoritmo substitui '
        'a sequência anterior. Continue no tópico do algoritmo escolhido.',
    keywords: ['Modo passo a passo', 'passos', 'navegador', 'reprodução'],
  ),
  HelpTopicIds.fsaEditorFilesAndExamples: HelpNodeCopy(
    title: 'Arquivos e exemplos de AF',
    body: 'As ações de arquivo importam, salvam ou renderizam autômatos, e os '
        'exemplos incluídos oferecem modelos prontos. Abra Algoritmos e '
        'selecione AFD - Termina com A, AFD - Binário divisível por 3, AFD - '
        'Paridade AB, AFD - Contém AB ou AFNλ - A ou AB. O exemplo selecionado '
        'substitui o AF atual e fica acessível mesmo com o canvas vazio. Use '
        'JFLAP ou JSON para continuar a edição e SVG ou PNG para compartilhar '
        'uma imagem. No '
        'painel File Operations, selecione Load JFLAP ou Load JSON e escolha um '
        'arquivo; em plataformas nativas, use Save as JFLAP, Save as JSON, '
        'Export SVG ou Export PNG, enquanto a Web mostra Download JFLAP, '
        'Download JSON e Download SVG. Uma importação bem-sucedida '
        'carrega o autômato, e a exportação confirma o arquivo criado. JFLAP '
        'usa .jff, arquivos malformados exibem erro, cancelar não altera o '
        'modelo e a exportação PNG nativa não aparece na Web. Continue em '
        'Arquivos e exemplos ou na visão geral do editor.',
    keywords: [
      'JFLAP',
      'JSON',
      'SVG',
      'PNG',
      'exemplos',
      'importar',
      'exportar'
    ],
  ),
  'fsa.theory': HelpNodeCopy(
    title: 'Teoria',
    keywords: ['teoria', 'linguagem regular', 'AFD', 'AFN'],
  ),
  HelpTopicIds.fsaTheoryDfa: HelpNodeCopy(
    title: 'Autômatos finitos determinísticos (AFD)',
    body: 'Um AFD é um autômato finito com exatamente um próximo estado para '
        'cada estado e símbolo de entrada. Use esse modelo em linguagens '
        'regulares cujo próximo passo não seja ambíguo. No editor de AF, crie '
        'um estado inicial, marque estados de aceitação e defina no máximo uma '
        'transição por símbolo em cada estado, sem transições λ. Uma execução '
        'segue um caminho e aceita somente se terminar em estado de aceitação '
        'após consumir toda a entrada. Transições ausentes deixam o AFD '
        'incompleto, e escolhas duplicadas para um símbolo o tornam não '
        'determinístico. Continue em AFN ou Completar AFD.',
    keywords: [
      'AFD',
      'determinístico',
      'linguagem regular',
      'função de transição'
    ],
  ),
  HelpTopicIds.fsaTheoryNfa: HelpNodeCopy(
    title: 'Autômatos finitos não determinísticos (AFN)',
    body:
        'Um AFN pode ter vários próximos estados para um símbolo e movimentos '
        'epsilon. Use-o quando ramificações ou uma construção compacta '
        'facilitarem a representação da linguagem regular. No editor, crie '
        'transições concorrentes ou transições λ e simule uma entrada pelos '
        'caminhos disponíveis. O AFN aceita quando pelo menos um caminho consome '
        'toda a entrada e chega a um estado de aceitação. Ramificações podem '
        'aumentar os traços e a busca, mas não dão ao AFN mais poder de '
        'linguagem que um AFD. Continue em AFN para AFD ou Transições epsilon.',
    keywords: ['AFN', 'não determinístico', 'ramificação', 'epsilon'],
  ),
  HelpTopicIds.fsaTheoryStates: HelpNodeCopy(
    title: 'Estados',
    body: 'Um estado registra a quantidade finita de histórico necessária em '
        'um ponto da execução. Use estados distintos para situações que exigem '
        'comportamentos futuros diferentes. Adicione e rotule estados no '
        'canvas, escolha um estado inicial e marque todas as condições de '
        'aceitação. A simulação move o marcador ativo entre esses estados '
        'enquanto consome a entrada. Rótulos são descritivos, e a aceitação '
        'depende do marcador e do fim da entrada, não do nome do estado. '
        'Continue em Transições ou Alfabeto e aceitação.',
    keywords: ['estados', 'inicial', 'aceitação', 'memória finita'],
  ),
  HelpTopicIds.fsaTheoryTransitions: HelpNodeCopy(
    title: 'Transições',
    body: 'Uma transição é uma regra direcionada entre estados, normalmente '
        'rotulada pela entrada que consome. Use transições para definir cada '
        'próximo passo permitido. Conecte origem e destino e atribua um símbolo, '
        'ou use λ para um movimento epsilon em AFN. A simulação percorre '
        'arestas correspondentes e muda o estado ativo. Uma transição com '
        'símbolo não corresponde a outra entrada, e correspondências '
        'concorrentes introduzem não determinismo. Continue em Alfabeto e '
        'aceitação ou Transições epsilon.',
    keywords: ['transições', 'aresta', 'símbolo', 'próximo estado'],
  ),
  HelpTopicIds.fsaTheoryAlphabetAndAcceptance: HelpNodeCopy(
    title: 'Alfabeto e aceitação',
    body: 'O alfabeto é o conjunto de símbolos das transições que consomem '
        'entrada, e aceitação define a pertinência à linguagem. Use ambos para '
        'especificar quais entradas fazem sentido e quais têm sucesso. Rotule '
        'transições com símbolos, comece no estado inicial, consuma toda a '
        'cadeia e verifique se algum caminho termina em estado de aceitação. '
        'Aceita significa que existe ao menos um caminho completo válido; '
        'Rejeitada significa que não existe. λ não pertence ao alfabeto, e '
        'parar cedo em estado de aceitação não aceita uma entrada ainda não '
        'consumida. Continue em AFD, AFN ou resultados da simulação.',
    keywords: ['alfabeto', 'aceitação', 'Aceita', 'Rejeitada', 'linguagem'],
  ),
  HelpTopicIds.fsaTheoryEpsilon: HelpNodeCopy(
    title: 'Epsilon e transições λ',
    body: 'Epsilon, representado por ε ou λ, é a cadeia vazia, e uma transição '
        'λ muda o estado sem consumir entrada. Use movimentos epsilon em AFNs '
        'quando a construção exigir uma ramificação opcional ou espontânea. '
        'Escolha a opção λ ao editar a transição e considere essas arestas antes '
        'ou entre movimentos com símbolos. Todos os estados alcançáveis por '
        'esses movimentos tornam-se estados atuais possíveis. Um AFD não pode '
        'ter transições λ, e ciclos epsilon não devem ser tratados como entrada '
        'consumida. Continue em Fecho epsilon ou Remover transições λ.',
    keywords: ['epsilon', 'lambda', 'cadeia vazia', 'transição lambda'],
  ),
  HelpTopicIds.fsaTheoryEpsilonClosure: HelpNodeCopy(
    title: 'Fecho epsilon',
    body: 'O fecho epsilon de um estado ou conjunto contém todos os estados '
        'alcançáveis apenas por transições λ, inclusive os estados iniciais do '
        'cálculo. Use-o para compreender simulação de AFN, remoção de lambda e '
        'construção de subconjuntos. Comece com o conjunto atual e percorra '
        'repetidamente todas as arestas λ até não surgir estado novo. O conjunto '
        'completo participa antes do consumo do próximo símbolo. Esquecer o '
        'estado inicial ou parar após uma única aresta λ produz um fecho '
        'incorreto. Continue em Remover transições λ ou AFN para AFD.',
    keywords: ['fecho epsilon', 'fecho lambda', 'alcançável', 'AFN'],
  ),
  HelpTopicIds.fsaTheoryEquivalence: HelpNodeCopy(
    title: 'Equivalência de linguagens',
    body: 'Dois autômatos finitos são equivalentes quando aceitam exatamente o '
        'mesmo conjunto de cadeias. Use equivalência para validar conversões, '
        'minimização ou dois projetos diferentes. Compare os comportamentos '
        'com Comparar equivalência ou por uma construção produto que procure '
        'aceitações diferentes. Um resultado equivalente indica que nenhuma '
        'entrada distintiva foi encontrada; um resultado diferente pode '
        'apresentar um contraexemplo. Diagramas e nomes de estados não precisam '
        'coincidir, e uma única cadeia diferente basta para negar equivalência. '
        'Continue em Comparar equivalência ou Minimizar AFD.',
    keywords: [
      'equivalência',
      'mesma linguagem',
      'contraexemplo',
      'comparação'
    ],
  ),
  HelpTopicIds.fsaTheoryClosureOperations: HelpNodeCopy(
    title: 'Operações de fecho',
    body: 'Linguagens regulares permanecem regulares sob união, interseção, '
        'diferença, complemento, fecho por prefixos e fecho por sufixos. Use '
        'esse fato para construir um autômato de uma linguagem derivada de '
        'outras linguagens regulares. Escolha o comando correspondente em '
        'Algoritmos e forneça um segundo AFD quando a operação for binária. O '
        'autômato gerado reconhece a linguagem definida pela operação. '
        'Operações binárias dependem da ordem quando aplicável e exigem entradas '
        'determinísticas válidas. O complemento matemático pressupõe uma função '
        'de transição total, mas o comando atual Complemento do AFD completa '
        'internamente as transições ausentes e exige somente uma entrada '
        'determinística válida, sem transições λ. Continue no tópico da '
        'operação específica ou em Equivalência.',
    keywords: ['fecho', 'união', 'interseção', 'diferença', 'complemento'],
  ),
  'grammar': HelpNodeCopy(
    title: 'Gramáticas',
    keywords: ['gramática', 'GLC', 'produções', 'análise'],
  ),
  'grammar.editor': HelpNodeCopy(
    title: 'Editor e analisador',
    keywords: ['editor', 'analisador', 'algoritmos', 'conversões'],
  ),
  HelpTopicIds.grammarEditorOverview: HelpNodeCopy(
    title: 'Visão geral do editor de gramáticas',
    body: 'O espaço Gramática reúne o editor de produções, o Analisador de '
        'gramática e a Análise da gramática. Use-o para definir uma gramática, '
        'testar uma cadeia, transformar regras ou converter o modelo. Informe '
        'Nome da gramática e Símbolo inicial, adicione regras pelos campos Lado '
        'esquerdo (variável) e Lado direito (produção) e abra Analisar ou '
        'Algoritmos. Ao montar o modelo, o provedor infere letras maiúsculas '
        'unitárias como não terminais e os demais símbolos como terminais. '
        'Regras inválidas ou ausentes impedem etapas posteriores; continue em '
        'Símbolos e símbolo inicial.',
    keywords: ['Editor de gramática', 'Nome', 'Símbolo inicial', 'Analisar'],
  ),
  'grammar.editor.productions': HelpNodeCopy(
    title: 'Produções',
    keywords: ['produção', 'regra', 'lado esquerdo', 'lado direito'],
  ),
  HelpTopicIds.grammarEditorProductionSymbols: HelpNodeCopy(
    title: 'Símbolos e símbolo inicial',
    body: 'Os símbolos da gramática são classificados como não terminais ou '
        'terminais, e Símbolo inicial indica onde começam as derivações. '
        'Defina-os antes de criar regras que o analisador e os algoritmos devam '
        'interpretar. Informe Nome da gramática, ajuste Símbolo inicial e use '
        'um símbolo como S em cada Lado esquerdo (variável); letras maiúsculas '
        'unitárias no lado direito são inferidas como não terminais. O modelo '
        'reúne os símbolos do lado esquerdo como não terminais e os demais do '
        'lado direito como terminais. Uma edição vazia do símbolo inicial é '
        'ignorada, mas ele precisa pertencer ao conjunto de não terminais; '
        'continue em Linhas e alternativas.',
    keywords: ['Símbolo inicial', 'terminal', 'não terminal', 'Nome'],
  ),
  HelpTopicIds.grammarEditorProductionRowsAndAlternatives: HelpNodeCopy(
    title: 'Linhas de produção e alternativas',
    body: 'Cada linha de produção armazena um lado esquerdo e uma alternativa '
        'do lado direito. Use várias linhas para alternativas como S → aS e '
        'S → b. Preencha Lado esquerdo (variável) e Lado direito (produção), '
        'selecione Adicionar e use o menu da linha para Editar ou Excluir; '
        'Atualizar e Cancelar aparecem durante a edição. Regras de produção '
        'mostra as regras numeradas na ordem de origem. Um valor compacto como '
        'aA é separado em caracteres e espaços delimitam símbolos maiores; não '
        'digite a barra vertical como separador. Continue em Produções vazias.',
    keywords: ['Adicionar', 'Editar', 'Excluir', 'Atualizar', 'alternativa'],
  ),
  HelpTopicIds.grammarEditorProductionLambda: HelpNodeCopy(
    title: 'Produções vazias com λ e ε',
    body: 'Uma produção λ ou ε deriva a cadeia vazia. Use-a quando um não '
        'terminal puder desaparecer ou quando a gramática precisar aceitar a '
        'entrada vazia. Em Lado direito (produção), selecione Inserir λ ou '
        'Inserir ε, ou digite λ, ε ou lambda, e adicione a regra. O editor '
        'armazena o lado direito vazio e o exibe como ε. O marcador vazio deve '
        'ser o único símbolo do lado direito; misturá-lo com outro símbolo ou '
        'repeti-lo gera uma mensagem de validação. Continue em Validação de '
        'produções.',
    keywords: ['lambda', 'epsilon', 'Inserir λ', 'Inserir ε', 'cadeia vazia'],
  ),
  HelpTopicIds.grammarEditorProductionValidation: HelpNodeCopy(
    title: 'Validação e limpeza de produções',
    body:
        'A validação impede que linhas malformadas entrem na gramática. Use-a '
        'quando Adicionar ou Atualizar não funcionar ou uma análise apontar '
        'erros. Preencha os dois lados, coloque exatamente um símbolo à '
        'esquerda e ao menos um símbolo comum ou um único λ/ε à direita; use '
        'Limpar para remover todas as produções após confirmar. Mensagens junto '
        'aos campos indicam o lado inválido, e a confirmação de Limpar oferece '
        'Desfazer. O editor valida a forma da linha, não propriedades da '
        'linguagem, e a análise também exige gramática não vazia com símbolo '
        'inicial declarado. Continue no Fluxo de análise.',
    keywords: ['validação', 'Limpar', 'Desfazer', 'erro', 'forma da regra'],
  ),
  'grammar.editor.parser': HelpNodeCopy(
    title: 'Analisador de gramática',
    keywords: ['analisador', 'cadeia', 'Earley', 'CYK'],
  ),
  HelpTopicIds.grammarEditorParserWorkflow: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Analisar uma cadeia',
    body: 'O Analisador de gramática verifica se a gramática atual deriva uma '
        'Cadeia de teste. Use-o depois de criar ao menos uma produção e um '
        'Símbolo inicial válido. Abra Analisar, escolha um Algoritmo de análise '
        'disponível, informe somente símbolos do alfabeto terminal inferido e '
        'selecione Analisar cadeia; durante a execução, Analisando... desativa '
        'a ação. Resultados da análise informa Aceita ou Rejeitada, tempo de '
        'execução e detalhes da estratégia. Gramática vazia, símbolo inicial '
        'inválido, caracteres desconhecidos, limite de tempo ou erro geram '
        'mensagens; continue em Automatic (Earley) ou CYK.',
    keywords: ['Analisador', 'Cadeia de teste', 'Analisar cadeia', 'Aceita'],
  ),
  HelpTopicIds.grammarEditorParserAutomaticEarley: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Análise automática com Earley',
    body: 'Automatic (Earley) é a opção disponível de reconhecimento geral de '
        'GLC. Use-a quando a gramática não se adequar claramente a um método '
        'especializado ou quando a aceitação robusta importar mais que um '
        'traço CYK detalhado. Selecione Automatic (Earley), informe a cadeia e '
        'ative Analisar cadeia; gramáticas de parênteses balanceados podem usar '
        'um caminho rápido antes de Earley. O resultado informa a aceitação e '
        'pode incluir uma árvore de derivação reconstruída por melhor esforço. '
        'O reconhecimento tem limite de cinco segundos, e um resultado aceito '
        'pode não ter árvore. Continue em Resultados, árvores e passos CYK.',
    keywords: ['Automatic (Earley)', 'Earley', 'GLC', 'limite de tempo'],
  ),
  HelpTopicIds.grammarEditorParserBruteForce: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Análise por força bruta',
    body:
        'Brute force procura recursivamente uma derivação entre as produções. '
        'Use-a em exemplos didáticos pequenos, nos quais uma derivação simples '
        'seja mais útil que ampla cobertura de formas gramaticais. Selecione '
        'Brute force, informe uma Cadeia de teste curta e ative Analisar '
        'cadeia. Uma execução aceita pode produzir uma árvore rasa, enquanto '
        'uma busca esgotada informa Rejeitada. A estratégia recursiva é '
        'limitada, pode crescer rapidamente e compartilha o limite de cinco '
        'segundos; use Automatic (Earley) para reconhecimento geral ou '
        'continue em Derivações.',
    keywords: ['Brute force', 'força bruta', 'derivação', 'recursiva'],
  ),
  HelpTopicIds.grammarEditorParserCyk: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Análise CYK',
    body: 'CYK (Cocke-Younger-Kasami) reconhece a cadeia por uma tabela de '
        'programação dinâmica. Use-o para acompanhar o preenchimento '
        'determinístico da tabela ou estudar análise pela Forma Normal de '
        'Chomsky. Selecione CYK (Cocke-Younger-Kasami), informe Cadeia de '
        'teste e ative Analisar cadeia; o algoritmo converte internamente uma '
        'cópia para FNC sem alterar a gramática do editor. Resultados da análise '
        'mostra aceitação, tempo e uma sequência navegável de Passos CYK. '
        'Conversão ou análise pode falhar, e o limite de cinco segundos informa '
        'estouro de tempo. Continue em FNC ou Resultados e passos.',
    keywords: ['CYK', 'Cocke-Younger-Kasami', 'FNC', 'tabela', 'passos'],
  ),
  HelpTopicIds.grammarEditorParserLl1: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Analisador preditivo LL(1)',
    body: 'A análise LL(1) escolhe uma produção com o não terminal atual e um '
        'token de antecipação. Selecione LL(1), informe a Cadeia de teste e '
        'ative Analisar cadeia. O analisador constrói a tabela FIRST/FOLLOW, '
        'recusa a execução se houver conflito e registra cada expansão, '
        'correspondência terminal, aceitação ou erro. Passos LL(1) mostra pilha, '
        'entrada restante, antecipação e produção escolhida. A entrada é '
        'dividida nos terminais declarados pela correspondência mais longa; a '
        'ordem lexical desempata comprimentos iguais. Remova recursão à esquerda '
        'ou fatore a gramática quando necessário.',
    keywords: ['LL(1)', 'análise preditiva', 'antecipação', 'pilha', 'passos'],
  ),
  HelpTopicIds.grammarEditorParserLr: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Disponibilidade do analisador LR',
    body: 'LR é uma família de análise ascendente para gramáticas livres de '
        'contexto. Use este tópico para separar a teoria das opções atualmente '
        'executáveis. LR está indisponível porque o analisador não está '
        'implementado, então ele é filtrado do '
        'menu Algoritmo de análise. O espaço atual não gera autômato, tabela '
        'nem resultado LR. Construir tabela de análise produz hoje uma tabela '
        'LL(1), embora a descrição do botão mencione LR(1); continue em Análise '
        'preditiva ou Automatic (Earley).',
    keywords: ['LR', 'LR(1)', 'indisponível', 'ascendente', 'tabela'],
  ),
  HelpTopicIds.grammarEditorParserResultsAndSteps: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Resultados, árvores e passos do analisador',
    body: 'Resultados da análise explica o desfecho e qualquer estrutura '
        'registrada pelo analisador escolhido. Use-o para examinar por que uma '
        'entrada foi aceita ou até onde uma rejeição avançou. Leia Aceita ou '
        'Rejeitada e Tempo de execução; rejeições não CYK podem mostrar Posição '
        'mais distante, símbolos esperados e mensagem, enquanto Automatic '
        '(Earley) ou Brute force aceitos podem expandir Árvore de derivação. '
        'Passos CYK oferece anterior, próximo, controle deslizante, título, '
        'destaques da tabela e explicação do passo. Passos LL(1) usa a mesma '
        'navegação para mostrar pilha, entrada restante, antecipação e produção. '
        'Árvores são reconstruídas por melhor esforço; continue em Árvores de '
        'análise, CYK ou LL(1).',
    keywords: [
      'Resultados',
      'Árvore de derivação',
      'Passos CYK',
      'Passos LL(1)'
    ],
  ),
  'grammar.editor.algorithms': HelpNodeCopy(
    title: 'Análises e transformações',
    keywords: ['análise', 'transformação', 'FIRST', 'FOLLOW'],
  ),
  HelpTopicIds.grammarEditorAlgorithms: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Visão geral dos algoritmos de gramática',
    body: 'Análise da gramática transforma regras e calcula dados para análise '
        'preditiva. Use-a com uma gramática válida quando precisar de forma '
        'normal, reescrita estrutural, conjuntos, tabela ou verificação de '
        'conflitos LL(1). Escolha Converter para FNC, Converter para FNG, '
        'Remover recursão à esquerda, Fatorar à esquerda, Calcular conjuntos '
        'FIRST, Calcular conjuntos FOLLOW, Construir tabela de análise ou '
        'Verificar ambiguidade. O painel mostra texto e, em FNC/FNG, Passos de '
        'transformação cujo Aplicar substitui a gramática do editor pelo '
        'resultado daquele passo. As ações ficam indisponíveis durante uma '
        'análise, e gramáticas inválidas geram relatório. Abra o tópico do '
        'algoritmo escolhido.',
    keywords: ['Análise da gramática', 'forma normal', 'Aplicar', 'resultado'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsCnf: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Converter para Forma Normal de Chomsky',
    body: 'Converter para FNC reescreve uma GLC em Forma Normal de Chomsky. '
        'Use-o para estudar CYK ou obter regras A→BC e A→a, respeitada a '
        'exceção da cadeia vazia no símbolo inicial. Selecione Converter para '
        'FNC e examine Passos de transformação, Gramática original, Gramática '
        'transformada, observações, derivações e diagnósticos. Aplicar em um '
        'passo substitui a gramática atual pelo resultado intermediário. Erros '
        'de validação ou diagnósticos graves interrompem a operação; continue '
        'na teoria de FNC ou em CYK.',
    keywords: ['Converter para FNC', 'Chomsky', 'A BC', 'passos'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsGnf: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Converter para Forma Normal de Greibach',
    body: 'Converter para FNG reescreve produções para que o lado direito '
        'comece por um terminal seguido de não terminais. Use-o para estudar a '
        'Forma Normal de Greibach ou preparar a construção de AP por Greibach. '
        'Selecione Converter para FNG e examine histórico, gramáticas, '
        'observações, derivações e diagnósticos. Aplicar em um passo carrega no '
        'editor a gramática produzida ali. Entrada inválida ou diagnóstico '
        'grave faz a conversão falhar sem aplicar resultado parcial; continue '
        'na teoria de FNG ou em Convert Grammar to PDA (Greibach).',
    keywords: [
      'Converter para FNG',
      'Greibach',
      'terminal primeiro',
      'Aplicar'
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Remover recursão direta e indireta à esquerda',
    body: 'Remover recursão à esquerda trata regras diretas como A→Aα e ciclos '
        'indiretos como A→Bα, B→Aβ. O algoritmo processa primeiro o símbolo '
        'inicial, depois usa a ordem das produções e desempate lexical para '
        'substituições estáveis. Examine cada etapa de substituição e de '
        'recursão direta, incluindo os não terminais com linha. Aplicar carrega '
        'no editor a gramática daquela etapa. A ação exige gramática válida e '
        'não vazia, não fatora regras e não garante uma gramática LL(1).',
    keywords: [
      'Remover recursão à esquerda',
      'recursão direta',
      'recursão indireta',
      'substituição ordenada',
      'símbolo com linha'
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsLeftFactor: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Fatorar produções à esquerda',
    body: 'Fatorar à esquerda extrai prefixos comuns para novos não terminais. '
        'Use-o quando alternativas começam da mesma forma e o analisador '
        'preditivo não consegue escolher de imediato. Selecione Fatorar à '
        'esquerda e examine a Análise de fatoração à esquerda, com gramáticas '
        'original e transformada, observações e regras derivadas. O painel '
        'exibe o resultado, mas não o aplica automaticamente ao editor. Uma '
        'gramática válida não vazia é obrigatória, e fatorar não garante LL(1); '
        'continue em FIRST, FOLLOW e tabela.',
    keywords: ['Fatorar à esquerda', 'prefixo comum', 'LL(1)', 'reescrita'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsFirst: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Calcular conjuntos FIRST',
    body: 'FIRST(X) contém terminais que podem iniciar cadeias derivadas de X, '
        'inclusive ε quando X for anulável. Use-o para analisar escolhas '
        'preditivas e preparar uma tabela LL(1). Selecione Calcular conjuntos '
        'FIRST e leia cada FIRST(não terminal), as observações e as explicações '
        'de derivação no resultado. A gramática do editor não muda. Símbolos ou '
        'produções inválidos interrompem a análise, e FIRST isolado não resolve '
        'continuações anuláveis; continue em conjuntos FOLLOW.',
    keywords: ['Calcular conjuntos FIRST', 'FIRST', 'anulável', 'terminal'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsFollow: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Calcular conjuntos FOLLOW',
    body: 'FOLLOW(A) contém terminais que podem suceder A imediatamente, e \$ '
        'marca o fim da entrada para o símbolo inicial. Use-o após FIRST quando '
        'alternativas anuláveis ou a tabela LL(1) exigirem contexto. Selecione '
        'Calcular conjuntos FOLLOW e examine cada FOLLOW(não terminal), '
        'observações e explicações de derivação. A análise calcula FIRST '
        'internamente e não modifica a gramática. Uma gramática válida e um '
        'símbolo inicial declarado são obrigatórios; continue em Construir '
        'tabela de análise.',
    keywords: ['Calcular conjuntos FOLLOW', 'FOLLOW', 'fim', 'anulável'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsParseTable: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Construir tabela LL(1)',
    body: 'Construir tabela de análise monta a tabela preditiva LL(1) atual. '
        'Use-a depois de FIRST e FOLLOW para ver qual produção corresponde a '
        'um não terminal e um símbolo de antecipação. Selecione Construir '
        'tabela de análise e leia as linhas tabuladas, Observações, Conflitos e '
        'Derivações em Análise da tabela LL(1). Células vazias aparecem como -, '
        'regras ε usam FOLLOW e entradas múltiplas indicam conflito. Embora a '
        'descrição do botão cite LL(1) ou LR(1), o resultado atual é somente '
        'LL(1); continue em Verificar ambiguidade.',
    keywords: [
      'Construir tabela de análise',
      'LL(1)',
      'antecipação',
      'conflito'
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsAmbiguity: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Interpretar a verificação de ambiguidade',
    body:
        'Verificar ambiguidade é uma verificação didática de conflitos LL(1), '
        'não uma prova geral de ambiguidade. Use-a para classificar se a tabela '
        'preditiva atual tem entradas concorrentes. Selecione Verificar '
        'ambiguidade e leia Classificação LL(1), Observações, Conflitos e '
        'Derivações. Sem conflitos, o resultado é LL(1); com conflitos, é Não '
        'LL(1). Uma gramática não LL(1) ainda pode ser não ambígua e exigir LR '
        'ou Earley; continue na teoria de Ambiguidade e Árvores de análise.',
    keywords: ['Verificar ambiguidade', 'LL(1)', 'conflito', 'classificação'],
  ),
  'grammar.editor.conversions': HelpNodeCopy(
    title: 'Conversões',
    keywords: ['conversão', 'AF', 'AP', 'Greibach'],
  ),
  HelpTopicIds.grammarEditorConversionsRightLinearToFsa: HelpNodeCopy(
    title: 'Gramática linear à direita para AF',
    body: 'Convert Right-Linear Grammar to FSA cria um autômato finito '
        'equivalente. Use-o somente com regras A→aB, A→a ou A→ε. Adicione ao '
        'menos uma produção e selecione Convert Right-Linear Grammar to FSA em '
        'Conversões. Com sucesso, o autômato gerado é carregado e o aplicativo '
        'muda para o espaço AF. A ausência de produções ou qualquer conversão '
        'já em andamento desativa este controle. Um símbolo inicial inválido ou '
        'outra falha de conversão não desativa previamente uma gramática não '
        'vazia; a falha retorna como erro após o acionamento. Símbolos '
        'indefinidos e regras que não sejam lineares à direita são informados '
        'nesse momento, sem mudar de espaço. Continue em Relações entre '
        'gramáticas, AF e AP.',
    keywords: ['Convert Right-Linear Grammar to FSA', 'linear à direita', 'AF'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaGeneral: HelpNodeCopy(
    title: 'Gramática para AP: construção geral',
    body: 'Convert Grammar to PDA (General) cria um AP de três estados ao '
        'expandir variáveis na pilha. Use-o para obter um autômato que reconheça '
        'a linguagem da gramática. Adicione produções e selecione Convert '
        'Grammar to PDA (General). Com sucesso, o AP é carregado, o aplicativo '
        'muda para o espaço AP e informa a conversão geral concluída. A ausência '
        'de produções ou qualquer conversão já em andamento desativa este '
        'controle. Um símbolo inicial inválido ou outra falha de conversão não '
        'desativa previamente uma gramática não vazia; a falha retorna como '
        'erro após o acionamento. A conversão exige símbolo inicial não terminal '
        'e tem limite de dez segundos. Continue na teoria da relação com AP.',
    keywords: ['Convert Grammar to PDA (General)', 'pilha', 'GLC', 'AP'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaStandard: HelpNodeCopy(
    title: 'Gramática para AP: construção padrão',
    body: 'Convert Grammar to PDA (Standard) aplica a construção padrão de GLC '
        'para AP com pilha. Use-o quando quiser a rota explicitamente chamada '
        'padrão para compará-la aos outros controles. Adicione produções e '
        'selecione Convert Grammar to PDA (Standard). A implementação atual '
        'produz a mesma construção de três estados da opção General, carrega o '
        'AP e muda para esse espaço. A ausência de produções ou qualquer '
        'conversão já em andamento desativa este controle. Um símbolo inicial '
        'inválido ou outra falha de conversão não desativa previamente uma '
        'gramática não vazia; a falha retorna como erro após o acionamento. A '
        'conversão tem limite de dez segundos; continue em General ou Greibach.',
    keywords: ['Convert Grammar to PDA (Standard)', 'padrão', 'AP'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaGreibach: HelpNodeCopy(
    title: 'Gramática para AP pela forma de Greibach',
    body:
        'Convert Grammar to PDA (Greibach) converte primeiro a GLC para FNG e '
        'depois cria transições de produção que consomem entrada. Use-o para '
        'relacionar regras de Greibach à construção de um AP. Adicione '
        'produções e selecione Convert Grammar to PDA (Greibach). Com sucesso, '
        'um AP obtido da gramática em FNG é carregado e o aplicativo muda para '
        'o espaço AP. A ausência de produções ou qualquer conversão já em '
        'andamento desativa este controle. Um símbolo inicial inválido ou outra '
        'falha de conversão não desativa previamente uma gramática não vazia; '
        'a falha retorna como erro após o acionamento. Conversão FNG falha ou '
        'inválida e o limite de dez segundos também mantêm o espaço atual. '
        'Continue em Converter para FNG.',
    keywords: ['Convert Grammar to PDA (Greibach)', 'FNG', 'AP'],
  ),
  HelpTopicIds.grammarEditorFilesAndExamples: HelpNodeCopy(
    title: 'Arquivos e exemplos de gramática',
    body: 'As ações de arquivo preservam regras ou geram um diagrama '
        'compartilhável, e há cinco exemplos GLC incluídos. Abra Algoritmos e '
        'selecione GLC - Palíndromo, GLC - Parênteses balanceados, GLC - a^n '
        'b^n, GLC - Zeros em quantidade par ou GLC - Expressões aritméticas. '
        'A escolha substitui a gramática atual mesmo quando o editor está '
        'vazio. Use exemplos para estudar e arquivos para continuar sua própria '
        'gramática. Quando um host fornece o painel compatível com gramática, Load JFLAP '
        'fica disponível em todas as plataformas quando o painel está montado. '
        'Os rótulos de exportação mudam de Save as JFLAP e Export SVG nas '
        'plataformas nativas para Download JFLAP e Download SVG na Web; arquivos '
        'de gramática JFLAP usam extensão .cfg. Uma carga bem-sucedida substitui '
        'a gramática fornecida, exportações criam XML ou SVG e cancelar não a '
        'altera. XML malformado, elementos de gramática, início ou produção '
        'ausentes, dados inacessíveis e falhas de gravação exibem erro. Falhas '
        'de importação oferecem Retry com Cancel no diálogo ou Retry com '
        'Dismiss no banner; não existe ação Report. Continue na visão geral '
        'após carregar.',
    keywords: ['JFLAP', 'SVG', 'cfg', 'exemplos', 'erro de arquivo'],
  ),
  'grammar.theory': HelpNodeCopy(
    title: 'Teoria de gramáticas',
    keywords: ['teoria', 'GLC', 'derivação', 'forma normal'],
  ),
  HelpTopicIds.grammarTheoryCfg: HelpNodeCopy(
    title: 'Gramáticas livres de contexto',
    body: 'Uma gramática livre de contexto reúne terminais, não terminais, '
        'produções e símbolo inicial, com um não terminal no lado esquerdo de '
        'cada regra. Use GLCs para descrever linguagens aninhadas ou recursivas '
        'que podem não ser regulares. Defina variáveis e terminais, escolha S '
        'ou outro símbolo inicial e adicione cada produção no editor. A '
        'gramática denota todas as cadeias terminais deriváveis do símbolo '
        'inicial. A descrição não escolhe uma estratégia de análise nem prova '
        'que as regras não sejam ambíguas. Continue em Produções e derivações.',
    keywords: ['GLC', 'livre de contexto', 'terminal', 'não terminal'],
  ),
  HelpTopicIds.grammarTheoryProductions: HelpNodeCopy(
    title: 'Regras de produção',
    body: 'Uma produção A→α permite substituir o não terminal A pela sequência '
        'α. Use produções para codificar cada expansão permitida em uma '
        'derivação. Adicione uma linha do editor para cada alternativa e use ε '
        'para a sequência vazia. Em conjunto, as linhas definem a relação usada '
        'pelos analisadores e transformações. Uma linha do editor aceita '
        'exatamente um símbolo à esquerda, embora o modelo interno represente '
        'formas gramaticais mais amplas. Continue em Derivações.',
    keywords: ['produção', 'regra', 'alternativa', 'substituição'],
  ),
  HelpTopicIds.grammarTheoryDerivations: HelpNodeCopy(
    title: 'Derivações',
    body: 'Uma derivação aplica repetidamente produções a partir do símbolo '
        'inicial até alcançar uma cadeia terminal. Use-a para justificar '
        'pertinência e comparar como analisadores formam um resultado. Escolha '
        'um não terminal da forma sentencial atual, aplique uma alternativa '
        'correspondente e repita até não restar variável. Uma sequência '
        'bem-sucedida demonstra que a cadeia final pertence à linguagem. '
        'Ordens diferentes podem levar à mesma árvore ou a árvores realmente '
        'distintas. Continue em Árvores de análise e ambiguidade.',
    keywords: ['derivação', 'forma sentencial', 'pertinência', 'produção'],
  ),
  HelpTopicIds.grammarTheoryParseTrees: HelpNodeCopy(
    title: 'Árvores de análise',
    body: 'Uma árvore de análise coloca o símbolo inicial na raiz, os símbolos '
        'das produções sob não terminais expandidos e a cadeia derivada nas '
        'folhas. Use-a para enxergar a estrutura gramatical, não apenas a '
        'aceitação. Execute Automatic (Earley) ou Brute force e expanda Árvore '
        'de derivação quando a reconstrução por melhor esforço existir; CYK '
        'mostra os passos da tabela no painel atual. Ler as folhas da esquerda '
        'para a direita produz a entrada. A ausência de árvore exibida não '
        'invalida um resultado Earley aceito, e árvores rasas podem omitir '
        'intervalos detalhados. Continue em Ambiguidade.',
    keywords: ['árvore de análise', 'Árvore de derivação', 'raiz', 'folhas'],
  ),
  HelpTopicIds.grammarTheoryAmbiguity: HelpNodeCopy(
    title: 'Ambiguidade',
    body: 'Uma gramática é ambígua quando ao menos uma cadeia possui duas '
        'árvores de análise distintas. Use o conceito quando estruturas '
        'alternativas alterarem a interpretação ou a escolha do analisador. '
        'Compare derivações e árvores da mesma entrada e use Verificar '
        'ambiguidade somente como indicador de conflitos LL(1). Duas árvores '
        'distintas provam ambiguidade. Um conflito LL(1) prova apenas que a '
        'gramática não é LL(1), não que ela seja ambígua. Continue em Recursão '
        'e fatoração ou nos resultados do analisador.',
    keywords: ['ambiguidade', 'duas árvores', 'conflito LL(1)'],
  ),
  HelpTopicIds.grammarTheoryLeftRecursionAndFactoring: HelpNodeCopy(
    title: 'Recursão à esquerda e fatoração',
    body: 'Recursão direta à esquerda começa uma alternativa com o próprio não '
        'terminal. A recursão indireta retorna por um ou mais não terminais. '
        'Remover recursão à esquerda usa substituição ordenada e reescrita de '
        'recursão direta nos dois casos. Fatorar à esquerda extrai um prefixo '
        'comum. Examine as novas variáveis e as etapas da transformação. As '
        'duas reescritas preservam a linguagem pretendida, mas nenhuma garante '
        'LL(1). Continue em FIRST e FOLLOW.',
    keywords: [
      'recursão à esquerda',
      'fatoração',
      'prefixo comum',
      'reescrita'
    ],
  ),
  HelpTopicIds.grammarTheoryFirstAndFollow: HelpNodeCopy(
    title: 'FIRST e FOLLOW',
    body: 'FIRST prevê quais terminais podem iniciar uma derivação, enquanto '
        'FOLLOW prevê quais terminais podem aparecer após um não terminal. Use '
        'os dois para construir e diagnosticar uma tabela preditiva. Calcule '
        'FIRST de cada símbolo e sequência, propague ε pelos prefixos anuláveis '
        'e então calcule FOLLOW a partir do marcador de fim do símbolo inicial '
        'e dos contextos das produções. Os conjuntos determinam células de '
        'regras comuns e vazias. Esquecer a propagação de anuláveis gera '
        'escolhas incorretas. Continue em Análise preditiva e tabelas LL(1).',
    keywords: ['FIRST', 'FOLLOW', 'anulável', 'preditiva'],
  ),
  HelpTopicIds.grammarTheoryPredictiveParsing: HelpNodeCopy(
    title: 'Análise preditiva e tabelas LL(1)',
    body: 'Um analisador LL(1) escolhe uma produção com um não terminal e um '
        'símbolo de antecipação. Use a tabela para identificar escolhas '
        'descendentes determinísticas. O Turing Lab também executa essa tabela '
        'na estratégia LL(1) e para antes da análise se uma célula tiver '
        'conflito. Calcule conjuntos FIRST e FOLLOW, selecione Construir '
        'tabela de análise e examine cada linha e coluna terminal. Uma célula '
        'com uma produção define a escolha; várias produções formam conflito. '
        'Remover recursão ou fatorar pode ajudar, mas não garante sucesso, e a '
        'tabela atual não é LR(1). Continue no tópico Construir tabela.',
    keywords: ['análise preditiva', 'LL(1)', 'antecipação', 'tabela'],
  ),
  HelpTopicIds.grammarTheoryCnf: HelpNodeCopy(
    title: 'Forma Normal de Chomsky',
    body: 'A Forma Normal de Chomsky restringe regras comuns de GLC a A→BC ou '
        'A→a, com exceção controlada de ε no símbolo inicial. Use FNC no CYK e '
        'para raciocinar sobre derivações binárias. Execute Converter para FNC '
        'e examine cada passo antes de aplicar um resultado. A gramática '
        'convertida preserva a linguagem conforme o tratamento documentado da '
        'cadeia vazia. Símbolos auxiliares e mais regras são esperados, e '
        'diagnósticos podem impedir uma conversão insegura. Continue em Análise '
        'CYK.',
    keywords: ['FNC', 'Forma Normal de Chomsky', 'A BC', 'CYK'],
  ),
  HelpTopicIds.grammarTheoryGnf: HelpNodeCopy(
    title: 'Forma Normal de Greibach',
    body: 'A Forma Normal de Greibach faz cada produção comum começar por um '
        'terminal seguido de zero ou mais não terminais. Use FNG para relacionar '
        'passos de derivação ao consumo de entrada e preparar a conversão de '
        'Greibach para AP. Execute Converter para FNG, examine diagnósticos e '
        'passos e aplique apenas o resultado desejado. Em um resultado válido, '
        'cada lado direito aplicável começa por terminal. A conversão pode '
        'introduzir símbolos ou falhar em estruturas não suportadas. Continue '
        'em Convert Grammar to PDA (Greibach).',
    keywords: ['FNG', 'Forma Normal de Greibach', 'terminal primeiro', 'AP'],
  ),
  HelpTopicIds.grammarTheoryGrammarFsaPda: HelpNodeCopy(
    title: 'Relações entre gramáticas, AF e AP',
    body: 'Gramáticas lineares à direita e autômatos finitos descrevem '
        'linguagens regulares, enquanto GLCs e APs descrevem linguagens livres '
        'de contexto. Use essas relações para escolher uma conversão sem perder '
        'estrutura expressiva. Converta uma gramática linear à direita para AF '
        'ou use as construções General, Standard ou Greibach de gramática para '
        'AP em uma GLC válida. Com sucesso, o espaço de destino abre o modelo '
        'gerado. Uma GLC geral nem sempre pode virar AF, e cada conversor exige '
        'sua própria forma estrutural. Continue no tópico da conversão escolhida.',
    keywords: ['gramática', 'AF', 'AP', 'regular', 'livre de contexto'],
  ),
  'pda': HelpNodeCopy(
    title: 'Autômatos de pilha',
    keywords: ['AP', 'PDA', 'autômato de pilha', 'livre de contexto'],
  ),
  'pda.editor': HelpNodeCopy(
    title: 'Editor e canvas',
    keywords: ['AP', 'PDA', 'editor', 'canvas', 'simulação'],
  ),
  HelpTopicIds.pdaEditorOverview: HelpNodeCopy(
    title: 'Visão geral do editor de AP',
    body: 'O espaço de AP reúne canvas de estados, inspetor da pilha ao vivo, '
        'simulação, análises, exemplos e exportação SVG. Use-o para construir '
        'ou examinar um autômato de pilha determinístico ou não determinístico. '
        'Adicione estados, marque os estados inicial e de aceitação, conecte-os '
        'com transições de entrada/pop/push e teste uma cadeia. O status do '
        'canvas informa quantidades, marcadores ausentes, uso de lambda e '
        'conflitos detectados. A simulação exige estado inicial, e certas '
        'análises também exigem aceitação ou transições normalizadas; siga a '
        'mensagem visível antes de confiar em uma AP parcial. Continue em '
        'Selecionar e editar estados ou Fluxo de simulação.',
    keywords: ['AP', 'PDA', 'espaço', 'editor', 'pilha'],
  ),
  'pda.editor.editing': HelpNodeCopy(
    title: 'Editar uma AP',
    keywords: ['AP', 'PDA', 'editar', 'estado', 'transição', 'lambda'],
  ),
  HelpTopicIds.pdaEditorSelectionAndStates: HelpNodeCopy(
    title: 'Selecionar e editar estados',
    body: 'O modo Selecionar permite mover e abrir estados da AP no canvas. '
        'Use-o depois de criar um estado ou quando Adicionar transição estiver '
        'ativo. Escolha Adicionar estado, volte a Selecionar, arraste o estado '
        'para movê-lo e dê dois toques para editar Rótulo do estado, Estado '
        'inicial, Estado de aceitação ou Excluir estado. Salvar atualiza os '
        'marcadores e arestas conectadas; excluir remove também as transições '
        'do estado. O editor mantém no máximo um estado inicial, e a simulação '
        'por estado final ainda depende dos marcadores corretos. Continue em '
        'Adicionar e editar transições de AP.',
    keywords: ['AP', 'PDA', 'Selecionar', 'estado inicial', 'aceitação'],
  ),
  HelpTopicIds.pdaEditorTransitions: HelpNodeCopy(
    title: 'Adicionar e editar transições de AP',
    body:
        'Uma transição de AP combina um símbolo de entrada, um símbolo de pop '
        'e um símbolo de push em uma aresta direcionada. Use-a para definir '
        'quando a máquina pode avançar e como a pilha muda. Escolha Adicionar '
        'transição, selecione origem e destino, preencha Símbolo de entrada, '
        'Símbolo para desempilhar e Símbolo para empilhar e salve; selecione '
        'uma aresta existente para editar ou excluir. O canvas mostra o rótulo '
        'canônico entrada, pop/push e atualiza os alfabetos. Todo campo sem '
        'lambda é obrigatório, e um push alterado com vários caracteres vira '
        'uma sequência ordenada de caracteres. Continue em Entrada, pop e push '
        'lambda.',
    keywords: [
      'AP',
      'PDA',
      'símbolo de entrada',
      'símbolo de pop',
      'símbolo de push'
    ],
  ),
  HelpTopicIds.pdaEditorLambdaSwitches: HelpNodeCopy(
    title: 'Entrada, pop e push lambda',
    body: 'As três chaves lambda tornam vazia, de forma independente, a parte '
        'de entrada, pop ou push de uma transição de AP. Use λ-entrada para não '
        'consumir entrada, λ-desempilhar para não testar nem remover o topo e '
        'λ-empilhar para não adicionar símbolo. Ative λ-entrada, '
        'λ-desempilhar ou λ-empilhar ao lado do campo e salve a transição. O '
        'campo desativado é limpo e a aresta mostra λ nessa posição. Deixar '
        'vazio um campo sem lambda impede salvar, enquanto movimentos lambda '
        'podem criar ramificações ou ciclos sujeitos aos limites de busca. '
        'Continue em Transições de AP ou Não determinismo.',
    keywords: [
      'AP',
      'PDA',
      'lambda',
      'epsilon',
      'λ-entrada',
      'λ-pop',
      'λ-push'
    ],
  ),
  HelpTopicIds.pdaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Desfazer, refazer e limpar',
    body: 'Os controles de histórico revertem ou restauram edições registradas '
        'da AP, enquanto Limpar canvas remove o grafo atual. Use Desfazer após '
        'uma alteração indesejada, Refazer ao voltar demais e Limpar canvas '
        'somente para recomeçar. Acione os controles da barra; a superfície '
        'móvel oferece as mesmas ações quando disponíveis. Desfazer e Refazer '
        'restauram o grafo da AP e atualizam a validação. Uma edição do modelo '
        'durante a reprodução no canvas encerra essa reprodução. A pilha '
        'exibida não faz parte do histórico de Desfazer ou Refazer e pode '
        'permanecer como o instantâneo anterior após o fim da reprodução. '
        'Somente Limpar canvas encerra explicitamente a reprodução e limpa a '
        'pilha exibida junto com o grafo. Desfazer e Refazer ficam inativos sem '
        'histórico naquela direção, e limpar o inspetor da pilha não limpa a '
        'AP. Continue em Arquivos e exemplos antes de substituir trabalho '
        'importante.',
    keywords: ['AP', 'PDA', 'Desfazer', 'Refazer', 'Limpar canvas'],
  ),
  'pda.editor.viewport': HelpNodeCopy(
    title: 'Visualização do canvas',
    keywords: ['AP', 'PDA', 'viewport', 'zoom', 'enquadrar'],
  ),
  HelpTopicIds.pdaEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom e deslocamento',
    body: 'Zoom e deslocamento mudam a visualização da AP sem alterar o '
        'autômato. Use-os para examinar estados e rótulos de transição '
        'densamente agrupados. Selecione Aumentar zoom ou Diminuir zoom, faça '
        'pinça com dois dedos em telas de toque e arraste uma área vazia para '
        'deslocar. O grafo preserva estados, arestas, linguagem e posições '
        'armazenadas enquanto escala ou deslocamento mudam. Arrastar com um '
        'dedo a partir de um estado move esse estado no modo Selecionar, e o '
        'zoom respeita os limites de escala do canvas. Continue em Enquadrar '
        'conteúdo e Redefinir visualização.',
    keywords: ['AP', 'PDA', 'zoom', 'deslocar', 'pinça'],
  ),
  HelpTopicIds.pdaEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Enquadrar conteúdo e redefinir visualização',
    body: 'Enquadrar conteúdo coloca todos os estados da AP na área visível, '
        'enquanto Redefinir visualização restaura zoom e deslocamento padrão. '
        'Use Enquadrar conteúdo quando nós saírem da tela e Redefinir '
        'visualização para voltar ao viewport neutro. Acione o comando '
        'correspondente na barra do canvas em desktop ou celular. Apenas a '
        'vista muda; coordenadas, transições e comportamento da pilha '
        'permanecem. Um canvas vazio não tem conteúdo para enquadrar, e nenhum '
        'dos comandos separa estados sobrepostos. Continue em Disponibilidade '
        'de Auto Layout ou Selecionar e editar estados.',
    keywords: ['AP', 'PDA', 'Enquadrar conteúdo', 'Redefinir visualização'],
  ),
  HelpTopicIds.pdaEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Disponibilidade de Auto Layout',
    body: 'Auto Layout reorganizaria as coordenadas dos estados sem mudar o '
        'comportamento da AP. Procure-o quando um grafo carregado estiver '
        'difícil de ler, mas o espaço de AP atual não expõe Auto Layout no '
        'canvas nem nas análises. Use Selecionar para arrastar estados '
        'manualmente e depois Enquadrar conteúdo. O movimento manual atualiza '
        'as arestas visíveis e preserva regras e linguagem. Não há resultado '
        'de Auto Layout de AP para aplicar nesta tela; suporte de layout com '
        'nome semelhante em outras áreas não é um comando oculto. Continue em '
        'Zoom e deslocamento ou Selecionar e editar estados.',
    keywords: ['AP', 'PDA', 'Auto Layout', 'indisponível', 'layout manual'],
  ),
  'pda.editor.stack': HelpNodeCopy(
    title: 'Pilha',
    keywords: ['AP', 'PDA', 'pilha', 'inspetor', 'alfabeto'],
  ),
  HelpTopicIds.pdaEditorStackInspector: HelpNodeCopy(
    title: 'Usar o inspetor da pilha',
    body: 'O inspetor da pilha é a visualização compacta da pilha da AP ao '
        'vivo. Use-o ao editar transições ou reproduzir traços para ver topo, '
        'tamanho, última operação e célula destacada. No desktop ele fica '
        'abaixo do canvas; no celular, mova ou redimensione o painel flutuante '
        'Pilha, toque numa célula para alternar destaque ou deslize à direita '
        'para destacar e à esquerda para remover. O painel mostra o topo '
        'primeiro e anima push e pop. Limpar esvazia apenas essa pilha exibida, '
        'não a definição da AP, e o painel vazio ocioso mostra o marcador '
        'inicial. Continue em Símbolo inicial e alfabeto da pilha.',
    keywords: ['AP', 'PDA', 'inspetor da pilha', 'celular', 'topo'],
  ),
  HelpTopicIds.pdaEditorStackInitialSymbolAndAlphabet: HelpNodeCopy(
    title: 'Símbolo inicial e alfabeto da pilha',
    body: 'O símbolo inicial da pilha é o marcador de base colocado no começo '
        'da execução, e o alfabeto da pilha reúne símbolos usados por pop e '
        'push. Use-os para manter coerentes as regras de transição. O modelo do '
        'canvas começa com Z, deriva outros símbolos dos campos de transição e '
        'permite preencher Símbolo inicial da pilha no painel de simulação. A '
        'execução inicia a pilha atual com esse valor e o acrescenta a uma '
        'cópia do alfabeto usada só na simulação. A tela não tem editor separado '
        'do alfabeto, e mudar esse campo não reescreve a AP do editor. Continue '
        'em Prévia da operação ou Teoria da pilha.',
    keywords: ['AP', 'PDA', 'símbolo inicial da pilha', 'alfabeto', 'Z'],
  ),
  HelpTopicIds.pdaEditorStackOperationPreview: HelpNodeCopy(
    title: 'Visualizar operações da pilha',
    body: 'A Prévia da operação ilustra o efeito na pilha da transição de AP '
        'em edição. Use-a antes de salvar uma regra de pop/push cuja ordem seja '
        'difícil de visualizar. Preencha entrada, pop e push ou suas chaves '
        'lambda e examine Entrada, Pop, Push e Resultado abaixo dos campos. Um '
        'pop não lambda remove o topo exibido, e um push com vários caracteres '
        'é empilhado da direita para a esquerda para deixar o primeiro '
        'caractere no topo; a prévia mostra no máximo cinco células. Ela é '
        'ilustrativa e não verifica se o símbolo de pop pedido coincide com o '
        'topo atual; a simulação faz essa verificação. Continue em Adicionar e '
        'editar transições de AP.',
    keywords: ['AP', 'PDA', 'Prévia da operação', 'pop', 'push', 'ordem'],
  ),
  'pda.editor.simulation': HelpNodeCopy(
    title: 'Simulação',
    keywords: ['AP', 'PDA', 'simulação', 'entrada', 'traço'],
  ),
  HelpTopicIds.pdaEditorSimulation: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Executar ou cancelar uma simulação de AP',
    body: 'A Simulação de AP busca no autômato atual um caminho que aceite uma '
        'entrada. Use-a depois de definir o grafo e sempre que quiser testar '
        'pertinência à linguagem. Preencha Cadeia de entrada, deixe-a vazia '
        'para ε, informe um Símbolo inicial da pilha não vazio, escolha '
        'Registrar traço passo a passo e selecione Simular AP; durante a '
        'execução, o botão permite cancelar. O painel inicializa a pilha e '
        'informa resultado ou Simulação cancelada. O fluxo atual aceita apenas '
        'após consumir toda a entrada em estado de aceitação, preserva espaços '
        'e para após cinco segundos ou limites de busca. Continue em Traço, '
        'pilha atual e entrada restante.',
    keywords: ['AP', 'PDA', 'Simular AP', 'cancelar', 'cadeia vazia'],
  ),
  HelpTopicIds.pdaEditorSimulationTraceAndStack: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Traço, pilha atual e entrada restante',
    body: 'O traço registra configurações da AP para examinar estado, pilha '
        'atual, entrada restante e transição usada em cada passo. Use-o para '
        'explicar um caminho aceito ou descobrir onde todas as ramificações '
        'param. Ative Registrar traço passo a passo antes de Simular AP e '
        'selecione uma linha, mova a linha do tempo ou use Passo anterior, '
        'Reproduzir, Pausar, Próximo passo e Reiniciar. A configuração '
        'selecionada atualiza destaques e o inspetor. Sem gravação detalhada, '
        'só o instantâneo final é mantido, e o texto concatenado da pilha não '
        'separa símbolos atômicos importados com vários caracteres. Continue '
        'em Resultados e reprodução no canvas.',
    keywords: ['AP', 'PDA', 'traço', 'pilha atual', 'entrada restante'],
  ),
  HelpTopicIds.pdaEditorSimulationResultsAndCanvas: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Ler resultados e reproduzir no canvas',
    body: 'Resultados da simulação resume se a execução da AP foi Aceita, '
        'Rejeitada, cancelada, encerrada por tempo ou falhou de outra forma. '
        'Use-o para confirmar a pertinência e reproduzir um traço registrado. '
        'Leia status, tempo e erro; com Registrar traço passo a passo ativo, '
        'Visualizar no Canvas aparece somente em layout estreito no iOS com '
        'menos de 1.024 pixels lógicos e abre controles anterior, '
        'reproduzir/pausar, próximo, palavra de entrada e fechar sobre o canvas. '
        'A reprodução projeta '
        'estado, transição, progresso da entrada e pilha. Outras plataformas '
        'mantêm os controles no painel, e fechar a reprodução limpa destaques '
        'sem editar a AP. Continue em Critérios de aceitação.',
    keywords: ['AP', 'PDA', 'Aceita', 'Rejeitada', 'Visualizar no Canvas'],
  ),
  'pda.editor.algorithms': HelpNodeCopy(
    title: 'Algoritmos',
    keywords: ['AP', 'PDA', 'algoritmos', 'análise', 'conversão'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Visão geral dos algoritmos de AP',
    body: 'Análise de AP reúne seis controles de conversão, simplificação e '
        'diagnóstico. Use-a depois de desenhar ou carregar uma AP quando uma '
        'simulação não basta. Selecione Converter para GLC, Simplificar AP, '
        'Verificar determinismo, Encontrar estados alcançáveis, Análise da '
        'linguagem ou Operações da pilha. O painel desativa todos durante uma '
        'análise e substitui o cartão pelo texto ou gramática gerada. Os botões '
        'continuam ativos sem AP e então informam esse pré-requisito, enquanto '
        'cada algoritmo pode exigir estrutura adicional. Continue no tópico '
        'do controle que pretende usar.',
    keywords: ['AP', 'PDA', 'Análise de AP', 'seis controles'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsToCfg: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Converter uma AP para GLC',
    body:
        'Converter para GLC constrói uma gramática livre de contexto a partir '
        'da AP atual. Use-o para estudar ou reaproveitar a mesma linguagem em '
        'forma de produções. Selecione Converter para GLC e examine símbolo '
        'inicial, não terminais, terminais, produções e descrição no cartão de '
        'resultado. Variáveis [p,A,q] representam uma obrigação de pilha entre '
        'estados. A AP precisa de estados, estado inicial, ao menos um estado '
        'de aceitação e cada transição deve desempilhar exatamente um símbolo '
        'não lambda; falhas não mudam a AP. A gramática aparece no painel sem '
        'abrir o editor de Gramática. Continue em AP e GLC.',
    keywords: ['AP', 'PDA', 'Converter para GLC', 'gramática', '[p,A,q]'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsMinimize: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Simplificar uma AP com segurança',
    body: 'Simplificar AP aplica reduções que preservam o modo de aceitação '
        'ativo. Remove estados de controle estruturalmente inalcançáveis, '
        'calcula o quociente de bissimulação forte até um ponto fixo e elimina '
        'transições exatamente duplicadas. A utilidade semântica exata ainda é '
        'ignorada; estados cuja utilidade com pilha é incerta são mantidos e a '
        'prévia exibe esse aviso. Aceitação por estado final e combinada exigem '
        'estado final, mas aceitação por pilha vazia não; o modo combinado '
        'continua significando estado final E pilha vazia. Revise modo, '
        'contagens e motivos; depois cancele sem alterações ou aplique como uma '
        'única operação desfazível. O simplificador conservador não calcula nem '
        'afirma produzir uma APND globalmente mínima. Continue em Encontrar '
        'estados alcançáveis.',
    keywords: [
      'AP',
      'PDA',
      'Simplificar AP',
      'bissimulação forte',
      'modo de aceitação',
    ],
  ),
  HelpTopicIds.pdaEditorAlgorithmsDeterminism: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Verificar determinismo',
    body: 'Verificar determinismo informa conflitos de transição detectados '
        'pelo editor da AP. Use-o para localizar ramificações com a mesma '
        'origem, condição de entrada e condição de pop. Selecione Verificar '
        'determinismo e examine o resultado determinístico ou NÃO '
        'determinístico, rótulos conflitantes, destaques, total de transições e '
        'quantidade lambda. O modelo não muda. A verificação atual agrupa '
        'chaves exatas origem/entrada/pop; não é um teste formal completo de '
        'AP determinística para toda interação entre entrada lambda e '
        'movimentos consumidores. Basta existir uma AP; aceitação não é exigida '
        'para o relatório. Continue em Não determinismo.',
    keywords: ['AP', 'PDA', 'Verificar determinismo', 'conflito', 'lambda'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsReachableStates: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Encontrar estados alcançáveis',
    body: 'Encontrar estados alcançáveis classifica estados da AP pela '
        'alcançabilidade no grafo desde o estado inicial. Use-o para localizar '
        'trechos desconectados antes de simplificar. Selecione Encontrar '
        'estados alcançáveis e leia o estado inicial e os conjuntos ordenados '
        'de alcançáveis e inalcançáveis; os alcançáveis também ficam destacados '
        'no canvas. O comando não altera a AP. Ele exige estado inicial e segue '
        'arestas dentro do limite de comprimento de entrada sem provar que '
        'cada caminho possui configuração viável da pilha; a análise é '
        'estrutural. Continue em Simplificar AP ou Operações da pilha.',
    keywords: ['AP', 'PDA', 'Encontrar estados alcançáveis', 'inalcançável'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsLanguage: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Analisar a linguagem',
    body: 'Análise da linguagem fornece uma amostra limitada da linguagem '
        'reconhecida pela AP. Use-a para conferir rapidamente alfabeto de '
        'entrada, símbolos da pilha, aceitação e exemplos curtos. Selecione '
        'Análise da linguagem e examine até dez cadeias aceitas e dez rejeitadas '
        'de comprimento máximo três, além do resumo de determinismo. O painel '
        'retorna conjuntos ou avisos sem alterar a AP. É necessário estado '
        'inicial, cada amostra usa aceitação por estado final, e não aparecer '
        'nessa busca limitada não prova nada sobre a linguagem completa, '
        'possivelmente infinita. Continue em Linguagens livres de contexto ou '
        'execute uma simulação específica.',
    keywords: ['AP', 'PDA', 'Análise da linguagem', 'amostra', 'cadeias'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsStackOperations: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Analisar operações da pilha',
    body: 'Operações da pilha resume os rótulos de pilha usados pelas '
        'transições da AP. Use-o para auditar quais regras fazem push, pop ou '
        'mencionam símbolos da pilha. Selecione Operações da pilha e examine '
        'símbolo inicial, operações únicas de push e pop, símbolos tocados e '
        'quantidades de transições de AP e AF. O relatório é textual e não '
        'muda o modelo. É necessária uma AP com estado inicial; a saída atual '
        'trata cada cadeia de push armazenada como uma operação e não calcula '
        'profundidade máxima da pilha em execução, apesar da descrição do '
        'botão. Continue em Teoria da pilha ou edição de transições.',
    keywords: ['AP', 'PDA', 'Operações da pilha', 'push', 'pop'],
  ),
  HelpTopicIds.pdaEditorFilesAndExamples: HelpNodeCopy(
    title: 'Arquivos, SVG e exemplos de AP',
    body: 'As áreas de exemplos e arquivos fornecem APs prontas e uma '
        'exportação visual do grafo atual. Use os exemplos visíveis APD - '
        'Parênteses Balanceados, APD - a^n b^n, APD - Palíndromo, APD - a^n '
        'b^2n ou APD - w#reverse(w) para explorar padrões da pilha, e use SVG '
        'para compartilhar o diagrama. Abra Algoritmos e selecione um exemplo; '
        'quando existir uma AP, escolha '
        'Export SVG em plataformas nativas ou Download SVG na Web. O exemplo '
        'substitui o modelo, enquanto a exportação cria uma imagem e informa '
        'sucesso ou erro. O painel atual não oferece ações de importar ou '
        'salvar AP em JFLAP ou JSON, e SVG não é AP editável; cancelar a '
        'exportação nativa não cria arquivo. Continue na visão geral.',
    keywords: ['AP', 'PDA', 'exemplos', 'SVG', 'Export SVG', 'Download SVG'],
  ),
  'pda.theory': HelpNodeCopy(
    title: 'Teoria',
    keywords: ['AP', 'PDA', 'teoria', 'pilha', 'aceitação'],
  ),
  HelpTopicIds.pdaTheoryPda: HelpNodeCopy(
    title: 'Autômatos de pilha',
    body: 'Um autômato de pilha é uma máquina de estados finitos ampliada por '
        'uma pilha ilimitada de último a entrar, primeiro a sair. Use uma AP '
        'quando memória finita não bastar para aninhamento ou contagens '
        'correspondentes de uma linguagem livre de contexto. Defina estados, '
        'alfabetos de entrada e pilha, estado e símbolo inicial, estados de '
        'aceitação e transições entrada/pop/push. Uma execução segue uma '
        'configuração válida e atualiza estado, entrada restante e pilha. O '
        'modelo matemático pode ter infinitas configurações, embora editor e '
        'simulador imponham tempo e busca finitos. Continue em Memória de pilha '
        'ou Transições de AP.',
    keywords: ['AP', 'PDA', 'autômato de pilha', 'modelo formal'],
  ),
  HelpTopicIds.pdaTheoryStack: HelpNodeCopy(
    title: 'Memória de pilha',
    body: 'A pilha de uma AP é memória LIFO cujo topo controla quais '
        'transições de pop estão disponíveis. Use-a para lembrar aberturas '
        'aninhadas, contagens ou um prefixo escolhido até chegar a entrada '
        'correspondente. Comece pelo símbolo inicial, teste e opcionalmente '
        'remova o topo com pop e acrescente zero ou mais símbolos com push. A '
        'pilha resultante integra a próxima configuração. Só o topo pode ser '
        'removido diretamente, a ordem de push importa e um pop impossível '
        'inviabiliza aquele caminho em vez de produzir resultado arbitrário. '
        'Continue em Transições de AP ou no inspetor da pilha.',
    keywords: ['AP', 'PDA', 'pilha', 'LIFO', 'topo', 'símbolo inicial'],
  ),
  HelpTopicIds.pdaTheoryTransitions: HelpNodeCopy(
    title: 'Transições de AP',
    body: 'Uma transição de AP leva estado, entrada opcional e teste opcional '
        'do topo a um novo estado e substituição da pilha. Use-a para codificar '
        'um passo legal da computação. No editor, escolha origem e destino, '
        'defina símbolo de entrada, símbolo de pop e símbolo de push e use as '
        'três chaves lambda para ações omitidas. Um movimento correspondente '
        'consome sua entrada, remove o topo exigido e empilha a substituição '
        'ordenada. Ele não ocorre se entrada ou pop não lambda não coincidir, '
        'e vários movimentos disponíveis introduzem não determinismo. Continue '
        'em Chaves lambda ou Não determinismo.',
    keywords: ['AP', 'PDA', 'transição', 'entrada', 'pop', 'push'],
  ),
  HelpTopicIds.pdaTheoryAcceptance: HelpNodeCopy(
    title: 'Critérios de aceitação',
    body: 'Aceitação define quais configurações completas da AP colocam uma '
        'entrada na linguagem. Use o critério escolhido pela ferramenta ao '
        'comparar uma construção manual com a simulação. A tela de AP atual '
        'começa no estado e símbolo inicial e busca até consumir toda a entrada '
        'em um estado de aceitação. Aceita significa que existe ao menos um '
        'caminho assim; Rejeitada indica que nenhum foi encontrado numa busca '
        'concluída. Os critérios por pilha vazia e combinado existem no núcleo, '
        'mas não podem ser selecionados nesta tela, e timeout ou limite de '
        'busca não provam rejeição matemática. Continue em Fluxo de simulação.',
    keywords: ['AP', 'PDA', 'aceitação', 'estado final', 'pilha vazia'],
  ),
  HelpTopicIds.pdaTheoryNondeterminism: HelpNodeCopy(
    title: 'Não determinismo em APs',
    body: 'Uma AP não determinística pode ter vários movimentos aplicáveis à '
        'mesma configuração, inclusive sem consumir entrada. Use ramificações '
        'quando a máquina precisar adivinhar um ponto de divisão ou estratégia '
        'de pilha, como ao reconhecer palíndromos. Crie regras entrada/pop '
        'concorrentes ou caminhos lambda e simule; a busca percorre '
        'configurações até uma aceitar ou as alternativas limitadas acabarem. '
        'Um único ramo aceito basta. Ciclos e ramificações podem atingir cinco '
        'segundos, profundidade 1.000 ou 100.000 configurações, e Verificar '
        'determinismo é um diagnóstico mais estreito. Continue nesse comando '
        'ou em Linguagens livres de contexto.',
    keywords: ['AP', 'PDA', 'não determinismo', 'ramificação', 'lambda'],
  ),
  HelpTopicIds.pdaTheoryContextFreeLanguages: HelpNodeCopy(
    title: 'Linguagens livres de contexto',
    body: 'Linguagens livres de contexto são exatamente as reconhecidas por '
        'APs não determinísticas nas equivalências usuais. Use essa classe para '
        'estruturas aninhadas ou recursivamente balanceadas, como parênteses e '
        'a^n b^n. Construa regras da pilha ou derive uma GLC e teste cadeias '
        'positivas e negativas representativas. A AP ou gramática descreve '
        'linguagem ilimitada, embora Análise da linguagem amostre apenas '
        'comprimento máximo três. APs determinísticas reconhecem um subconjunto '
        'próprio dessa classe, e uma amostra limitada não estabelece '
        'equivalência. Continue em AP e GLC ou nos exemplos incluídos.',
    keywords: [
      'AP',
      'PDA',
      'linguagem livre de contexto',
      'GLC',
      'aninhamento'
    ],
  ),
  HelpTopicIds.pdaTheoryPdaAndCfg: HelpNodeCopy(
    title: 'AP e gramáticas livres de contexto',
    body: 'APs não determinísticas e gramáticas livres de contexto são duas '
        'formas equivalentes de descrever linguagens livres de contexto. Use '
        'conversão para relacionar comportamento da pilha a produções ou '
        'examinar outro modelo formal. Execute Converter para GLC numa AP '
        'adequada ou uma conversão de gramática para AP no espaço Gramática. O '
        'conversor gera variáveis [p,A,q] e exibe a GLC sem trocar de espaço. '
        'Esta implementação exige estrutura por estado final e exatamente um '
        'pop não lambda em cada transição, então uma AP matematicamente '
        'conversível pode precisar ser normalizada. Continue em Converter para '
        'GLC ou Relações entre gramáticas, AF e AP.',
    keywords: ['AP', 'PDA', 'GLC', 'conversão', 'equivalência'],
  ),
  'tm': HelpNodeCopy(
    title: 'Máquinas de Turing',
    keywords: ['MT', 'TM', 'Máquina de Turing', 'fita', 'computação'],
  ),
  'tm.editor': HelpNodeCopy(
    title: 'Editor e canvas',
    keywords: ['MT', 'TM', 'Máquina de Turing', 'editor', 'canvas'],
  ),
  HelpTopicIds.tmEditorOverview: HelpNodeCopy(
    title: 'Visão geral do editor de máquinas de Turing',
    body: 'O espaço MT reúne canvas de estados, inspetor de fita única, '
        'simulação, análise estrutural, métricas, exemplos e exportação SVG. '
        'Use-o para construir e testar uma máquina cujas transições leem, '
        'escrevem e movem o cabeçote. Adicione estados, marque os estados '
        'inicial e de aceitação, crie transições, informe uma cadeia e ative '
        'Simular MT. O canvas e o status resumem a máquina, enquanto os painéis '
        'mostram traço e análise. Simulação e análise exigem ao menos um estado, '
        'e máquinas inválidas retornam uma mensagem. Continue em Selecionar e '
        'editar estados ou Fluxo da simulação.',
    keywords: ['MT', 'TM', 'Máquina de Turing', 'editor', 'Simular MT'],
  ),
  'tm.editor.editing': HelpNodeCopy(
    title: 'Editar uma máquina de Turing',
    keywords: ['MT', 'TM', 'editar', 'estado', 'transição', 'histórico'],
  ),
  HelpTopicIds.tmEditorSelectionAndStates: HelpNodeCopy(
    title: 'Selecionar e editar estados',
    body: 'Estados representam o controle finito da MT, e Selecionar permite '
        'movê-los ou editá-los. Use esses controles para definir onde o cálculo '
        'começa, termina com sucesso ou muda de comportamento. Ative Adicionar '
        'estado, crie um estado e selecione-o para editar rótulo, Estado '
        'inicial ou Estado de aceitação; arraste para reposicionar. A máquina, '
        'as arestas ligadas, as contagens e a validação são atualizadas. Só um '
        'estado pode ser inicial, e excluir um estado também exclui suas '
        'transições. Continue em Adicionar e editar transições.',
    keywords: ['MT', 'TM', 'Selecionar', 'Adicionar estado', 'estado inicial'],
  ),
  HelpTopicIds.tmEditorTransitions: HelpNodeCopy(
    title: 'Adicionar e editar transições',
    body:
        'Uma transição da MT escolhe o próximo estado e uma operação da fita. '
        'Use transições para definir o que a máquina faz com cada símbolo sob o '
        'cabeçote. Ative Adicionar transição, selecione origem e destino, '
        'preencha o editor de operação e salve; selecione uma aresta existente '
        'para editar ou excluir. O canvas exibe leitura/escrita,direção e '
        'recalcula símbolos e conflitos não determinísticos. Campos de leitura '
        'ou escrita vazios são rejeitados, e regras concorrentes para o mesmo '
        'estado e símbolo lido tornam a máquina não determinística. Continue em '
        'Leitura, escrita e direção.',
    keywords: ['MT', 'TM', 'Adicionar transição', 'aresta', 'operação'],
  ),
  HelpTopicIds.tmEditorReadWriteAndDirection: HelpNodeCopy(
    title: 'Leitura, escrita e direção',
    body: 'Símbolo lido, Símbolo escrito e Direção definem uma regra da MT. '
        'Use-os quando a transição precisar reconhecer a célula atual, '
        'substituí-la e produzir movimento do cabeçote. Informe um símbolo lido '
        'e um símbolo escrito não vazios, escolha Esquerda, Direita ou Parado e '
        'ative Salvar ou pressione Enter; Escape cancela. O rótulo passa a '
        'leitura/escrita,direção e a regra fica disponível à simulação. Espaços '
        'externos são removidos, campo vazio é inválido e branco é um símbolo '
        'configurado, não ausência de valor. Continue em Símbolo branco e '
        'alfabeto da fita.',
    keywords: ['MT', 'TM', 'Símbolo lido', 'Símbolo escrito', 'Direção'],
  ),
  HelpTopicIds.tmEditorHistoryAndClear: HelpNodeCopy(
    title: 'Desfazer, refazer e limpar',
    body: 'Desfazer e Refazer restauram edições registradas no canvas da MT, '
        'enquanto Limpar canvas remove o grafo. Use o histórico após uma edição '
        'indesejada e Limpar somente para recomeçar. Ative os controles da '
        'barra ou os atalhos disponíveis e confira estados e transições '
        'restaurados. Qualquer mudança no modelo encerra a reprodução no canvas '
        'e redefine a fita exibida com o símbolo branco atual; Limpar faz isso '
        'explicitamente com o grafo. O histórico cobre o modelo, não edições '
        'manuais de células, e tem limite. Continue em Arquivos e exemplos.',
    keywords: ['MT', 'TM', 'Desfazer', 'Refazer', 'Limpar canvas'],
  ),
  'tm.editor.viewport': HelpNodeCopy(
    title: 'Visualização do canvas',
    keywords: ['MT', 'TM', 'visualização', 'zoom', 'ajustar', 'redefinir'],
  ),
  HelpTopicIds.tmEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom e deslocamento',
    body: 'Zoom e deslocamento alteram a área visível da MT sem mudar sua '
        'estrutura formal. Use-os para examinar um grafo denso ou alcançar '
        'estados fora da tela. Use Ampliar ou Reduzir, roda do mouse, trackpad '
        'ou gesto de pinça com dois dedos e arraste o fundo para deslocar. A '
        'escala e o deslocamento mudam, mantendo posições e transições na mesma '
        'máquina. Gestos dependem do dispositivo e zoom não corrige estados '
        'sobrepostos. Continue em Ajustar ao conteúdo e Redefinir visualização.',
    keywords: ['MT', 'TM', 'Ampliar', 'Reduzir', 'deslocar', 'pinça'],
  ),
  HelpTopicIds.tmEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Ajustar ao conteúdo e redefinir visualização',
    body: 'Ajustar ao conteúdo enquadra o grafo da MT, enquanto Redefinir '
        'visualização retorna à escala e posição padrão. Use Ajustar quando '
        'estados saírem da tela e Redefinir para uma vista neutra. Ative a ação '
        'correspondente na barra do canvas. Só a visualização muda; posições '
        'salvas, transições, fita e linguagem permanecem iguais. Num canvas '
        'vazio, Ajustar recorre à vista padrão, e nenhuma ação reorganiza '
        'sobreposições. Continue em Disponibilidade do Layout automático.',
    keywords: ['MT', 'TM', 'Ajustar ao conteúdo', 'Redefinir visualização'],
  ),
  HelpTopicIds.tmEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Disponibilidade do Layout automático',
    body: 'Layout automático reposicionaria os estados do grafo. Procure-o '
        'quando uma máquina organizada manualmente ficar difícil de ler. O '
        'espaço MT atual não expõe Layout automático, então mova estados com '
        'Selecionar e use Ajustar ao conteúdo para enquadrá-los. Arrastar '
        'manualmente altera as coordenadas salvas e redesenha as arestas. O '
        'algoritmo homônimo de AF não está disponível para MT, e nenhum botão '
        'de análise muda o layout. Continue em Selecionar e editar estados.',
    keywords: ['MT', 'TM', 'Layout automático', 'indisponível'],
  ),
  'tm.editor.tape': HelpNodeCopy(
    title: 'Fita e cabeçote',
    keywords: ['MT', 'TM', 'fita', 'cabeçote', 'símbolo branco', 'alfabeto'],
  ),
  HelpTopicIds.tmEditorTapeInspector: HelpNodeCopy(
    title: 'Usar o inspetor da fita',
    body: 'O inspetor mostra células visíveis e a posição do cabeçote da MT '
        'ativa. Use-o para examinar ou preparar o conteúdo da fita e acompanhar '
        'um passo da simulação. Expanda o painel, selecione uma célula editável, '
        'escolha um símbolo do alfabeto da fita ou digite um caractere e '
        'confirme; use Limpar para redefinir a exibição. A célula escolhida é '
        'atualizada, enquanto selecionar um passo projeta o instantâneo gravado. '
        'Edições manuais não reescrevem o grafo nem o alfabeto de entrada, e a '
        'simulação começa pela Cadeia de entrada. Continue em Cabeçote e célula '
        'atual.',
    keywords: ['MT', 'TM', 'inspetor da fita', 'Editar célula', 'Limpar'],
  ),
  HelpTopicIds.tmEditorTapeBlankAndAlphabet: HelpNodeCopy(
    title: 'Símbolo branco e alfabeto da fita',
    body: 'O alfabeto da fita contém todo símbolo que pode aparecer nela, '
        'inclusive o símbolo branco usado além da entrada escrita. Use-o para '
        'ler rótulos de transição ou editar células. Informe explicitamente o '
        'branco configurado, normalmente B ou □, nas regras de leitura e '
        'escrita; o editor deriva outros símbolos das transições. A simulação '
        'expande a fita com brancos conforme o cabeçote se move. Este é um '
        'editor de fita única e não expõe edição de múltiplas fitas, seleção de '
        'número da fita ou cabeçotes separados, embora o formato serializado '
        'mantenha campos de compatibilidade. Continue em Fita e cabeçote.',
    keywords: ['MT', 'TM', 'fita única', 'múltiplas fitas', 'símbolo branco'],
  ),
  HelpTopicIds.tmEditorTapeHeadAndCurrentCell: HelpNodeCopy(
    title: 'Cabeçote e célula atual',
    body: 'O cabeçote identifica a célula lida pela próxima transição. Use o '
        'marcador central e o rótulo da posição para acompanhar seu movimento '
        'durante a edição ou o traço. Selecione um passo ou use Passo anterior, '
        'Próximo passo, Reproduzir, Pausar ou Reiniciar; o inspetor projeta o '
        'passo e marca leitura, escrita e célula atual. Esquerda pode expandir '
        'o início da fita, Direita pode acrescentar um branco e Parado mantém o '
        'índice. A faixa visível representa uma fita, não vários cabeçotes. '
        'Continue em Traço e fita.',
    keywords: ['MT', 'TM', 'cabeçote', 'célula atual', 'Esquerda', 'Direita'],
  ),
  'tm.editor.simulation': HelpNodeCopy(
    title: 'Simulação',
    keywords: ['MT', 'TM', 'simulação', 'entrada', 'traço', 'reprodução'],
  ),
  HelpTopicIds.tmEditorSimulation: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Informar entrada e simular',
    body: 'A simulação executa a MT atual desde o estado inicial sobre uma '
        'cadeia. Use-a para testar se um estado de aceitação é alcançado nessa '
        'entrada específica. Digite em Cadeia de entrada, deixe vazio para ε, '
        'preserve espaços pretendidos e ative Simular MT; durante a execução, '
        'use Cancelar simulação se necessário. O resultado é Aceita, Rejeitada, '
        'cancelada, expirada ou erro, com traço quando a execução começa. Os '
        'símbolos precisam pertencer ao alfabeto de entrada; a execução da UI '
        'tem timeout de cinco segundos e limites de 10.000 passos determinísticos '
        'ou 100.000 configurações não determinísticas. Cancelamento não devolve '
        'traço parcial. Continue em Traço e fita.',
    keywords: [
      'MT',
      'TM',
      'Cadeia de entrada',
      'Simular MT',
      'Cancelar simulação'
    ],
  ),
  HelpTopicIds.tmEditorSimulationTraceAndTape: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Ler o traço e a fita',
    body: 'O traço da MT registra estado, conteúdo da fita, transição aplicada '
        'e posição do cabeçote em cada passo disponível. Use-o para explicar um '
        'resultado ou localizar a primeira operação inesperada. Selecione uma '
        'linha ou posição da linha do tempo e use Passo anterior, Próximo passo, '
        'Reproduzir, Pausar e Reiniciar. Estado, transição, célula e instantâneo '
        'da fita ficam sincronizados, e traços longos são recolhidos depois do '
        'primeiro bloco. Execução cancelada não tem traço, e timeout ou rejeição '
        'pode terminar antes da aceitação. Continue em Resultados e reprodução '
        'no canvas.',
    keywords: ['MT', 'TM', 'traço', 'Passo anterior', 'Reproduzir', 'Pausar'],
  ),
  HelpTopicIds.tmEditorSimulationResultsAndCanvas: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Resultados e reprodução no canvas',
    body: 'Os resultados distinguem aceitação de rejeição e disponibilizam o '
        'caminho gravado para reprodução. Use Visualizar no Canvas para '
        'reproduzir grafo e fita juntos. Após executar, leia Aceita ou Rejeitada '
        'e ative Visualizar no Canvas; use Passo anterior, Reproduzir ou Pausar, '
        'Próximo passo e Fechar. A reprodução destaca os elementos ativos e '
        'projeta a fita sem mudar a máquina. Visualizar no Canvas só aparece no '
        'layout estreito no iOS com menos de 1.024 pixels lógicos; os demais '
        'layouts mantêm a reprodução no painel de traço. Continue em Parada e '
        'aceitação.',
    keywords: [
      'MT',
      'TM',
      'Aceita',
      'Rejeitada',
      'Visualizar no Canvas',
      'iOS',
    ],
  ),
  'tm.editor.algorithms': HelpNodeCopy(
    title: 'Análise',
    keywords: ['MT', 'TM', 'análise', 'limitada', 'traço', 'perfil'],
  ),
  HelpTopicIds.tmEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Visão geral da análise de máquinas de Turing',
    body: 'Análise da MT combina ferramentas de execução limitada com '
        'relatórios estruturais da máquina atual. Use-a após desenhar ou '
        'carregar um exemplo para focar estados, transições, fita, '
        'alcançabilidade, tempo ou avisos. A análise Término e ciclos classifica '
        'uma entrada concreta com limites visíveis. Alcançabilidade compara o '
        'grafo exato com execução concreta limitada. Explorador de linguagem '
        'classifica uma amostra shortlex limitada. Ative Término e ciclos, '
        'Alcançabilidade, Explorador de linguagem, Traço da fita, Perfil de '
        'tempo ou Perfil de espaço. Os controles só ficam desativados durante '
        'outra '
        'análise; máquina ausente ou inválida gera erro após o acionamento. Abra '
        'o tópico do foco escolhido.',
    keywords: ['MT', 'TM', 'Análise da MT', 'análise estrutural', 'resultados'],
  ),
  HelpTopicIds.tmEditorAlgorithmsDecidability: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Término e ciclos',
    body: 'A análise Término e ciclos classifica uma entrada concreta com os '
        'limites de passos, configurações e tempo exibidos. Uma execução que '
        'para é aceita ou rejeitada. A repetição de uma configuração '
        'determinística prova um ciclo e informa início e período. Atingir um '
        'limite deixa o resultado inconclusivo; não prova rejeição nem laço. A '
        'exploração não determinística aceita quando algum ramo aceita e só '
        'rejeita após '
        'esgotar o grafo finito de configurações alcançáveis. Esse resultado '
        'por entrada não faz afirmação sobre término em todas as entradas.',
    keywords: ['MT', 'TM', 'Término e ciclos', 'parada', 'ciclo', 'limites'],
  ),
  HelpTopicIds.tmEditorAlgorithmsReachableStates: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Alcançabilidade',
    body: 'Alcançabilidade separa duas afirmações. A '
        'alcançabilidade estrutural percorre iterativamente as arestas de '
        'controle e prova estados desconectados. A análise semântica limitada '
        'explora configurações canônicas para o escopo de entradas separado por '
        'vírgulas e registra o testemunho mais curto de cada estado observado. '
        'O painel mostra limites de passos, configurações e tempo. Atingir um '
        'limite torna o relatório incompleto; estados ainda não observados não '
        'são chamados de inalcançáveis. As cores do canvas distinguem estados '
        'observados, não observados dentro dos limites e desconexão estrutural. '
        'Continue em Configurações.',
    keywords: ['MT', 'TM', 'Alcançabilidade', 'inalcançáveis'],
  ),
  HelpTopicIds.tmEditorAlgorithmsLanguage: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Explorador de linguagem',
    body: 'O Explorador de linguagem enumera primeiro a cadeia vazia e depois '
        'as cadeias em ordem shortlex determinística até o comprimento e o limite '
        'de candidatas configurados. Defina os limites de passos, configurações '
        'e tempo por entrada, confira a estimativa e ative Explorador de '
        'linguagem. O relatório separa quatro grupos: aceita, rejeitada após '
        'parada, ciclo '
        'provado e inconclusiva. Timeout, limite de passos, limite de memória '
        'por configurações ou cancelamento nunca aparece como rejeição. Limitar '
        'ou cancelar mantém o prefixo avaliado. Selecione uma cadeia para '
        'carregar o traço limitado e suas métricas. A amostra não infere a '
        'linguagem completa nem prova equivalência. Continue em Linguagens '
        'recursivamente enumeráveis.',
    keywords: [
      'MT',
      'TM',
      'Explorador de linguagem',
      'shortlex',
      'limite de candidatas',
      'inconclusiva',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsTapeOperations: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Traço da fita',
    body: 'O Traço da fita executa a máquina sobre a entrada concreta '
        'compartilhada e mede um ramo real. O relatório mostra leituras e '
        'escritas por símbolo, células alteradas, movimentos, reversões, '
        'posições lógicas estáveis, intervalo visitado, pico de células não '
        'brancas, contagens por transição e uma diferença esparsa entre a fita '
        'inicial e final. Transições definidas mas não executadas continuam '
        'visíveis como cobertura estática. Para uma MT não determinística, o '
        'relatório identifica o ramo aceito, rejeitado, cíclico ou o ramo '
        'limitado mais longo, sem combinar ramos distintos. Abra Rastreamento '
        'da execução relacionado para examinar o rastreamento produzido pela '
        'mesma execução. Entrada vazia significa epsilon; os limites de passos, '
        'configurações e tempo continuam válidos. Somente uma fita é executada. '
        'Continue em Fita e cabeçote.',
    keywords: ['MT', 'TM', 'Traço da fita', 'símbolo lido', 'símbolo escrito'],
  ),
  HelpTopicIds.tmEditorAlgorithmsTime: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Perfil de tempo',
    body: 'O Perfil de tempo agrupa entradas candidatas do comprimento '
        'zero até o máximo exibido e executa cada uma com orçamentos explícitos '
        'de passos de transição, configurações e tempo. As contagens de '
        'candidatos ficam visíveis antes da execução. Para uma MTD, linhas '
        'exaustivas informam o mínimo e o máximo de passos entre execuções que '
        'param; o máximo observado abre a entrada testemunha e seu traço. '
        'Linhas amostradas e linhas com execução desconhecida ou cancelada '
        'continuam visivelmente incompletas. Para uma MTN, a ação informa '
        'profundidade de exploração e configurações exploradas como métricas '
        'operacionais, nunca como complexidade temporal determinística. O tempo '
        'de relógio do dispositivo é identificado como diagnóstico do perfil. '
        'Os pontos limitados não inferem uma classe Big-O. Continue em '
        'Complexidade de tempo e espaço.',
    keywords: [
      'MT',
      'TM',
      'Perfil de tempo',
      'passos de transição',
      'comprimento da entrada',
      'testemunho',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsSpace: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Perfil de espaço',
    body: 'O Perfil de espaço agrupa execuções limitadas por comprimento da '
        'entrada. O relatório mostra o maior intervalo visitado pelo cabeçote '
        'e o maior '
        'número simultâneo de células não brancas, com uma entrada testemunha '
        'para cada máximo. Configure o limite de candidatas e os limites de '
        'execução por entrada. O intervalo usa coordenadas lógicas estáveis da '
        'fita em cada movimento do cabeçote. Uma linha exaustiva cobre todas as '
        'cadeias do comprimento. Uma linha amostrada usa o prefixo shortlex '
        'determinístico, e uma linha incompleta encontrou limite de enumeração, '
        'execução ou '
        'cancelamento. Para MT não determinística, os máximos cobrem todas as '
        'configurações de ramos exploradas dentro do limite exibido. A fita '
        'única armazena entrada e dados de trabalho. O tamanho declarado do '
        'alfabeto da fita não é usado como espaço. Esse perfil limitado não '
        'prova complexidade assintótica de espaço. Continue em '
        'Complexidade de tempo e espaço.',
    keywords: [
      'MT',
      'TM',
      'Perfil de espaço',
      'intervalo visitado',
      'células não brancas',
    ],
  ),
  HelpTopicIds.tmEditorFilesAndExamples: HelpNodeCopy(
    title: 'Arquivos e exemplos',
    body: 'Exemplos de MT incluídos fornecem máquinas prontas, e o painel de '
        'arquivo exporta o diagrama atual como SVG. Use MT - a^n b^n, MT - '
        'Binário para unário, MT - Cópia de string, MT - Incremento binário ou '
        'MT - Verificador de palíndromo para estudar uma máquina funcional. Abra '
        'Análise da MT e selecione um exemplo, ou use Exportar SVG nas '
        'plataformas nativas e Baixar SVG na web. Carregar exemplo substitui a '
        'MT atual; o SVG inclui fita, cabeçote, estados, transições e legenda. O '
        'espaço não oferece ações de importar ou salvar MT em JFLAP ou JSON, e '
        'cancelar exportação não muda o modelo. Continue na visão geral.',
    keywords: ['MT', 'TM', 'exemplos', 'Exportar SVG', 'Baixar SVG', 'JFLAP'],
  ),
  'tm.theory': HelpNodeCopy(
    title: 'Teoria',
    keywords: ['MT', 'TM', 'Máquina de Turing', 'teoria', 'computabilidade'],
  ),
  HelpTopicIds.tmTheoryTm: HelpNodeCopy(
    title: 'Máquinas de Turing',
    body: 'Uma máquina de Turing combina controle finito com uma fita cujas '
        'células podem ser lidas e reescritas. Use esse modelo para algoritmos '
        'e linguagens que precisam de memória além de estados finitos ou uma '
        'pilha. Defina estados, inicial, estados de aceitação, alfabeto da fita '
        'com símbolo branco e transições de leitura, escrita e movimento. Uma '
        'execução produz configurações e aceita ao chegar a estado de aceitação. '
        'O app executa modelo de fita única com tempo limitado, portanto timeout '
        'não é rejeição matemática. Continue em Fita e cabeçote.',
    keywords: ['MT', 'TM', 'Máquina de Turing', 'controle finito', 'fita'],
  ),
  HelpTopicIds.tmTheoryTapeAndHead: HelpNodeCopy(
    title: 'Fita e cabeçote',
    body: 'A fita oferece armazenamento conceitualmente ilimitado, e um '
        'cabeçote lê e escreve a célula atual. Use esses conceitos para '
        'interpretar cada transição da MT. Em cada passo, combine o símbolo '
        'lido, escreva o substituto, mova para Esquerda, Direita ou Parado e '
        'entre no destino. A configuração seguinte contém nova fita, posição e '
        'estado; células não escritas têm o símbolo branco. O app aumenta uma '
        'lista finita conforme necessário e mostra uma fita, enquanto uma MT '
        'multi-tape coordenaria várias fitas e cabeçotes por passo. Continue em '
        'Configurações.',
    keywords: ['MT', 'TM', 'fita', 'cabeçote', 'símbolo branco', 'multi-tape'],
  ),
  HelpTopicIds.tmTheoryConfigurations: HelpNodeCopy(
    title: 'Configurações',
    body: 'Uma configuração é o estado instantâneo completo da MT: estado de '
        'controle, conteúdo da fita e posição do cabeçote. Use configurações '
        'para raciocinar sobre uma transição ou comparar linhas consecutivas do '
        'traço. Comece no estado inicial com a entrada na fita e o cabeçote na '
        'posição zero e aplique uma regra compatível por vez. Cada passo grava '
        'estado, fita, transição e posição resultantes. Um estado alcançável no '
        'grafo pode não ocorrer numa configuração realizável porque os símbolos '
        'restringem as regras. Continue em Parada e aceitação.',
    keywords: ['MT', 'TM', 'configuração', 'conteúdo da fita', 'cabeçote'],
  ),
  HelpTopicIds.tmTheoryHaltingAndAcceptance: HelpNodeCopy(
    title: 'Parada e aceitação',
    body: 'Uma execução aceita ao chegar a estado de aceitação e rejeita ao '
        'parar fora dele por falta de transição compatível. Use essa distinção '
        'ao ler Aceita, Rejeitada, ciclo provado ou desconhecido por limite. '
        'Siga o traço desde '
        'a configuração inicial até estado de aceitação, regra ausente ou '
        'limite computacional encerrar a execução no app. O resultado identifica '
        'o desfecho observado e preserva o traço disponível. Uma configuração '
        'determinística repetida prova um ciclo; timeout e outros limites de '
        'recursos permanecem desconhecidos por limite, sem provar rejeição ou '
        'não parada matemática. Continue em Linguagens decidíveis.',
    keywords: ['MT', 'TM', 'parada', 'aceitação', 'rejeição', 'timeout'],
  ),
  HelpTopicIds.tmTheoryDecidableLanguages: HelpNodeCopy(
    title: 'Linguagens decidíveis',
    body: 'Uma linguagem é decidível quando alguma MT para em toda entrada e '
        'aceita exatamente seus membros. Use a definição para separar decisões '
        'totais de reconhecedores que podem executar para sempre. Demonstre '
        'correção da pertinência e término para toda entrada possível. Um '
        'decisor válido devolve aceitação ou rejeição em passos finitos. Testar '
        'exemplos ou executar Término e ciclos não estabelece essa '
        'propriedade universal; o app só apresenta avisos estruturais. Continue '
        'em Linguagens recursivamente enumeráveis.',
    keywords: ['MT', 'TM', 'linguagem decidível', 'decisor', 'término'],
  ),
  HelpTopicIds.tmTheoryRecursivelyEnumerable: HelpNodeCopy(
    title: 'Linguagens recursivamente enumeráveis',
    body: 'Uma linguagem recursivamente enumerável tem um reconhecedor MT que '
        'aceita membros, mas pode executar para sempre em não membros. Use essa '
        'classe quando a aceitação pode ser testemunhada sem garantia total de '
        'rejeição. Descreva a máquina reconhecedora e mostre que membros acabam '
        'em aceitação. Execuções bem-sucedidas demonstram membros individuais, '
        'enquanto timeout deixa não pertinência ou não término indeterminados. '
        'Um simulador limitado não distingue esses casos nem prova a classe da '
        'linguagem inteira. Continue em Parada e aceitação.',
    keywords: ['MT', 'TM', 'recursivamente enumerável', 'reconhecedor'],
  ),
  HelpTopicIds.tmTheoryTimeAndSpace: HelpNodeCopy(
    title: 'Complexidade de tempo e espaço',
    body: 'Tempo de uma MT conta passos em função do tamanho da entrada, e '
        'espaço conta células distintas usadas na fita. Use essas medidas para '
        'comparar algoritmos sem depender de uma execução no dispositivo. '
        'Escolha o parâmetro de tamanho, derive limites para execuções relevantes '
        'e declare se a máquina é determinística ou não determinística. O '
        'resultado é um argumento assintótico como O(f(n)), não um conjunto '
        'finito de valores observados no painel. Perfil de tempo '
        'fornece contagens empíricas de transições para MTD ou métricas de '
        'exploração explicitamente rotuladas para MTN; ele não infere a classe '
        'assintótica. Perfil de espaço fornece máximos observados de células e '
        'testemunhos para o mesmo tipo de escopo finito; ele não trata o '
        'tamanho do alfabeto como espaço usado. Continue traçando '
        'entradas sem tratá-las como prova.',
    keywords: ['MT', 'TM', 'complexidade de tempo', 'complexidade de espaço'],
  ),
  'regex': HelpNodeCopy(
    title: 'Expressões regulares',
    keywords: ['regex', 'expressão regular', 'padrão', 'linguagem regular'],
  ),
  'regex.editor': HelpNodeCopy(
    title: 'Editor e ferramentas',
    keywords: ['regex', 'editor', 'validação', 'conversão', 'análise'],
  ),
  HelpTopicIds.regexEditorOverview: HelpNodeCopy(
    title: 'Visão geral do editor de regex',
    body:
        'O espaço Regex mantém entrada do padrão, alfabeto e teste ao vivo de '
        'cadeias no editor. A ação Algoritmos abre os cinco exemplos Regex - '
        'Repetição de A, Regex - Termina com AB, Regex - Binário iniciado por '
        '0, Regex - Pares AB ou BA e Regex - Blocos de A e B, junto com '
        'conversões, simplificação, análise estrutural, amostras e comparação '
        'de equivalência. Use-o para explorar uma expressão regular '
        'ou alternar entre representações regex e autômato finito. Digite um '
        'padrão, mantenha Alfabeto não vazio, acompanhe o aviso de validação e '
        'escolha a operação necessária. Os resultados surgem nos cartões '
        'correspondentes ou no estado compartilhado de AF usado pelos painéis '
        'de conversão. Entrada vazia ou inválida bloqueia operações, e algumas '
        'construções dependem do universo do alfabeto. Continue em Entrada e '
        'validação.',
    keywords: ['regex', 'editor', 'Alfabeto', 'validação', 'AF'],
  ),
  HelpTopicIds.regexEditorInput: HelpNodeCopy(
    title: 'Entrada e validação',
    body: 'Expressão regular é o campo do padrão, e seu aviso informa se a '
        'sintaxe atual pode ser usada. Valide antes de testar, converter, '
        'simplificar, analisar ou gerar amostras. Digite no campo ou acione '
        'Validar regex; a validação ocorre a cada mudança e informa a posição '
        'de escapes, delimitadores, classes, uniões ou quantificadores '
        'malformados. Um padrão válido mostra Regex válida e libera as '
        'operações do provedor. Padrão vazio, parênteses desequilibrados, classe '
        'vazia, intervalo descendente, operando ausente e quantificadores '
        'consecutivos continuam inválidos. Continue em Alfabeto.',
    keywords: ['regex', 'Expressão regular', 'Validar regex', 'inválida'],
  ),
  HelpTopicIds.regexEditorAlphabet: HelpNodeCopy(
    title: 'Alfabeto',
    body: 'Alfabeto é o conjunto de caracteres individuais usado como universo '
        'pelas construções de regex que dependem de contexto. Edite-o quando o '
        'curinga . ou um atalho complementado precisar saber quais símbolos '
        'pode representar. Digite os caracteres diretamente; cada rune Unicode '
        'vira um símbolo, repetições são eliminadas no conjunto resolvido e '
        'espaços contam. Conversão, correspondência, análise e amostras expandem '
        '., \\D, \\W e \\S contra esse conjunto. Um Alfabeto vazio desativa '
        'teste, conversão, simplificação, análise e geração de amostras; a '
        'comparação ainda aceita duas expressões que não precisem de universo. '
        'Continue em Testar cadeias.',
    keywords: ['regex', 'Alfabeto', 'curinga', r'\D', r'\W', r'\S'],
  ),
  HelpTopicIds.regexEditorTestStrings: HelpNodeCopy(
    title: 'Testar cadeias',
    body: 'Cadeia de teste verifica se toda a entrada pertence à linguagem da '
        'regex atual. Use-a para exemplos rápidos de pertinência depois que '
        'padrão e Alfabeto estiverem válidos. Digite em Cadeia de teste ou '
        'acione o botão de reprodução; cada edição inicia nova simulação de AFN '
        'e o campo vazio representa a palavra vazia. O aviso muda para Aceita! '
        'ou Não aceita quando a simulação mais recente termina. Erros de '
        'conversão ou simulação substituem um resultado confiável, e pedidos '
        'assíncronos antigos são ignorados. Continue em Conversões.',
    keywords: ['regex', 'Cadeia de teste', 'Aceita', 'Não aceita', 'vazia'],
  ),
  'regex.editor.conversions': HelpNodeCopy(
    title: 'Conversões',
    keywords: ['regex', 'conversão', 'AFN', 'AFD', 'AF para regex'],
  ),
  HelpTopicIds.regexEditorConversions: HelpNodeCopy(
    title: 'Visão geral das conversões',
    body:
        'As conversões ligam o espaço Regex a autômatos finitos equivalentes. '
        'Use-as para inspecionar modelos operacionais ou receber um padrão '
        'produzido no espaço AF. Com padrão válido e Alfabeto não vazio, abra '
        'Algoritmos e acione Converter para AFN ou Converter para AFD; um '
        'resultado AF para Regex '
        'aparece aqui depois do comando executado em AF. O autômato criado fica '
        'no provedor compartilhado de AF, e a conversão para AFD também abre o '
        'espaço AF. Falha de sintaxe, expansão do alfabeto ou conversão posterior '
        'é mostrada no lugar de resultado parcial. Continue em Converter para '
        'AFN.',
    keywords: [
      'regex',
      'Converter para AFN',
      'Converter para AFD',
      'AF para Regex'
    ],
  ),
  HelpTopicIds.regexEditorConversionsToNfa: HelpNodeCopy(
    title: 'Converter para AFN',
    body: 'Converter para AFN aplica a construção de Thompson à regex atual e '
        'produz um autômato finito não determinístico equivalente. Use-o para '
        'ver como união, concatenação e repetição viram estados e transições '
        'epsilon. Valide o padrão, mantenha Alfabeto não vazio e acione '
        'Converter para AFN. Uma mensagem de sucesso confirma que o novo AFN '
        'está no provedor do espaço AF. Sintaxe inválida ou token dependente de '
        'alfabeto sem universo útil interrompe a conversão. Continue no tópico '
        'Regex para AFN de AF ou em Converter para AFD.',
    keywords: ['regex', 'Converter para AFN', 'Thompson', 'transição epsilon'],
  ),
  HelpTopicIds.regexEditorConversionsToDfa: HelpNodeCopy(
    title: 'Converter para AFD',
    body: 'Converter para AFD cria o AFN da regex, determiniza-o e completa '
        'transições ausentes. Use-o quando simulação ou comparação precisar de '
        'autômato determinístico total. Valide a regex, mantenha Alfabeto não '
        'vazio e acione Converter para AFD. O resultado substitui o modelo AF '
        'compartilhado e o app abre o espaço AF. Falha na conversão regex-AFN '
        'ou AFN-AFD é exibida e não promete um AFD parcial. Continue na teoria '
        'de AFD ou em Equivalência.',
    keywords: ['regex', 'Converter para AFD', 'determinizar', 'AFD completo'],
  ),
  HelpTopicIds.regexEditorConversionsFaToRegex: HelpNodeCopy(
    title: 'Resultado de AF para regex',
    body: 'AF para Regex elimina estados do autômato finito atual e envia a '
        'expressão resultante a este espaço. Use-o após o comando de conversão '
        'em AF para obter uma descrição textual da linguagem do autômato. '
        'Execute AF para Regex em AF, volte a Regex se necessário e use '
        'Simplificar saída para escolher o valor simplificado ou bruto quando '
        'ambos existirem. O cartão oferece texto selecionável e Copiar para a '
        'área de transferência. Nenhum cartão aparece até o provedor de '
        'algoritmos conter um resultado. Continue em Simplificação.',
    keywords: [
      'regex',
      'AF para Regex',
      'eliminação de estados',
      'Simplificar saída'
    ],
  ),
  HelpTopicIds.regexEditorSimplification: HelpNodeCopy(
    title: 'Passos de simplificação',
    body: 'A simplificação aplica identidades aceitas da álgebra regular e '
        'registra cada transformação. Use Simplificar com passos para estudar '
        'por que uma expressão válida pode ser encurtada. Execute a ação, '
        'expanda o resultado e navegue por Passo anterior, Próximo passo ou por '
        'um item da linha do tempo. O cartão mostra regex original e '
        'simplificada, regras, fragmentos antes/depois, caracteres economizados, '
        'redução e tempo quando houve progresso. É exigida regex válida e não '
        'vazia, e expressões equivalentes podem não ter regra simplificadora. '
        'Continue em Análise de complexidade.',
    keywords: ['regex', 'Simplificar com passos', 'Passo anterior', 'redução'],
  ),
  HelpTopicIds.regexEditorComplexity: HelpNodeCopy(
    title: 'Análise de complexidade',
    body: 'Análise de complexidade resume a estrutura do padrão, não a '
        'complexidade de execução de um motor de correspondência. Use o botão '
        'visível Analyze Complexity para comparar formatos de expressões. '
        'Execute a ação e expanda os detalhes para ver Star Height (altura de '
        'estrela), Nesting Depth (profundidade de aninhamento), Complexity '
        'Score, contagens de operadores e o Alphabet resolvido. O cartão '
        'classifica o padrão como Simple, Moderate ou Complex por métricas '
        'estruturais ponderadas. As contagens refletem a expressão analisada e '
        'não garantem tempo ou espaço assintótico. Continue em Cadeias de amostra.',
    keywords: ['regex', 'Analyze Complexity', 'Star Height', 'contagens'],
  ),
  HelpTopicIds.regexEditorSampleStrings: HelpNodeCopy(
    title: 'Cadeias de amostra',
    body:
        'Cadeias de amostra gera exemplos distintos aceitos pela regex atual. '
        'Use-as para explorar a linguagem antes de digitar sua própria Cadeia '
        'de teste. Acione o botão visível Generate Sample Strings para até 10 '
        'exemplos ou Generate More para até 15, expanda, selecione um chip ou '
        'use Copy All. O resumo informa quantidade, aceitação de ε e menor '
        'cadeia gerada quando disponível. A geração limita cada amostra a 30 '
        'caracteres e pode devolver menos valores únicos que o solicitado. '
        'Continue em Testar cadeias ou Equivalência.',
    keywords: ['regex', 'Sample Strings', 'Generate More', 'Copy All', '30'],
  ),
  HelpTopicIds.regexEditorEquivalence: HelpNodeCopy(
    title: 'Comparar equivalência',
    body: 'Comparar equivalência verifica se duas regexes descrevem a mesma '
        'linguagem sobre o Alfabeto atual. Use-o quando padrões diferentes '
        'devem aceitar exatamente as mesmas cadeias. Mantenha a expressão '
        'principal em Expressão regular, digite a outra no campo de comparação '
        'e acione Comparar equivalência. Cada expressão vira um AFD completo, '
        'e o aviso informa equivalente ou não equivalente. Os dois campos de '
        'expressão são necessários; Alfabeto precisa ser não vazio apenas se '
        'uma expressão usar . ou atalho complementado, e erros de conversão '
        'aparecem como mensagem de comparação malsucedida. Continue em '
        'Equivalência com AF.',
    keywords: ['regex', 'Comparar equivalência', 'equivalente', 'AFD completo'],
  ),
  HelpTopicIds.regexEditorEmbeddedFsaPanels: HelpNodeCopy(
    title: 'Painéis de AF incorporados',
    body: 'Layouts desktop e tablet de Regex reutilizam Painel de algoritmos e '
        'Painel de simulação de AF ao lado do formulário. Use-os como atalhos '
        'para Regex para AFN, AFN para AFD, limpar entradas ou simular uma '
        'cadeia. Acione um comando disponível, que delega aos mesmos handlers '
        'de regex e ao mesmo estado compartilhado de autômato dos controles '
        'principais. Os painéis mostram resultados normais de AF e ações '
        'desativadas quando nenhum handler Regex foi fornecido. No celular, o '
        'formulário fica em uma coluna rolável sem esses painéis laterais. '
        'Continue na visão geral do editor de AF.',
    keywords: [
      'regex',
      'Painel de algoritmos',
      'Painel de simulação',
      'desktop'
    ],
  ),
  'regex.theory': HelpNodeCopy(
    title: 'Teoria',
    keywords: ['regex', 'teoria', 'operadores', 'linguagem regular', 'AF'],
  ),
  HelpTopicIds.regexTheoryRegex: HelpNodeCopy(
    title: 'Expressões regulares',
    body: 'Uma expressão regular denota uma linguagem regular combinando '
        'símbolos atômicos com escolha finita, sequência e repetição. Use esse '
        'modelo para descrever exatamente as linguagens reconhecíveis por '
        'autômatos finitos. Monte um padrão com literal, agrupamento ( ), '
        'concatenação, união |, estrela de Kleene *, mais +, opcional ?, '
        'curinga ., classe de caracteres [ ], atalhos \\d, \\D, \\s, \\S, '
        '\\w e \\W e epsilon ε. O resultado denota um conjunto de cadeias '
        'inteiras, não busca de substring no editor. Sintaxe válida isolada não '
        'mostra que uma amostra pertence à linguagem. Continue em Literais e '
        'agrupamento.',
    keywords: ['regex', 'linguagem regular', 'operador', 'autômato finito'],
  ),
  HelpTopicIds.regexTheoryLiteralsAndGrouping: HelpNodeCopy(
    title: 'Literais, conjuntos e agrupamento',
    body: 'Um literal corresponde a si mesmo, enquanto agrupamento ( ) faz uma '
        'subexpressão agir como um operando. Use grupos para controlar o escopo '
        'e classe de caracteres [ ] ou intervalo como [a-c] para escolher um '
        'símbolo de um conjunto. Digite metacaracteres após barra invertida '
        'quando precisarem ser literais; o curinga . usa o Alfabeto, e os '
        'atalhos \\d, \\D, \\s, \\S, \\w e \\W fornecem conjuntos '
        'predefinidos ou complementados. Cada literal, curinga, classe ou '
        'atalho consome um símbolo. Classes vazias, intervalos descendentes e '
        'formas complementadas sem universo não funcionam. Continue em '
        'Concatenação e união.',
    keywords: [
      'regex',
      'literal',
      'agrupamento',
      'classe de caracteres',
      'curinga'
    ],
  ),
  HelpTopicIds.regexTheoryConcatenationAndUnion: HelpNodeCopy(
    title: 'Concatenação e união',
    body:
        'Concatenação coloca expressões lado a lado, enquanto união | escolhe '
        'um dos operandos. Use concatenação para partes ordenadas como ab e '
        'união para alternativas como a|b. Escreva a concatenação sem operador '
        'e coloque | entre expressões completas à esquerda e à direita. A '
        'linguagem de ab contém cadeias unidas; a de a|b contém cadeias de '
        'qualquer lado. Um | inicial, final ou sem operando é inválido, e pode '
        'ser necessário agrupar para definir seu escopo. Continue em Estrela '
        'de Kleene e mais.',
    keywords: ['regex', 'concatenação', 'união', '|', 'alternativa'],
  ),
  HelpTopicIds.regexTheoryKleeneStarAndPlus: HelpNodeCopy(
    title: 'Estrela de Kleene e mais',
    body: 'Estrela de Kleene * repete a expressão anterior zero ou mais vezes, '
        'e mais + a repete uma ou mais vezes. Use * quando a palavra vazia for '
        'permitida e + quando pelo menos uma cópia for exigida. Coloque o '
        'operador pós-fixo logo após literal, classe, atalho ou expressão '
        'agrupada, como a* ou (ab)+. A linguagem resultante contém toda '
        'repetição finita permitida. Um quantificador não pode iniciar a '
        'expressão nem seguir outro quantificador diretamente neste editor. '
        'Continue em Opcional.',
    keywords: ['regex', 'estrela de Kleene', '*', 'mais', '+', 'repetição'],
  ),
  HelpTopicIds.regexTheoryOptional: HelpNodeCopy(
    title: 'Operador opcional',
    body: 'O operador opcional ? permite zero ou uma cópia da expressão '
        'anterior. Use-o para símbolo ou trecho agrupado opcional, como a? ou '
        '(ab)?. Digite o ? literal depois do operando; o ícone de interrogação '
        'exibido ao lado de Opcional (?) na Análise de complexidade é '
        'decorativo e não é uma ação de Ajuda. A linguagem inclui o operando e '
        'a escolha vazia. ? inicial ou quantificadores consecutivos são '
        'inválidos. Continue em Precedência.',
    keywords: ['regex', 'opcional', '?', 'zero ou uma', 'ícone decorativo'],
  ),
  HelpTopicIds.regexTheoryPrecedence: HelpNodeCopy(
    title: 'Precedência dos operadores',
    body:
        'A precedência decide quais operandos cada operador de regex controla '
        'quando não há parênteses. Use-a para ler ou escrever expressões '
        'compactas sem alterar a linguagem por engano. O editor aplica primeiro '
        'os pós-fixos *, + e ?, depois a concatenação implícita e por último a '
        'união |; agrupamento ( ) substitui essa ordem. Assim, ab|c significa '
        '(ab)|c, enquanto a(b|c) concatena a com uma das alternativas. Intenção '
        'ambígua não é erro de sintaxe, então acrescente parênteses quando a '
        'estrutura desejada não estiver clara. Continue em Lambda e epsilon.',
    keywords: ['regex', 'precedência', 'pós-fixo', 'concatenação', 'união'],
  ),
  HelpTopicIds.regexTheoryLambda: HelpNodeCopy(
    title: 'Lambda e epsilon',
    body: 'Lambda e epsilon são nomes comuns para a palavra vazia, que tem '
        'comprimento zero. Use a palavra vazia quando a linguagem contiver uma '
        'cadeia sem símbolos ou o autômato se mover sem consumir entrada. No '
        'campo Regex, digite epsilon ε para criar o nó de palavra vazia '
        'suportado; Cadeia de teste vazia testa essa palavra. A conversão '
        'representa os movimentos necessários como transições epsilon no AFN. '
        'O caractere λ não é token de palavra vazia neste parser de regex e é '
        'tratado como símbolo literal quando digitado. Continue em Linguagens '
        'regulares.',
    keywords: ['regex', 'lambda', 'epsilon', 'ε', 'palavra vazia'],
  ),
  HelpTopicIds.regexTheoryRegularLanguages: HelpNodeCopy(
    title: 'Linguagens regulares',
    body: 'Uma linguagem regular é qualquer linguagem denotada por regex ou '
        'reconhecida por autômato finito. Use essa classe para padrões que '
        'precisam somente de memória de estados finitos. Construa regex, AF ou '
        'ambos e raciocine sobre todas as cadeias aceitas pela representação. '
        'Conversões e verificações de equivalência preservam a linguagem regular '
        'representada quando têm sucesso. Testar muitas cadeias dá evidência '
        'sobre esses exemplos, não prova sobre todas as cadeias. Continue em '
        'Equivalência com AF.',
    keywords: ['regex', 'linguagem regular', 'memória finita', 'AF'],
  ),
  HelpTopicIds.regexTheoryEquivalenceWithFsa: HelpNodeCopy(
    title: 'Equivalência com autômatos finitos',
    body: 'Regexes e autômatos finitos têm o mesmo poder expressivo sobre '
        'linguagens regulares. Use essa equivalência para alternar entre notação '
        'algébrica compacta e grafo operacional de estados. A construção de '
        'Thompson leva regex a AFN, a construção de subconjuntos leva AFN a AFD '
        'e eliminação de estados leva AF a regex. Uma conversão bem-sucedida '
        'aceita a mesma linguagem, embora sua forma seja diferente. Erros de '
        'conversão ou algumas amostras não estabelecem equivalência sozinhos. '
        'Continue na visão geral de conversões ou em Comparar equivalência.',
    keywords: ['regex', 'AF', 'AFN', 'AFD', 'eliminação de estados'],
  ),
  'pumping': HelpNodeCopy(
    title: 'Lema do Bombeamento',
    keywords: ['lema do bombeamento', 'regularidade', 'não regular', 'prova'],
  ),
  'pumping.editor': HelpNodeCopy(
    title: 'Jogo e progresso',
    keywords: ['lema do bombeamento', 'jogo', 'desafio', 'progresso'],
  ),
  HelpTopicIds.pumpingEditorOverview: HelpNodeCopy(
    title: 'Visão geral do espaço de bombeamento',
    body: 'O espaço Bombeamento reúne um jogo de classificação, painel teórico '
        'com três abas e painel de progresso. Use-o para praticar o '
        'reconhecimento de linguagens regulares e não regulares enquanto '
        'consulta o método de prova. Inicie o jogo, responda cada desafio, leia '
        'o feedback e consulte as abas visíveis Theory, Steps ou Examples '
        'quando necessário. O '
        'espaço atualiza pontos do jogo e histórico separado de tentativas '
        'durante o avanço. É uma prática guiada, não um editor de provas nem um '
        'decisor automático de regularidade. Continue em Fluxo do jogo.',
    keywords: ['lema do bombeamento', 'jogo', 'Theory', 'Steps', 'Examples'],
  ),
  HelpTopicIds.pumpingEditorGame: HelpNodeCopy(
    title: 'Fluxo do jogo',
    body: 'Jogo do Lema do Bombeamento apresenta em sequência oito desafios '
        'fixos de classificação de linguagens. Use-o para testar o entendimento '
        'após ler o teorema ou revisar exemplos comuns. Acione Start Game, '
        'inspecione Language, descrição e Examples, escolha uma resposta de '
        'regularidade e acione Submit Answer. O feedback explica a resposta '
        'armazenada e oferece a próxima ação disponível. Submit Answer fica '
        'desativado até uma escolha, e o jogo não solicita uma prova formal. '
        'Continue em Dificuldade e desafios.',
    keywords: ['lema do bombeamento', 'Start Game', 'Submit Answer', 'desafio'],
  ),
  HelpTopicIds.pumpingEditorDifficultyAndChallenges: HelpNodeCopy(
    title: 'Dificuldade e desafios',
    body: 'Os desafios são agrupados nos níveis 1 a 4 e rotulados EASY, MEDIUM '
        'ou HARD. Use o selo e os exemplos para estimar quanto raciocínio '
        'sobre contagem, cópia, paridade ou fechamento será necessário. Avance '
        'pelos oito desafios incluídos com Next Challenge após enviar cada '
        'resposta. O cabeçalho mostra nível, dificuldade, número do desafio, '
        'pontos e eventual sequência de acertos. Respostas corretas começam em '
        '10, 20 ou 30 pontos para Easy, Medium ou Hard, somam duas vezes o nível '
        'e ganham bônus de 50% dos pontos-base após dois acertos consecutivos; '
        'uma tentativa Hard incorreta recebe 5 pontos. Essa pontuação não '
        'fornece testemunha nem prova a classificação. Continue em Escolha de '
        'regularidade.',
    keywords: ['lema do bombeamento', 'EASY', 'MEDIUM', 'HARD', 'sequência'],
  ),
  HelpTopicIds.pumpingEditorRegularityChoice: HelpNodeCopy(
    title: 'Escolher regular ou não regular',
    body: 'O jogo pergunta Is this language regular? e oferece Yes, it is '
        'regular ou No, it is not regular. Use a escolha para classificar toda '
        'a linguagem '
        'exibida, não apenas os exemplos listados. Selecione um cartão e acione '
        'Submit Answer; o cartão escolhido ganha aparência ativa. O valor '
        'enviado é comparado com os dados do desafio e registra tentativa '
        'correta ou errada. Exemplos isolados não provam a classificação, e um '
        'subconjunto não regular sozinho não torna uma união arbitrária não '
        'regular. Continue em Testemunha e decomposição.',
    keywords: [
      'lema do bombeamento',
      'regular',
      'não regular',
      'classificação'
    ],
  ),
  HelpTopicIds.pumpingEditorWitnessAndDecomposition: HelpNodeCopy(
    title: 'Testemunha e decomposição no jogo',
    body: 'Uma prova pelo lema normalmente escolhe uma cadeia testemunha e '
        'raciocina sobre toda decomposição permitida s = xyz. Use essas ideias '
        'mentalmente ao decidir um desafio não regular. Leia a linguagem, os '
        'exemplos e a aba Steps do painel Help, identifique testemunha de comprimento '
        'pelo menos p e avalie onde y poderia estar. O feedback pode mostrar '
        'uma testemunha e decomposição representativas após o envio. O jogo '
        'atual não tem campos de testemunha, x, y ou z e não valida uma '
        'decomposição fornecida pelo jogador. Continue em Escolha de '
        'bombeamento e envio.',
    keywords: ['lema do bombeamento', 'testemunha', 'decomposição', 'xyz', 'p'],
  ),
  HelpTopicIds.pumpingEditorPumpingChoiceAndSubmit: HelpNodeCopy(
    title: 'Escolha de bombeamento e envio',
    body: 'Uma prova por contradição escolhe o expoente de bombeamento somente '
        'depois de considerar a decomposição do oponente. Use esse raciocínio '
        'antes de enviar uma classificação não regular. No jogo atual, escolha '
        'apenas o cartão de regularidade e acione Submit Answer; não existe '
        'controle para k, bombear para cima, bombear para baixo ou construir '
        'cadeia. O envio registra a tentativa e abre feedback Correct! ou '
        'Incorrect. Sem classificação escolhida, o botão fica desativado, e a '
        'UI não verifica seu raciocínio de quantificadores. Continue em '
        'Feedback, repetir e praticar.',
    keywords: ['lema do bombeamento', 'Submit Answer', 'expoente', 'k'],
  ),
  HelpTopicIds.pumpingEditorFeedbackRetryAndPractice: HelpNodeCopy(
    title: 'Feedback, repetir e praticar',
    body:
        'O feedback revela Correct! ou Incorrect, uma explicação e dicas para '
        'resposta errada quando o desafio as fornece. Use-o para comparar seu '
        'raciocínio com a lição armazenada antes de avançar. Acione Next '
        'Challenge ou Finish Game; em desafio errado que não seja o último, '
        'Retry limpa a escolha e registra um evento de repetição. A conclusão '
        'informa nível de desempenho, pontuação final em pontos, percentual, '
        'mensagens de aprendizagem e Practice Again; os limiares são Expert em '
        '90%, Advanced em 75%, Intermediate em 60% e Beginner abaixo de 60%. '
        'Retry não está '
        'disponível no último desafio e não apaga a tentativa anterior do '
        'histórico. Continue em Progresso.',
    keywords: [
      'lema do bombeamento',
      'Correct',
      'Incorrect',
      'Retry',
      'Practice Again'
    ],
  ),
  HelpTopicIds.pumpingEditorProgress: HelpNodeCopy(
    title: 'Progresso e estatísticas',
    body: 'Progresso resume desafios concluídos e o histórico cronológico de '
        'tentativas e repetições da sessão atual. Use-o para revisar resultados '
        'separadamente do total de pontos do cabeçalho do jogo. Leia Overall '
        'Progress, Precisão (Accuracy), respostas corretas (Correct), Tentativas '
        '(Attempts) e Pontuação (Score); precisão é '
        'corretas divididas por tentativas, enquanto esta Pontuação é respostas '
        'corretas divididas pelo total de desafios. Respostas enviadas somam '
        'tentativas e histórico, e Next Challenge marca um desafio como '
        'concluído. Montar uma sessão nova do jogo ou selecionar Practice Again '
        'zera essas métricas, e eventos de repetição não somam tentativa por si '
        'mesmos. Continue em Limitações.',
    keywords: [
      'lema do bombeamento',
      'Precisão',
      'Corretas',
      'Tentativas',
      'Pontuação'
    ],
  ),
  HelpTopicIds.pumpingEditorResponsiveLayout: HelpNodeCopy(
    title: 'Layout responsivo',
    body: 'O espaço Bombeamento reorganiza Jogo, Ajuda e Progresso conforme a '
        'largura disponível. Use os controles visíveis em vez de esperar um '
        'painel em posição fixa. Abaixo de 1.024 pixels lógicos, os controles '
        'Show ou Hide Game, Help e Progress revelam seções empilhadas; de 1.024 a '
        'menos de 1.400, o jogo permanece principal e Help e Progress usam '
        'abas de tablet; a partir de 1.400, os três aparecem em colunas. Conteúdo '
        'e progresso permanecem iguais durante a mudança de layout. Uma seção '
        'móvel oculta não é limpa nem enviada. Continue na visão geral do espaço.',
    keywords: [
      'lema do bombeamento',
      'celular',
      'tablet',
      'desktop',
      'Show Progress'
    ],
  ),
  'pumping.theory': HelpNodeCopy(
    title: 'Teoria',
    keywords: ['lema do bombeamento', 'teorema', 'quantificadores', 'prova'],
  ),
  HelpTopicIds.pumpingTheoryStatement: HelpNodeCopy(
    title: 'Enunciado do Lema do Bombeamento',
    body: 'O Lema do Bombeamento dá uma propriedade necessária de repetição '
        'para toda linguagem regular. Use-o principalmente para obter '
        'contradição quando uma linguagem não pode ser regular. Suponha L '
        'regular, obtenha comprimento de bombeamento p, tome s suficientemente '
        'longa em L e exija uma decomposição permitida s = xyz cuja parte '
        'central possa ser repetida qualquer número de vezes. Uma linguagem '
        'regular precisa ter tal decomposição para cada membro suficientemente '
        'longo. O teorema não identifica p nem decomposição para uma linguagem '
        'apenas alegada como regular. Continue em Ordem dos quantificadores.',
    keywords: ['lema do bombeamento', 'enunciado', 'linguagem regular', 'xyz'],
  ),
  HelpTopicIds.pumpingTheoryQuantifiers: HelpNodeCopy(
    title: 'Ordem dos quantificadores',
    body: 'A ordem dos quantificadores determina quem escolhe cada objeto no '
        'Lema do Bombeamento e não pode ser rearranjada. Use a ordem para não '
        'provar somente uma decomposição favorável. Para toda linguagem regular '
        'L, existe p ≥ 1 tal que, para toda s ∈ L com |s| ≥ p, existe uma '
        'decomposição s = xyz tal que |xy| ≤ p, |y| > 0 e, para todo k ≥ 0, '
        'xyᵏz ∈ L. Uma prova de não regularidade nega isso respondendo a cada p '
        'com uma testemunha s e vencendo toda decomposição permitida com algum '
        'k. Escolher y por conta própria é insuficiente, pois o lado regular '
        'possui essa escolha existencial. Continue em Estratégia de prova.',
    keywords: ['lema do bombeamento', 'quantificadores', 'para todo', 'existe'],
  ),
  HelpTopicIds.pumpingTheoryProofStrategy: HelpNodeCopy(
    title: 'Estratégia de prova',
    body: 'A estratégia padrão é uma prova por contradição contra a condição '
        'necessária do lema. Use-a quando a linguagem parecer exigir contagem, '
        'cópia ou simetria sem limite. Suponha L regular, tome p como seu '
        'comprimento de bombeamento, escolha s ∈ L com |s| ≥ p, cubra toda '
        'decomposição válida s = xyz e escolha k que leve xyᵏz para fora de L. '
        'A contradição mostra que a hipótese de regularidade era falsa. Não '
        'encontrar testemunha ou expoente não mostra que L é regular. Continue '
        'em Escolher uma testemunha.',
    keywords: [
      'lema do bombeamento',
      'contradição',
      'estratégia',
      'não regular'
    ],
  ),
  HelpTopicIds.pumpingTheoryChooseWitness: HelpNodeCopy(
    title: 'Escolher uma testemunha',
    body: 'A testemunha é uma cadeia s em L cuja estrutura expõe a memória '
        'exigida pela linguagem. Use-a após receber um comprimento de '
        'bombeamento p arbitrário. Defina s em função de p, verifique s ∈ L e '
        '|s| ≥ p e posicione os primeiros p símbolos de modo a restringir todo '
        'y legal. Uma boa testemunha faz o bombeamento alterar contagem, '
        'fronteira, cópia ou simetria obrigatória. Escolher cadeia curta fixa ou '
        'fora de L não contradiz o teorema. Continue em Todas as decomposições.',
    keywords: [
      'lema do bombeamento',
      'testemunha',
      'cadeia s',
      'comprimento p'
    ],
  ),
  HelpTopicIds.pumpingTheoryAllDecompositions: HelpNodeCopy(
    title: 'Cobrir todas as decomposições',
    body: 'A alegação do lado regular pode escolher qualquer decomposição '
        's = xyz que satisfaça |xy| ≤ p e |y| > 0. Use análise de casos quando '
        'y puder ocupar partes diferentes da testemunha. Receba uma '
        'decomposição válida arbitrária, derive o que as restrições impõem a y '
        'e cubra cada posição ou conteúdo restante. A prova vence somente se '
        'cada decomposição permitida tiver algum expoente que a danifique. '
        'Demonstrar uma decomposição conveniente preserva a alegação '
        'existencial. Continue em Encontrar contradição.',
    keywords: ['lema do bombeamento', 'todas as decomposições', '|xy|', '|y|'],
  ),
  HelpTopicIds.pumpingTheoryContradiction: HelpNodeCopy(
    title: 'Encontrar uma contradição',
    body: 'Uma contradição é um expoente k ≥ 0 para o qual xyᵏz não pertence a '
        'L. Use bombeamento para baixo com k = 0 ou para cima com k = 2 quando '
        'um deles quebrar a propriedade definidora. Para uma decomposição legal '
        'arbitrária, calcule a cadeia bombeada e mostre exatamente qual condição '
        'de pertinência falha. O resultado viola a exigência do lema de que todo '
        'k preserve a pertinência. O expoente pode depender da decomposição, mas '
        'o argumento não pode omitir nenhuma decomposição permitida. Continue '
        'em Limitações.',
    keywords: ['lema do bombeamento', 'contradição', 'bombear', 'k'],
  ),
  HelpTopicIds.pumpingTheoryLimitations: HelpNodeCopy(
    title: 'O que o lema não prova',
    body:
        'O Lema do Bombeamento é condição necessária das linguagens regulares, '
        'não uma caracterização completa utilizável nos dois sentidos. Use uma '
        'contradição bem-sucedida para provar uma linguagem não regular. Se '
        'todas as testemunhas tentadas bombearem ou uma decomposição funcionar, '
        'procure testemunha mais forte ou outro teorema. O lema prova não '
        'regularidade; ele não prova regularidade. Um AFD, expressão regular, '
        'gramática regular ou argumento de fechamento pode estabelecer '
        'regularidade, enquanto uma tentativa frustrada de bombeamento não '
        'estabelece nada. Continue no exemplo regular.',
    keywords: ['lema do bombeamento', 'limitação', 'não regularidade', 'AFD'],
  ),
  HelpTopicIds.pumpingTheoryRegularExample: HelpNodeCopy(
    title: 'Exemplo regular: a*',
    body: 'A linguagem L = {aⁿ | n ≥ 0} é regular e é denotada por a*. Use-a '
        'para ver como uma linguagem regular satisfaz a condição de bombeamento '
        'sem confundir essa demonstração com uma prova de regularidade. Para '
        'todo p e aⁿ suficientemente longa, uma decomposição possível é '
        'x = ε, y = a e z = aⁿ⁻¹, de modo que xyᵏz continua sendo cadeia de a '
        'para todo k ≥ 0. Um autômato aceitador de um estado com laço a prova '
        'regularidade independentemente. Exibir apenas essa decomposição '
        'favorável não provaria regular uma linguagem desconhecida. Continue '
        'no exemplo aⁿbⁿ.',
    keywords: ['lema do bombeamento', 'exemplo regular', 'a*', 'autômato'],
  ),
  HelpTopicIds.pumpingTheoryNonregularAnbn: HelpNodeCopy(
    title: 'Exemplo não regular: aⁿbⁿ',
    body: 'A linguagem L = {aⁿbⁿ | n ≥ 0} não é regular porque exige duas '
        'contagens iguais e ilimitadas em blocos. Use-a como padrão clássico de '
        'testemunha e decomposição. Dado p, escolha s = aᵖbᵖ; toda decomposição '
        'com |xy| ≤ p e |y| > 0 coloca y não vazio inteiramente entre os '
        'primeiros símbolos a. Bombear com k = 2 acrescenta a sem acrescentar '
        'b, portanto xy²z fica fora de L. O argumento deve dizer que todo y '
        'legal tem essa forma, não escolher y = a sem justificativa. Continue '
        'no exemplo ww.',
    keywords: [
      'lema do bombeamento',
      'não regular',
      'a^n b^n',
      'contagens iguais'
    ],
  ),
  HelpTopicIds.pumpingTheoryNonregularWw: HelpNodeCopy(
    title: 'Exemplo não regular: ww',
    body: 'A linguagem L = {ww | w ∈ {a,b}*} contém duas cópias consecutivas '
        'idênticas e não é a linguagem dos palíndromos. Use uma testemunha '
        'estruturada como s = aᵖbaᵖb, onde w = aᵖb. Todo y legal nas primeiras '
        'p posições contém somente símbolos a da primeira cópia; bombear altera '
        'essa cópia sem alterar a segunda. A cadeia bombeada não pode mais ser '
        'dividida nas mesmas duas cópias, produzindo contradição. Uma prova '
        'completa deve justificar a conclusão para todo comprimento permitido '
        'de y em vez de depender apenas de um exemplo. Continue em Estratégia '
        'de prova.',
    keywords: [
      'lema do bombeamento',
      'não regular',
      'ww',
      'cadeias duplicadas'
    ],
  ),
  'shortcuts': HelpNodeCopy(
    title: 'Atalhos de teclado',
    keywords: ['teclado', 'atalhos', 'foco', 'teclado físico'],
  ),
  HelpTopicIds.shortcutsCanvas: HelpNodeCopy(
    title: 'Atalhos do canvas',
    body: 'Os atalhos do canvas operam o canvas editável de autômato que está '
        'com foco. Use-os quando houver um teclado físico e o foco estiver fora '
        'de um campo de texto. Pressione A para adicionar um estado no centro '
        'da área visível e manter o modo de adição ativo, T para o modo de '
        'transição, V para o modo de seleção, Delete ou Backspace para remover '
        'o estado ou a transição selecionada, Ctrl+Z ou Cmd+Z para '
        'desfazer e Ctrl+Y, Cmd+Y, Ctrl+Shift+Z ou Cmd+Shift+Z para refazer. A '
        'ferramenta ativa, o grafo e o histórico mudam como mudariam pelos '
        'controles visíveis. Os atalhos de edição não atuam em canvases somente '
        'leitura, e os atalhos de letras ou histórico são ignorados enquanto '
        'um campo de texto tem foco. Escape volta ao modo de seleção ou cancela '
        'o diálogo ou editor atual. Continue em Modificadores por plataforma '
        'ou Navegação por foco.',
    keywords: ['canvas', 'A', 'T', 'V', 'Delete', 'desfazer', 'refazer'],
  ),
  HelpTopicIds.shortcutsSimulation: HelpNodeCopy(
    title: 'Atalhos de simulação',
    body:
        'Os atalhos de simulação operam a entrada e os controles do painel de '
        'simulação atual. Use-os com um teclado físico ao informar uma cadeia '
        'de teste ou percorrer controles. Pressione Enter com o campo de '
        'entrada em foco para enviá-lo, use Tab e Shift+Tab para passar pela '
        'entrada, opções e ações e pressione Enter ou Espaço sobre um botão em '
        'foco. A mesma simulação ou ação em foco é executada e o resultado '
        'aparece no painel. Enter não ignora validação nem um controle '
        'indisponível, e a simulação de AF não tem atalho de cancelamento '
        'durante a execução. Continue em Navegação por foco ou Limites de '
        'simulação.',
    keywords: ['simulação', 'Enter', 'Espaço', 'Tab', 'entrada'],
  ),
  HelpTopicIds.shortcutsDialogsAndForms: HelpNodeCopy(
    title: 'Diálogos e formulários',
    body: 'Os atalhos de diálogos e formulários confirmam, cancelam ou '
        'percorrem um editor ativo. Use-os nos editores de transição, no '
        'diálogo de atalhos de teclado e em outros controles com ações padrão '
        'de teclado. Pressione Enter ou Enter do teclado numérico para enviar '
        'ou ativar, Escape para cancelar, Tab para o próximo campo e Shift+Tab '
        'para o campo anterior. Um formulário válido é enviado, e um overlay '
        'cancelado fecha sem aplicar sua edição pendente. Campos obrigatórios '
        'continuam impedindo uma transição inválida, e a ação exata de Enter '
        'pertence ao controle em foco. Continue em Cancelar e fechar ou '
        'Navegação por foco.',
    keywords: ['diálogo', 'formulário', 'Enter', 'Escape', 'Tab', 'enviar'],
  ),
  HelpTopicIds.shortcutsFocusNavigation: HelpNodeCopy(
    title: 'Navegação por foco',
    body: 'O foco de teclado identifica qual controle recebe a próxima ação de '
        'teclado. Use a navegação por foco quando um ponteiro ou gesto de toque '
        'não for conveniente. Pressione Tab para seguir a ordem de leitura ou '
        'a ordem explícita do formulário, Shift+Tab para voltar e Enter ou '
        'Espaço para ativar o botão em foco. O indicador de foco percorre ações '
        'e campos disponíveis sem alterar o autômato por si só. Controles '
        'ocultos ou desativados não são destinos úteis, e os atalhos de letras '
        'do canvas pausam quando um campo de texto editável tem foco. Continue '
        'em Diálogos e formulários ou Atalhos do canvas.',
    keywords: ['foco', 'Tab', 'Shift Tab', 'Enter', 'Espaço', 'teclado'],
  ),
  HelpTopicIds.shortcutsPlatformModifiers: HelpNodeCopy(
    title: 'Modificadores por plataforma',
    body: 'Os atalhos com modificadores têm variantes equivalentes com Control '
        'e Command quando o canvas registra ambas. Consulte este tópico ao '
        'alternar entre Windows, Linux, Web, macOS, iPadOS ou iOS com teclado '
        'físico. Use Ctrl+Z, Ctrl+Y ou Ctrl+Shift+Z em teclados orientados a '
        'Control e Cmd+Z, Cmd+Y ou Cmd+Shift+Z nas plataformas Apple. O comando '
        'correspondente do histórico do canvas é executado sem mudar de '
        'significado. Esses atalhos exigem teclado físico, um canvas editável '
        'responsável pela ação e nenhum campo de texto consumindo a tecla. '
        'Continue em Atalhos do canvas.',
    keywords: ['Ctrl', 'Cmd', 'Command', 'Apple', 'teclado físico'],
  ),
  HelpTopicIds.shortcutsCancelAndClose: HelpNodeCopy(
    title: 'Cancelar e fechar',
    body: 'Escape cancela o contexto de teclado que possui a tecla naquele '
        'momento. Use-o para sair de um editor de transição, fechar um diálogo '
        'de atalhos ou devolver um canvas editável ao modo de seleção. '
        'Pressione Escape uma vez com o foco dentro do editor, diálogo ou '
        'canvas. Edições pendentes do editor são descartadas, o diálogo de '
        'atalhos fecha ou o canvas limpa a origem de transição e seleciona a '
        'ferramenta de seleção. Escape não promete sair da página de Ajuda nem '
        'cancelar todo algoritmo em execução, pois essas áreas têm ações '
        'próprias. Continue em Diálogos e formulários.',
    keywords: ['Escape', 'cancelar', 'fechar', 'modo de seleção', 'diálogo'],
  ),
  'troubleshooting': HelpNodeCopy(
    title: 'Solução de problemas',
    keywords: ['solução de problemas', 'erro', 'recuperação', 'validação'],
  ),
  HelpTopicIds.troubleshootingInvalidAutomata: HelpNodeCopy(
    title: 'Autômatos inválidos',
    body: 'Um autômato inválido não tem uma estrutura obrigatória ou contém '
        'uma transição que a operação atual não pode usar. Abra este tópico '
        'quando uma simulação ou algoritmo estiver desativado ou retornar uma '
        'mensagem de validação. Leia o estado do espaço, adicione um estado '
        'inicial, adicione um estado de aceitação quando a operação o exigir e '
        'corrija transições incompletas ou conflitantes. A validação muda com o '
        'grafo, e o comando fica utilizável quando seus próprios requisitos são '
        'cumpridos. Algumas análises impõem condições mais estritas que a '
        'edição; por isso, siga a mensagem específica em vez de supor que todo '
        'grafo não vazio é válido. Continue em Marcadores de estado ausentes '
        'ou Não determinismo.',
    keywords: ['autômato inválido', 'validação', 'estado inicial', 'erro'],
  ),
  HelpTopicIds.troubleshootingGrammarInput: HelpNodeCopy(
    title: 'Erros na entrada da gramática',
    body: 'Os erros da entrada da gramática identificam uma produção ou campo '
        'que não pode formar a gramática solicitada. Use este tópico quando uma '
        'linha de produção mostrar erro ou a análise e as conversões rejeitarem '
        'o modelo. Mantenha um não terminal à esquerda, informe símbolos ou '
        'alternativas válidos à direita, use λ ou ε para a palavra vazia e '
        'selecione um símbolo inicial declarado pela gramática. As linhas '
        'corretas permanecem no editor, e o estado ou resultado do comando '
        'informa se a gramática pode prosseguir. Produções vazias, símbolos não '
        'declarados e formas específicas de algoritmo, como FNC, ainda podem '
        'exigir outra correção. Continue em Validação de produções ou '
        'Estratégias de análise.',
    keywords: ['erro de gramática', 'produção', 'símbolo inicial', 'lambda'],
  ),
  HelpTopicIds.troubleshootingRegexInput: HelpNodeCopy(
    title: 'Erros na entrada da expressão regular',
    body: 'Um diagnóstico de expressão regular aponta uma sintaxe que o parser '
        'atual não aceita. Use este tópico quando a validação marcar a expressão '
        'como inválida ou os controles de conversão e teste permanecerem '
        'indisponíveis. Leia a posição do diagnóstico, feche grupos e classes '
        'de caracteres, complete escapes e remova operadores binários ou '
        'pós-fixos mal posicionados; informe um alfabeto quando um curinga ou '
        'atalho complementado precisar dele. Uma expressão corrigida fica '
        'válida e habilita as operações cujas outras entradas estão prontas. '
        'Uma expressão vazia é inválida, enquanto ε representa a palavra vazia '
        'e um λ digitado é um símbolo literal. Continue em Entrada e validação '
        'de Regex.',
    keywords: [
      'erro de regex',
      'diagnóstico',
      'sintaxe',
      'alfabeto',
      'epsilon'
    ],
  ),
  HelpTopicIds.troubleshootingSimulationLimits: HelpNodeCopy(
    title: 'Limites de simulação',
    body: 'Os limites de simulação encerram uma busca que demora demais ou '
        'explora configurações demais. Use este tópico após um timeout, limite '
        'de configurações ou resultado semelhante a laço. Encurte a entrada, '
        'remova ramificações ou laços desnecessários e tente um equivalente '
        'determinístico quando a linguagem permitir; se o aplicativo estiver '
        'lento, reduza autômatos muito grandes ou simplifique grafos com muitas '
        'transições. As execuções de AF, '
        'gramática, AP e MT na tela usam limite de 5 segundos; as buscas de AP '
        'e MT não determinística também limitam a exploração a 100.000 '
        'configurações, e a execução de MT determinística para após 10.000 '
        'passos. O aplicativo retorna uma falha limitada em vez de continuar '
        'indefinidamente. Um timeout não prova rejeição; portanto, inspecione o '
        'modelo antes de mudar a linguagem esperada. Continue em Não '
        'determinismo ou no tópico de simulação do espaço atual.',
    keywords: ['timeout', '5 segundos', 'limite de configurações', 'laço'],
  ),
  HelpTopicIds.troubleshootingParserStrategies: HelpNodeCopy(
    title: 'Estratégias de análise',
    body: 'As estratégias de análise usam algoritmos e requisitos de gramática '
        'diferentes para testar uma cadeia. Use este tópico quando uma '
        'estratégia estiver indisponível, atingir timeout ou contrariar uma '
        'suposição sobre a forma da gramática. Comece com Automatic (Earley) '
        'para análise geral, tente Brute force para uma gramática pequena ou '
        'escolha CYK (Cocke-Younger-Kasami) quando sua tabela e seus passos '
        'forem úteis. O painel retorna aceitação, diagnósticos e qualquer '
        'derivação ou passo disponível. LL(1) está disponível para gramáticas '
        'preditivas sem conflitos; LR continua indisponível. Toda estratégia '
        'continua sujeita ao limite de 5 segundos. Continue no tópico do parser '
        'selecionado.',
    keywords: [
      'parser',
      'Automatic (Earley)',
      'Brute force',
      'CYK',
      'LL',
      'LR'
    ],
  ),
  HelpTopicIds.troubleshootingFileImportExport: HelpNodeCopy(
    title: 'Importação e exportação de arquivos',
    body: 'Erros de arquivo ocorrem quando o arquivo ou a ação escolhida não '
        'corresponde ao espaço e à plataforma atuais. Use este tópico quando o '
        'carregamento falhar, uma ação de exportação não existir ou o seletor '
        'da plataforma não retornar arquivo. Abra o espaço correspondente, '
        'escolha uma ação visível de Load, Save, Export ou Download e tente '
        'novamente com um arquivo compatível que não esteja corrompido. Uma '
        'bem-sucedida substitui o modelo atual, e uma exportação bem-sucedida '
        'cria o formato nomeado pela ação. AP e MT atualmente expõem '
        'exportação SVG, não carregamento ou salvamento JFLAP ou JSON; na Web, '
        'as ações baixam arquivos, e cancelar o seletor não altera o modelo. '
        'Continue em Arquivos e exemplos do espaço atual.',
    keywords: ['erro de arquivo', 'importar', 'exportar', 'JFLAP', 'SVG'],
  ),
  HelpTopicIds.troubleshootingMissingStateMarkers: HelpNodeCopy(
    title: 'Marcadores de estado ausentes',
    body: 'Os marcadores de estado informam onde o autômato começa e quais '
        'estados aceitam. Use este tópico quando a validação informar ausência '
        'de estado inicial, ausência de estado de aceitação ou mais de um '
        'marcador inicial. Selecione um estado, ative Estado inicial em '
        'exatamente um estado e ative Estado de aceitação em cada estado final '
        'pretendido. O canvas desenha os marcadores, e a validação é recalculada '
        'imediatamente. Algumas análises não exigem estado de aceitação, mas '
        'simulações sempre precisam de estado inicial utilizável, e o resultado '
        'de aceitação depende da semântica do espaço. Continue em Autômatos '
        'inválidos ou Estados.',
    keywords: [
      'estado inicial',
      'estado de aceitação',
      'marcador',
      'validação'
    ],
  ),
  HelpTopicIds.troubleshootingNondeterminism: HelpNodeCopy(
    title: 'Não determinismo inesperado',
    body: 'Não determinismo significa que mais de uma próxima configuração '
        'pode ser aplicada à mesma situação atual. Use este tópico quando uma '
        'operação exigir AFD ou o indicador de determinismo informar conflitos. '
        'Inspecione as transições destacadas ou relatadas, remova um movimento '
        'ε ou uma escolha duplicada de entrada não intencional ou converta um '
        'AFN em AFD quando for adequado. O indicador muda, e comandos exclusivos '
        'de modelos determinísticos ficam disponíveis após a remoção de todos '
        'os conflitos relevantes. Transições de AP e MT incluem condições de '
        'pilha ou leitura; por isso, arestas visualmente iguais não são a única '
        'fonte possível de ramificação. Continue em Determinismo e validação ou '
        'na análise de determinismo do espaço.',
    keywords: ['não determinismo', 'AFD', 'AFN', 'epsilon', 'conflito'],
  ),
  HelpTopicIds.troubleshootingLostCanvasView: HelpNodeCopy(
    title: 'Visualização perdida no canvas',
    body: 'Uma visualização perdida significa que o modelo ainda existe, mas o '
        'zoom ou deslocamento o levou para fora da área útil. Use este tópico '
        'quando o canvas parecer vazio ou os estados estiverem pequenos demais '
        'para selecionar. Escolha Ajustar ao conteúdo para enquadrar todos os '
        'estados atuais e depois use Redefinir visualização se quiser o zoom e '
        'a origem padrão; os botões de zoom e o gesto de pinça podem refinar o '
        'resultado. Somente a visualização muda, e os dados do grafo permanecem '
        'intactos. Um grafo vazio não tem conteúdo para enquadrar, e o ajuste '
        'não reorganiza estados sobrepostos. Continue no tópico de visualização '
        'do espaço atual.',
    keywords: [
      'Ajustar ao conteúdo',
      'Redefinir visualização',
      'zoom',
      'canvas vazio'
    ],
  ),
  'about': HelpNodeCopy(
    title: 'Sobre',
    keywords: ['sobre', 'projeto', 'licenças', 'créditos'],
  ),
  HelpTopicIds.aboutDeveloperAndProject: HelpNodeCopy(
    title: 'Desenvolvedor e projeto',
    body: 'O Turing Lab é desenvolvido por Thales Matheus Mendonça Santos. Use '
        'este tópico para identificar o projeto e localizar seu repositório '
        'público de código-fonte. Abra Licenças e use o controle Repositório do '
        'projeto para abrir https://github.com/ThalesMMS/Turing-Lab. O link '
        'sai do aplicativo para o navegador da plataforma quando ela consegue '
        'abri-lo. A falta de rede ou de associação com um '
        'navegador pode impedir a abertura sem alterar o trabalho local. '
        'Continue em Licenças ou Agradecimentos.',
    keywords: [
      'desenvolvedor',
      'Thales',
      'repositório',
      'GitHub',
      'Turing-Lab'
    ],
  ),
  HelpTopicIds.aboutLicenses: HelpNodeCopy(
    title: 'Licenças',
    body: 'O Turing Lab é uma reimplementação em Flutter inspirada no JFLAP e '
        'compatível com ele, não uma versão oficial do JFLAP. Use este tópico '
        'para inspecionar os termos e avisos incluídos no aplicativo. Expanda '
        'Apache License 2.0 para o código Flutter original do Turing Lab, '
        'Licença do JFLAP 7.1 para as partes derivadas do JFLAP, GraphView (MIT '
        'License), Avisos de terceiros das plataformas Apple para o fork '
        'incluído do GraphView e dependências de plugins Apple ou Licenças dos '
        'pacotes informadas pelo Flutter. Cada controle carrega ou abre a fonte '
        'de licença incluída correspondente. O texto incluído pode informar '
        'falha de carregamento, e as licenças de pacotes ficam separadas dos '
        'quatro arquivos de texto incluídos. Continue em Agradecimentos ou '
        'Distribuição.',
    keywords: ['licença', 'Apache License 2.0', 'JFLAP 7.1', 'MIT'],
  ),
  HelpTopicIds.aboutAcknowledgments: HelpNodeCopy(
    title: 'Agradecimentos',
    body: 'Os agradecimentos creditam as pessoas e projetos cujo trabalho está '
        'representado no Turing Lab. Use este tópico para as atribuições de '
        'JFLAP e GraphView que acompanham os avisos de licença. Ele cita Susan '
        'H. Rodger, da Duke University; Thomas Finley, Ryan Cavalcante, Stephen '
        'Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) '
        'Lee, Jonathan Su e Henry Qin; e Nabil Mosharraf, autor do GraphView. O '
        'projeto original está em http://www.jflap.org, e o fork mantido do '
        'GraphView permanece sob a licença MIT. Esses créditos não tornam o '
        'Turing Lab uma versão oficial do JFLAP. Continue em Licenças ou '
        'Distribuição.',
    keywords: ['Susan Rodger', 'Duke University', 'equipe JFLAP', 'GraphView'],
  ),
  HelpTopicIds.aboutDistribution: HelpNodeCopy(
    title: 'Distribuição',
    body: 'A distribuição descreve como esta versão é oferecida enquanto '
        'contém material derivado do JFLAP. Consulte-a antes de descrever ou '
        'redistribuir o aplicativo. O Turing Lab é distribuído como um '
        'aplicativo educacional gratuito e não monetizado enquanto incluir '
        'esse material, junto com as licenças e avisos nomeados neste catálogo '
        'de Ajuda. Os usuários recebem o aplicativo sob esses termos declarados '
        'do projeto e de terceiros. A distribuição gratuita não substitui '
        'nenhum aviso Apache, JFLAP, MIT, de pacote ou de plataforma. Continue '
        'em Licenças.',
    keywords: ['distribuição', 'gratuito', 'não monetizado', 'educacional'],
  ),
});
