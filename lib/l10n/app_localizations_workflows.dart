import 'app_localizations.dart';

/// Presentation-only bridge for legacy algorithm prose.
///
/// Core algorithms still expose human-readable English in some structured
/// traces. Renderers pass that prose through this adapter so locale concerns do
/// not leak into the core model. New controls and summaries should use the
/// generated ARB getters directly; this bridge can shrink as trace payloads gain
/// stable message keys and arguments.
extension AppLocalizationsWorkflows on AppLocalizations {
  String localizeWorkflowText(String source) {
    final common = switch (source) {
      'Simulation' => simulation,
      'Input String' => inputString,
      'Leave blank for ε; whitespace is preserved' => simulationInputHint,
      'Simulate' => simulate,
      'Simulating...' => simulating,
      'Cancel simulation' => cancelSimulation,
      'Run simulation' => runSimulation,
      'Runs the machine using the currently entered input string.' =>
        runSimulationHint,
      'Simulation Result' => simulationResult,
      'Regex Result' => regexResult,
      'Regular Expression' => regularExpression,
      'Step-by-Step Mode' => stepByStepMode,
      'Step-by-Step Execution' => stepByStepExecution,
      'Play' => play,
      'Pause' => pause,
      'Reset' => reset,
      'Expand' => expand,
      'Collapse' => collapse,
      'No steps recorded' => noStepsRecorded,
      'No steps available' => noStepsAvailable,
      'No steps' => noSteps,
      'Timeline' => timeline,
      'Timeline scrubber' => timelineScrubber,
      'No simulation results yet' => noSimulationResults,
      'Enter an input string and click Simulate to see results' =>
        simulationEmptyHint,
      'Accepted' => accepted,
      'Rejected' => rejected,
      'Suggested fixes' => suggestedFixes,
      'Automaton has no states' => automatonHasNoStates,
      'Cannot simulate empty automaton' => cannotSimulateEmptyAutomaton,
      'PDA has no states' => pdaHasNoStates,
      'TM has no states' => tmHasNoStates,
      'Automaton must have at least one state' =>
        automatonMustHaveAtLeastOneState,
      'Cannot convert empty automaton to regex' =>
        cannotConvertEmptyAutomatonToRegex,
      'FA must have at least one state' => faMustHaveAtLeastOneState,
      'NFA must have at least one state' => nfaMustHaveAtLeastOneState,
      'DFA must have at least one state' => dfaMustHaveAtLeastOneState,
      'PDA must have at least one state' => pdaMustHaveAtLeastOneState,
      'Turing machine must have at least one state' =>
        tmMustHaveAtLeastOneState,
      'Turing machine must have at least one state.' =>
        tmMustHaveAtLeastOneStatePeriod,
      'Automaton A must have at least one state' =>
        automatonAMustHaveAtLeastOneState,
      'Automaton B must have at least one state' =>
        automatonBMustHaveAtLeastOneState,
      'Cannot create game with empty automaton' =>
        cannotCreateGameWithEmptyAutomaton,
      'Untitled Automaton' => untitledAutomaton,
      'Canvas PDA' => canvasPda,
      'Canvas TM' => canvasTm,
      'Simulation failed' => simulationFailed,
      'Simulation cancelled' => simulationCancelled,
      'EQUIVALENT' => equivalent,
      'NOT EQUIVALENT' => notEquivalent,
      'Automaton A' => automatonA,
      'Automaton B' => automatonB,
      _ => null,
    };
    if (common != null) {
      return common;
    }

    if (!localeName.startsWith('pt')) {
      return workflowLegacyText(source);
    }

    final exact = _ptWorkflowCopy[source];
    if (exact != null) {
      return workflowLegacyText(exact);
    }

    var translated = source;
    for (final replacement in _ptWorkflowReplacements) {
      translated = translated.replaceAll(replacement.$1, replacement.$2);
    }
    for (final pattern in _ptWorkflowPatterns) {
      translated = translated.replaceAllMapped(pattern.$1, pattern.$2);
    }
    return workflowLegacyText(translated);
  }
}

const _ptWorkflowCopy = <String, String>{
  'Algorithms': 'Algoritmos',
  'Files': 'Arquivos',
  'Undo edit': 'Desfazer edição',
  'Redo edit': 'Refazer edição',
  'Cancel expansion': 'Cancelar expansão',
  'Definition': 'Definição',
  'Axiom tokens': 'Tokens do axioma',
  'Separate symbols with spaces.': 'Separe os símbolos com espaços.',
  'Parallel production rules': 'Regras de produção paralela',
  'Use F -> F + F, or L < F > R @2 -> G for contexts and weights.':
      'Use F -> F + F ou L < F > R @2 -> G para contextos e pesos.',
  'Turtle command mapping': 'Mapeamento de comandos da tartaruga',
  'One token = command per line, for example F = drawForward.':
      'Um token = comando por linha, por exemplo F = drawForward.',
  'Iterations': 'Iterações',
  'Angle °': 'Ângulo °',
  'Step length': 'Comprimento do passo',
  'Step Data': 'Dados da etapa',
  'Typed Step Data': 'Dados tipados da etapa',
  'CYK Step Data': 'Dados da etapa CYK',
  'NFA→DFA': 'AFN→AFD',
  'Minimize': 'Minimizar',
  'FA→Regex': 'AF→Expressão regular',
  'Regex→NFA': 'Expressão regular→AFN',
  'CYK Parse': 'Análise CYK',
  'Simplify': 'Simplificar',
  'Concatenate': 'Concatenar',
  'Kleene Star': 'Estrela de Kleene',
  'Reverse': 'Inverter',
  'Current States': 'Estados atuais',
  'Visited States': 'Estados visitados',
  'Empty Set': 'Conjunto vazio',
  'Empty List': 'Lista vazia',
  'Is Accepting State': 'É estado de aceitação',
  'Has Transitions': 'Tem transições',
  'Current State': 'Estado atual',
  'Next State To Process': 'Próximo estado a processar',
  'Operation': 'Operação',
  'Current states': 'Estados atuais',
  'Processed symbol': 'Símbolo processado',
  'Epsilon closure': 'Fecho-ε',
  'Reachable states': 'Estados alcançáveis',
  'Next state set': 'Conjunto do próximo estado',
  'New state': 'Novo estado',
  'DFA state': 'Estado do AFD',
  'Partition size': 'Tamanho da partição',
  'Processing set': 'Conjunto em processamento',
  'Distinguishing symbol': 'Símbolo diferenciador',
  'Predecessors': 'Predecessores',
  'Split set': 'Conjunto dividido',
  'Caused split': 'Causou divisão',
  'Equivalence class': 'Classe de equivalência',
  'Regex fragment': 'Fragmento de expressão regular',
  'Active syntax node and fragment invariant':
      'Nó sintático ativo e invariante do fragmento',
  'Regex position': 'Posição na expressão regular',
  'Created states': 'Estados criados',
  'Created transitions': 'Transições criadas',
  'Fragment start': 'Início do fragmento',
  'Fragment accept': 'Aceitação do fragmento',
  'Stack size': 'Tamanho da pilha',
  'Final NFA': 'AFN final',
  'Cell': 'Célula',
  'Substring': 'Subcadeia',
  'Terminal': 'Terminal',
  'Split point': 'Ponto de divisão',
  'Left cell': 'Célula esquerda',
  'Right cell': 'Célula direita',
  'Left variables': 'Variáveis à esquerda',
  'Right variables': 'Variáveis à direita',
  'Added variable': 'Variável adicionada',
  'Cell variables': 'Variáveis da célula',
  'Accepted': 'Aceita',
  'Output': 'Saída',
  'Undefined transition': 'Transição indefinida',
  'Conflict': 'Conflito',
  'Bounded unknown': 'Desconhecido dentro dos limites',
  'Model error': 'Erro do modelo',
  'Stale request': 'Solicitação obsoleta',
  'Cell modified': 'Célula modificada',
  'Fill Base Case': 'Preencher caso base',
  'Scale': 'Escala',
  'Heading °': 'Direção °',
  'Origin X': 'Origem X',
  'Origin Y': 'Origem Y',
  'Line width': 'Largura da linha',
  'Width change': 'Variação da largura',
  'Hue change °': 'Variação do matiz °',
  'Random seed': 'Semente aleatória',
  'Context-ignored tokens': 'Tokens ignorados no contexto',
  'Space-separated, for example + - [ ].':
      'Separados por espaços, por exemplo + - [ ].',
  'Apply and expand': 'Aplicar e expandir',
  'Pause generation playback': 'Pausar reprodução das gerações',
  'Play generations': 'Reproduzir gerações',
  'Reset viewport': 'Redefinir visualização',
  'No geometry to display.': 'Nenhuma geometria para exibir.',
  'Generated tokens': 'Tokens gerados',
  'No generated word.': 'Nenhuma palavra gerada.',
  'Empty word.': 'Palavra vazia.',
  'Ready.': 'Pronto.',
  'Expanding in parallel…': 'Expandindo em paralelo…',
  'Expansion complete.': 'Expansão concluída.',
  'Expansion cancelled.': 'Expansão cancelada.',
  'The L-system is invalid.': 'O sistema L é inválido.',
  'The L-system definition is invalid.': 'A definição do sistema L é inválida.',
  'Animation is disabled by reduced-motion settings.':
      'A animação está desativada pelas configurações de movimento reduzido.',
  'SVG export ready.': 'Exportação SVG pronta.',
  'PNG export ready.': 'Exportação PNG pronta.',
  'Iterations must be zero or greater.':
      'As iterações devem ser zero ou maiores.',
  'Rendering cancelled.': 'Renderização cancelada.',
  'Rendering stopped at the segment limit.':
      'A renderização parou no limite de segmentos.',
  'Imported document is not an L-system.':
      'O documento importado não é um sistema L.',
  'Imported document is not an unrestricted grammar.':
      'O documento importado não é uma gramática irrestrita.',
  'Expected an unrestricted grammar.': 'Era esperada uma gramática irrestrita.',
  'Unsupported unrestricted grammar session.':
      'A sessão da gramática irrestrita não é compatível.',
  'Case ID': 'ID do caso',
  'Explicit input tokens': 'Tokens explícitos de entrada',
  'Timeout': 'Limite de tempo',
  'Retained trace limit': 'Limite do traço retido',
  'Model ID': 'ID do modelo',
  'Model revision': 'Revisão do modelo',
  'Strategy ID': 'ID da estratégia',
  'Maximum concurrency': 'Concorrência máxima',
  'Batch size': 'Tamanho do lote',
  'Request generation': 'Geração da solicitação',
  'Batch execution': 'Execução em lote',
  'Inputs, one case per line': 'Entradas, um caso por linha',
  'Use spaces between tokens and ε for the empty word.':
      'Use espaços entre tokens e ε para a palavra vazia.',
  'Use ε for the empty word. Whitespace is preserved.':
      'Use ε para a palavra vazia. O espaço em branco é preservado.',
  'Add case': 'Adicionar caso',
  'Import TXT/CSV': 'Importar TXT/CSV',
  'Max length': 'Comprimento máximo',
  'Max cases': 'Máximo de casos',
  'Generate words': 'Gerar palavras',
  'Cancel batch': 'Cancelar lote',
  'Run batch': 'Executar lote',
  'Comparing…': 'Comparando…',
  'Compare model': 'Comparar modelo',
  'Export JSON': 'Exportar JSON',
  'Export CSV': 'Exportar CSV',
  'Limits and execution settings': 'Limites e configurações de execução',
  'Strategy': 'Estratégia',
  'Tokenization': 'Tokenização',
  'Retain traces': 'Reter traços',
  'Concurrency': 'Concorrência',
  'Stop after first non-success outcome':
      'Parar após o primeiro resultado não bem-sucedido',
  'Timeout (s)': 'Tempo limite (s)',
  'Trace steps': 'Passos do traço',
  'Raw string': 'Cadeia bruta',
  'Unicode symbols': 'Símbolos Unicode',
  'Explicit tokens': 'Tokens explícitos',
  'No traces': 'Sem traços',
  'Failures only': 'Somente falhas',
  'Selected case': 'Caso selecionado',
  'All cases': 'Todos os casos',
  'Partial results': 'Resultados parciais',
  'Filter input, status, or diagnostic':
      'Filtrar entrada, estado ou diagnóstico',
  'Sort': 'Ordenar',
  'Input order': 'Ordem de entrada',
  'Outcome': 'Resultado',
  'Elapsed time': 'Tempo decorrido',
  'No results match the current filter.':
      'Nenhum resultado corresponde ao filtro atual.',
  'Results cleared because the model changed.':
      'Resultados limpos porque o modelo mudou.',
  'Add at least one case. Use ε for the empty word.':
      'Adicione pelo menos um caso. Use ε para a palavra vazia.',
  'No differences found in these finite cases. This is not a proof of general equivalence.':
      'Nenhuma diferença encontrada nestes casos finitos. Isso não é uma prova de equivalência geral.',
  'Rerun with trace': 'Executar novamente com traço',
  'Open trace': 'Abrir traço',
  'Rerun this case': 'Executar este caso novamente',
  'Remove this case': 'Remover este caso',
  'The executor returned no trace for this case.':
      'O executor não retornou um traço para este caso.',
  'Added an empty-word case.': 'Caso de palavra vazia adicionado.',
  'Generation length must be non-negative and count positive.':
      'O comprimento da geração deve ser não negativo e a quantidade positiva.',
  'The model has no alphabet; only ε can be generated.':
      'O modelo não tem alfabeto; somente ε pode ser gerado.',
  'Finite comparison complete. It does not prove general equivalence.':
      'Comparação finita concluída. Isso não prova equivalência geral.',
  'Comparing the same finite input cases…':
      'Comparando os mesmos casos de entrada finitos…',
  'Batch cancelled; completed and cancelled cases are retained.':
      'Lote cancelado; os casos concluídos e cancelados foram mantidos.',
  'Trace rerun cancelled.': 'Nova execução com traço cancelada.',
  'Trace rerun complete.': 'Nova execução com traço concluída.',
  'Cancelling batch…': 'Cancelando lote…',
  'Settings changed; run the batch again.':
      'As configurações mudaram; execute o lote novamente.',
  'Show detailed algorithm execution steps with explanations':
      'Mostrar etapas detalhadas da execução do algoritmo com explicações',
  'Practice FA to Regex': 'Praticar AF para expressão regular',
  'Construct the state-elimination result yourself with validated steps and hints.':
      'Construa você mesmo o resultado da eliminação de estados com etapas validadas e dicas.',
  'Practice FA to Regular Grammar': 'Praticar AF para gramática regular',
  'Map states and transitions to a right-linear grammar with source provenance.':
      'Mapeie estados e transições para uma gramática linear à direita com proveniência da origem.',
  'Building union automaton...': 'Construindo o autômato da união...',
  'Union complete': 'União concluída',
  'Building concatenation NFA...': 'Construindo o AFN da concatenação...',
  'Concatenation complete': 'Concatenação concluída',
  'Building intersection automaton...':
      'Construindo o autômato da interseção...',
  'Intersection complete': 'Interseção concluída',
  'Building difference automaton...': 'Construindo o autômato da diferença...',
  'Difference complete': 'Diferença concluída',
  'Comparing automata...': 'Comparando autômatos...',
  'Add state': 'Adicionar estado',
  'Add transition': 'Adicionar transição',
  'Add states, then mark one entry state and any exits.':
      'Adicione estados e marque um estado de entrada e as saídas.',
  'No transitions in this fragment yet.':
      'Ainda não há transições neste fragmento.',
  'Check fragment': 'Verificar fragmento',
  'Active syntax node': 'Nó sintático ativo',
  'Fragment invariant': 'Invariante do fragmento',
  'State and transition IDs must be unique. New IDs include the syntax-node ID to avoid sibling collisions.':
      'Os IDs de estados e transições devem ser únicos. Novos IDs incluem o ID do nó sintático para evitar colisões entre irmãos.',
  'entry': 'entrada',
  'accepting': 'aceitação',
  'ordinary': 'comum',
  'Edit state': 'Editar estado',
  'Remove state': 'Remover estado',
  'Edit transition': 'Editar transição',
  'Remove transition': 'Remover transição',
  'Transition removed.': 'Transição removida.',
  'Remove state?': 'Remover estado?',
  'State added.': 'Estado adicionado.',
  'State updated.': 'Estado atualizado.',
  'State removed.': 'Estado removido.',
  'Add a state before adding a transition.':
      'Adicione um estado antes de adicionar uma transição.',
  'Transition added.': 'Transição adicionada.',
  'Transition updated.': 'Transição atualizada.',
  'Add at least one state.': 'Adicione pelo menos um estado.',
  'Add at least one state': 'Adicione pelo menos um estado',
  'Mark a start state': 'Marque um estado inicial',
  'Select a state and set it as the initial/start state.':
      'Selecione um estado e defina-o como estado inicial.',
  'Create a state on the canvas before adding transitions.':
      'Crie um estado no canvas antes de adicionar transições.',
  'Reassign the start state to an existing state':
      'Atribua o estado inicial a um estado existente',
  'Define an alphabet': 'Defina um alfabeto',
  'Add the symbol to the alphabet': 'Adicione o símbolo ao alfabeto',
  'Either add the transition symbol to the automaton alphabet, or edit the transition to use an existing symbol.':
      'Adicione o símbolo da transição ao alfabeto do autômato ou edite a transição para usar um símbolo existente.',
  'Make transitions deterministic': 'Torne as transições determinísticas',
  'Fix accepting state reference':
      'Corrija a referência do estado de aceitação',
  'Mark an accepting state': 'Marque um estado de aceitação',
  'Define the input alphabet': 'Defina o alfabeto de entrada',
  'Define the stack alphabet': 'Defina o alfabeto da pilha',
  'Fix the initial stack symbol': 'Corrija o símbolo inicial da pilha',
  'Fix the input symbol': 'Corrija o símbolo de entrada',
  'Fix the stack pop symbol': 'Corrija o símbolo removido da pilha',
  'Fix the stack push symbol': 'Corrija o símbolo empilhado',
  'Mark an accepting (halt) state': 'Marque um estado de aceitação (parada)',
  'Add input symbols that may appear in the input string.':
      'Adicione símbolos de entrada que possam aparecer na cadeia de entrada.',
  'Define the tape alphabet': 'Defina o alfabeto da fita',
  'Set a blank symbol': 'Defina um símbolo branco',
  'Add blank symbol to tape alphabet':
      'Adicione o símbolo branco ao alfabeto da fita',
  'Make input alphabet a subset of tape alphabet':
      'Faça o alfabeto de entrada ser um subconjunto do alfabeto da fita',
  'Fix tape symbols in transition': 'Corrija os símbolos da fita na transição',
  'Add at least one production': 'Adicione pelo menos uma produção',
  'Set the start symbol': 'Defina o símbolo inicial',
  'Use a non-terminal as start symbol':
      'Use um não terminal como símbolo inicial',
  'Fix the production': 'Corrija a produção',
  'Enter an input string': 'Informe uma cadeia de entrada',
  'Remove or replace the invalid symbol':
      'Remova ou substitua o símbolo inválido',
  'Mark exactly one entry state.': 'Marque exatamente um estado de entrada.',
  'State ID': 'ID do estado',
  'Use a unique ID in this construction.': 'Use um ID único nesta construção.',
  'Display label': 'Rótulo de exibição',
  'Shown in the automaton editor.': 'Exibido no editor de autômatos.',
  'Entry state': 'Estado de entrada',
  'The fragment must have exactly one.': 'O fragmento deve ter exatamente um.',
  'Marks an exit from this fragment.': 'Marca uma saída deste fragmento.',
  'Save state': 'Salvar estado',
  'Enter a state ID.': 'Informe um ID de estado.',
  'Use a unique state ID.': 'Use um ID de estado único.',
  'Transition ID': 'ID da transição',
  'From state': 'Do estado',
  'To state': 'Para o estado',
  'Epsilon transition': 'Transição ε',
  'Consumes no input symbol.': 'Não consome símbolo de entrada.',
  'Input symbols': 'Símbolos de entrada',
  'Save transition': 'Salvar transição',
  'Enter a transition ID.': 'Informe um ID de transição.',
  'Use a unique transition ID.': 'Use um ID de transição único.',
  'Choose an input symbol or epsilon.': 'Escolha um símbolo de entrada ou ε.',
  'Turing machine acceptance policy':
      'Política de aceitação da máquina de Turing',
  'Acceptance policy': 'Política de aceitação',
  'Saved with this TM document': 'Salva com este documento de MT',
  'Final state': 'Estado final',
  'Halting': 'Parada',
  'Final state or halting': 'Estado final ou parada',
  'Accept when a final state is entered.':
      'Aceite quando um estado final for alcançado.',
  'Accept when execution halts, even outside a final state.':
      'Aceite quando a execução parar, mesmo fora de um estado final.',
  'Accept when a final state is entered or execution halts.':
      'Aceite quando um estado final for alcançado ou a execução parar.',
  'entered a final state': 'entrou em um estado final',
  'halted in a final state': 'parou em um estado final',
  'halted outside a final state': 'parou fora de um estado final',
  'reachable configurations were exhausted':
      'as configurações alcançáveis foram esgotadas',
  'an exact configuration repeated': 'uma configuração exata se repetiu',
  'the step limit was reached': 'o limite de passos foi atingido',
  'the configuration limit was reached':
      'o limite de configurações foi atingido',
  'the timeout was reached': 'o limite de tempo foi atingido',
  'the simulation was cancelled': 'a simulação foi cancelada',
  'the machine is invalid': 'a máquina é inválida',
  'Simulation Steps:': 'Passos da simulação:',
  'Step limit reached; the result is inconclusive':
      'Limite de passos atingido; o resultado é inconclusivo',
  'Configuration limit reached; the result is inconclusive':
      'Limite de configurações atingido; o resultado é inconclusivo',
  'Simulation timed out': 'A simulação excedeu o limite de tempo',
  'Infinite loop detected': 'Loop infinito detectado',
  'Simulation inconclusive': 'Simulação inconclusiva',
  'Invalid machine': 'Máquina inválida',
  'Grammar Analysis': 'Análise da gramática',
  'PDA Analysis': 'Análise do AP',
  'TM Analysis': 'Análise da MT',
  'PDA Simulation': 'Simulação de AP',
  'TM Simulation': 'Simulação de MT',
  'Simulation Input': 'Entrada da simulação',
  'Initial Stack Symbol': 'Símbolo inicial da pilha',
  'Record step-by-step trace': 'Registrar traço passo a passo',
  'Simulate PDA': 'Simular AP',
  'Simulate TM': 'Simular MT',
  'Simulation Results': 'Resultados da simulação',
  'Simulation error': 'Erro de simulação',
  'Grammar Parser': 'Analisador de gramática',
  'Parsing Algorithm': 'Algoritmo de análise',
  'Test String': 'Cadeia de teste',
  'Parsing...': 'Analisando...',
  'Parse String': 'Analisar cadeia',
  'Parse Results': 'Resultados da análise',
  'No parse results yet': 'Nenhum resultado de análise',
  'Enter a string and click Parse to see results':
      'Informe uma cadeia e ative Analisar para ver os resultados',
  'Batch parsing': 'Análise em lote',
  'Run ordered cases with Earley, CYK, LL(1), LR(1), or brute force':
      'Execute casos ordenados com Earley, CYK, LL(1), LR(1) ou força bruta',
  'Grammar batch execution': 'Execução em lote de gramáticas',
  'Automatic (Earley)': 'Automático (Earley)',
  'Brute force': 'Força bruta',
  'LL(1) Steps': 'Passos LL(1)',
  'LL(1) teaching workspace': 'Ambiente didático LL(1)',
  'LL(1) conflict': 'Conflito LL(1)',
  'Canonical LR(1)': 'LR(1) canônico',
  'Canonical LR(1) conflict': 'Conflito LR(1) canônico',
  'Canonical collection': 'Coleção canônica',
  'ACTION / GOTO table': 'Tabela ACTION / GOTO',
  'Canonical LR(1) ACTION and GOTO table':
      'Tabela ACTION e GOTO LR(1) canônica',
  'State': 'Estado',
  'No source items': 'Nenhum item de origem',
  'Shift/reduce': 'Deslocamento/redução',
  'Reduce/reduce': 'Redução/redução',
  'Actions': 'Ações',
  'Witness prefix': 'Prefixo testemunha',
  'Reset execution': 'Reiniciar execução',
  'Previous step': 'Passo anterior',
  'Pause execution': 'Pausar execução',
  'Play execution': 'Reproduzir execução',
  'Next step': 'Próximo passo',
  'Diagnostic': 'Diagnóstico',
  'State stack': 'Pilha de estados',
  'Symbol stack': 'Pilha de símbolos',
  'Lookup': 'Consulta',
  'Reduction': 'Redução',
  'The parser stack and input both reached the end marker.':
      'A pilha do analisador e a entrada chegaram ao marcador final.',
  'LL(1) parsing was cancelled.': 'A análise LL(1) foi cancelada.',
  'LL(1) parser stopped with an empty stack.':
      'O analisador LL(1) parou com a pilha vazia.',
  'Canonical LR(1) parsing was cancelled.':
      'A análise LR(1) canônica foi cancelada.',
  'LR(1) reduction would underflow the parser stack.':
      'A redução LR(1) faria a pilha do analisador ficar sem elementos.',
  'Shift-reduce execution': 'Execução por deslocamento e redução',
  'Transitions': 'Transições',
  'Conflicts (all actions preserved)': 'Conflitos (todas as ações preservadas)',
  'Time limit reached': 'Limite de tempo atingido',
  'Step limit reached': 'Limite de passos atingido',
  'Invalid input': 'Entrada inválida',
  'Unable to tokenize input': 'Não foi possível tokenizar a entrada',
  'Bounded search options': 'Opções de busca limitada',
  'Bounded brute-force search': 'Busca limitada por força bruta',
  'Derivation mode': 'Modo de derivação',
  'Leftmost': 'Mais à esquerda',
  'Rightmost': 'Mais à direita',
  'All positions': 'Todas as posições',
  'Maximum depth': 'Profundidade máxima',
  'Maximum frontier size': 'Tamanho máximo da fronteira',
  'Maximum explored nodes': 'Máximo de nós explorados',
  'Maximum retained states': 'Máximo de estados retidos',
  'Maximum symbol count': 'Máximo de símbolos',
  'Witness limit': 'Limite de testemunhos',
  'Operations per batch': 'Operações por lote',
  'depth': 'profundidade',
  'frontier': 'fronteira',
  'explored nodes': 'nós explorados',
  'retained states': 'estados retidos',
  'symbol count': 'quantidade de símbolos',
  'time': 'tempo',
  'Time limit (ms)': 'Limite de tempo (ms)',
  'Cancel search': 'Cancelar busca',
  'Recursive grammars can grow quickly. A reached limit is inconclusive, not rejection.':
      'Gramáticas recursivas podem crescer rapidamente. Atingir um limite é inconclusivo, não uma rejeição.',
  'Search limits must be whole numbers.':
      'Os limites da busca devem ser números inteiros.',
  'Derivation witness': 'Testemunho de derivação',
  'Selected derivation tree': 'Árvore de derivação selecionada',
  'Copy JSON report': 'Copiar relatório JSON',
  'Structured report copied': 'Relatório estruturado copiado',
  'Explored': 'Explorados',
  'Generated': 'Gerados',
  'Frontier / peak': 'Fronteira / pico',
  'Depth': 'Profundidade',
  'Pruned': 'Podados',
  'Witnesses': 'Testemunhos',
  'Elapsed': 'Tempo decorrido',
  'Reached limit': 'Limite atingido',
  'terminal count': 'quantidade de terminais',
  'terminal prefix': 'prefixo terminal',
  'terminal suffix': 'sufixo terminal',
  'terminal subsequence': 'subsequência terminal',
  'minimum yield': 'derivação mínima',
  'duplicate witness': 'testemunho duplicado',
  'Pruned by reason': 'Podados por motivo',
  'Previous derivation step': 'Passo anterior da derivação',
  'Next derivation step': 'Próximo passo da derivação',
  'Reset derivation': 'Reiniciar derivação',
  'Before': 'Antes',
  'After': 'Depois',
  'The start symbol is the witness.': 'O símbolo inicial é o testemunho.',
  'Start user-controlled derivation': 'Iniciar derivação controlada',
  'Start a new user-controlled derivation': 'Iniciar nova derivação controlada',
  'User-controlled derivation': 'Derivação controlada pelo usuário',
  'Target': 'Alvo',
  'Copy structured derivation': 'Copiar derivação estruturada',
  'Structured derivation copied': 'Derivação estruturada copiada',
  'Any occurrence': 'Qualquer ocorrência',
  'Challenge rules': 'Regras do desafio',
  'Restart before changing the derivation mode.':
      'Reinicie antes de alterar o modo de derivação.',
  'Current sentential form': 'Forma sentencial atual',
  'Choose a production': 'Escolha uma produção',
  'No matching occurrence': 'Nenhuma ocorrência correspondente',
  'Choose the exact occurrence': 'Escolha a ocorrência exata',
  'Move preview': 'Prévia do passo',
  'Apply this move': 'Aplicar este passo',
  'Undo move': 'Desfazer passo',
  'Redo move': 'Refazer passo',
  'Start a new session': 'Iniciar nova sessão',
  'Cancel hint search': 'Cancelar busca de dica',
  'Request bounded hint': 'Solicitar dica limitada',
  'Preview suggested move': 'Visualizar passo sugerido',
  'Derivation history': 'Histórico da derivação',
  'Branch here': 'Ramificar aqui',
  'Current derivation tree': 'Árvore de derivação atual',
  'Choose the next derivation move.': 'Escolha o próximo passo da derivação.',
  'Target reached': 'Alvo atingido',
  'Local dead end. This is not proof that the grammar cannot derive the target.':
      'Beco sem saída local. Isso não prova que a gramática não possa derivar o alvo.',
  'The grammar or target changed. Start a new session.':
      'A gramática ou o alvo mudou. Inicie uma nova sessão.',
  'The grammar is invalid.': 'A gramática é inválida.',
  'The target is invalid.': 'O alvo é inválido.',
  'This derivation mode is not available for the grammar.':
      'Este modo de derivação não está disponível para a gramática.',
  'Challenge rules are missing.': 'As regras do desafio estão ausentes.',
  'The source grammar changed.': 'A gramática de origem mudou.',
  'The target changed.': 'O alvo mudou.',
  'The derivation is already complete.': 'A derivação já está concluída.',
  'The selected production no longer exists.':
      'A produção selecionada não existe mais.',
  'The production does not match at that token position.':
      'A produção não corresponde nessa posição de token.',
  'That occurrence is not allowed by the selected derivation mode.':
      'Essa ocorrência não é permitida pelo modo de derivação selecionado.',
  'Challenge rules do not allow that production.':
      'As regras do desafio não permitem essa produção.',
  'The challenge step limit was reached.':
      'O limite de passos do desafio foi atingido.',
  'This terminal form differs from the target.':
      'Esta forma terminal difere do alvo.',
  'No production applies to the current form.':
      'Nenhuma produção se aplica à forma atual.',
  'That history position is unavailable.':
      'Essa posição do histórico não está disponível.',
  'The saved derivation session is malformed.':
      'A sessão de derivação salva está malformada.',
  'The saved derivation session version is unsupported.':
      'A versão da sessão de derivação salva não é compatível.',
  'Unable to start the derivation session.':
      'Não foi possível iniciar a sessão de derivação.',
  'Variable dependency graph': 'Grafo de dependência de variáveis',
  'Explore direct and left-corner dependencies with exact production provenance.':
      'Explore dependências diretas e de canto esquerdo com origem exata nas produções.',
  'The source grammar changed. Reopen the graph to analyze the current revision.':
      'A gramática de origem mudou. Reabra o grafo para analisar a revisão atual.',
  'The dependency graph could not be built.':
      'Não foi possível construir o grafo de dependência.',
  'Dependency mode': 'Modo de dependência',
  'Graph layout': 'Layout do grafo',
  'Direct occurrence': 'Ocorrência direta',
  'Left corner': 'Canto esquerdo',
  'Nullable-aware left corner': 'Canto esquerdo considerando anuláveis',
  'Layered': 'Em camadas',
  'Circular': 'Circular',
  'Grid': 'Grade',
  'Fit graph': 'Ajustar grafo',
  'Zoom in': 'Ampliar',
  'Zoom out': 'Reduzir',
  'Export SVG': 'Exportar SVG',
  'Export PNG': 'Exportar PNG',
  'Reachable and productive': 'Alcançável e produtiva',
  'Nonproductive': 'Não produtiva',
  'Recursive component': 'Componente recursivo',
  'Sources': 'Fontes',
  'Sinks': 'Sumidouros',
  'Recursive components': 'Componentes recursivos',
  'Dependencies and provenance': 'Dependências e origem',
  'Selected variable': 'Variável selecionada',
  'Dependencies': 'Dependências',
  'Reachability witness': 'Testemunho de alcançabilidade',
  'Edges': 'Arestas',
  'LHS position': 'Posição no lado esquerdo',
  'RHS position': 'Posição no lado direito',
  'Recursion witnesses': 'Testemunhos de recursão',
  'Variable dependency graph exported.':
      'Grafo de dependência de variáveis exportado.',
  'CFG to PDA (LL) construction': 'Construção GLC para AP (LL)',
  'CFG to PDA (LR) construction': 'Construção GLC para AP (LR)',
  'CFG to PDA (LL) construction preview':
      'Prévia da construção GLC para AP (LL)',
  'CFG to PDA (LR) construction preview':
      'Prévia da construção GLC para AP (LR)',
  'Preview a conflict-free top-down LL stack construction with provenance.':
      'Visualize uma construção LL descendente sem conflitos e com origem rastreável.',
  'Preview conflict-free bottom-up shifts and reductions with LR item provenance.':
      'Visualize deslocamentos e reduções ascendentes sem conflitos e com origem nos itens LR.',
  'The source grammar changed. Reopen the preview for the current revision.':
      'A gramática de origem mudou. Reabra a prévia para a revisão atual.',
  'The CFG to PDA construction failed.': 'A construção de GLC para AP falhou.',
  'LL(1) conflicts block the LL construction.':
      'Conflitos LL(1) impedem a construção LL.',
  'Canonical LR(1) conflicts block the LR construction.':
      'Conflitos LR(1) canônicos impedem a construção LR.',
  'The source is not a valid context-free grammar.':
      'A origem não é uma gramática livre de contexto válida.',
  'The construction prerequisite could not be completed.':
      'Não foi possível concluir o pré-requisito da construção.',
  'Acceptance': 'Aceitação',
  'final state after all input': 'estado final após consumir toda a entrada',
  'States': 'Estados',
  'Construction assumptions': 'Premissas da construção',
  'Construction steps': 'Etapas da construção',
  'Construction steps. Use arrow keys to change the selected step.':
      'Etapas da construção. Use as setas para mudar a etapa selecionada.',
  'Source grammar': 'Gramática de origem',
  'PDA preview': 'Prévia do AP',
  'Open in PDA editor': 'Abrir no editor de AP',
  'CFG to PDA construction opened in the PDA editor.':
      'Construção de GLC para AP aberta no editor de AP.',
  'Generated CFG from PDA': 'GLC gerada a partir do AP',
  'Non-terminals of the form [p,A,q] indicate moving from state p':
      'Não terminais no formato [p,A,q] indicam a passagem do estado p',
  'with stack symbol A on top to state q after consuming a string.':
      'com o símbolo A no topo da pilha para o estado q após consumir uma cadeia.',
  'Start productions:': 'Produções iniciais:',
  'Transition productions:': 'Produções de transição:',
  'Terminals:': 'Terminais:',
  'Stack alphabet:': 'Alfabeto da pilha:',
  'Undo': 'Desfazer',
  'Bounded differential evidence': 'Evidência diferencial limitada',
  'Finite samples can detect a mismatch but cannot prove language equivalence.':
      'Amostras finitas podem detectar divergências, mas não provam equivalência de linguagens.',
  'Run sampled check': 'Executar verificação amostral',
  'Empty input': 'Entrada vazia',
  'Grammar and PDA accepted this sample.':
      'A gramática e o AP aceitaram esta amostra.',
  'Grammar and PDA rejected this sample.':
      'A gramática e o AP rejeitaram esta amostra.',
  'Grammar and PDA disagree on this sample.':
      'A gramática e o AP divergem nesta amostra.',
  'The sampled check was inconclusive within its bounds.':
      'A verificação amostral foi inconclusiva dentro dos limites.',
  'Create PDA state': 'Criar estado do AP',
  'Initialize the LL stack': 'Inicializar a pilha LL',
  'Expand a grammar variable': 'Expandir uma variável da gramática',
  'Match an input terminal': 'Corresponder um terminal da entrada',
  'Shift an input terminal': 'Deslocar um terminal da entrada',
  'Reduce by a production': 'Reduzir por uma produção',
  'Recognize the start variable': 'Reconhecer a variável inicial',
  'Verify the bottom marker': 'Verificar o marcador de fundo',
  'The source must be a valid context-free grammar.':
      'A origem deve ser uma gramática livre de contexto válida.',
  'Acceptance requires all input consumed and the final state reached.':
      'A aceitação exige consumir toda a entrada e alcançar o estado final.',
  'A collision-safe bottom marker initializes the stack.':
      'Um marcador de fundo sem colisões inicializa a pilha.',
  'The canonical LL(1) table must be conflict-free.':
      'A tabela LL(1) canônica deve estar livre de conflitos.',
  'LL transitions expand the leftmost stack variable top-down.':
      'As transições LL expandem de cima para baixo a variável no topo da pilha.',
  'The canonical LR(1) table must be conflict-free.':
      'A tabela LR(1) canônica deve estar livre de conflitos.',
  'LR transitions shift terminals and reduce production right sides bottom-up.':
      'As transições LR deslocam terminais e reduzem lados direitos de baixo para cima.',
  'Finite differential samples are evidence, not an equivalence proof.':
      'Amostras diferenciais finitas são evidência, não prova de equivalência.',
  'The grammar has no productions.': 'A gramática não possui produções.',
  'The grammar has no start symbol.': 'A gramática não possui símbolo inicial.',
  'The start symbol is undeclared': 'O símbolo inicial não está declarado',
  'Malformed CFG production': 'Produção de GLC malformada',
  'Duplicate production ID': 'ID de produção duplicado',
  'Undeclared production symbol': 'Símbolo de produção não declarado',
  'Construction diagnostic': 'Diagnóstico da construção',
  'TM to unrestricted grammar construction':
      'Construção de MT para gramática irrestrita',
  'Preview a token-safe single-tape construction with exact transition provenance.':
      'Visualize uma construção de fita única que preserva tokens e a origem exata das transições.',
  'TM to unrestricted grammar construction preview':
      'Prévia da construção de MT para gramática irrestrita',
  'The source TM changed. Reopen the preview for the current revision.':
      'A MT de origem mudou. Reabra a prévia para a revisão atual.',
  'The TM to grammar construction failed.':
      'A construção de MT para gramática falhou.',
  'This TM uses features outside the supported conversion subset.':
      'Esta MT usa recursos fora do subconjunto de conversão compatível.',
  'The TM cannot be converted until its diagnostics are resolved.':
      'A MT não pode ser convertida até que os diagnósticos sejam resolvidos.',
  'Single tape, two-way infinite': 'Fita única, infinita nas duas direções',
  'entering a final state': 'entrada em um estado final',
  'Productions': 'Produções',
  'Variables': 'Variáveis',
  'Production family': 'Família de produções',
  'All families': 'Todas as famílias',
  'Source TM': 'MT de origem',
  'Result grammar': 'Gramática resultante',
  'Construction report copied.': 'Relatório da construção copiado.',
  'Copy report': 'Copiar relatório',
  'Open in unrestricted grammar editor':
      'Abrir no editor de gramática irrestrita',
  'TM and grammar accepted this sample.':
      'A MT e a gramática aceitaram esta amostra.',
  'TM and grammar rejected this sample.':
      'A MT e a gramática rejeitaram esta amostra.',
  'TM and grammar disagree on this sample.':
      'A MT e a gramática divergem nesta amostra.',
  'The sampled check could not validate this input.':
      'A verificação amostral não pôde validar esta entrada.',
  'Input encoding': 'Codificação da entrada',
  'Blank boundaries': 'Limites em branco',
  'Move left': 'Mover à esquerda',
  'Move right': 'Mover à direita',
  'Stay move': 'Movimento estacionário',
  'Accepting state': 'Estado de aceitação',
  'Cleanup left sweep': 'Limpeza em varredura à esquerda',
  'Cleanup right sweep': 'Limpeza em varredura à direita',
  'Only single-tape machines are supported.':
      'Apenas máquinas de fita única são compatíveis.',
  'The tape is infinite in both directions.':
      'A fita é infinita nas duas direções.',
  'Entering a final state accepts immediately.':
      'A entrada em um estado final aceita imediatamente.',
  'Deterministic and nondeterministic transitions are preserved.':
      'Transições determinísticas e não determinísticas são preservadas.',
  'Tape and grammar symbols remain atomic tokens.':
      'Os símbolos da fita e da gramática permanecem tokens atômicos.',
  'Each derivation chooses enough finite blank padding for its computation.':
      'Cada derivação escolhe preenchimento finito em branco suficiente para sua computação.',
  'The TM model is invalid.': 'O modelo da MT é inválido.',
  'The TM has no valid initial state.':
      'A MT não possui um estado inicial válido.',
  'The TM has no accepting state, so the generated language is empty.':
      'A MT não possui estado de aceitação; portanto, a linguagem gerada é vazia.',
  'Multi-tape conversion is not supported; use a single-tape TM.':
      'A conversão de múltiplas fitas não é compatível; use uma MT de fita única.',
  'Inline or remove building blocks before conversion.':
      'Incorpore ou remova os blocos de construção antes da conversão.',
  'The blank symbol cannot also be an input symbol.':
      'O símbolo em branco não pode ser também um símbolo de entrada.',
  'Input symbol outside the tape alphabet':
      'Símbolo de entrada fora do alfabeto da fita',
  'The production construction limit was reached.':
      'O limite de produções da construção foi atingido.',
  'The generated grammar did not validate.':
      'A gramática gerada não passou na validação.',
  'Unreachable state preserved': 'Estado inalcançável preservado',
  'Replace unrestricted grammar?': 'Substituir a gramática irrestrita?',
  'Opening this result replaces the current unrestricted grammar. You can undo it.':
      'Abrir este resultado substitui a gramática irrestrita atual. É possível desfazer.',
  'TM construction opened in the unrestricted grammar editor.':
      'Construção da MT aberta no editor de gramática irrestrita.',
  'LR cells': 'Células LR',
  'Table cell': 'Célula da tabela',
  'Empty table cell': 'Célula vazia da tabela',
  'Editable parse-table teaching workspace':
      'Ambiente didático editável da tabela de análise',
  'Teaching mode': 'Modo didático',
  'Edit your table without changing the generated reference.':
      'Edite sua tabela sem alterar a referência gerada.',
  'Hide generated answers': 'Ocultar respostas geradas',
  'Show generated answers': 'Mostrar respostas geradas',
  'Type a production ID, shift/reduce action, or GOTO state. Conflict cells offer every generated action.':
      'Informe um ID de produção, ação shift/reduce ou estado GOTO. Células em conflito oferecem todas as ações geradas.',
  'Conflict. Choose the action you want to test.':
      'Conflito. Escolha a ação que deseja testar.',
  'Your entry': 'Sua entrada',
  'table cell': 'célula da tabela',
  'Generated answer for': 'Resposta gerada para',
  'Generated, read only': 'Gerado, somente leitura',
  'Correct entry.': 'Entrada correta.',
  'Valid conflict choice. The other generated actions remain unchanged.':
      'Escolha de conflito válida. As outras ações geradas permanecem inalteradas.',
  'This generated cell is empty.': 'Esta célula gerada está vazia.',
  'This entry does not match a generated action.':
      'Esta entrada não corresponde a uma ação gerada.',
  'The saved table exercise could not be restored.':
      'Não foi possível restaurar o exercício de tabela salvo.',
  'No hint was found. This is not a global non-membership claim.':
      'Nenhuma dica foi encontrada. Isso não é uma afirmação global de não pertinência.',
  'Hint search was cancelled.': 'A busca de dica foi cancelada.',
  'Hint search cannot run on this session.':
      'A busca de dica não pode ser executada nesta sessão.',
  'Grammar': 'Gramática',
  'Failed to load grammar examples.':
      'Falha ao carregar exemplos de gramática.',
  'Grammar applied to editor.': 'Gramática aplicada ao editor.',
  'Practice Regular Grammar to FA': 'Praticar gramática regular para AF',
  'Unable to preview this transformation.':
      'Não foi possível visualizar esta transformação.',
  'FIRST and FOLLOW': 'FIRST e FOLLOW',
  'Predictive parse table': 'Tabela de análise preditiva',
  'Select a cell to inspect its production and provenance.':
      'Selecione uma célula para inspecionar sua produção e origem.',
  'Empty cell': 'Célula vazia',
  'LL(1) step timeline': 'Linha do tempo dos passos LL(1)',
  'Left-recursion removal preview': 'Prévia da remoção de recursão à esquerda',
  'Left-factoring preview': 'Prévia da fatoração à esquerda',
  'Preview left-recursion removal': 'Visualizar remoção de recursão à esquerda',
  'Preview left factoring': 'Visualizar fatoração à esquerda',
  'Preview only. The source grammar will not change.':
      'Somente visualização. A gramática original não será alterada.',
  'Stack': 'Pilha',
  'Remaining input': 'Entrada restante',
  'Lookahead': 'Antecipação',
  'Production': 'Produção',
  'Production ID': 'ID da produção',
  'Expected': 'Esperado',
  'Accept input': 'Aceitar entrada',
  'Parsing error': 'Erro de análise',
  'NFA to DFA': 'AFN para AFD',
  'Remove ε-transitions': 'Remover transições ε',
  'Minimize DFA': 'Minimizar AFD',
  'Complete DFA': 'Completar AFD',
  'Complement DFA': 'Complemento do AFD',
  'Union of DFAs': 'União de AFDs',
  'Intersection of DFAs': 'Interseção de AFDs',
  'Difference of DFAs': 'Diferença de AFDs',
  'Prefix Closure': 'Fecho por prefixos',
  'Suffix Closure': 'Fecho por sufixos',
  'FA to Regex': 'AF para expressão regular',
  'FSA to Grammar': 'AF para gramática',
  'Regex to NFA': 'Expressão regular para AFN',
  'Step input': 'Entrada da etapa',
  'Source entities': 'Entidades de origem',
  'FA to Regex step input': 'Entrada da etapa de AF para expressão regular',
  'Check step': 'Verificar etapa',
  'This step has no FA or grammar editor.':
      'Esta etapa não possui editor de AF ou gramática.',
  'Nonterminal': 'Não terminal',
  'Enter a nonterminal.': 'Informe um não terminal.',
  'Left-side nonterminal': 'Não terminal do lado esquerdo',
  'Enter the left-side nonterminal.':
      'Informe o não terminal do lado esquerdo.',
  'Use ε as the right side': 'Usar ε como lado direito',
  'Epsilon consumes no input symbol.':
      'Épsilon não consome símbolo de entrada.',
  'Right-side symbols': 'Símbolos do lado direito',
  'Right side': 'Lado direito',
  'Separate symbols with spaces, for example: a A.':
      'Separe os símbolos com espaços, por exemplo: a A.',
  'Enter at least one right-side symbol.':
      'Informe pelo menos um símbolo do lado direito.',
  'Enter the source state ID.': 'Informe o ID do estado de origem.',
  'Enter the destination state ID.': 'Informe o ID do estado de destino.',
  'Transition type': 'Tipo de transição',
  'Input symbol': 'Símbolo de entrada',
  'Epsilon (ε)': 'Épsilon (ε)',
  'Select a transition type.': 'Selecione um tipo de transição.',
  'Enter an input symbol.': 'Informe um símbolo de entrada.',
  'Destination state is accepting': 'O estado de destino é de aceitação',
  'Mark state as accepting': 'Marcar estado como de aceitação',
  'Select accepting before checking this step.':
      'Marque o estado como de aceitação antes de verificar esta etapa.',
  'Protected start state': 'Estado inicial protegido',
  'Protected final state': 'Estado final protegido',
  'Endpoint bridge label': 'Rótulo da ponte entre extremos',
  'State to eliminate': 'Estado a eliminar',
  'Protected start and final states cannot be eliminated.':
      'Os estados inicial e final protegidos não podem ser eliminados.',
  'Select a state to eliminate.': 'Selecione um estado para eliminar.',
  'Affected state pair': 'Par de estados afetado',
  'State-elimination formula and current labels':
      'Fórmula de eliminação de estados e rótulos atuais',
  'State-elimination formula': 'Fórmula de eliminação de estados',
  'Resulting pair expression': 'Expressão resultante do par',
  'Enter the label after applying the formula.':
      'Informe o rótulo após aplicar a fórmula.',
  'State to remove': 'Estado a remover',
  'Validated affected pairs': 'Pares afetados validados',
  'Checking this step removes the state only after every affected pair is valid.':
      'A verificação desta etapa remove o estado somente depois que todos os pares afetados forem válidos.',
  'Final regular expression': 'Expressão regular final',
  'Enter an expression equivalent to the source automaton.':
      'Informe uma expressão equivalente ao autômato de origem.',
  'Enter a regular expression.': 'Informe uma expressão regular.',
  'This step has no FA to Regex editor.':
      'Esta etapa não possui editor de AF para expressão regular.',
  'Manual construction — progress is saved on this device.':
      'Construção manual — o progresso é salvo neste dispositivo.',
  'Construction progress': 'Progresso da construção',
  'Close': 'Fechar',
  'Source': 'Origem',
  'Learner construction': 'Construção do aluno',
  'Construction complete': 'Construção concluída',
  'Applied actions': 'Ações aplicadas',
  'No actions yet.': 'Nenhuma ação ainda.',
  'Revealed step': 'Etapa revelada',
  'Learner step': 'Etapa do aluno',
  'Redo': 'Refazer',
  'Restart': 'Reiniciar',
  'Hint': 'Dica',
  'Reveal step': 'Revelar etapa',
  'Compare': 'Comparar',
  'Open result': 'Abrir resultado',
  'Enter text.': 'Informe o texto.',
  'Enter this structured value as JSON.':
      'Informe este valor estruturado como JSON.',
  'The source changed. Restart or branch from the edited document.':
      'A origem mudou. Reinicie ou crie uma ramificação a partir do documento editado.',
  'Restart from edited source': 'Reiniciar a partir da origem editada',
  'Branch from edited source': 'Criar ramificação a partir da origem editada',
  'Auto Layout': 'Layout automático',
  'Compare Equivalence': 'Comparar equivalência',
  'Clear': 'Limpar',
  'Convert to CNF': 'Converter para FNC',
  'Convert to GNF': 'Converter para FNG',
  'Remove Left Recursion': 'Remover recursão à esquerda',
  'Eliminate direct and indirect left recursion':
      'Eliminar recursão direta e indireta à esquerda',
  'Left Factor': 'Fatorar à esquerda',
  'Find First Sets': 'Calcular conjuntos FIRST',
  'Find Follow Sets': 'Calcular conjuntos FOLLOW',
  'Build Parse Table': 'Construir tabela de análise',
  'Check Ambiguity': 'Verificar ambiguidade',
  'Convert to CFG': 'Converter para GLC',
  'Simplify PDA': 'Simplificar AP',
  'Check Determinism': 'Verificar determinismo',
  'Find Reachable States': 'Encontrar estados alcançáveis',
  'Reachability input scope': 'Escopo de entradas para alcançabilidade',
  'Separate inputs with commas; use ε for the empty string.':
      'Separe as entradas por vírgulas; use ε para a cadeia vazia.',
  'Compare structural reachability with bounded witnesses':
      'Compare alcançabilidade estrutural com testemunhos limitados',
  'Structural and bounded semantic reachability':
      'Alcançabilidade estrutural e semântica limitada',
  'Structurally reachable (exact over-approximation)':
      'Estruturalmente alcançáveis (superaproximação exata)',
  'Reached within bounds': 'Alcançados dentro dos limites',
  'Not observed before a bound stopped exploration':
      'Não observados antes de um limite interromper a exploração',
  'Not observed for this input scope':
      'Não observados neste escopo de entradas',
  'Structurally unreachable (exact)': 'Estruturalmente inalcançáveis (exato)',
  'Shortest witnesses': 'Testemunhos mais curtos',
  'Language Analysis': 'Análise da linguagem',
  'Stack Operations': 'Operações da pilha',
  'Termination and Cycles': 'Término e ciclos',
  'Analysis focus: Termination and Cycles': 'Foco da análise: Término e ciclos',
  'Input': 'Entrada',
  'Conclusion': 'Conclusão',
  'Exact for this input': 'Exato para esta entrada',
  'Bounded': 'Limitado',
  'Halted and rejected': 'Parou e rejeitou',
  'Proven cycle': 'Ciclo provado',
  'Inconclusive within limits': 'Inconclusivo dentro dos limites',
  'Cancelled': 'Cancelado',
  'Invalid machine or input': 'Máquina ou entrada inválida',
  'Transitions executed': 'Transições executadas',
  'Configurations explored': 'Configurações exploradas',
  'Transitions explored': 'Transições exploradas',
  'Step limit': 'Limite de passos',
  'Configuration limit': 'Limite de configurações',
  'Time limit': 'Limite de tempo',
  'Limit reached': 'Limite atingido',
  'steps': 'passos',
  'configurations': 'Limite de configurações',
  'timeout': 'Tempo limite',
  'Cycle start': 'Início do ciclo',
  'Cycle period': 'Período do ciclo',
  'Repeated state': 'Estado repetido',
  'Repeated head position': 'Posição repetida do cabeçote',
  'Repeated nonblank tape cells': 'Células não brancas repetidas da fita',
  'Repeated cycle trace': 'Traço do ciclo repetido',
  'Classify one input under explicit execution limits':
      'Classifique uma entrada com limites explícitos de execução',
  'Execution input for termination and tape analysis':
      'Entrada de execução para término e análise da fita',
  'Termination and tape analysis controls':
      'Controles de análise de término e fita',
  'Reachability analysis controls': 'Controles de análise de alcançabilidade',
  'Reachability': 'Alcançabilidade',
  'Analysis focus: Structural and bounded semantic reachability':
      'Foco da análise: Alcançabilidade estrutural e semântica limitada',
  'Language Explorer': 'Explorador de linguagem',
  'Analysis focus: Language Explorer':
      'Foco da análise: Explorador de linguagem',
  'Classify a bounded shortlex sample into four outcomes':
      'Classifique uma amostra shortlex limitada em quatro resultados',
  'Language explorer limits': 'Limites do explorador de linguagem',
  'Max input length': 'Comprimento máximo da entrada',
  'Candidate cap': 'Limite de candidatas',
  'Steps per input': 'Passos por entrada',
  'Configurations per input': 'Configurações por entrada',
  'Timeout per input (ms)': 'Tempo limite por entrada (ms)',
  'Cancel exploration': 'Cancelar exploração',
  'Completeness': 'Completude',
  'Complete': 'Completo',
  'Cancelled • incomplete': 'Cancelado • incompleto',
  'Sampled • deterministic shortlex prefix':
      'Amostrado • prefixo shortlex determinístico',
  'Complete enumeration • bounded outcomes remain':
      'Enumeração completa • ainda há resultados limitados',
  'Input alphabet': 'Alfabeto de entrada',
  'Evaluated candidates': 'Candidatas avaliadas',
  'Requested candidates': 'Candidatas solicitadas',
  'Exploration time': 'Tempo de exploração',
  'Step limit per input': 'Limite de passos por entrada',
  'Configuration limit per input': 'Limite de configurações por entrada',
  'Time limit per input': 'Limite de tempo por entrada',
  'Halted rejected': 'Parou e rejeitou',
  'Inconclusive': 'Inconclusivo',
  'Leave empty to analyze the empty string.':
      'Deixe vazio para analisar a cadeia vazia.',
  'Limits: 10,000 steps, 100,000 configurations, 5 seconds':
      'Limites: 10.000 passos, 100.000 configurações, 5 segundos',
  'Cancel analysis': 'Cancelar análise',
  'Cancelling analysis…': 'Cancelando análise…',
  'Tape Trace': 'Traço da fita',
  'Analysis focus: Tape Trace': 'Foco da análise: Traço da fita',
  'Selected branch': 'Ramo selecionado',
  'Deterministic execution': 'Execução determinística',
  'Accepting NTM branch': 'Ramo de MTN que aceita',
  'Rejecting NTM branch': 'Ramo de MTN que rejeita',
  'Cyclic NTM branch': 'Ramo cíclico de MTN',
  'Longest bounded NTM branch': 'Ramo limitado mais longo da MTN',
  'Executed transitions': 'Transições executadas',
  'Writes that changed a cell': 'Escritas que alteraram uma célula',
  'Head reversals': 'Inversões do cabeçote',
  'Head movements': 'Movimentos do cabeçote',
  'Visited head interval': 'Intervalo visitado pelo cabeçote',
  'Distinct cells visited': 'Células distintas visitadas',
  'Maximum simultaneous nonblank cells':
      'Máximo de células não brancas simultâneas',
  'Declared tape alphabet': 'Alfabeto declarado da fita',
  'Measure operations on one concrete execution branch':
      'Meça operações em um ramo concreto de execução',
  'Related execution trace': 'Rastreamento da execução relacionado',
  'Space Profile': 'Perfil de espaço',
  'Measure bounded tape-cell usage by input length':
      'Meça o uso limitado de células da fita por comprimento da entrada',
  'Space profiler limits': 'Limites do perfil de espaço',
  'Candidates per length': 'Candidatas por comprimento',
  'Analysis focus: Space Profile': 'Foco da análise: Perfil de espaço',
  'Time Profile': 'Perfil de tempo',
  'Analysis focus: Time Profile': 'Foco da análise: Perfil de tempo',
  'Measure transition steps by input length within bounds':
      'Meça passos de transição por comprimento de entrada dentro dos limites',
  'Bounded time-profile scope': 'Escopo do perfil temporal limitado',
  'Time profiler controls': 'Controles do perfil de tempo',
  'Maximum input length': 'Comprimento máximo da entrada',
  'Candidate limit per length': 'Limite de candidatos por comprimento',
  'Planned candidates': 'Candidatos planejados',
  'Enter integer bounds to calculate the candidate plan.':
      'Informe limites inteiros para calcular o plano de candidatos.',
  'Candidate counts appear after a Turing machine is available.':
      'As contagens de candidatos aparecem quando uma máquina de Turing estiver disponível.',
  'Per candidate: 50,000 transition steps, 100,000 configurations, 5 seconds':
      'Por candidato: 50.000 passos de transição, 100.000 configurações, 5 segundos',
  'Enter integer bounds before starting the bounded time profile.':
      'Informe limites inteiros antes de iniciar o perfil temporal limitado.',
  'No analysis results yet': 'Nenhum resultado de análise',
  'Analysis Results': 'Resultados da análise',
  'Load Examples': 'Carregar exemplos',
  'Conversions': 'Conversões',
  'No structural issues detected.': 'Nenhum problema estrutural detectado.',
  'Processing...': 'Processando...',
  'Executing...': 'Executando...',
  'Completed successfully': 'Concluído com sucesso',
  'Loading automaton...': 'Carregando autômato...',
  'Loading examples...': 'Carregando exemplos...',
  'Failed to load automaton': 'Falha ao carregar o autômato',
  'Comparison complete': 'Comparação concluída',
  'Comparison failed': 'Falha na comparação',
  'Language Comparison': 'Comparação de linguagens',
  'Current Automaton': 'Autômato atual',
  'Compared Automaton': 'Autômato comparado',
  'Automata are equivalent': 'Os autômatos são equivalentes',
  'Automata are not equivalent': 'Os autômatos não são equivalentes',
  'Generated Grammar': 'Gramática gerada',
  'Generated reference grammar': 'Gramática de referência gerada',
  'Generated reference. Read only.': 'Referência gerada. Somente leitura.',
  'Remove lambda': 'Remover produções vazias',
  'Remove useless productions': 'Remover produções inúteis',
  'Finish CNF': 'Concluir FNC',
  'Grammar normalization teaching workspace':
      'Ambiente didático de normalização de gramáticas',
  'Your intermediate productions': 'Suas produções intermediárias',
  'Your draft stays here when validation finds a mistake.':
      'Seu rascunho permanece aqui quando a validação encontra um erro.',
  'Normalization validation result': 'Resultado da validação da normalização',
  'Hide reference': 'Ocultar referência',
  'Compare with reference': 'Comparar com a referência',
  'Valid equivalent step.': 'Etapa equivalente válida.',
  'Duplicate production.': 'Produção duplicada.',
  'Unknown symbol.': 'Símbolo desconhecido.',
  'Use the form A -> symbol symbol.': 'Use o formato A -> símbolo símbolo.',
  'Missing production:': 'Produção ausente:',
  'Unexpected production:': 'Produção inesperada:',
  'The source grammar changed. Start a new exercise.':
      'A gramática de origem mudou. Inicie um novo exercício.',
  'The saved exercise could not be restored.':
      'Não foi possível restaurar o exercício salvo.',
  'Line': 'Linha',
  'Explanation': 'Explicação',
  'Notes': 'Observações',
  'Derivations': 'Derivações',
  'Conflicts': 'Conflitos',
  'Reachable': 'Alcançáveis',
  'Unreachable': 'Inalcançáveis',
  'Total states': 'Total de estados',
  'Accepting states': 'Estados de aceitação',
  'Non-accepting states': 'Estados que não são de aceitação',
  'Total transitions': 'Total de transições',
  'Potential Issues': 'Possíveis problemas',
  'Operand A': 'Operando A',
  'Operand B': 'Operando B',
  'DFA for complement': 'AFD para complemento',
  'DFA for prefix closure': 'AFD para fecho por prefixos',
  'DFA for suffix closure': 'AFD para fecho por sufixos',
  'Operand A has labeled transitions, but the alphabet is empty.':
      'O operando A possui transições rotuladas, mas o alfabeto está vazio.',
  'Operand B has labeled transitions, but the alphabet is empty.':
      'O operando B possui transições rotuladas, mas o alfabeto está vazio.',
  'The automaton does not have a defined initial state.':
      'O autômato não possui estado inicial definido.',
  'Examples: aabb (for balanced parentheses), abab (for palindromes)':
      'Exemplos: aabb (parênteses balanceados), abab (palíndromos)',
  'Validation': 'Validação',
  'Initialization': 'Inicialização',
  'Alphabet Normalization': 'Normalização do alfabeto',
  'DFA Conversion': 'Conversão para AFD',
  'DFA Completion': 'Completude do AFD',
  'Product Construction': 'Construção do produto',
  'Product State Created': 'Estado produto criado',
  'Product Transition': 'Transição do produto',
  'Product Construction Complete': 'Construção do produto concluída',
  'BFS Search': 'Busca em largura',
  'Initial Pair Check': 'Verificação do par inicial',
  'State Pair Visit': 'Visita do par de estados',
  'Counterexample Found': 'Contraexemplo encontrado',
  'BFS Complete': 'Busca em largura concluída',
  'Comparison Result': 'Resultado da comparação',
  'Unknown Step': 'Passo desconhecido',
  'Automaton A alphabet': 'Alfabeto do autômato A',
  'Automaton B alphabet': 'Alfabeto do autômato B',
  'Automaton': 'Autômato',
  'Distinguishing string': 'Cadeia distintiva',
  'Equivalent': 'Equivalente',
  'Compute initial ε-closure': 'Calcular o ε-fecho inicial',
  'Initial DFA state is the ε-closure of the NFA start state':
      'O estado inicial do AFD é o ε-fecho do estado inicial do AFN',
  'Follow NFA transitions on the current symbol':
      'Seguir as transições do AFN no símbolo atual',
  'Compute ε-closure of reachable states':
      'Calcular o ε-fecho dos estados alcançáveis',
  'Close under ε-transitions to form the next DFA state':
      'Fechar sob transições ε para formar o próximo estado do AFD',
  'One DFA state represents an entire set of NFA states':
      'Um estado do AFD representa um conjunto inteiro de estados do AFN',
  'DFA transitions summarize all possible NFA moves on a symbol':
      'As transições do AFD resumem todos os movimentos possíveis do AFN em um símbolo',
  'Conversion complete': 'Conversão concluída',
  'All reachable subsets have been converted to DFA components':
      'Todos os subconjuntos alcançáveis foram convertidos em componentes do AFD',
  'Create initial partition': 'Criar a partição inicial',
  'Remove unreachable states': 'Remover estados inalcançáveis',
  'Partition stabilized': 'Partição estabilizada',
  'Minimization complete': 'Minimização concluída',
  'Begin Thompson\'s construction': 'Iniciar a construção de Thompson',
  'Apply concatenation': 'Aplicar concatenação',
  'Apply union (alternation)': 'Aplicar união (alternância)',
  'Apply Kleene star (*)': 'Aplicar estrela de Kleene (*)',
  'Apply plus (+)': 'Aplicar mais (+)',
  'Apply optional (?)': 'Aplicar opcional (?)',
  'Complete NFA construction': 'Concluir a construção do AFN',
  'Initialize CYK table': 'Inicializar a tabela CYK',
  'Initialize': 'Inicializar',
  'Process Cell': 'Processar célula',
  'Check Split': 'Verificar divisão',
  'Apply Production': 'Aplicar produção',
  'Complete Cell': 'Concluir célula',
  'Completion': 'Conclusão',
  'Check Acceptance': 'Verificar aceitação',
  'Match terminal': 'Corresponder terminal',
  'Acceptance check': 'Verificação de aceitação',
  'CYK parsing complete': 'Análise CYK concluída',
  'Check acceptance': 'Verificar aceitação',
  'Parsing complete': 'Análise concluída',
  'Validate input automaton': 'Validar o autômato de entrada',
  'Add new initial state': 'Adicionar novo estado inicial',
  'Add new final state': 'Adicionar novo estado final',
  'Extract final regular expression': 'Extrair a expressão regular final',
  'Begin regex simplification': 'Iniciar a simplificação da expressão regular',
  'Simplification complete': 'Simplificação concluída',
  'No further simplification': 'Nenhuma simplificação adicional',
  'Create NFA for epsilon': 'Criar AFN para épsilon',
  'Create NFA for wildcard': 'Criar AFN para curinga',
  'Create NFA for character class': 'Criar AFN para classe de caracteres',
  'Clone and mirror the states': 'Clonar e espelhar os estados',
  'Reverse every transition': 'Inverter cada transição',
  'Add the new entry': 'Adicionar a nova entrada',
  'Set the reversed accepting state': 'Definir o estado de aceitação invertido',
  'Clone the operand': 'Clonar o operando',
  'Add the epsilon entry': 'Adicionar a entrada épsilon',
  'Add repeat transitions': 'Adicionar transições de repetição',
  'Add exit transitions': 'Adicionar transições de saída',
  'Connect the operands': 'Conectar os operandos',
  'Turing machine transition': 'Transição da máquina de Turing',
  'Transition applied': 'Transição aplicada',
  'Computed ε-closure': 'ε-fecho calculado',
  'Symbol consumed': 'Símbolo consumido',
  'Expanded via ε-transitions': 'Expandido via transições ε',
  'Applied PDA transition': 'Transição de AP aplicada',
  'Failed to encode PNG data': 'Falha ao codificar dados PNG',
  'Documents directory is not available on web.':
      'O diretório de documentos não está disponível na web.',
  'No Turing machine available. Draw states and transitions on the canvas to analyze.':
      'Nenhuma máquina de Turing disponível. Desenhe estados e transições no canvas para analisar.',
  'No input-length group was evaluated.':
      'Nenhum grupo de comprimento de entrada foi avaliado.',
  'No candidates were evaluated.': 'Nenhuma candidata foi avaliada.',
  'No trace was recorded for this bounded run.':
      'Nenhum traço foi registrado para esta execução limitada.',
  'Exploration cancelled. Evaluated results were kept.':
      'Exploração cancelada. Os resultados avaliados foram mantidos.',
  'Space profiling cancelled. Evaluated rows were kept.':
      'Perfil de espaço cancelado. As linhas avaliadas foram mantidas.',
  'Estimated candidates: invalid limits':
      'Candidatas estimadas: limites inválidos',
  'Words': 'Palavras',
  'Repeated NTM configurations observed':
      'Configurações repetidas da MTN observadas',
  'Reads by symbol': 'Leituras por símbolo',
  'Writes by old symbol': 'Escritas pelo símbolo antigo',
  'Writes by new symbol': 'Escritas pelo símbolo novo',
  'Transition execution counts': 'Contagens de execução das transições',
  'Defined but not executed transitions':
      'Transições definidas mas não executadas',
  'Sparse initial-to-final tape diff':
      'Diferença esparsa da fita inicial para a final',
  'First and last step touching each cell':
      'Primeiro e último passo que tocam cada célula',
  'Sampled': 'Amostrado',
  'Exhaustive': 'Exaustivo',
  'Incomplete': 'Incompleto',
  'Selected word': 'Palavra selecionada',
  'DTM transition-step profile': 'Perfil de passos de transição da MTD',
  'NTM exploration metrics (not deterministic time)':
      'Métricas de exploração da MTND (não representam tempo determinístico)',
  'Candidate coverage': 'Cobertura de candidatas',
  'Visited span maximum': 'Máximo do intervalo visitado',
  'Maximum nonblank cells': 'Máximo de células não brancas',
  'Inconclusive executions': 'Execuções inconclusivas',
  'Read symbol': 'Símbolo lido',
  'Incoming transition': 'Transição de entrada',
  'Head position': 'Posição do cabeçote',
  'State trace': 'Traço de estados',
  'Transition trace': 'Traço de transições',
  'Semantic exploration': 'Exploração semântica',
  'Complete for this input scope': 'Completo neste escopo de entradas',
  'Introduce new start symbol': 'Introduzir novo símbolo inicial',
  'Remove ε-productions': 'Remover produções ε',
  'Remove unit productions': 'Remover produções unitárias',
  'Remove useless symbols': 'Remover símbolos inúteis',
  'Replace terminals and binarize': 'Substituir terminais e binarizar',
  'Convert to Greibach Normal Form (GNF)':
      'Converter para Forma Normal de Greibach (FNG)',
  'Not observed': 'Não observado',
  'The deterministic shortlex prefix was sampled because this length exceeds the candidate cap.':
      'O prefixo shortlex determinístico foi amostrado porque este comprimento excede o limite de candidatas.',
  'Sampled • incomplete': 'Amostrado • incompleto',
  'Input lengths': 'Comprimentos de entrada',
  'Input scope': 'Escopo de entradas',
  'Turing Lab could not write to the selected location. The file may be outside the app sandbox or no longer writable. Choose a destination again from the system save dialog and try again.':
      'O Turing Lab não conseguiu gravar no local selecionado. O arquivo pode estar fora da área restrita do aplicativo ou não ser mais gravável. Escolha o destino novamente no diálogo de salvamento do sistema e tente de novo.',
  'Turing Lab could not read the selected file. The file may be outside the app sandbox or no longer readable. Pick the file again from the system dialog and try again.':
      'O Turing Lab não conseguiu ler o arquivo selecionado. O arquivo pode estar fora da área restrita do aplicativo ou não ser mais legível. Escolha o arquivo novamente no diálogo do sistema e tente de novo.',
  'The selected save location is no longer available. Choose a different destination and try again.':
      'O local de salvamento selecionado não está mais disponível. Escolha outro destino e tente de novo.',
  'The selected file is no longer available. Pick the file again and try again.':
      'O arquivo selecionado não está mais disponível. Escolha o arquivo novamente e tente de novo.',
  'Hide Details': 'Ocultar detalhes',
  'Show More Details': 'Mostrar mais detalhes',
};

// Replacements are sequential. Keep longer or more specific source strings
// before entries that contain the same substrings.
const _ptWorkflowReplacements = <(String, String)>[
  ('Generated CFG from PDA', 'GLC gerada a partir do AP'),
  ('Duplicate production.', 'Produção duplicada.'),
  ('Unknown symbol.', 'Símbolo desconhecido.'),
  ('Missing production:', 'Produção ausente:'),
  ('Unexpected production:', 'Produção inesperada:'),
  (
    'Non-terminals of the form [p,A,q] indicate moving from state p',
    'Não terminais no formato [p,A,q] indicam a passagem do estado p',
  ),
  (
    'with stack symbol A on top to state q after consuming a string.',
    'com o símbolo A no topo da pilha para o estado q após consumir uma cadeia.',
  ),
  ('Start productions:', 'Produções iniciais:'),
  ('Transition productions:', 'Produções de transição:'),
  ('Terminals:', 'Terminais:'),
  ('Stack alphabet:', 'Alfabeto da pilha:'),
  ('Production IDs must be unique.', 'Os IDs das produções devem ser únicos.'),
  (
    'Turtle movement produced non-finite geometry.',
    'O movimento da tartaruga produziu geometria não finita.',
  ),
  (
    'Turtle branch stack exceeded its configured limit.',
    'A pilha de ramificações da tartaruga excedeu o limite configurado.',
  ),
  (
    'A branch pop has no matching push.',
    'Uma remoção da ramificação não tem inserção correspondente.',
  ),
  (
    'Turtle line width must remain positive and finite.',
    'A largura da linha da tartaruga deve permanecer positiva e finita.',
  ),
  (
    'Nested turtle polygons are not supported.',
    'Polígonos aninhados da tartaruga não são compatíveis.',
  ),
  (
    'A polygon close has no matching begin command.',
    'Um fechamento de polígono não tem comando de início correspondente.',
  ),
  (
    'A turtle polygon requires at least three points.',
    'Um polígono da tartaruga exige pelo menos três pontos.',
  ),
  (
    'Turtle color commands require a supported color.',
    'Os comandos de cor da tartaruga exigem uma cor compatível.',
  ),
  (
    'Turtle line width increment must be positive and finite.',
    'O incremento da largura da linha da tartaruga deve ser positivo e finito.',
  ),
  (
    'Turtle distance must be positive and finite.',
    'A distância da tartaruga deve ser positiva e finita.',
  ),
  (
    'A turtle polygon was not closed.',
    'Um polígono da tartaruga não foi fechado.',
  ),
  (
    'Select an algorithm above to analyze your ',
    'Selecione um algoritmo acima para analisar ',
  ),
  (
    'Convert non-deterministic to deterministic automaton',
    'Converter autômato não determinístico em determinístico',
  ),
  (
    'Eliminate epsilon transitions from the automaton',
    'Eliminar transições epsilon do autômato',
  ),
  (
    'Minimize deterministic finite automaton',
    'Minimizar o autômato finito determinístico',
  ),
  (
    'Add trap state to make DFA complete',
    'Adicionar estado armadilha para completar o AFD',
  ),
  (
    'Flip accepting states after completion',
    'Inverter estados de aceitação após completar',
  ),
  (
    'Identify reachable states from initial state',
    'Identificar estados alcançáveis a partir do estado inicial',
  ),
  ('Failed to load ', 'Falha ao carregar '),
  ('Example loaded: ', 'Exemplo carregado: '),
  ('Failed to convert ', 'Falha ao converter '),
  ('Analysis failed', 'Falha na análise'),
  ('Retaining witness trace for ', 'Retendo o traço testemunha para '),
  ('Searching: ', 'Buscando: '),
  (' explored, ', ' explorados, '),
  (' queued, ', ' na fila, '),
  (' witnesses', ' testemunhos'),
  ('Witness ', 'Testemunho '),
  ('Position ', 'Posição '),
  (' matching occurrence(s)', ' ocorrência(s) correspondente(s)'),
  ('Hint search: ', 'Busca de dica: '),
  (' expanded, ', ' expandidos, '),
  ('Search-derived suggestion: apply ', 'Sugestão da busca: aplique '),
  (' at position ', ' na posição '),
  ('Hint search reached the ', 'A busca de dica atingiu o limite '),
  (' limit. The result is inconclusive.', '. O resultado é inconclusivo.'),
  (' steps', ' passos'),
  ('Step ', 'Passo '),
  (' of ', ' de '),
  (' • production ', ' • produção '),
  ('Profiling length ', 'Perfilando comprimento '),
  ('Conversion failed', 'Falha na conversão'),
  ('No FSA examples available.', 'Nenhum exemplo de AF disponível.'),
  ('No grammar examples available.', 'Nenhum exemplo de gramática disponível.'),
  ('No PDA examples available.', 'Nenhum exemplo de AP disponível.'),
  ('No TM examples available.', 'Nenhum exemplo de MT disponível.'),
  ('No Regex examples available.', 'Nenhum exemplo de regex disponível.'),
  ('Initial state', 'Estado inicial'),
  ('Reachable states', 'Estados alcançáveis'),
  ('Unreachable states', 'Estados inalcançáveis'),
  ('Accepting states', 'Estados de aceitação'),
  ('Total transitions', 'Total de transições'),
  ('Total states', 'Total de estados'),
  ('transitions', 'transições'),
  ('states', 'estados'),
  ('Warnings', 'Avisos'),
  ('Result', 'Resultado'),
  ('Start symbol', 'Símbolo inicial'),
  ('Productions', 'Produções'),
  ('Terminals', 'Terminais'),
  ('Non-terminals', 'Não terminais'),
  ('Expand ', 'Expandir '),
  ('Match "', 'Corresponder "'),
  (
    ' must have a defined initial state.',
    ' deve possuir estado inicial definido.',
  ),
  (
    ' must be deterministic (no nondeterministic transitions).',
    ' deve ser determinístico (sem transições não determinísticas).',
  ),
  (
    ' cannot contain ε (epsilon) transitions.',
    ' não pode conter transições ε (epsilon).',
  ),
  (
    ' has a transition with a symbol outside the alphabet: ',
    ' possui transição com símbolo fora do alfabeto: ',
  ),
  (
    'Error computing DFA complement: ',
    'Erro ao calcular o complemento do AFD: ',
  ),
  (
    'Error computing prefix closure: ',
    'Erro ao calcular o fecho por prefixos: ',
  ),
  (
    'Error computing suffix closure: ',
    'Erro ao calcular o fecho por sufixos: ',
  ),
  ('Error combining DFAs (', 'Erro ao combinar AFDs ('),
  ('Error removing ε-transitions: ', 'Erro ao remover transições ε: '),
  (' must have at least one state', ' deve ter pelo menos um estado'),
  (
    'Cannot simulate empty automaton',
    'Não é possível simular um autômato vazio',
  ),
  (
    'Cannot convert empty automaton to regex',
    'Não é possível converter um autômato vazio em expressão regular',
  ),
  ('Process symbol \'', 'Processar símbolo \''),
  ('Create DFA state ', 'Criar estado AFD '),
  ('Create transition on \'', 'Criar transição em \''),
  ('Fill base case for "', 'Preencher caso base para "'),
  ('Apply production ', 'Aplicar produção '),
  ('Create NFA for symbol \'', 'Criar AFN para o símbolo \''),
  ('Create NFA for shortcut ', 'Criar AFN para o atalho '),
  ('Clone the ', 'Clonar o '),
  ('Failed to save ', 'Falha ao salvar '),
  ('Failed to encode PNG data', 'Falha ao codificar dados PNG'),
  (
    'Failed to get documents directory',
    'Falha ao obter o diretório de documentos',
  ),
  ('Failed to create unique file', 'Falha ao criar arquivo único'),
  ('Failed to list files', 'Falha ao listar arquivos'),
  ('Failed to delete file', 'Falha ao excluir arquivo'),
  ('Failed to start download', 'Falha ao iniciar o download'),
  (
    'Failed to load automaton from provided data',
    'Falha ao carregar o autômato a partir dos dados fornecidos',
  ),
  (
    'Failed to load automaton from provided JSON data',
    'Falha ao carregar o autômato a partir dos dados JSON fornecidos',
  ),
  (
    'Failed to load grammar from provided data',
    'Falha ao carregar a gramática a partir dos dados fornecidos',
  ),
  (
    'Documents directory is not available on web.',
    'O diretório de documentos não está disponível na web.',
  ),
  (' transition(s)', ' transição(ões)'),
  (' configuration(s) explored', ' configuração(ões) exploradas'),
  ('Failed to export ', 'Falha ao exportar '),
  ('Failed to prepare ', 'Falha ao preparar '),
  ('Example not found: ', 'Exemplo não encontrado: '),
  (
    'PNG export is not supported on web.',
    'A exportação PNG não é suportada na web.',
  ),
  ('Read symbol "', 'Leu o símbolo "'),
  (' from the input.', ' da entrada.'),
  ('From state ', 'Do estado '),
  (', the transition on "', ', a transição em "'),
  (' leads to ', ' leva a '),
  (
    'Computing ε-closure of initial state ',
    'Calculando o ε-fecho do estado inicial ',
  ),
  (
    'This gives us the set of states reachable without consuming input: ',
    'Isso nos dá o conjunto de estados alcançáveis sem consumir entrada: ',
  ),
  (
    'This set contains an accepting state, so the initial DFA state will be accepting.',
    'Este conjunto contém um estado de aceitação, então o estado inicial do AFD será de aceitação.',
  ),
  ('Process symbol \'', 'Processar símbolo \''),
  ('Create DFA state ', 'Criar estado AFD '),
  ('Create transition on \'', 'Criar transição em \''),
  (
    'Subset construction creates a DFA state for each distinct reachable NFA state set.',
    'A construção por subconjuntos cria um estado de AFD para cada conjunto distinto de estados de AFN alcançáveis.',
  ),
  (
    'CNF conversion requires the start symbol to not appear on the right-hand side of any production. A fresh start symbol is added with a single unit production to the old start symbol.',
    'A conversão para FNC exige que o símbolo inicial não apareça no lado direito de nenhuma produção. Um novo símbolo inicial é adicionado com uma única produção unitária para o símbolo inicial antigo.',
  ),
  (
    'Eliminates ε-productions by computing nullable non-terminals and adding productions with nullable symbols omitted. If the (new) start symbol is nullable, its ε-production is preserved.',
    'Elimina produções ε calculando não-terminais anuláveis e adicionando produções com os símbolos anuláveis omitidos. Se o (novo) símbolo inicial for anulável, sua produção ε é preservada.',
  ),
  (
    'Removes productions of the form A → B by computing unit-closure pairs and replacing them with the productions of the target non-terminal.',
    'Remove produções da forma A → B calculando pares de fecho unitário e substituindo-as pelas produções do não-terminal de destino.',
  ),
  (
    'Removes unreachable and unproductive non-terminals (and productions referencing them), since they cannot contribute to any derivation from the start symbol.',
    'Remove não-terminais inalcançáveis e improdutivos (e produções que os referenciam), pois eles não contribuem para nenhuma derivação a partir do símbolo inicial.',
  ),
  (
    'For any production with length ≥ 2, terminals are replaced by fresh non-terminals so that binary productions only contain non-terminals. Then productions longer than 2 are broken into a chain of binary productions.',
    'Em qualquer produção com comprimento ≥ 2, os terminais são substituídos por novos não-terminais para que produções binárias contenham só não-terminais. Depois, produções com mais de 2 símbolos são quebradas em uma cadeia de produções binárias.',
  ),
  (
    'Converted grammar to Greibach Normal Form where each production has the form A → aα (a terminal followed by zero or more nonterminals).',
    'Gramática convertida para a Forma Normal de Greibach, em que cada produção tem a forma A → aα (um terminal seguido de zero ou mais não-terminais).',
  ),
  (' cell(s) • witness ', ' célula(s) • testemunha '),
];

final _ptWorkflowPatterns = <(RegExp, String Function(Match))>[
  (
    RegExp(
      r'^This matches the (lambda|unit|useless|cnf|later) step, which comes later\.$',
    ),
    (match) {
      final stage = switch (match[1]) {
        'lambda' => 'remoção de produções vazias',
        'unit' => 'remoção de produções unitárias',
        'useless' => 'remoção de produções inúteis',
        'cnf' => 'conclusão da FNC',
        _ => 'posterior',
      };
      return 'Esta etapa corresponde à etapa $stage, que vem depois.';
    },
  ),
  (
    RegExp(r'^(\d+) source item\(s\)$'),
    (match) {
      final count = int.parse(match[1]!);
      return count == 1 ? '1 item de origem' : '$count itens de origem';
    },
  ),
  (
    RegExp(r'^(.+) · viable prefix: (.*)$'),
    (match) => '${match[1]} · prefixo viável: ${match[2]}',
  ),
  (RegExp(r'^ACTION (?!I\d+, )(.+)$'), (match) => 'AÇÃO ${match[1]}'),
  (RegExp(r'^GOTO (?!I\d+, )(.+)$'), (match) => 'GOTO ${match[1]}'),
  (
    RegExp(r'^ACTION I(\d+), (.+): (.+)$'),
    (match) =>
        'AÇÃO I${match[1]}, ${match[2]}: '
        '${match[3] == 'empty' ? 'vazio' : match[3]}',
  ),
  (
    RegExp(r'^GOTO I(\d+), (.+): (.+)$'),
    (match) =>
        'GOTO I${match[1]}, ${match[2]}: '
        '${match[3] == 'empty' ? 'vazio' : match[3]}',
  ),
  (
    RegExp(r'^(Shift/reduce|Reduce/reduce) at \[(.+), (.+)\]$'),
    (match) =>
        '${match[1] == 'Shift/reduce' ? 'Deslocamento/redução' : 'Redução/redução'} '
        'em [${match[2]}, ${match[3]}]',
  ),
  (
    RegExp(
      r'^Actions: (.*)\n(?:Witness prefix|Testemunho prefix): (.*)\nSources: (.*)$',
    ),
    (match) =>
        'Ações: ${match[1]}\n'
        'Prefixo testemunha: ${match[2]}\n'
        'Origens: ${match[3]}',
  ),
  (
    RegExp(r'^Shifted (.+) and entered I(\d+)\.$'),
    (match) => 'Deslocou ${match[1]} e entrou em I${match[2]}.',
  ),
  (
    RegExp(r'^Reduced by (.+): (.+)\.$'),
    (match) => 'Reduziu por ${match[1]}: ${match[2]}.',
  ),
  (
    RegExp(r'^Accepted on the completed augmented start item\.$'),
    (match) => 'Aceitou no item inicial aumentado concluído.',
  ),
  (
    RegExp(r'^No ACTION for \[I(\d+), (.+)\]\.$'),
    (match) => 'Nenhuma ação ACTION para [I${match[1]}, ${match[2]}].',
  ),
  (
    RegExp(r'^Conflicting ACTION entries at \[I(\d+), (.+)\]\.$'),
    (match) => 'Entradas ACTION conflitantes em [I${match[1]}, ${match[2]}].',
  ),
  (
    RegExp(r'^Missing GOTO for \[I(\d+), (.+)\]\.$'),
    (match) => 'GOTO ausente para [I${match[1]}, ${match[2]}].',
  ),
  (
    RegExp(r'^Canonical LR\(1\) construction was cancelled\.$'),
    (match) => 'A construção LR(1) canônica foi cancelada.',
  ),
  (
    RegExp(r'^Canonical LR\(1\) construction timed out after (.+)\.$'),
    (match) =>
        'A construção LR(1) canônica excedeu o limite de tempo após ${match[1]}.',
  ),
  (
    RegExp(
      r'^Canonical LR\(1\) construction exceeded the (item|state) limit\.$',
    ),
    (match) =>
        'A construção LR(1) canônica excedeu o limite de '
        '${match[1] == 'item' ? 'itens' : 'estados'}.',
  ),
  (
    RegExp(r'^Canonical LR\(1\) parsing was cancelled\.$'),
    (match) => 'A análise LR(1) canônica foi cancelada.',
  ),
  (
    RegExp(r'^Canonical LR\(1\) parsing timed out after (.+)\.$'),
    (match) =>
        'A análise LR(1) canônica excedeu o limite de tempo após ${match[1]}.',
  ),
  (
    RegExp(r'^Canonical LR\(1\) parsing reached the (\d+)-step limit\.$'),
    (match) =>
        'A análise LR(1) canônica atingiu o limite de ${match[1]} passos.',
  ),
  (
    RegExp(
      r'^The canonical LR\(1\) collection belongs to a different grammar revision\.$',
    ),
    (match) =>
        'A coleção LR(1) canônica pertence a uma revisão diferente da gramática.',
  ),
  (
    RegExp(
      r'^Grammar is not deterministic canonical LR\(1\): conflict at \[(.+), (.+)\]\.$',
    ),
    (match) =>
        'A gramática não é LR(1) canônica determinística: conflito em '
        '[${match[1]}, ${match[2]}].',
  ),
  (
    RegExp(r'^(shiftReduce|reduceReduce) conflict at \[(.+), (.+)\]\.$'),
    (match) =>
        '${match[1] == 'shiftReduce' ? 'Conflito de deslocamento/redução' : 'Conflito de redução/redução'} '
        'em [${match[2]}, ${match[3]}].',
  ),
  (
    RegExp(r'^LL\(1\) parsing timed out after (.+)\.$'),
    (match) => 'A análise LL(1) excedeu o limite de tempo após ${match[1]}.',
  ),
  (
    RegExp(r'^LL\(1\) parsing stopped at the (\d+)-step limit\.$'),
    (match) => 'A análise LL(1) parou no limite de ${match[1]} passos.',
  ),
  (
    RegExp(r'^Grammar is not LL\(1\): (?!conflict at )(.+)\.$'),
    (match) => 'A gramática não é LL(1): ${match[1]}.',
  ),
  (
    RegExp(
      r'^Unexpected trailing input "([^"]*)" at position (\d+); expected end of input\.$',
    ),
    (match) =>
        'Entrada extra inesperada "${match[1]}" na posição ${match[2]}; '
        'era esperado o fim da entrada.',
  ),
  (
    RegExp(r'^Unexpected end of input; expected "([^"]*)"\.$'),
    (match) => 'Fim inesperado da entrada; era esperado "${match[1]}".',
  ),
  (
    RegExp(
      r'^Terminal mismatch at position (\d+): expected "([^"]*)", found "([^"]*)"\.$',
    ),
    (match) =>
        'Incompatibilidade de terminal na posição ${match[1]}: era esperado '
        '"${match[2]}", mas foi encontrado "${match[3]}".',
  ),
  (
    RegExp(r'^Matched terminal "([^"]*)" and advanced the input\.$'),
    (match) => 'Terminal "${match[1]}" correspondente; entrada avançada.',
  ),
  (
    RegExp(
      r'^No production for \[([^,]+), ([^\]]+)\]; expected one of: (.+)\.$',
    ),
    (match) =>
        'Nenhuma produção para [${match[1]}, ${match[2]}]; era esperado um de: '
        '${match[3]}.',
  ),
  (
    RegExp(r'^Grammar is not LL\(1\): conflict at \[(.+), (.+)\]: (.+)\.$'),
    (match) =>
        'A gramática não é LL(1): conflito em [${match[1]}, ${match[2]}]: '
        '${match[3]}.',
  ),
  (
    RegExp(r'^Selected (.+) → (.+) from table\[(.+), (.+)\]\.$'),
    (match) =>
        'Selecionado ${match[1]} → ${match[2]} da tabela '
        '[${match[3]}, ${match[4]}].',
  ),
  (
    RegExp(r'^The string "([^"]*)" cannot be derived from grammar$'),
    (match) => 'A cadeia "${match[1]}" não pode ser derivada pela gramática',
  ),
  (
    RegExp(r'^Parsing using the (.+) parser failed$'),
    (match) => 'A análise usando o analisador ${match[1]} falhou',
  ),
  (
    RegExp(r'^Match terminal "([^"]*)"$'),
    (match) => 'Corresponder terminal "${match[1]}"',
  ),
  (
    RegExp(r'^Process substring "([^"]*)"$'),
    (match) => 'Processar subcadeia "${match[1]}"',
  ),
  (
    RegExp(r'^Try split "([^"]*)" \| "([^"]*)"$'),
    (match) => 'Tentar divisão "${match[1]}" | "${match[2]}"',
  ),
  (
    RegExp(r'^Process cell \[(\d+)\]\[(\d+)\]$'),
    (match) => 'Processar célula [${match[1]}][${match[2]}]',
  ),
  (
    RegExp(r'^Check split (?:at position|na posição) (\d+)$'),
    (match) => 'Verificar divisão na posição ${match[1]}',
  ),
  (
    RegExp(r'^Complete cell \[(\d+)\]\[(\d+)\]$'),
    (match) => 'Concluir célula [${match[1]}][${match[2]}]',
  ),
  (
    RegExp(r'^Cell \[(\d+)\]\[(\d+)\] complete$'),
    (match) => 'Célula [${match[1]}][${match[2]}] concluída',
  ),
  (
    RegExp(
      r'^Processing terminal "([^"]*)" at position (\d+)\. Looking for productions of the form A → "([^"]*)"\. No variables produce this terminal\.$',
    ),
    (match) =>
        'Processando o terminal "${match[1]}" na posição ${match[2]}. '
        'Procurando produções da forma A → "${match[3]}". '
        'Nenhuma variável produz este terminal.',
  ),
  (
    RegExp(
      r'^Processing terminal "([^"]*)" at position (\d+)\. Looking for productions of the form A → "([^"]*)"\. Variables that derive this terminal: (.+)\.$',
    ),
    (match) =>
        'Processando o terminal "${match[1]}" na posição ${match[2]}. '
        'Procurando produções da forma A → "${match[3]}". '
        'Variáveis que derivam este terminal: ${match[4]}.',
  ),
  (
    RegExp(r'^Sentential form fragment: "([^"]*)" at input position (\d+)\.$'),
    (match) =>
        'Fragmento da forma sentencial: "${match[1]}" na posição de entrada '
        '${match[2]}.',
  ),
  (
    RegExp(
      r'^We add every variable A such that there is a production A → "([^"]*)"\.$',
    ),
    (match) =>
        'Adicionamos toda variável A para a qual existe uma produção '
        'A → "${match[1]}".',
  ),
  (
    RegExp(r'^No variable derives "([^"]*)", so this cell stays empty\.$'),
    (match) =>
        'Nenhuma variável deriva "${match[1]}"; portanto, esta célula permanece vazia.',
  ),
  (
    RegExp(r'^Added variables: (.+)\.$'),
    (match) => 'Variáveis adicionadas: ${match[1]}.',
  ),
  (
    RegExp(r'^Busca de dica: (\d+) expandidos, (\d+) queued$'),
    (match) => 'Busca de dica: ${match[1]} expandidos, ${match[2]} na fila',
  ),
  (
    RegExp(
      r'^A busca de dica atingiu o limite (depth|expandedForms|visitedForms|frontier|symbolCount|time|resource)\. O resultado é inconclusivo\.$',
    ),
    (match) =>
        'A busca de dica atingiu o limite ${_ptHintLimitKind(match[1]!)}. '
        'O resultado é inconclusivo.',
  ),
  (
    RegExp(
      r'^Processing substring "([^"]*)" of (\d+) tokens starting at token position (\d+)\. We will try all possible ways to split this substring and check if any productions apply\.$',
    ),
    (match) =>
        'Processando a subcadeia "${match[1]}" de ${match[2]} tokens, '
        'começando na posição de token ${match[3]}. Tentaremos todas as '
        'formas possíveis de dividir esta subcadeia e verificar se alguma '
        'produção se aplica.',
  ),
  (
    RegExp(
      r'^We are filling table cell \[(\d+)\]\[(\d+)\] for a substring of (\d+) tokens\.$',
    ),
    (match) =>
        'Preenchemos a célula da tabela [${match[1]}][${match[2]}] para uma '
        'subcadeia de ${match[3]} tokens.',
  ),
  (
    RegExp(
      r'^Try all split points and apply productions A → B C where B derives the left part and C derives the right part\.$',
    ),
    (match) =>
        'Tente todos os pontos de divisão e aplique produções A → B C em que '
        'B deriva a parte esquerda e C deriva a parte direita.',
  ),
  (
    RegExp(
      r'^Splitting "([^"]*)" into "([^"]*)" \(cell \[(\d+)\]\[(\d+)\]\) and "([^"]*)" \(cell \[(\d+)\]\[(\d+)\]\)\. Left cell contains: \{(.*)\}\. Right cell contains: \{(.*)\}\. Looking for productions of the form A → B C where B ∈ left and C ∈ right\.$',
    ),
    (match) =>
        'Dividindo "${match[1]}" em "${match[2]}" (célula '
        '[${match[3]}][${match[4]}]) e "${match[5]}" (célula '
        '[${match[6]}][${match[7]}]). A célula esquerda contém: '
        '{${match[8]}}. A célula direita contém: {${match[9]}}. Procurando '
        'produções da forma A → B C em que B ∈ esquerda e C ∈ direita.',
  ),
  (
    RegExp(r'^Left part \(cell \[(\d+)\]\[(\d+)\]\) has \{(.*)\}\.$'),
    (match) =>
        'A parte esquerda (célula [${match[1]}][${match[2]}]) contém '
        '{${match[3]}}.',
  ),
  (
    RegExp(r'^Right part \(cell \[(\d+)\]\[(\d+)\]\) has \{(.*)\}\.$'),
    (match) =>
        'A parte direita (célula [${match[1]}][${match[2]}]) contém '
        '{${match[3]}}.',
  ),
  (
    RegExp(
      r'^If we find a production A → B C with B in left and C in right, then add A to cell \[(\d+)\]\[(\d+)\]\.$',
    ),
    (match) =>
        'Se encontrarmos uma produção A → B C com B na esquerda e C na '
        'direita, adicionaremos A à célula [${match[1]}][${match[2]}].',
  ),
  (
    RegExp(
      r'^Found production ([^ ]+) → ([^ ]+) ([^ ]+)\. Since ([^ ]+) is in the left cell and ([^ ]+) is in the right cell, we can derive "([^"]*)" using ([^ ]+)\. Adding ([^ ]+) to cell \[(\d+)\]\[(\d+)\]\.$',
    ),
    (match) =>
        'Produção encontrada ${match[1]} → ${match[2]} ${match[3]}. Como '
        '${match[4]} está na célula esquerda e ${match[5]} está na célula '
        'direita, podemos derivar "${match[6]}" usando ${match[7]}. '
        'Adicionando ${match[8]} à célula [${match[9]}][${match[10]}].',
  ),
  (
    RegExp(
      r'^We found a production that can combine the left and right parts\.$',
    ),
    (match) =>
        'Encontramos uma produção que pode combinar as partes esquerda e direita.',
  ),
  (
    RegExp(
      r'^Because ([^ ]+) derives the left substring and ([^ ]+) derives the right substring, ([^ ]+) derives "([^"]*)"\.$',
    ),
    (match) =>
        'Como ${match[1]} deriva a subcadeia esquerda e ${match[2]} deriva a '
        'subcadeia direita, ${match[3]} deriva "${match[4]}".',
  ),
  (
    RegExp(r'^Add ([^ ]+) to table cell \[(\d+)\]\[(\d+)\]\.$'),
    (match) =>
        'Adicione ${match[1]} à célula da tabela [${match[2]}][${match[3]}].',
  ),
  (
    RegExp(
      r'^Finished processing substring "([^"]*)" at cell \[(\d+)\]\[(\d+)\]\. No non-terminals can derive this substring\.$',
    ),
    (match) =>
        'Terminamos de processar a subcadeia "${match[1]}" na célula '
        '[${match[2]}][${match[3]}]. Nenhum não terminal pode derivar esta '
        'subcadeia.',
  ),
  (
    RegExp(
      r'^Finished processing substring "([^"]*)" at cell \[(\d+)\]\[(\d+)\]\. Non-terminals that can derive this substring: (.+)\.$',
    ),
    (match) =>
        'Terminamos de processar a subcadeia "${match[1]}" na célula '
        '[${match[2]}][${match[3]}]. Não terminais que podem derivar esta '
        'subcadeia: ${match[4]}.',
  ),
  (RegExp(r'^Substring: "([^"]*)"\.$'), (match) => 'Subcadeia: "${match[1]}".'),
  (
    RegExp(r'^No non-terminal derives this substring\.$'),
    (match) => 'Nenhum não terminal deriva esta subcadeia.',
  ),
  (
    RegExp(r'^Non-terminals that derive this substring: (.+)\.$'),
    (match) => 'Não terminais que derivam esta subcadeia: ${match[1]}.',
  ),
  (
    RegExp(
      r'^Checking if input string "([^"]*)" is accepted\. The top cell of the table contains: \{(.*)\}\. The start symbol ([^ ]+) is present, so the string IS accepted by the grammar\.$',
    ),
    (match) =>
        'Verificando se a cadeia de entrada "${match[1]}" é aceita. A célula '
        'superior da tabela contém: {${match[2]}}. O símbolo inicial '
        '${match[3]} está presente; portanto, a cadeia é aceita pela gramática.',
  ),
  (
    RegExp(
      r'^Checking if input string "([^"]*)" is accepted\. The top cell of the table contains: \{(.*)\}\. The start symbol ([^ ]+) is NOT present, so the string is NOT accepted by the grammar\.$',
    ),
    (match) =>
        'Verificando se a cadeia de entrada "${match[1]}" é aceita. A célula '
        'superior da tabela contém: {${match[2]}}. O símbolo inicial '
        '${match[3]} não está presente; portanto, a cadeia não é aceita pela '
        'gramática.',
  ),
  (
    RegExp(r'^Final \(top\) cell contains: \{(.*)\}\.$'),
    (match) => 'A célula final (superior) contém: {${match[1]}}.',
  ),
  (
    RegExp(
      r'^(?:Start symbol|Símbolo inicial) ([^ ]+) (?:is present|está presente) → ACCEPT\.$',
    ),
    (match) => 'O símbolo inicial ${match[1]} está presente → ACEITA.',
  ),
  (
    RegExp(
      r'^(?:Start symbol|Símbolo inicial) ([^ ]+) (?:is missing|está ausente) → REJECT\.$',
    ),
    (match) => 'O símbolo inicial ${match[1]} está ausente → REJEITA.',
  ),
  (
    RegExp(
      r'^CYK parsing completed for input string "([^"]*)"\. Processed (\d+) out of (\d+) cells in the parse table\. The string IS in the language generated by the grammar\.$',
    ),
    (match) =>
        'A análise CYK foi concluída para a cadeia de entrada "${match[1]}". '
        'Foram processadas ${match[2]} de ${match[3]} células na tabela de '
        'análise. A cadeia pertence à linguagem gerada pela gramática.',
  ),
  (
    RegExp(
      r'^CYK parsing completed for input string "([^"]*)"\. Processed (\d+) out of (\d+) cells in the parse table\. The string is NOT in the language generated by the grammar\.$',
    ),
    (match) =>
        'A análise CYK foi concluída para a cadeia de entrada "${match[1]}". '
        'Foram processadas ${match[2]} de ${match[3]} células na tabela de '
        'análise. A cadeia não pertence à linguagem gerada pela gramática.',
  ),
  (
    RegExp(r'^Filled (\d+) / (\d+) cells\.$'),
    (match) => 'Preenchidas ${match[1]} / ${match[2]} células.',
  ),
  (
    RegExp(
      r'^(?:Result|Resultado): ACCEPT \(string is generated by the grammar\)\.$',
    ),
    (match) => 'Resultado: ACEITA (a cadeia é gerada pela gramática).',
  ),
  (
    RegExp(
      r'^(?:Result|Resultado): REJECT \(string is not generated by the grammar\)\.$',
    ),
    (match) => 'Resultado: REJEITA (a cadeia não é gerada pela gramática).',
  ),
  (
    RegExp(r'Policy: (.+?)\. Reason: (.+?)\.'),
    (match) =>
        'Política: ${_ptTmPolicy(match[1]!)}. Motivo: ${_ptTmDetail(match[2]!)}.',
  ),
  (
    RegExp(r'Rejected: (.+)'),
    (match) => 'Rejeitada: ${_ptTmDetail(match[1]!)}',
  ),
  (
    RegExp(r'(\w+) L-systems are preserved but not expanded\.'),
    (match) =>
        'Sistemas L ${_ptLSystemVariant(match[1]!)} são preservados, mas não expandidos.',
  ),
  (
    RegExp(r'Turtle command (.+?) requires a finite number\.'),
    (match) => 'O comando da tartaruga ${match[1]} exige um número finito.',
  ),
  (
    RegExp(r'(\d+) turtle branch state\(s\) were not restored\.'),
    (match) {
      final count = int.parse(match[1]!);
      return count == 1
          ? '1 estado de ramificação da tartaruga não foi restaurado.'
          : '$count estados de ramificação da tartaruga não foram restaurados.';
    },
  ),
  (
    RegExp(r'^Rule (\d+) must contain ->\.$'),
    (match) => 'A regra ${match[1]} deve conter ->.',
  ),
  (
    RegExp(r'^Rule (\d+) has an incomplete context marker\.$'),
    (match) => 'A regra ${match[1]} tem um marcador de contexto incompleto.',
  ),
  (
    RegExp(r'^Rule (\d+) must have one predecessor token\.$'),
    (match) => 'A regra ${match[1]} deve ter um token predecessor.',
  ),
  (
    RegExp(r'^Rule (\d+) must have one token between < and >\.$'),
    (match) => 'A regra ${match[1]} deve ter um token entre < e >.',
  ),
  (
    RegExp(r'^Command mapping (\d+) must contain =\.$'),
    (match) => 'O mapeamento de comandos ${match[1]} deve conter =.',
  ),
  (
    RegExp(r'^Command mapping (\d+) must start with one token\.$'),
    (match) =>
        'O mapeamento de comandos ${match[1]} deve começar com um token.',
  ),
  (
    RegExp(r'^Duplicate command mapping for (.+)\.$'),
    (match) => 'Mapeamento de comando duplicado para ${match[1]}.',
  ),
  (
    RegExp(r'^Command mapping (\d+) uses an unknown command\.$'),
    (match) =>
        'O mapeamento de comandos ${match[1]} usa um comando desconhecido.',
  ),
  (
    RegExp(r'^Generation (\d+) (?:of|de) (\d+)$'),
    (match) => 'Geração ${match[1]} de ${match[2]}',
  ),
  (
    RegExp(r'^Generation (\d+) has (\d+) tokens\.$'),
    (match) => 'A geração ${match[1]} tem ${match[2]} tokens.',
  ),
  (
    RegExp(r'^Generation (\d+) has (\d+) tokens and (\d+) segments\.$'),
    (match) =>
        'A geração ${match[1]} tem ${match[2]} tokens e ${match[3]} segmentos.',
  ),
  (
    RegExp(
      r'^Turtle rendering for generation (\d+), (\d+) line segments, maximum branch depth (\d+)\.$',
    ),
    (match) =>
        'Renderização da tartaruga para a geração ${match[1]}, ${match[2]} segmentos de linha, profundidade máxima de ramificação ${match[3]}.',
  ),
  (RegExp(r'^(\d+) more tokens$'), (match) => 'mais ${match[1]} tokens'),
  (
    RegExp(r'^Expansion stopped at the (.+) limit\.$'),
    (match) =>
        'A expansão parou no limite de ${_ptLSystemLimitKind(match[1]!)}.',
  ),
  (
    RegExp(r'^Input length (.+)$'),
    (match) => 'Comprimento da entrada ${match[1]}',
  ),
  (
    RegExp(r'^Input (.+) • step (\d+)$'),
    (match) => 'Entrada ${match[1]} • passo ${match[2]}',
  ),
  (
    RegExp(r'^Case (.+), input (.+), outcome (.+)$'),
    (match) => 'Caso ${match[1]}, entrada ${match[2]}, resultado ${match[3]}',
  ),
  (RegExp(r'^Trace · (.+)$'), (match) => 'Traço · ${match[1]}'),
  (RegExp(r'^steps (.+)$'), (match) => 'passos ${match[1]}'),
  (RegExp(r'^configurations (.+)$'), (match) => 'configurações ${match[1]}'),
  (RegExp(r'^(.+) elapsed$'), (match) => 'tempo decorrido: ${match[1]}'),
  (RegExp(r'^Output: (.+)$'), (match) => 'Saída: ${match[1]}'),
  (RegExp(r'^Code: (.+)$'), (match) => 'Código: ${match[1]}'),
  (
    RegExp(r'^Comparison differs: (.+)$'),
    (match) => 'A comparação difere: ${match[1]}',
  ),
  (
    RegExp(r'^(\d+) differences found in these finite cases\.$'),
    (match) => '${match[1]} diferenças encontradas nestes casos finitos.',
  ),
  (
    RegExp(r'^The batch limit is (\d+) cases\.$'),
    (match) => 'O lote tem limite de ${match[1]} casos.',
  ),
  (
    RegExp(r'^Batch started for (\d+) cases\.$'),
    (match) => 'Lote iniciado para ${match[1]} casos.',
  ),
  (
    RegExp(r'^Batch complete in (.+)\.$'),
    (match) => 'Lote concluído em ${match[1]}.',
  ),
  (
    RegExp(r'^The comparison model does not support (.+)\.$'),
    (match) => 'O modelo de comparação não oferece suporte a ${match[1]}.',
  ),
  (
    RegExp(r'^Comparison failed: (.+)$'),
    (match) => 'Falha na comparação: ${match[1]}',
  ),
  (
    RegExp(r'^Rerunning (.+) with trace…$'),
    (match) => 'Executando novamente ${match[1]} com traço…',
  ),
  (
    RegExp(r'^Rerunning (.+)…$'),
    (match) => 'Executando novamente ${match[1]}…',
  ),
  (
    RegExp(r'^Case (.+) rerun complete\.$'),
    (match) => 'Nova execução do caso ${match[1]} concluída.',
  ),
  (
    RegExp(r'^Imported (\d+) cases from (.+)\.$'),
    (match) => '${match[1]} casos importados de ${match[2]}.',
  ),
  (
    RegExp(r'^Could not import inputs: (.+)$'),
    (match) => 'Não foi possível importar as entradas: ${match[1]}',
  ),
  (RegExp(r'^Removed case (.+)\.$'), (match) => 'Caso ${match[1]} removido.'),
  (
    RegExp(r'^Generated case count cannot exceed (\d+)\.$'),
    (match) => 'A quantidade de casos gerados não pode exceder ${match[1]}.',
  ),
  (
    RegExp(r'^Generated (\d+) ordered cases\.$'),
    (match) => 'Gerados ${match[1]} casos ordenados.',
  ),
  (
    RegExp(r'^Report exported to (.+)\.$'),
    (match) => 'Relatório exportado para ${match[1]}.',
  ),
  (
    RegExp(r'^Could not export report: (.+)$'),
    (match) => 'Não foi possível exportar o relatório: ${match[1]}',
  ),
  (
    RegExp(r'^(\d+) de (\d+) expected$'),
    (match) => '${match[1]} de ${match[2]} esperados',
  ),
  (
    RegExp(
      r'^(\d+) estados, (\d+) transições, one entry state, and (\d+) accepting estados\. Alphabet: (.+)\.$',
    ),
    (match) =>
        '${match[1]} estados, ${match[2]} transições, uma entrada e '
        '${match[3]} estados de aceitação. Alfabeto: ${match[4]}.',
  ),
  (
    RegExp(r'^State (.+), ID (.+), (.+)$'),
    (match) => 'Estado ${match[1]}, ID ${match[2]}, ${match[3]}',
  ),
  (
    RegExp(r'^Transition (.+), from (.+) to (.+), input (.+)$'),
    (match) =>
        'Transição ${match[1]}, de ${match[2]} para ${match[3]}, entrada ${match[4]}',
  ),
  (
    RegExp(r'^State actions for (.+)$'),
    (match) => 'Ações do estado ${match[1]}',
  ),
  (
    RegExp(r'^Transition actions for (.+)$'),
    (match) => 'Ações da transição ${match[1]}',
  ),
  (
    RegExp(r'^(.+) · (.+) · source \[(\d+), (\d+)\)$'),
    (match) => '${match[1]} · ${match[2]} · origem [${match[3]}, ${match[4]})',
  ),
  (
    RegExp(r'^Remove (.+) from this fragment\?$'),
    (match) => 'Remover ${match[1]} deste fragmento?',
  ),
  (
    RegExp(r'^Remove (.+) and its (\d+) connected transition\?$'),
    (match) => 'Remover ${match[1]} e sua ${match[2]} transição conectada?',
  ),
  (
    RegExp(r'^Remove (.+) and its (\d+) connected transições\?$'),
    (match) => 'Remover ${match[1]} e suas ${match[2]} transições conectadas?',
  ),
  (
    RegExp(
      r'^Step, configuration, and timeout limits must be positive; the trace limit must be between 0 and (\d+)\.$',
    ),
    (match) =>
        'Os limites de passos, configurações e tempo devem ser positivos; '
        'o limite do traço deve estar entre 0 e ${match[1]}.',
  ),
  (
    RegExp(r'^Batch progress: ([0-9.,]+) of ([0-9.,]+) cases complete$'),
    (match) => 'Progresso do lote: ${match[1]} de ${match[2]} casos concluídos',
  ),
  (
    RegExp(r'^Batch progress: ([0-9.,]+) de ([0-9.,]+) cases complete$'),
    (match) => 'Progresso do lote: ${match[1]} de ${match[2]} casos concluídos',
  ),
  (
    RegExp(r'^([0-9.,]+) of ([0-9.,]+) cases complete$'),
    (match) => '${match[1]} de ${match[2]} casos concluídos',
  ),
  (
    RegExp(r'^([0-9.,]+) de ([0-9.,]+) cases complete$'),
    (match) => '${match[1]} de ${match[2]} casos concluídos',
  ),
  (RegExp(r'^(\d+) of (\d+)$'), (match) => '${match[1]} de ${match[2]}'),
];

String _ptLSystemLimitKind(String source) => switch (source) {
  'generations' => 'gerações',
  'symbols' => 'símbolos',
  'estimatedBytes' => 'bytes estimados',
  'elapsedTime' => 'tempo decorrido',
  _ => source,
};

String _ptHintLimitKind(String source) => switch (source) {
  'depth' => 'profundidade',
  'expandedForms' => 'formas expandidas',
  'visitedForms' => 'formas visitadas',
  'frontier' => 'fronteira',
  'symbolCount' => 'quantidade de símbolos',
  'time' => 'tempo',
  'resource' => 'recurso',
  _ => source,
};

String _ptLSystemVariant(String source) => switch (source) {
  'stochastic' => 'estocásticos',
  'parametric' => 'paramétricos',
  'contextSensitive' => 'sensíveis ao contexto',
  _ => source,
};

String _ptTmPolicy(String source) => switch (source) {
  'Final state' => 'Estado final',
  'Halting' => 'Parada',
  'Final state or halting' => 'Estado final ou parada',
  _ => source,
};

String _ptTmDetail(String source) => switch (source) {
  'entered a final state' => 'entrou em um estado final',
  'halted in a final state' => 'parou em um estado final',
  'halted outside a final state' => 'parou fora de um estado final',
  'reachable configurations were exhausted' =>
    'as configurações alcançáveis foram esgotadas',
  'an exact configuration repeated' => 'uma configuração exata se repetiu',
  'the step limit was reached' => 'o limite de passos foi atingido',
  'the configuration limit was reached' =>
    'o limite de configurações foi atingido',
  'the timeout was reached' => 'o limite de tempo foi atingido',
  'the simulation was cancelled' => 'a simulação foi cancelada',
  'the machine is invalid' => 'a máquina é inválida',
  'Step limit reached; the result is inconclusive' =>
    'Limite de passos atingido; o resultado é inconclusivo',
  'Configuration limit reached; the result is inconclusive' =>
    'Limite de configurações atingido; o resultado é inconclusivo',
  'Simulation timed out' => 'A simulação excedeu o limite de tempo',
  'Infinite loop detected' => 'Loop infinito detectado',
  'Simulation inconclusive' => 'Simulação inconclusiva',
  'Simulation cancelled' => 'Simulação cancelada',
  'Invalid machine' => 'Máquina inválida',
  _ => source,
};

extension AppLocalizationsCanvasNames on AppLocalizations {
  /// Maps stored default canvas names to the current locale.
  String localizedCanvasName(String storedName) {
    return switch (storedName) {
      'Untitled Automaton' => untitledAutomaton,
      'Canvas PDA' => canvasPda,
      'Canvas TM' => canvasTm,
      _ => storedName,
    };
  }
}

extension AppLocalizationsExampleNames on AppLocalizations {
  /// Maps stored example identifiers to localized button titles.
  String localizedExampleName(String storedName) {
    return switch (storedName) {
      'AFD - Termina com A' => exampleDfaEndsWithA,
      'AFD - Binário divisível por 3' => exampleDfaBinaryDivBy3,
      'AFD - Paridade AB' => exampleDfaParityAb,
      'AFD - Contém AB' => exampleDfaContainsAb,
      'AFNλ - A ou AB' => exampleNfaLambdaAOrAb,
      'GLC - Palíndromo' => exampleCfgPalindrome,
      'GLC - Parênteses balanceados' => exampleCfgBalancedParens,
      'GLC - a^n b^n' => exampleCfgAnBn,
      'GLC - Zeros em quantidade par' => exampleCfgEvenZeros,
      'GLC - Expressões aritméticas' => exampleCfgArithmetic,
      'APD - Parênteses Balanceados' => examplePdaBalancedParens,
      'APD - a^n b^n' => examplePdaAnBn,
      'APD - Palíndromo' => examplePdaPalindrome,
      'APD - a^n b^2n' => examplePdaAnB2n,
      'APD - w#reverse(w)' => examplePdaWHashReverseW,
      'MT - a^n b^n' => exampleTmAnBn,
      'MT - Binário para unário' => exampleTmBinaryToUnary,
      'MT - Cópia de string' => exampleTmCopyString,
      'MT - Incremento binário' => exampleTmBinaryIncrement,
      'MT - Verificador de palíndromo' => exampleTmPalindromeChecker,
      'Regex - Repetição de A' => exampleRegexRepeatA,
      'Regex - Termina com AB' => exampleRegexEndsWithAb,
      'Regex - Binário iniciado por 0' => exampleRegexBinaryStarts0,
      'Regex - Pares AB ou BA' => exampleRegexPairsAbOrBa,
      'Regex - Blocos de A e B' => exampleRegexBlocksAb,
      _ => storedName,
    };
  }
}
