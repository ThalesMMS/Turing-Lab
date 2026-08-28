import '../core/messages/structured_message.dart';
import '../core/pumping_lemma/pumping_lemma.dart';
import 'app_localizations.dart';

enum PumpingLemmaText {
  challenge,
  exampleOrProblem,
  mode,
  modeChallenge,
  modePractice,
  modeFreeForm,
  adversarialProofSteps,
  retryDecomposition,
  restartSession,
  hint,
  explanation,
  lengthLabel,
  lengthHelp,
  opponentChoosesP,
  witnessArray,
  witnessHelp,
  learnerChoosesWitness,
  validDecomposition,
  opponentChoosesDecomposition,
  exponentLabel,
  exponentHelp,
  learnerChoosesI,
  wordRemains,
  manualEvidenceHelp,
  checkWord,
  evidenceBoundary,
  finiteEvidenceNotice,
  regularProofBoundary,
  contextFreeProofBoundary,
  history,
  noChoices,
  sessionCopied,
  copyReport,
}

extension PumpingLemmaLocalizations on AppLocalizations {
  bool get _isPortuguese => localeName.toLowerCase().startsWith('pt');

  String pumpingLemmaText(PumpingLemmaText key) =>
      (_isPortuguese ? _pumpingPt : _pumpingEn)[key]!;

  String pumpingTheorem(PumpingLemmaTheorem theorem) => switch (theorem) {
    PumpingLemmaTheorem.regular =>
      _isPortuguese
          ? 'Lema do bombeamento para linguagens regulares'
          : 'Regular pumping lemma',
    PumpingLemmaTheorem.contextFree =>
      _isPortuguese
          ? 'Lema do bombeamento para linguagens livres de contexto'
          : 'Context-free pumping lemma',
  };

  String pumpingModeLabel(PumpingLemmaMode mode) =>
      pumpingLemmaText(switch (mode) {
        PumpingLemmaMode.challenge => PumpingLemmaText.modeChallenge,
        PumpingLemmaMode.guidedPractice => PumpingLemmaText.modePractice,
        PumpingLemmaMode.freeForm => PumpingLemmaText.modeFreeForm,
      });

  String pumpingLearningObjective(String objective) => _isPortuguese
      ? 'Objetivo de aprendizagem: $objective'
      : 'Learning objective: $objective';

  String pumpingRepresentationSource(String representation, String revision) =>
      _isPortuguese
      ? 'Representação: $representation. Revisão da fonte: $revision.'
      : 'Representation: $representation. Source revision: $revision.';

  String pumpingDecompositionHelp(int count) => _isPortuguese
      ? 'O oponente escolhe uma de $count decomposições finitas.'
      : 'Opponent selects one of $count finite decompositions.';

  String pumpingRoundComplete(int score) => _isPortuguese
      ? 'Rodada concluída. Pontuação: $score. Tentar novamente explora outra decomposição sem pontuar duas vezes a mesma rodada.'
      : 'Round complete. Score: $score. Retry explores another decomposition without awarding the same round twice.';

  String pumpingStage(PumpingLemmaStage stage) => switch (stage) {
    PumpingLemmaStage.awaitingPumpingLength =>
      _isPortuguese
          ? 'Etapa 1, para todo p: o oponente escolhe o comprimento de bombeamento.'
          : 'Step 1, for every p: opponent chooses the pumping length.',
    PumpingLemmaStage.awaitingWitness =>
      _isPortuguese
          ? 'Etapa 2, existe w: o aprendiz escolhe uma testemunha que depende de p.'
          : 'Step 2, there exists w: learner chooses a witness that depends on p.',
    PumpingLemmaStage.awaitingDecomposition =>
      _isPortuguese
          ? 'Etapa 3, para toda decomposição válida: o oponente escolhe a divisão.'
          : 'Step 3, for every valid decomposition: opponent chooses the split.',
    PumpingLemmaStage.awaitingExponent =>
      _isPortuguese
          ? 'Etapa 4, existe i: o aprendiz escolhe um expoente de bombeamento.'
          : 'Step 4, there exists i: learner chooses a pump exponent.',
    PumpingLemmaStage.awaitingEvidence =>
      _isPortuguese
          ? 'Etapa 5: verifique a pertinência concreta e declare a obrigação de prova restante.'
          : 'Step 5: check concrete membership and state the remaining proof obligation.',
    PumpingLemmaStage.completed =>
      _isPortuguese
          ? 'A rodada finita selecionada foi concluída.'
          : 'The selected finite round is complete.',
  };

  String pumpingTurn(PumpingLemmaTurnKind kind) => switch (kind) {
    PumpingLemmaTurnKind.pumpingLengthChosen =>
      _isPortuguese ? 'Oponente escolheu p' : 'Opponent chose p',
    PumpingLemmaTurnKind.witnessChosen =>
      _isPortuguese ? 'Aprendiz escolheu w' : 'Learner chose w',
    PumpingLemmaTurnKind.decompositionChosen =>
      _isPortuguese
          ? 'Oponente escolheu a decomposição'
          : 'Opponent chose decomposition',
    PumpingLemmaTurnKind.exponentChosen =>
      _isPortuguese ? 'Aprendiz escolheu i' : 'Learner chose i',
    PumpingLemmaTurnKind.evidenceRecorded =>
      _isPortuguese
          ? 'Evidência finita registrada'
          : 'Finite evidence recorded',
    PumpingLemmaTurnKind.completed =>
      _isPortuguese ? 'Rodada concluída' : 'Round completed',
    PumpingLemmaTurnKind.retry =>
      _isPortuguese ? 'Nova tentativa de decomposição' : 'Decomposition retry',
    PumpingLemmaTurnKind.restarted =>
      _isPortuguese ? 'Sessão reiniciada' : 'Session restarted',
  };

  String pumpingSegmentDescription({
    required String label,
    required int start,
    required int end,
    required String tokens,
  }) => _isPortuguese
      ? '$label, tokens de $start a $end: $tokens'
      : '$label tokens $start through $end: $tokens';

  String pumpingDecompositionSemantics(String description) => _isPortuguese
      ? 'Decomposição. $description'
      : 'Decomposition. $description';

  String pumpingExponentWord(int exponent, String word) => _isPortuguese
      ? 'Para o expoente $exponent, palavra bombeada: $word'
      : 'For exponent $exponent, pumped word: $word';

  String pumpingPumpedWord(String word) =>
      _isPortuguese ? 'Palavra bombeada: $word' : 'Pumped word: $word';

  String get pumpingEmptyWord => _isPortuguese ? 'épsilon' : 'epsilon';

  String resolvePumpingLemmaMessage(StructuredMessage message) {
    if (message.namespace != 'pumping') {
      return structuredMessageUnknown(message.stableCode);
    }
    return switch (message.code) {
      'validation.pumping-length-positive' when _noArguments(message) =>
        pumpingMessagePumpingLengthPositive,
      'validation.exponent-non-negative' when _noArguments(message) =>
        pumpingMessageExponentNonNegative,
      'validation.maximum-tokens-non-negative' when _noArguments(message) =>
        pumpingMessageMaximumTokensNonNegative,
      'validation.required-text-not-empty'
          when _matches(message, const {
            'field': (
              kind: StructuredMessageArgumentKind.identifier,
              role: 'field-name',
            ),
          }) =>
        pumpingMessageRequiredTextNotEmpty(_string(message, 'field')),
      'validation.suggested-witness-not-empty' when _noArguments(message) =>
        pumpingMessageSuggestedWitnessNotEmpty,
      'validation.custom-title-not-empty' when _noArguments(message) =>
        pumpingMessageCustomTitleNotEmpty,
      'validation.witness-requires-pumping-length' when _noArguments(message) =>
        pumpingMessageWitnessRequiresPumpingLength,
      'validation.witness-minimum-tokens'
          when _matches(message, const {
            'minimum': (
              kind: StructuredMessageArgumentKind.integer,
              role: 'minimum-token-count',
            ),
          }) =>
        pumpingMessageWitnessMinimumTokens(_int(message, 'minimum')),
      'validation.decomposition-theorem-mismatch'
          when _matches(message, const {
            'actual': (
              kind: StructuredMessageArgumentKind.outcome,
              role: 'pumping-theorem',
            ),
            'expected': (
              kind: StructuredMessageArgumentKind.outcome,
              role: 'pumping-theorem',
            ),
          }) =>
        pumpingMessageDecompositionTheoremMismatch(
          _theoremWire(_string(message, 'actual'), _isPortuguese),
          _theoremWire(_string(message, 'expected'), _isPortuguese),
        ),
      'validation.decomposition-witness-mismatch' when _noArguments(message) =>
        pumpingMessageDecompositionWitnessMismatch,
      'validation.decomposition-constraint-violation'
          when _noArguments(message) =>
        pumpingMessageDecompositionConstraintViolation,
      'input.enter-positive-pumping-length' when _noArguments(message) =>
        pumpingMessageEnterPositivePumpingLength,
      'input.enter-non-negative-exponent' when _noArguments(message) =>
        pumpingMessageEnterNonNegativeExponent,
      'input.invalid-token-array' when _noArguments(message) =>
        pumpingMessageInvalidTokenArray,
      'session.no-valid-decomposition' when _noArguments(message) =>
        pumpingMessageNoValidDecomposition,
      'session.decompositions-enumerated'
          when _matches(message, const {
            'count': (
              kind: StructuredMessageArgumentKind.count,
              role: 'decomposition-count',
            ),
          }) =>
        pumpingMessageDecompositionsEnumerated(_int(message, 'count')),
      'session.pumped-word-bounded'
          when _matches(message, const {
            'minimum': (
              kind: StructuredMessageArgumentKind.integer,
              role: 'minimum-token-count',
            ),
            'maximum': (
              kind: StructuredMessageArgumentKind.bound,
              role: 'token-limit',
            ),
          }) =>
        pumpingMessagePumpedWordBounded(
          _int(message, 'minimum'),
          _int(message, 'maximum'),
        ),
      'session.choose-bounded-exponent' when _noArguments(message) =>
        pumpingMessageChooseBoundedExponent,
      'outcome.counterexample-evidence' when _noArguments(message) =>
        pumpingMessageCounterexampleEvidence,
      'outcome.finite-check-inconclusive' when _noArguments(message) =>
        pumpingMessageFiniteCheckInconclusive,
      'session.imported' when _noArguments(message) =>
        pumpingMessageSessionImported,
      'transition.wrong-stage' when _noArguments(message) =>
        pumpingMessageTransitionWrongStage,
      'transition.wrong-player' when _noArguments(message) =>
        pumpingMessageTransitionWrongPlayer,
      'transition.invalid-pumping-length' when _noArguments(message) =>
        resolvePumpingLemmaMessage(
          PumpingLemmaMessages.pumpingLengthPositive(),
        ),
      'transition.witness-too-short' when _noArguments(message) =>
        pumpingMessageTransitionWitnessTooShort,
      'transition.witness-outside-language' when _noArguments(message) =>
        pumpingMessageTransitionWitnessOutsideLanguage,
      'transition.decomposition-mismatch' when _noArguments(message) =>
        resolvePumpingLemmaMessage(
          PumpingLemmaMessages.decompositionWitnessMismatch(),
        ),
      'transition.decomposition-constraint' when _noArguments(message) =>
        resolvePumpingLemmaMessage(
          PumpingLemmaMessages.decompositionConstraintViolation(),
        ),
      'transition.invalid-exponent' when _noArguments(message) =>
        resolvePumpingLemmaMessage(PumpingLemmaMessages.exponentNonNegative()),
      _ => structuredMessageUnknown(message.stableCode),
    };
  }
}

typedef _PumpingArgumentContract = ({
  StructuredMessageArgumentKind kind,
  String? role,
});

bool _noArguments(StructuredMessage message) => message.arguments.isEmpty;

bool _matches(
  StructuredMessage message,
  Map<String, _PumpingArgumentContract> expected,
) {
  if (message.arguments.length != expected.length) return false;
  for (final entry in expected.entries) {
    final argument = message.arguments[entry.key];
    if (argument == null ||
        argument.kind != entry.value.kind ||
        argument.role != entry.value.role) {
      return false;
    }
  }
  return true;
}

int _int(StructuredMessage message, String key) =>
    message.arguments[key]!.value as int;

String _string(StructuredMessage message, String key) =>
    message.arguments[key]!.value as String;

String _theoremWire(String value, bool portuguese) => switch (value) {
  'regular' => portuguese ? 'regular' : 'regular',
  'contextFree' => portuguese ? 'livre de contexto' : 'context-free',
  _ => value,
};

const _pumpingEn = <PumpingLemmaText, String>{
  PumpingLemmaText.challenge: 'Pumping challenge',
  PumpingLemmaText.exampleOrProblem: 'Example or problem',
  PumpingLemmaText.mode: 'Mode',
  PumpingLemmaText.modeChallenge: 'Guided challenge',
  PumpingLemmaText.modePractice: 'Practice and explanation',
  PumpingLemmaText.modeFreeForm: 'Free-form assistant',
  PumpingLemmaText.adversarialProofSteps: 'Adversarial proof steps',
  PumpingLemmaText.retryDecomposition: 'Retry decomposition',
  PumpingLemmaText.restartSession: 'Restart session',
  PumpingLemmaText.hint: 'Hint',
  PumpingLemmaText.explanation: 'Explanation',
  PumpingLemmaText.lengthLabel: 'Pumping length p',
  PumpingLemmaText.lengthHelp: 'Opponent chooses any p > 0.',
  PumpingLemmaText.opponentChoosesP: 'Opponent chooses p',
  PumpingLemmaText.witnessArray: 'Witness token array',
  PumpingLemmaText.witnessHelp:
      'Learner chooses w in L with at least p tokens. Example: ["a","b"]',
  PumpingLemmaText.learnerChoosesWitness: 'Learner chooses witness',
  PumpingLemmaText.validDecomposition: 'Valid decomposition',
  PumpingLemmaText.opponentChoosesDecomposition:
      'Opponent chooses decomposition',
  PumpingLemmaText.exponentLabel: 'Pump exponent i',
  PumpingLemmaText.exponentHelp: 'Learner chooses any i >= 0.',
  PumpingLemmaText.learnerChoosesI: 'Learner chooses i',
  PumpingLemmaText.wordRemains: 'Pumped word remains in the language',
  PumpingLemmaText.manualEvidenceHelp:
      'Manual bounded predicate result. This is evidence only.',
  PumpingLemmaText.checkWord: 'Check pumped word',
  PumpingLemmaText.evidenceBoundary: 'Evidence and proof boundary',
  PumpingLemmaText.finiteEvidenceNotice:
      "Concrete membership checks are finite evidence. They never certify the theorem's universal quantifiers.",
  PumpingLemmaText.regularProofBoundary:
      'The pumping lemma cannot prove that a language is regular.',
  PumpingLemmaText.contextFreeProofBoundary:
      'Failure to find a contradiction does not prove that a language is context-free.',
  PumpingLemmaText.history: 'History',
  PumpingLemmaText.noChoices: 'No choices recorded yet.',
  PumpingLemmaText.sessionCopied: 'Session report copied.',
  PumpingLemmaText.copyReport: 'Copy structured session report',
};

const _pumpingPt = <PumpingLemmaText, String>{
  PumpingLemmaText.challenge: 'Desafio de bombeamento',
  PumpingLemmaText.exampleOrProblem: 'Exemplo ou problema',
  PumpingLemmaText.mode: 'Modo',
  PumpingLemmaText.modeChallenge: 'Desafio guiado',
  PumpingLemmaText.modePractice: 'Prática e explicação',
  PumpingLemmaText.modeFreeForm: 'Assistente de formato livre',
  PumpingLemmaText.adversarialProofSteps: 'Etapas da prova adversária',
  PumpingLemmaText.retryDecomposition: 'Tentar outra decomposição',
  PumpingLemmaText.restartSession: 'Reiniciar sessão',
  PumpingLemmaText.hint: 'Dica',
  PumpingLemmaText.explanation: 'Explicação',
  PumpingLemmaText.lengthLabel: 'Comprimento de bombeamento p',
  PumpingLemmaText.lengthHelp: 'O oponente escolhe qualquer p > 0.',
  PumpingLemmaText.opponentChoosesP: 'Oponente escolhe p',
  PumpingLemmaText.witnessArray: 'Vetor de tokens da testemunha',
  PumpingLemmaText.witnessHelp:
      'O aprendiz escolhe w em L com pelo menos p tokens. Exemplo: ["a","b"]',
  PumpingLemmaText.learnerChoosesWitness: 'Aprendiz escolhe a testemunha',
  PumpingLemmaText.validDecomposition: 'Decomposição válida',
  PumpingLemmaText.opponentChoosesDecomposition:
      'Oponente escolhe a decomposição',
  PumpingLemmaText.exponentLabel: 'Expoente de bombeamento i',
  PumpingLemmaText.exponentHelp: 'O aprendiz escolhe qualquer i >= 0.',
  PumpingLemmaText.learnerChoosesI: 'Aprendiz escolhe i',
  PumpingLemmaText.wordRemains: 'A palavra bombeada permanece na linguagem',
  PumpingLemmaText.manualEvidenceHelp:
      'Resultado manual de predicado limitado. Isto é apenas evidência.',
  PumpingLemmaText.checkWord: 'Verificar palavra bombeada',
  PumpingLemmaText.evidenceBoundary: 'Evidência e limite da prova',
  PumpingLemmaText.finiteEvidenceNotice:
      'Verificações concretas de pertinência são evidências finitas. Elas nunca certificam os quantificadores universais do teorema.',
  PumpingLemmaText.regularProofBoundary:
      'O lema do bombeamento não pode provar que uma linguagem é regular.',
  PumpingLemmaText.contextFreeProofBoundary:
      'Não encontrar uma contradição não prova que uma linguagem é livre de contexto.',
  PumpingLemmaText.history: 'Histórico',
  PumpingLemmaText.noChoices: 'Nenhuma escolha registrada.',
  PumpingLemmaText.sessionCopied: 'Relatório da sessão copiado.',
  PumpingLemmaText.copyReport: 'Copiar relatório estruturado da sessão',
};
