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
  'LL(1) Steps': 'Passos LL(1)',
  'Stack': 'Pilha',
  'Remaining input': 'Entrada restante',
  'Lookahead': 'Antecipação',
  'Production': 'Produção',
  'Expected': 'Esperado',
  'Accept input': 'Aceitar entrada',
  'Parsing error': 'Erro de análise',
  'NFA to DFA': 'AFN para AFD',
  'Remove λ-transitions': 'Remover transições λ',
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
  'Step limit': 'Limite de passos',
  'Configuration limit': 'Limite de configurações',
  'Time limit': 'Limite de tempo',
  'Limit reached': 'Limite atingido',
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
  'Candidate coverage': 'Cobertura de candidatas',
  'Visited span maximum': 'Máximo do intervalo visitado',
  'Maximum nonblank cells': 'Máximo de células não brancas',
  'Inconclusive executions': 'Execuções inconclusivas',
  'Read symbol': 'Símbolo lido',
  'Incoming transition': 'Transição de entrada',
  'State trace': 'Traço de estados',
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
  (
    'Select an algorithm above to analyze your ',
    'Selecione um algoritmo acima para analisar '
  ),
  (
    'Convert non-deterministic to deterministic automaton',
    'Converter autômato não determinístico em determinístico'
  ),
  (
    'Eliminate epsilon transitions from the automaton',
    'Eliminar transições epsilon do autômato'
  ),
  (
    'Minimize deterministic finite automaton',
    'Minimizar o autômato finito determinístico'
  ),
  (
    'Add trap state to make DFA complete',
    'Adicionar estado armadilha para completar o AFD'
  ),
  (
    'Flip accepting states after completion',
    'Inverter estados de aceitação após completar'
  ),
  (
    'Identify reachable states from initial state',
    'Identificar estados alcançáveis a partir do estado inicial'
  ),
  ('Failed to load ', 'Falha ao carregar '),
  ('Example loaded: ', 'Exemplo carregado: '),
  ('Failed to convert ', 'Falha ao converter '),
  ('Analysis failed', 'Falha na análise'),
  ('Retaining witness trace for ', 'Retendo o traço testemunha para '),
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
    ' deve possuir estado inicial definido.'
  ),
  (
    ' must be deterministic (no nondeterministic transitions).',
    ' deve ser determinístico (sem transições não determinísticas).'
  ),
  (
    ' cannot contain ε (epsilon) transitions.',
    ' não pode conter transições ε (epsilon).'
  ),
  (
    ' has a transition with a symbol outside the alphabet: ',
    ' possui transição com símbolo fora do alfabeto: '
  ),
  (
    'Error computing DFA complement: ',
    'Erro ao calcular o complemento do AFD: '
  ),
  (
    'Error computing prefix closure: ',
    'Erro ao calcular o fecho por prefixos: '
  ),
  (
    'Error computing suffix closure: ',
    'Erro ao calcular o fecho por sufixos: '
  ),
  ('Error combining DFAs (', 'Erro ao combinar AFDs ('),
  (
    'Error removing lambda transitions: ',
    'Erro ao remover transições lambda: '
  ),
  (' must have at least one state', ' deve ter pelo menos um estado'),
  (
    'Cannot simulate empty automaton',
    'Não é possível simular um autômato vazio'
  ),
  (
    'Cannot convert empty automaton to regex',
    'Não é possível converter um autômato vazio em expressão regular'
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
    'Falha ao obter o diretório de documentos'
  ),
  ('Failed to create unique file', 'Falha ao criar arquivo único'),
  ('Failed to list files', 'Falha ao listar arquivos'),
  ('Failed to delete file', 'Falha ao excluir arquivo'),
  ('Failed to start download', 'Falha ao iniciar o download'),
  (
    'Failed to load automaton from provided data',
    'Falha ao carregar o autômato a partir dos dados fornecidos'
  ),
  (
    'Failed to load automaton from provided JSON data',
    'Falha ao carregar o autômato a partir dos dados JSON fornecidos'
  ),
  (
    'Failed to load grammar from provided data',
    'Falha ao carregar a gramática a partir dos dados fornecidos'
  ),
  (
    'Documents directory is not available on web.',
    'O diretório de documentos não está disponível na web.'
  ),
  (' transition(s)', ' transição(ões)'),
  (' configuration(s) explored', ' configuração(ões) exploradas'),
  ('Failed to export ', 'Falha ao exportar '),
  ('Failed to prepare ', 'Falha ao preparar '),
  ('Example not found: ', 'Exemplo não encontrado: '),
  (
    'PNG export is not supported on web.',
    'A exportação PNG não é suportada na web.'
  ),
  ('Read symbol "', 'Leu o símbolo "'),
  (' from the input.', ' da entrada.'),
  ('From state ', 'Do estado '),
  (', the transition on "', ', a transição em "'),
  (' leads to ', ' leva a '),
  (
    'Computing ε-closure of initial state ',
    'Calculando o ε-fecho do estado inicial '
  ),
  (
    'This gives us the set of states reachable without consuming input: ',
    'Isso nos dá o conjunto de estados alcançáveis sem consumir entrada: '
  ),
  (
    'This set contains an accepting state, so the initial DFA state will be accepting.',
    'Este conjunto contém um estado de aceitação, então o estado inicial do AFD será de aceitação.'
  ),
  ('Process symbol \'', 'Processar símbolo \''),
  ('Create DFA state ', 'Criar estado AFD '),
  ('Create transition on \'', 'Criar transição em \''),
  (
    'Subset construction creates a DFA state for each distinct reachable NFA state set.',
    'A construção por subconjuntos cria um estado de AFD para cada conjunto distinto de estados de AFN alcançáveis.'
  ),
  (
    'CNF conversion requires the start symbol to not appear on the right-hand side of any production. A fresh start symbol is added with a single unit production to the old start symbol.',
    'A conversão para FNC exige que o símbolo inicial não apareça no lado direito de nenhuma produção. Um novo símbolo inicial é adicionado com uma única produção unitária para o símbolo inicial antigo.'
  ),
  (
    'Eliminates ε-productions by computing nullable non-terminals and adding productions with nullable symbols omitted. If the (new) start symbol is nullable, its ε-production is preserved.',
    'Elimina produções ε calculando não-terminais anuláveis e adicionando produções com os símbolos anuláveis omitidos. Se o (novo) símbolo inicial for anulável, sua produção ε é preservada.'
  ),
  (
    'Removes productions of the form A → B by computing unit-closure pairs and replacing them with the productions of the target non-terminal.',
    'Remove produções da forma A → B calculando pares de fecho unitário e substituindo-as pelas produções do não-terminal de destino.'
  ),
  (
    'Removes unreachable and unproductive non-terminals (and productions referencing them), since they cannot contribute to any derivation from the start symbol.',
    'Remove não-terminais inalcançáveis e improdutivos (e produções que os referenciam), pois eles não contribuem para nenhuma derivação a partir do símbolo inicial.'
  ),
  (
    'For any production with length ≥ 2, terminals are replaced by fresh non-terminals so that binary productions only contain non-terminals. Then productions longer than 2 are broken into a chain of binary productions.',
    'Em qualquer produção com comprimento ≥ 2, os terminais são substituídos por novos não-terminais para que produções binárias contenham só não-terminais. Depois, produções com mais de 2 símbolos são quebradas em uma cadeia de produções binárias.'
  ),
  (
    'Converted grammar to Greibach Normal Form where each production has the form A → aα (a terminal followed by zero or more nonterminals).',
    'Gramática convertida para a Forma Normal de Greibach, em que cada produção tem a forma A → aα (um terminal seguido de zero ou mais não-terminais).'
  ),
  (' cell(s) • witness ', ' célula(s) • testemunha '),
];

final _ptWorkflowPatterns = <(RegExp, String Function(Match))>[
  (
    RegExp(r'^Input length (.+)$'),
    (match) => 'Comprimento da entrada ${match[1]}',
  ),
  (
    RegExp(r'^(\d+) of (\d+)$'),
    (match) => '${match[1]} de ${match[2]}',
  ),
];

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
