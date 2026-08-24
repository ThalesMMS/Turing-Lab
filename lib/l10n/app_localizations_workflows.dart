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
];
