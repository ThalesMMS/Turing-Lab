import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../core/messages/structured_message.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/manual_conversion_content_copy.dart';
import '../localization/manual_conversion_localizations.dart';

class ManualConversionWorkspace extends ConsumerStatefulWidget {
  const ManualConversionWorkspace({
    super.key,
    required this.title,
    required this.workspaceKey,
    required this.initialSession,
    required this.sourcePreview,
    required this.resultPreviewBuilder,
    required this.onOpenResult,
    required this.onClose,
    this.onStepAccepted,
    this.onApplyPayload,
    this.requirementEditorBuilder,
    this.inputPayloadKeys,
    this.onRestartFromSource,
    this.onBranchFromSource,
    this.currentSourceDocumentId,
    this.currentSourceRevision,
  });

  final String title;
  final String workspaceKey;
  final ManualConversionSession initialSession;
  final Widget sourcePreview;
  final Widget Function(Map<String, Object?> artifact) resultPreviewBuilder;
  final FutureOr<void> Function(Map<String, Object?> artifact) onOpenResult;
  final VoidCallback onClose;
  final ManualConversionSession Function(ManualConversionSession session)?
  onStepAccepted;
  final ManualConversionCommandResult Function(
    ManualConversionSession session,
    Map<String, Object?> payload,
  )?
  onApplyPayload;
  final Widget Function(
    BuildContext context,
    ManualConversionRequirement requirement,
    ValueChanged<Map<String, Object?>> onSubmit,
  )?
  requirementEditorBuilder;
  final Set<String>? inputPayloadKeys;
  final FutureOr<ManualConversionSession> Function(
    ManualConversionSession invalidatedSession,
  )?
  onRestartFromSource;
  final FutureOr<ManualConversionSession> Function(
    ManualConversionSession invalidatedSession,
    String branchId,
  )?
  onBranchFromSource;
  final String? currentSourceDocumentId;
  final int? currentSourceRevision;

  @override
  ConsumerState<ManualConversionWorkspace> createState() =>
      _ManualConversionWorkspaceState();
}

class _ManualConversionWorkspaceState
    extends ConsumerState<ManualConversionWorkspace> {
  late ManualConversionSession _session;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final FocusNode _invalidatedFocusNode = FocusNode();
  final FocusScopeNode _requirementEditorFocusScope = FocusScopeNode(
    debugLabel: 'Manual conversion requirement editor',
  );
  final GlobalKey _requirementEditorKey = GlobalKey();
  final Map<String, String> _fieldErrors = {};
  late String _storageKey;
  bool _restoring = true;
  String? _validationMessage;
  StructuredMessage? _validationStructuredMessage;

  String? get _resolvedValidationMessage {
    final structured = _validationStructuredMessage;
    return structured == null
        ? _validationMessage
        : appLocalizationsOf(context).resolveStructuredMessage(structured);
  }

  void _setValidationMessage(String? message) {
    _validationMessage = message;
    _validationStructuredMessage = null;
  }

  String get _currentSourceDocumentId =>
      widget.currentSourceDocumentId ?? widget.initialSession.source.documentId;

  int get _currentSourceRevision =>
      widget.currentSourceRevision ?? widget.initialSession.source.revision;

  String _storageKeyForSource(ManualConversionSource source) {
    if (source.matches(
      documentId: widget.initialSession.source.documentId,
      revision: widget.initialSession.source.revision,
    )) {
      return widget.workspaceKey;
    }
    final suffix =
        '.${widget.initialSession.source.documentId}.'
        '${widget.initialSession.source.revision}';
    final prefix = widget.workspaceKey.endsWith(suffix)
        ? widget.workspaceKey.substring(
            0,
            widget.workspaceKey.length - suffix.length,
          )
        : widget.workspaceKey;
    return '$prefix.${source.documentId}.${source.revision}';
  }

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _storageKey = widget.workspaceKey;
    _resetControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restore());
  }

  @override
  void didUpdateWidget(covariant ManualConversionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final checked = _session.checkSource(
      documentId: _currentSourceDocumentId,
      revision: _currentSourceRevision,
    );
    if (checked.status != _session.status) {
      _setSession(checked);
      if (checked.status == ManualConversionStatus.invalidated) {
        _announceSourceInvalidated();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _invalidatedFocusNode.dispose();
    _requirementEditorFocusScope.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final restored = ref
        .read(manualConversionSessionStoreProvider)
        .load(
          _storageKey,
          documentId: widget.initialSession.source.documentId,
          revision: widget.initialSession.source.revision,
        );
    if (!mounted) return;
    setState(() {
      if (restored.isSuccess) {
        final candidate = restored.session!.checkSource(
          documentId: _currentSourceDocumentId,
          revision: _currentSourceRevision,
        );
        if (candidate.status == ManualConversionStatus.invalidated ||
            _revalidates(candidate)) {
          _session = candidate;
        } else {
          _session = widget.initialSession;
          _setValidationMessage(
            appLocalizationsOf(context).localizeWorkflowText(
              'Saved learner actions are no longer valid.',
            ),
          );
        }
      } else if (restored.diagnostics.isNotEmpty) {
        final diagnostic = restored.diagnostics.first;
        _validationMessage = diagnostic.structuredMessage == null
            ? appLocalizationsOf(
                context,
              ).manualConversionDiagnostic(diagnostic.message)
            : null;
        _validationStructuredMessage = diagnostic.structuredMessage;
      }
      _restoring = false;
      _resetControllers();
    });
    if (_session.status == ManualConversionStatus.invalidated) {
      _announceSourceInvalidated();
    }
  }

  bool _revalidates(ManualConversionSession restored) {
    if (!restored.actions.any((action) => action.validatedExternally)) {
      return true;
    }
    final validate = widget.onApplyPayload;
    if (validate == null) return true;
    var replay = widget.initialSession;
    for (final action in restored.actions) {
      final requirement = replay.currentRequirement;
      if (requirement == null ||
          requirement.id != action.requirementId ||
          requirement.type != action.type) {
        return false;
      }
      final result = action.validatedExternally
          ? validate(replay, action.payload)
          : action.revealed
          ? replay.revealCurrent()
          : replay.apply(
              requirementId: action.requirementId,
              type: action.type,
              payload: action.payload,
            );
      if (!result.isSuccess) return false;
      var next = result.session;
      if (action.revealed && action.validatedExternally) {
        next = next.markLatestActionRevealed();
      }
      replay = widget.onStepAccepted?.call(next) ?? next;
      final replayedAction = replay.appliedActions.last;
      if (replayedAction.revealed != action.revealed ||
          replayedAction.validatedExternally != action.validatedExternally ||
          !_jsonDeepEquals(
            replayedAction.validationEvidence?.toJson(),
            action.validationEvidence?.toJson(),
          ) ||
          !_jsonDeepEquals(
            replayedAction.learnerArtifact,
            action.learnerArtifact,
          )) {
        return false;
      }
    }
    return true;
  }

  Future<void> _persist() async {
    try {
      final saved = await ref
          .read(manualConversionSessionStoreProvider)
          .save(_storageKey, _session);
      if (!saved && mounted) {
        setState(() {
          _setValidationMessage(
            appLocalizationsOf(
              context,
            ).localizeWorkflowText('Progress could not be saved.'),
          );
        });
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _setValidationMessage(
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('Progress could not be saved.'),
        );
      });
    }
  }

  void _setSession(ManualConversionSession session) {
    setState(() {
      _session = session;
      _setValidationMessage(null);
      _fieldErrors.clear();
      _resetControllers();
    });
    unawaited(_persist());
  }

  void _resetControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    final requirement = _session.currentRequirement;
    if (requirement == null) return;
    if (widget.requirementEditorBuilder != null) return;
    final keys =
        widget.inputPayloadKeys ??
        (requirement.allowedPayloadKeys.isEmpty
            ? requirement.expectedPayload.keys.toSet()
            : requirement.allowedPayloadKeys);
    for (final key in keys) {
      _controllers[key] = TextEditingController();
      _focusNodes[key] = FocusNode();
    }
  }

  void _apply() {
    final requirement = _session.currentRequirement;
    if (requirement == null) return;
    final payload = <String, Object?>{};
    _fieldErrors.clear();
    _setValidationMessage(null);
    for (final entry in _controllers.entries) {
      try {
        payload[entry.key] = _parseField(
          entry.value.text,
          requirement.expectedPayload[entry.key],
        );
      } on FormatException catch (error) {
        setState(() => _fieldErrors[entry.key] = error.message);
        _focusNodes[entry.key]?.requestFocus();
        _announce(error.message);
        return;
      }
    }
    _applyPayload(payload);
  }

  void _applyPayload(Map<String, Object?> payload) {
    final requirement = _session.currentRequirement;
    if (requirement == null) return;
    _fieldErrors.clear();
    _setValidationMessage(null);
    final result =
        widget.onApplyPayload?.call(_session, payload) ??
        _session.apply(
          requirementId: requirement.id,
          type: requirement.type,
          payload: payload,
        );
    if (!result.isSuccess) {
      final message = _diagnosticMessage(result.diagnostics.first);
      setState(() => _setValidationMessage(message));
      _announce(message);
      return;
    }
    final accepted =
        widget.onStepAccepted?.call(result.session) ?? result.session;
    _setSession(accepted);
    final next = accepted.currentRequirement;
    final message = next == null
        ? appLocalizationsOf(
            context,
          ).localizeWorkflowText('Step accepted. Construction complete.')
        : '${appLocalizationsOf(context).localizeWorkflowText('Step accepted.')} '
              '${appLocalizationsOf(context).localizeWorkflowText('Next step')}: '
              '${_contentFor(next).title}';
    _announce(message);
    _focusCurrentContext();
  }

  Object? _parseField(String raw, Object? example) {
    final value = raw.trim();
    if (example is String) return value;
    if (value.isEmpty && example == null) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      throw FormatException(
        appLocalizationsOf(
          context,
        ).localizeWorkflowText('Use valid JSON for structured values.'),
      );
    }
  }

  void _undo() {
    final result = _session.undo();
    if (result.isSuccess) {
      _setSession(result.session);
    } else {
      _announce(_diagnosticMessage(result.diagnostics.first));
    }
  }

  void _redo() {
    final result = _session.redo();
    if (result.isSuccess) {
      _setSession(result.session);
    } else {
      _announce(_diagnosticMessage(result.diagnostics.first));
    }
  }

  void _restart() {
    _setSession(_session.restart());
    _announce(
      appLocalizationsOf(
        context,
      ).localizeWorkflowText('Construction restarted.'),
    );
  }

  void _showHint() {
    final requirement = _session.currentRequirement;
    if (requirement == null) return;
    final content = _contentFor(requirement);
    _showTextDialog(
      title: appLocalizationsOf(context).localizeWorkflowText('Hint'),
      body: '${content.hint}\n\n${_provenance(requirement.provenanceIds)}',
    );
  }

  void _reveal() {
    final requirement = _session.currentRequirement;
    if (requirement == null) return;
    final validatesPayload = widget.onApplyPayload;
    final result = validatesPayload == null
        ? _session.revealCurrent()
        : validatesPayload(_session, requirement.expectedPayload);
    if (!result.isSuccess) {
      final message = _diagnosticMessage(result.diagnostics.first);
      setState(() => _setValidationMessage(message));
      _announce(message);
      return;
    }
    final revealed = validatesPayload == null
        ? result.session
        : result.session.markLatestActionRevealed();
    final accepted = widget.onStepAccepted?.call(revealed) ?? revealed;
    _setSession(accepted);
    final content = _contentFor(requirement);
    _showTextDialog(
      title: appLocalizationsOf(context).localizeWorkflowText('Step revealed'),
      body:
          '${content.revealExplanation}\n\n${_provenance(requirement.provenanceIds)}',
    );
    _focusCurrentContext();
  }

  void _compare() {
    final evidence =
        _session.latestEvidence ??
        (_session.isComplete ? _session.completionEvidence : null);
    if (evidence == null) {
      _announce(
        appLocalizationsOf(
          context,
        ).localizeWorkflowText('Complete a validated step before comparing.'),
      );
      return;
    }
    final certainty = appLocalizationsOf(
      context,
    ).manualConversionCertainty(evidence.certainty);
    final counterexample = evidence.counterexample == null
        ? ''
        : '\n\n${appLocalizationsOf(context).manualConversionCounterexample(evidence.counterexample!)}';
    final summary = appLocalizationsOf(
      context,
    ).manualConversionEvidenceSummary(evidence.summary);
    _showTextDialog(
      title: appLocalizationsOf(context).localizeWorkflowText('Comparison'),
      body:
          '$certainty\n\n$summary$counterexample\n\n'
          '${_provenance(evidence.provenanceIds)}',
    );
  }

  Future<void> _showTextDialog({required String title, required String body}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              appLocalizationsOf(context).localizeWorkflowText('Close'),
            ),
          ),
        ],
      ),
    );
  }

  String _provenance(Iterable<String> ids) {
    return appLocalizationsOf(context).manualConversionProvenance(ids);
  }

  String _diagnosticMessage(ManualConversionDiagnostic diagnostic) {
    final l10n = appLocalizationsOf(context);
    final structured = diagnostic.structuredMessage;
    return structured == null
        ? l10n.manualConversionDiagnostic(diagnostic.message)
        : l10n.resolveStructuredMessage(structured);
  }

  void _announce(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _announceSourceInvalidated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _invalidatedFocusNode.requestFocus();
    });
  }

  void _focusCurrentContext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_session.status == ManualConversionStatus.invalidated) {
        _invalidatedFocusNode.requestFocus();
        return;
      }
      if (_focusNodes.isNotEmpty) {
        _focusNodes.values.first.requestFocus();
        return;
      }
      final editorContext = _requirementEditorKey.currentContext;
      if (editorContext == null) return;
      final policy = FocusTraversalGroup.maybeOf(editorContext);
      policy
          ?.findFirstFocus(
            _requirementEditorFocusScope,
            ignoreCurrentFocus: true,
          )
          ?.requestFocus();
    });
  }

  Future<void> _restartFromSource() async {
    final createSession = widget.onRestartFromSource;
    if (createSession == null) return;
    try {
      final restarted = await createSession(_session);
      _storageKey = _storageKeyForSource(restarted.source);
      _setSession(restarted);
    } on Object {
      setState(() {
        _setValidationMessage(
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('Could not restart from the edited source.'),
        );
      });
    }
  }

  Future<void> _branchFromSource() async {
    final createSession = widget.onBranchFromSource;
    if (createSession == null) return;
    final branchId =
        '${_session.id}.branch.${DateTime.now().microsecondsSinceEpoch}';
    try {
      final branched = await createSession(_session, branchId);
      _storageKey = _storageKeyForSource(branched.source);
      _setSession(branched);
    } on Object {
      setState(() {
        _setValidationMessage(
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('Could not branch from the edited source.'),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final theme = Theme.of(context);
    final progress = _session.requirements.isEmpty
        ? 1.0
        : _session.cursor / _session.requirements.length;

    return FocusTraversalGroup(
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            children: [
              Semantics(
                header: true,
                child: ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(widget.title),
                  subtitle: Text(
                    l10n.localizeWorkflowText(
                      'Manual construction — progress is saved on this device.',
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.localizeWorkflowText('Close'),
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
              LinearProgressIndicator(
                value: progress,
                semanticsLabel: l10n.localizeWorkflowText(
                  'Construction progress',
                ),
                semanticsValue: '${(progress * 100).round()}',
              ),
              Expanded(
                child: _restoring
                    ? const Center(child: CircularProgressIndicator())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final panes = [
                            _buildPane(
                              title: l10n.localizeWorkflowText('Source'),
                              child: widget.sourcePreview,
                            ),
                            _buildPane(
                              title: l10n.localizeWorkflowText(
                                'Learner construction',
                              ),
                              child: _buildLearnerPane(),
                            ),
                          ];
                          if (constraints.maxWidth >= 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: panes[0]),
                                const VerticalDivider(width: 1),
                                Expanded(child: panes[1]),
                              ],
                            );
                          }
                          return ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              SizedBox(height: 280, child: panes[0]),
                              const SizedBox(height: 12),
                              SizedBox(height: 480, child: panes[1]),
                            ],
                          );
                        },
                      ),
              ),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPane({required String title, required Widget child}) {
    return Semantics(
      container: true,
      label: title,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnerPane() {
    final l10n = appLocalizationsOf(context);
    final requirement = _session.currentRequirement;
    if (_session.status == ManualConversionStatus.invalidated) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.localizeWorkflowText(
                  'The source changed. Restart or branch from the edited document.',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.onRestartFromSource != null)
              FilledButton.icon(
                focusNode: _invalidatedFocusNode,
                onPressed: _restartFromSource,
                icon: const Icon(Icons.restart_alt),
                label: Text(
                  l10n.localizeWorkflowText('Restart from edited source'),
                ),
              ),
            if (widget.onBranchFromSource != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _branchFromSource,
                icon: const Icon(Icons.call_split),
                label: Text(
                  l10n.localizeWorkflowText('Branch from edited source'),
                ),
              ),
            ],
            if (_resolvedValidationMessage case final message?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      );
    }
    if (requirement == null) {
      return ListView(
        children: [
          Icon(
            Icons.check_circle,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.localizeWorkflowText('Construction complete'),
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          widget.resultPreviewBuilder(
            _session.learnerArtifact ?? _session.canonicalArtifact,
          ),
        ],
      );
    }

    final content = _contentFor(requirement);

    return ListView(
      children: [
        Semantics(
          container: true,
          label: content.title,
          hint: content.accessibleDescription,
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_session.cursor + 1}. ${content.title}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(content.instruction),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_session.learnerArtifact case final artifact?) ...[
          SizedBox(height: 180, child: widget.resultPreviewBuilder(artifact)),
          const SizedBox(height: 12),
        ],
        if (widget.requirementEditorBuilder case final builder?)
          FocusTraversalGroup(
            child: FocusScope(
              node: _requirementEditorFocusScope,
              child: Builder(
                key: _requirementEditorKey,
                builder: (context) =>
                    builder(context, requirement, _applyPayload),
              ),
            ),
          )
        else ...[
          for (final indexed in _controllers.entries.indexed) ...[
            Builder(
              builder: (context) {
                final index = indexed.$1;
                final entry = indexed.$2;
                final isLast = index == _controllers.length - 1;
                return TextField(
                  controller: entry.value,
                  focusNode: _focusNodes[entry.key],
                  decoration: InputDecoration(
                    labelText: entry.key,
                    helperText: _fieldHelp(
                      requirement.expectedPayload[entry.key],
                    ),
                    errorText: _fieldErrors[entry.key],
                    border: const OutlineInputBorder(),
                  ),
                  textInputAction: isLast
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onChanged: (_) {
                    if (_fieldErrors.remove(entry.key) != null) setState(() {});
                  },
                  onSubmitted: (_) {
                    if (isLast) {
                      _apply();
                    } else {
                      _focusNodes[_controllers.keys.elementAt(index + 1)]
                          ?.requestFocus();
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('manual-conversion-apply'),
            onPressed: _controllers.isEmpty ? null : _apply,
            icon: const Icon(Icons.check),
            label: Text(l10n.localizeWorkflowText('Check step')),
          ),
        ],
        if (_resolvedValidationMessage case final message?) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.localizeWorkflowText('Applied actions'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_session.appliedActions.isEmpty)
          Text(l10n.localizeWorkflowText('No actions yet.'))
        else
          for (final action in _session.appliedActions.reversed)
            ListTile(
              dense: true,
              leading: Icon(
                action.revealed ? Icons.visibility : Icons.check_circle_outline,
              ),
              title: Text(action.requirementId),
              subtitle: Text(
                action.revealed
                    ? l10n.localizeWorkflowText('Revealed step')
                    : l10n.localizeWorkflowText('Learner step'),
              ),
            ),
      ],
    );
  }

  _ResolvedRequirementContent _contentFor(
    ManualConversionRequirement requirement,
  ) {
    final l10n = appLocalizationsOf(context);
    final localized = ManualConversionContentCopies.resolveRequirement(
      requirement: requirement,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    return _ResolvedRequirementContent(
      title: localized?.title ?? l10n.localizeWorkflowText(requirement.title),
      instruction:
          localized?.instruction ??
          l10n.localizeWorkflowText(requirement.instruction),
      hint: localized?.hint ?? l10n.localizeWorkflowText(requirement.hint),
      revealExplanation:
          localized?.revealExplanation ??
          l10n.localizeWorkflowText(requirement.revealExplanation),
      accessibleDescription:
          localized?.accessibleDescription ??
          l10n.localizeWorkflowText(requirement.instruction),
    );
  }

  String _fieldHelp(Object? expected) {
    if (expected is String) {
      return appLocalizationsOf(context).localizeWorkflowText('Enter text.');
    }
    return appLocalizationsOf(
      context,
    ).localizeWorkflowText('Enter this structured value as JSON.');
  }

  Widget _buildControls() {
    final l10n = appLocalizationsOf(context);
    final enabled = _session.status != ManualConversionStatus.invalidated;
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: enabled && _session.canUndo ? _undo : null,
              icon: const Icon(Icons.undo),
              label: Text(l10n.localizeWorkflowText('Undo')),
            ),
            OutlinedButton.icon(
              onPressed: enabled && _session.canRedo ? _redo : null,
              icon: const Icon(Icons.redo),
              label: Text(l10n.localizeWorkflowText('Redo')),
            ),
            OutlinedButton.icon(
              onPressed: enabled ? _restart : null,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.localizeWorkflowText('Restart')),
            ),
            OutlinedButton.icon(
              onPressed: enabled && _session.currentRequirement != null
                  ? _showHint
                  : null,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l10n.localizeWorkflowText('Hint')),
            ),
            OutlinedButton.icon(
              onPressed: enabled && _session.currentRequirement != null
                  ? _reveal
                  : null,
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.localizeWorkflowText('Reveal step')),
            ),
            OutlinedButton.icon(
              onPressed:
                  enabled &&
                      (_session.latestEvidence != null || _session.isComplete)
                  ? _compare
                  : null,
              icon: const Icon(Icons.compare_arrows),
              label: Text(l10n.localizeWorkflowText('Compare')),
            ),
            FilledButton.icon(
              key: const ValueKey('manual-conversion-open-result'),
              onPressed: _session.isComplete
                  ? () => widget.onOpenResult(
                      _session.learnerArtifact ?? _session.canonicalArtifact,
                    )
                  : null,
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.localizeWorkflowText('Open result')),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ResolvedRequirementContent {
  const _ResolvedRequirementContent({
    required this.title,
    required this.instruction,
    required this.hint,
    required this.revealExplanation,
    required this.accessibleDescription,
  });

  final String title;
  final String instruction;
  final String hint;
  final String revealExplanation;
  final String accessibleDescription;
}

bool _jsonDeepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map && right is Map) {
    if (left.length != right.length ||
        left.keys.any((key) => !right.containsKey(key))) {
      return false;
    }
    return left.keys.every((key) => _jsonDeepEquals(left[key], right[key]));
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonDeepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
