import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/messages/structured_message.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/pumping_lemma_localizations.dart';
import '../content/pumping_lemma_problem_content_copy.dart';
import '../providers/pumping_lemma_progress_provider.dart';
import 'document_interoperability_binding.dart';
import 'file_operations_panel.dart';
import 'interoperability_presentation_labels.dart';

final class PumpingLemmaWorkspace extends ConsumerStatefulWidget {
  const PumpingLemmaWorkspace({super.key, required this.theorem});

  final PumpingLemmaTheorem theorem;

  @override
  ConsumerState<PumpingLemmaWorkspace> createState() =>
      _PumpingLemmaWorkspaceState();
}

final class _PumpingLemmaWorkspaceState
    extends ConsumerState<PumpingLemmaWorkspace> {
  final _pumpingLengthController = TextEditingController(text: '2');
  final _witnessController = TextEditingController();
  final _exponentController = TextEditingController(text: '0');
  late PumpingLemmaProblem _problem;
  late PumpingLemmaSessionController<PumpingDecomposition> _controller;
  List<PumpingDecomposition> _decompositions = const [];
  int _selectedDecomposition = 0;
  PumpingLemmaMode _mode = PumpingLemmaMode.guidedPractice;
  bool _manualMembership = false;
  _PumpingLemmaNotice? _message;
  bool _messageIsError = false;

  List<PumpingLemmaProblem> get _problems =>
      widget.theorem == PumpingLemmaTheorem.regular
      ? PumpingLemmaProblemCatalog.regular
      : PumpingLemmaProblemCatalog.contextFree;

  StateNotifierProvider<PumpingLemmaProgressNotifier, PumpingLemmaProgressState>
  get _progressProvider => widget.theorem == PumpingLemmaTheorem.regular
      ? regularPumpingLemmaProgressProvider
      : contextFreePumpingLemmaProgressProvider;

  @override
  void initState() {
    super.initState();
    _problem = _problems.first;
    _controller = _newController(_problem);
    _pumpingLengthController.text = '${_problem.suggestedPumpingLength}';
    _witnessController.text = jsonEncode(_problem.suggestedWitness);
    _exponentController.text = '0';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(_progressProvider.notifier)
          .startNewGame(totalChallenges: _problems.length);
    });
  }

  @override
  void dispose() {
    _pumpingLengthController.dispose();
    _witnessController.dispose();
    _exponentController.dispose();
    super.dispose();
  }

  PumpingLemmaSessionController<PumpingDecomposition> _newController(
    PumpingLemmaProblem problem,
  ) {
    final session = PumpingLemmaSession<PumpingDecomposition>(
      sessionId: '${problem.id}-${DateTime.now().microsecondsSinceEpoch}',
      challengeId: problem.id,
      sourceRevision: problem.sourceRevision,
      theorem: problem.theorem,
      mode: _mode,
      role: PumpingLemmaRole.learner,
      targetLanguage: problem.languageDescription,
    );
    return problem.theorem == PumpingLemmaTheorem.regular
        ? PumpingLemmaSessionController.regular(
            initialSession: session,
            sessionIdFactory: _sessionId,
          )
        : PumpingLemmaSessionController.contextFree(
            initialSession: session,
            sessionIdFactory: _sessionId,
          );
  }

  String _sessionId() =>
      '${_problem.id}-${DateTime.now().microsecondsSinceEpoch}';

  void _selectProblem(String? id) {
    if (id == null) return;
    final problem = _problems.firstWhere((item) => item.id == id);
    setState(() {
      _problem = problem;
      _controller = _newController(problem);
      _pumpingLengthController.text = '${problem.suggestedPumpingLength}';
      _witnessController.text = jsonEncode(problem.suggestedWitness);
      _exponentController.text = '0';
      _decompositions = const [];
      _selectedDecomposition = 0;
      _message = null;
    });
  }

  void _setMode(PumpingLemmaMode? mode) {
    if (mode == null || mode == _mode) return;
    setState(() {
      _mode = mode;
      _controller = _newController(_problem);
      _decompositions = const [];
      _selectedDecomposition = 0;
      _message = null;
    });
  }

  void _choosePumpingLength() {
    final value = int.tryParse(_pumpingLengthController.text);
    if (value == null) {
      _showStructured(
        PumpingLemmaMessages.enterPositivePumpingLength(),
        error: true,
      );
      return;
    }
    try {
      _controller.choosePumpingLength(
        expectedSessionId: _controller.state.sessionId,
        player: PumpingLemmaPlayer.opponent,
        pumpingLength: value,
      );
      setState(() => _message = null);
    } on PumpingLemmaTransitionException catch (error) {
      _showTransition(error.violation);
    }
  }

  void _chooseWitness() {
    try {
      final witness = _parseTokens(_witnessController.text);
      final membership = PumpingLemmaProblemCatalog.evaluateCurated(
        _problem,
        witness,
      );
      _controller.chooseWitness(
        expectedSessionId: _controller.state.sessionId,
        player: PumpingLemmaPlayer.learner,
        witness: witness,
        isInLanguage: membership.isInLanguage ?? _manualMembership,
      );
      _decompositions = widget.theorem == PumpingLemmaTheorem.regular
          ? PumpingDecompositionEnumerator.regular(
              witness: witness,
              pumpingLength: _controller.state.pumpingLength!,
            )
          : PumpingDecompositionEnumerator.contextFree(
              witness: witness,
              pumpingLength: _controller.state.pumpingLength!,
            );
      setState(() {
        _selectedDecomposition = 0;
        _message = _StructuredPumpingLemmaNotice(
          PumpingLemmaMessages.decompositionsEnumerated(_decompositions.length),
        );
        _messageIsError = false;
      });
    } on PumpingLemmaArgumentError catch (error) {
      _showStructured(error.structuredMessage, error: true);
    } on PumpingLemmaTransitionException catch (error) {
      _showTransition(error.violation);
    }
  }

  void _chooseDecomposition() {
    if (_decompositions.isEmpty) {
      _showStructured(PumpingLemmaMessages.noValidDecomposition(), error: true);
      return;
    }
    try {
      _controller.chooseDecomposition(
        expectedSessionId: _controller.state.sessionId,
        player: PumpingLemmaPlayer.opponent,
        decomposition: _decompositions[_selectedDecomposition],
      );
      setState(() => _message = null);
    } on PumpingLemmaTransitionException catch (error) {
      _showTransition(error.violation);
    }
  }

  void _chooseExponent() {
    final exponent = int.tryParse(_exponentController.text);
    if (exponent == null) {
      _showStructured(
        PumpingLemmaMessages.enterNonNegativeExponent(),
        error: true,
      );
      return;
    }
    try {
      final outcome = _controller.chooseExponent(
        expectedSessionId: _controller.state.sessionId,
        player: PumpingLemmaPlayer.learner,
        exponent: exponent,
      );
      if (outcome case PumpingWordBounded(
        :final maximumTokens,
        :final minimumRequiredTokens,
      )) {
        _showStructured(
          PumpingLemmaMessages.pumpedWordBounded(
            minimumRequiredTokens: minimumRequiredTokens,
            maximumTokens: maximumTokens,
          ),
          error: true,
        );
        return;
      }
      setState(() => _message = null);
    } on PumpingLemmaTransitionException catch (error) {
      _showTransition(error.violation);
    }
  }

  void _recordEvidence() {
    final state = _controller.state;
    final pumpedWord = state.pumpedWord;
    if (pumpedWord == null) {
      _showStructured(
        PumpingLemmaMessages.chooseBoundedExponent(),
        error: true,
      );
      return;
    }
    final membership = PumpingLemmaProblemCatalog.evaluateCurated(
      _problem,
      pumpedWord,
    );
    final remains = membership.isInLanguage ?? _manualMembership;
    final evidence = PumpingLemmaEvidence.bounded(
      observations: [
        PumpingExponentObservation(
          exponent: state.pumpExponent!,
          remainsInLanguage: remains,
        ),
      ],
    );
    try {
      _controller.recordEvidence(
        expectedSessionId: state.sessionId,
        player: PumpingLemmaPlayer.learner,
        evidence: evidence,
      );
      _controller.complete(
        expectedSessionId: state.sessionId,
        scoreDelta:
            evidence.certainty == PumpingEvidenceCertainty.counterexample
            ? 1
            : 0,
      );
      ref.read(_progressProvider.notifier)
        ..recordAnswer(
          challengeId: _problems.indexOf(_problem),
          challengeContentId: _problem.id,
          language: _problem.languageDescription,
          challengeContentVersion: _problem.contentVersion,
          isCorrect:
              evidence.certainty == PumpingEvidenceCertainty.counterexample,
        )
        ..markChallengeCompleted(
          _problem.id,
          challengeContentVersion: _problem.contentVersion,
        );
      setState(() {
        _message = _StructuredPumpingLemmaNotice(
          evidence.certainty == PumpingEvidenceCertainty.counterexample
              ? PumpingLemmaMessages.counterexampleEvidence()
              : PumpingLemmaMessages.finiteCheckInconclusive(),
        );
        _messageIsError = false;
      });
    } on PumpingLemmaTransitionException catch (error) {
      _showTransition(error.violation);
    }
  }

  void _retry() {
    final state = _controller.state;
    _controller.recordRetry(expectedSessionId: state.sessionId);
    ref
        .read(_progressProvider.notifier)
        .recordRetry(
          challengeId: _problems.indexOf(_problem),
          challengeContentId: _problem.id,
          language: _problem.languageDescription,
        );
    setState(() {
      _message = null;
      _selectedDecomposition = 0;
    });
  }

  void _restart() {
    _controller.restart();
    setState(() {
      _pumpingLengthController.text = '${_problem.suggestedPumpingLength}';
      _witnessController.text = jsonEncode(_problem.suggestedWitness);
      _exponentController.text = '0';
      _decompositions = const [];
      _selectedDecomposition = 0;
      _message = null;
    });
  }

  void _showStructured(StructuredMessage message, {required bool error}) {
    setState(() {
      _message = _StructuredPumpingLemmaNotice(message);
      _messageIsError = error;
    });
  }

  void _showContent(_PumpingLemmaContentField field) {
    setState(() {
      _message = _ContentPumpingLemmaNotice(field);
      _messageIsError = false;
    });
  }

  void _showTransition(PumpingLemmaTransitionViolation violation) {
    final message = switch (violation) {
      PumpingLemmaTransitionViolation.wrongStage =>
        PumpingLemmaMessages.transitionWrongStage(),
      PumpingLemmaTransitionViolation.wrongPlayer =>
        PumpingLemmaMessages.transitionWrongPlayer(),
      PumpingLemmaTransitionViolation.invalidPumpingLength =>
        PumpingLemmaMessages.transitionInvalidPumpingLength(),
      PumpingLemmaTransitionViolation.witnessTooShort =>
        PumpingLemmaMessages.transitionWitnessTooShort(),
      PumpingLemmaTransitionViolation.witnessOutsideLanguage =>
        PumpingLemmaMessages.transitionWitnessOutsideLanguage(),
      PumpingLemmaTransitionViolation.decompositionMismatch =>
        PumpingLemmaMessages.transitionDecompositionMismatch(),
      PumpingLemmaTransitionViolation.decompositionConstraint =>
        PumpingLemmaMessages.transitionDecompositionConstraint(),
      PumpingLemmaTransitionViolation.invalidExponent =>
        PumpingLemmaMessages.transitionInvalidExponent(),
    };
    _showStructured(message, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 840;
        final problem = _ProblemCard(
          theorem: widget.theorem,
          problem: _problem,
          problems: _problems,
          mode: _mode,
          onProblemChanged: _selectProblem,
          onModeChanged: _setMode,
        );
        final game = _buildGameCard(state);
        final evidence = _buildEvidenceCard(state);
        return SingleChildScrollView(
          key: ValueKey('pumping-${widget.theorem.name}-scroll'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              problem,
              const SizedBox(height: 16),
              if (compact) ...[
                game,
                const SizedBox(height: 16),
                evidence,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: game),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: evidence),
                  ],
                ),
              const SizedBox(height: 16),
              FileOperationsPanel(interoperability: _interoperabilityBinding()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameCard(PumpingLemmaSession<PumpingDecomposition> state) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    appLocalizationsOf(
                      context,
                    ).pumpingLemmaText(PumpingLemmaText.adversarialProofSteps),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(appLocalizationsOf(context).pumpingStage(state.stage)),
                const SizedBox(height: 12),
                _ConstraintSummary(theorem: widget.theorem, state: state),
                const SizedBox(height: 16),
                ..._stageControls(state),
                if (state.decomposition != null) ...[
                  const SizedBox(height: 16),
                  _SegmentedWord(
                    decomposition: state.decomposition!,
                    pumpedWord: state.pumpedWord,
                    exponent: state.pumpExponent,
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _message!.resolve(appLocalizationsOf(context), _problem),
                      key: const ValueKey('pumping-session-message'),
                      style: TextStyle(
                        color: _messageIsError
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('pumping-retry'),
                      onPressed: state.pumpingLength == null ? null : _retry,
                      icon: const Icon(Icons.replay),
                      label: Text(
                        appLocalizationsOf(
                          context,
                        ).pumpingLemmaText(PumpingLemmaText.retryDecomposition),
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('pumping-restart'),
                      onPressed: _restart,
                      icon: const Icon(Icons.restart_alt),
                      label: Text(
                        appLocalizationsOf(
                          context,
                        ).pumpingLemmaText(PumpingLemmaText.restartSession),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showContent(_PumpingLemmaContentField.hint),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: Text(
                        appLocalizationsOf(
                          context,
                        ).pumpingLemmaText(PumpingLemmaText.hint),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showContent(_PumpingLemmaContentField.explanation),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(
                        appLocalizationsOf(
                          context,
                        ).pumpingLemmaText(PumpingLemmaText.explanation),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  List<Widget> _stageControls(
    PumpingLemmaSession<PumpingDecomposition> state,
  ) => switch (state.stage) {
    PumpingLemmaStage.awaitingPumpingLength => [
      TextField(
        key: const ValueKey('pumping-length-input'),
        controller: _pumpingLengthController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.lengthLabel),
          helperText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.lengthHelp),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _choosePumpingLength(),
      ),
      const SizedBox(height: 12),
      _primaryButton(
        key: 'choose-pumping-length',
        label: appLocalizationsOf(
          context,
        ).pumpingLemmaText(PumpingLemmaText.opponentChoosesP),
        icon: Icons.looks_one_outlined,
        onPressed: _choosePumpingLength,
      ),
    ],
    PumpingLemmaStage.awaitingWitness => [
      TextField(
        key: const ValueKey('pumping-witness-input'),
        controller: _witnessController,
        decoration: InputDecoration(
          labelText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.witnessArray),
          helperText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.witnessHelp),
          border: const OutlineInputBorder(),
        ),
        minLines: 1,
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      _primaryButton(
        key: 'choose-witness',
        label: appLocalizationsOf(
          context,
        ).pumpingLemmaText(PumpingLemmaText.learnerChoosesWitness),
        icon: Icons.text_fields,
        onPressed: _chooseWitness,
      ),
    ],
    PumpingLemmaStage.awaitingDecomposition => [
      DropdownButtonFormField<int>(
        key: const ValueKey('pumping-decomposition-input'),
        initialValue: _decompositions.isEmpty ? null : _selectedDecomposition,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.validDecomposition),
          helperText: appLocalizationsOf(
            context,
          ).pumpingDecompositionHelp(_decompositions.length),
          border: const OutlineInputBorder(),
        ),
        items: [
          for (var index = 0; index < _decompositions.length; index++)
            DropdownMenuItem(
              value: index,
              child: Text(
                _decompositionLabel(
                  appLocalizationsOf(context),
                  _decompositions[index],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) =>
            setState(() => _selectedDecomposition = value ?? 0),
      ),
      const SizedBox(height: 12),
      _primaryButton(
        key: 'choose-decomposition',
        label: appLocalizationsOf(
          context,
        ).pumpingLemmaText(PumpingLemmaText.opponentChoosesDecomposition),
        icon: Icons.call_split,
        onPressed: _chooseDecomposition,
      ),
    ],
    PumpingLemmaStage.awaitingExponent => [
      TextField(
        key: const ValueKey('pumping-exponent-input'),
        controller: _exponentController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.exponentLabel),
          helperText: appLocalizationsOf(
            context,
          ).pumpingLemmaText(PumpingLemmaText.exponentHelp),
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _chooseExponent(),
      ),
      const SizedBox(height: 12),
      _primaryButton(
        key: 'choose-exponent',
        label: appLocalizationsOf(
          context,
        ).pumpingLemmaText(PumpingLemmaText.learnerChoosesI),
        icon: Icons.exposure,
        onPressed: _chooseExponent,
      ),
    ],
    PumpingLemmaStage.awaitingEvidence => [
      if (PumpingLemmaProblemCatalog.evaluateCurated(
            _problem,
            state.pumpedWord!,
          ).certainty ==
          PumpingMembershipCertainty.unavailable)
        SwitchListTile(
          value: _manualMembership,
          onChanged: (value) => setState(() => _manualMembership = value),
          title: Text(
            appLocalizationsOf(
              context,
            ).pumpingLemmaText(PumpingLemmaText.wordRemains),
          ),
          subtitle: Text(
            appLocalizationsOf(
              context,
            ).pumpingLemmaText(PumpingLemmaText.manualEvidenceHelp),
          ),
        ),
      _primaryButton(
        key: 'record-pumping-evidence',
        label: appLocalizationsOf(
          context,
        ).pumpingLemmaText(PumpingLemmaText.checkWord),
        icon: Icons.fact_check_outlined,
        onPressed: _recordEvidence,
      ),
    ],
    PumpingLemmaStage.completed => [
      Text(appLocalizationsOf(context).pumpingRoundComplete(state.score)),
    ],
  };

  Widget _primaryButton({
    required String key,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) => FilledButton.icon(
    key: ValueKey(key),
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
  );

  Widget _buildEvidenceCard(PumpingLemmaSession<PumpingDecomposition> state) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  appLocalizationsOf(
                    context,
                  ).pumpingLemmaText(PumpingLemmaText.evidenceBoundary),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                appLocalizationsOf(
                  context,
                ).pumpingLemmaText(PumpingLemmaText.finiteEvidenceNotice),
              ),
              const SizedBox(height: 8),
              Text(
                appLocalizationsOf(context).pumpingLemmaText(
                  widget.theorem == PumpingLemmaTheorem.regular
                      ? PumpingLemmaText.regularProofBoundary
                      : PumpingLemmaText.contextFreeProofBoundary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appLocalizationsOf(
                  context,
                ).pumpingLemmaText(PumpingLemmaText.history),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (state.history.isEmpty)
                Text(
                  appLocalizationsOf(
                    context,
                  ).pumpingLemmaText(PumpingLemmaText.noChoices),
                )
              else
                for (final turn in state.history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Text('${turn.revision}')),
                    title: Text(
                      appLocalizationsOf(context).pumpingTurn(turn.kind),
                    ),
                  ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('copy-pumping-session-report'),
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: jsonEncode(_document().toJson())),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        appLocalizationsOf(
                          context,
                        ).pumpingLemmaText(PumpingLemmaText.sessionCopied),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: Text(
                  appLocalizationsOf(
                    context,
                  ).pumpingLemmaText(PumpingLemmaText.copyReport),
                ),
              ),
            ],
          ),
        ),
      );

  PumpingLemmaDocument _document() {
    final progressState = ref.read(_progressProvider);
    final progress = PumpingLemmaEnvironmentProgress(
      challengeScores: progressState.challengeScores,
      completedChallengeIds: progressState.completedChallengeIds,
      challengeContentVersions: progressState.challengeContentVersions,
    );
    return widget.theorem == PumpingLemmaTheorem.regular
        ? RegularPumpingLemmaDocument(
            problem: _problem,
            session: PumpingLemmaSession<RegularPumpingDecomposition>.fromJson(
              _controller.state.toJson(),
            ),
            progress: progress,
          )
        : ContextFreePumpingLemmaDocument(
            problem: _problem,
            session:
                PumpingLemmaSession<ContextFreePumpingDecomposition>.fromJson(
                  _controller.state.toJson(),
                ),
            progress: progress,
          );
  }

  DocumentInteroperabilityBinding _interoperabilityBinding() {
    final registry = ref.read(documentInteroperabilityRegistryProvider);
    final key = widget.theorem == PumpingLemmaTheorem.regular
        ? DefaultFormalSystemIds.regularPumping
        : DefaultFormalSystemIds.contextFreePumping;
    final descriptor = registry.formalSystems.descriptorFor(key)!;
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: key,
      currentDocument: InteroperableDocument<Object>(
        document: _document(),
        systemKey: key,
        schema: descriptor.schema,
      ),
      replace: (document) async {
        final pumping = document.document;
        if (pumping is! PumpingLemmaDocument ||
            pumping.theorem != widget.theorem) {
          throw StateError('The imported pumping theorem does not match.');
        }
        _loadDocument(pumping);
      },
      captureCheckpoint: _document,
      restoreCheckpoint: (checkpoint) {
        _loadDocument(checkpoint! as PumpingLemmaDocument);
      },
      systemLabel: (context, __) =>
          widget.theorem == PumpingLemmaTheorem.regular
          ? appLocalizationsOf(context).homeNavigationRegularPumpingDescription
          : appLocalizationsOf(
              context,
            ).homeNavigationContextFreePumpingDescription,
      formatLabel: defaultDocumentFormatLabel,
    );
  }

  void _loadDocument(PumpingLemmaDocument document) {
    final session = PumpingLemmaSession<PumpingDecomposition>.fromJson(
      document.erasedSession.toJson(),
    );
    final currentContentVersions = <String, int>{
      document.problem.id: document.problem.contentVersion,
      for (final problem in _problems) problem.id: problem.contentVersion,
    };
    final migratedProgress = PumpingLemmaContentMigration.reconcile(
      progress: document.progress,
      currentContentVersions: currentContentVersions,
    ).progress;
    ref
        .read(_progressProvider.notifier)
        .restoreProgress(
          totalChallenges: _problems.length,
          challengeScores: migratedProgress.challengeScores,
          completedChallengeIds: migratedProgress.completedChallengeIds,
          challengeContentVersions: migratedProgress.challengeContentVersions,
        );
    setState(() {
      _problem = document.problem;
      _mode = session.mode;
      _controller = widget.theorem == PumpingLemmaTheorem.regular
          ? PumpingLemmaSessionController.regular(
              initialSession: session,
              sessionIdFactory: _sessionId,
            )
          : PumpingLemmaSessionController.contextFree(
              initialSession: session,
              sessionIdFactory: _sessionId,
            );
      _pumpingLengthController.text = '${session.pumpingLength ?? 2}';
      _witnessController.text = jsonEncode(session.witness);
      _exponentController.text = '${session.pumpExponent ?? 0}';
      if (session.pumpingLength != null && session.witness.isNotEmpty) {
        _decompositions = widget.theorem == PumpingLemmaTheorem.regular
            ? PumpingDecompositionEnumerator.regular(
                witness: session.witness,
                pumpingLength: session.pumpingLength!,
              )
            : PumpingDecompositionEnumerator.contextFree(
                witness: session.witness,
                pumpingLength: session.pumpingLength!,
              );
      } else {
        _decompositions = const [];
      }
      _selectedDecomposition = 0;
      _message = _StructuredPumpingLemmaNotice(
        PumpingLemmaMessages.sessionImported(),
      );
      _messageIsError = false;
    });
  }
}

final class _ProblemCard extends StatelessWidget {
  const _ProblemCard({
    required this.theorem,
    required this.problem,
    required this.problems,
    required this.mode,
    required this.onProblemChanged,
    required this.onModeChanged,
  });

  final PumpingLemmaTheorem theorem;
  final PumpingLemmaProblem problem;
  final List<PumpingLemmaProblem> problems;
  final PumpingLemmaMode mode;
  final ValueChanged<String?> onProblemChanged;
  final ValueChanged<PumpingLemmaMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final copy = PumpingLemmaProblemContentCopies.resolve(
      id: problem.id,
      languageCode: l10n.localeName,
      fallbackTitle: problem.customTitle,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.pumpingTheorem(theorem),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final problemPicker = Semantics(
                  key: const ValueKey('pumping-problem-picker'),
                  label: l10n.pumpingLemmaText(PumpingLemmaText.challenge),
                  value: copy.semanticLabel,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('pumping-problem-picker-${problem.id}'),
                    initialValue: problem.id,
                    isExpanded: true,
                    menuMaxHeight: 360,
                    decoration: InputDecoration(
                      labelText: l10n.pumpingLemmaText(
                        PumpingLemmaText.exampleOrProblem,
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final item in problems)
                        DropdownMenuItem(
                          key: ValueKey('pumping-problem-option-${item.id}'),
                          value: item.id,
                          child: Text(
                            PumpingLemmaProblemContentCopies.resolve(
                              id: item.id,
                              languageCode: l10n.localeName,
                              fallbackTitle: item.customTitle,
                            ).title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: onProblemChanged,
                  ),
                );
                final modePicker = DropdownButtonFormField<PumpingLemmaMode>(
                  key: ValueKey('pumping-mode-picker-${mode.name}'),
                  initialValue: mode,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.pumpingLemmaText(PumpingLemmaText.mode),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: PumpingLemmaMode.challenge,
                      child: Text(
                        l10n.pumpingModeLabel(PumpingLemmaMode.challenge),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: PumpingLemmaMode.guidedPractice,
                      child: Text(
                        l10n.pumpingModeLabel(PumpingLemmaMode.guidedPractice),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DropdownMenuItem(
                      value: PumpingLemmaMode.freeForm,
                      child: Text(
                        l10n.pumpingModeLabel(PumpingLemmaMode.freeForm),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: onModeChanged,
                );
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      problemPicker,
                      const SizedBox(height: 12),
                      modePicker,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: problemPicker),
                    const SizedBox(width: 12),
                    Expanded(child: modePicker),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Semantics(
              key: const ValueKey('pumping-language-description'),
              container: true,
              label: l10n.languageLabelValue(problem.languageDescription),
              child: ExcludeSemantics(child: Text(problem.languageDescription)),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pumpingLearningObjective(copy.learningObjective),
              key: const ValueKey('pumping-learning-objective'),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.pumpingRepresentationSource(
                problem.representationKind.name,
                problem.sourceRevision,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

final class _ConstraintSummary extends StatelessWidget {
  const _ConstraintSummary({required this.theorem, required this.state});

  final PumpingLemmaTheorem theorem;
  final PumpingLemmaSession<PumpingDecomposition> state;

  @override
  Widget build(BuildContext context) {
    final p = state.pumpingLength;
    final decomposition = state.decomposition;
    final constraints = theorem == PumpingLemmaTheorem.regular
        ? ['w = xyz', '|xy| <= p${p == null ? '' : ' = $p'}', '|y| > 0']
        : ['w = uvxyz', '|vxy| <= p${p == null ? '' : ' = $p'}', '|vy| > 0'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final constraint in constraints)
          Chip(
            avatar: decomposition == null
                ? const Icon(Icons.hourglass_empty, size: 18)
                : const Icon(Icons.check, size: 18),
            label: Text(constraint),
          ),
      ],
    );
  }
}

final class _SegmentedWord extends StatelessWidget {
  const _SegmentedWord({
    required this.decomposition,
    required this.pumpedWord,
    required this.exponent,
  });

  final PumpingDecomposition decomposition;
  final List<String>? pumpedWord;
  final int? exponent;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final description = decomposition.segments
        .map(
          (segment) => l10n.pumpingSegmentDescription(
            label: segment.label,
            start: segment.start,
            end: segment.end,
            tokens: _tokens(l10n, segment.tokens),
          ),
        )
        .join('. ');
    return Semantics(
      container: true,
      label: l10n.pumpingDecompositionSemantics(description),
      value: pumpedWord == null
          ? null
          : l10n.pumpingExponentWord(exponent!, _tokens(l10n, pumpedWord!)),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final segment in decomposition.segments)
                  Chip(
                    avatar: segment.pumped
                        ? const Icon(Icons.repeat, size: 18)
                        : null,
                    label: Text(
                      '${segment.label}: ${_tokens(l10n, segment.tokens)} '
                      '[${segment.start}, ${segment.end})',
                    ),
                  ),
              ],
            ),
            if (pumpedWord != null) ...[
              const SizedBox(height: 8),
              Text(l10n.pumpingPumpedWord(_tokens(l10n, pumpedWord!))),
            ],
          ],
        ),
      ),
    );
  }
}

List<String> _parseTokens(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw PumpingLemmaArgumentError.message(
        PumpingLemmaMessages.invalidTokenArray(),
      );
    }
    return decoded.cast<String>();
  } on FormatException {
    throw PumpingLemmaArgumentError.message(
      PumpingLemmaMessages.invalidTokenArray(),
    );
  }
}

String _tokens(AppLocalizations l10n, List<String> tokens) =>
    tokens.isEmpty ? l10n.pumpingEmptyWord : tokens.join(' ');

String _decompositionLabel(
  AppLocalizations l10n,
  PumpingDecomposition decomposition,
) => decomposition.segments
    .map((segment) => '${segment.label}=${_tokens(l10n, segment.tokens)}')
    .join('; ');

enum _PumpingLemmaContentField { hint, explanation }

sealed class _PumpingLemmaNotice {
  const _PumpingLemmaNotice();

  String resolve(AppLocalizations l10n, PumpingLemmaProblem problem);
}

final class _StructuredPumpingLemmaNotice extends _PumpingLemmaNotice {
  const _StructuredPumpingLemmaNotice(this.message);

  final StructuredMessage message;

  @override
  String resolve(AppLocalizations l10n, PumpingLemmaProblem problem) =>
      l10n.resolveStructuredMessage(message);
}

final class _ContentPumpingLemmaNotice extends _PumpingLemmaNotice {
  const _ContentPumpingLemmaNotice(this.field);

  final _PumpingLemmaContentField field;

  @override
  String resolve(AppLocalizations l10n, PumpingLemmaProblem problem) {
    final copy = PumpingLemmaProblemContentCopies.resolve(
      id: problem.id,
      languageCode: l10n.localeName,
      fallbackTitle: problem.customTitle,
    );
    return switch (field) {
      _PumpingLemmaContentField.hint => copy.hint,
      _PumpingLemmaContentField.explanation => copy.explanation,
    };
  }
}
