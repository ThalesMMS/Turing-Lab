import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../core/algorithms/tm_block_dependency_analyzer.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/state.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_building_blocks.dart';
import '../../core/services/tm_block_project_editor.dart';
import 'tm_editor_provider.dart';

class TMBlockLibraryState {
  const TMBlockLibraryState({
    this.project,
    this.navigationPath = const [],
    this.diagnostics = const [],
    this.canUndo = false,
    this.canRedo = false,
    this.lastError,
    this.lastErrorCompatibilityDetail,
  });

  final TMBlockProject? project;
  final List<String> navigationPath;
  final List<TMBlockDiagnostic> diagnostics;
  final bool canUndo;
  final bool canRedo;
  final StructuredMessage? lastError;
  final String? lastErrorCompatibilityDetail;

  String? get activeBlockId =>
      navigationPath.isEmpty ? null : navigationPath.last;
}

class TMBlockLibraryNotifier extends StateNotifier<TMBlockLibraryState> {
  TMBlockLibraryNotifier(this._tmEditor) : super(const TMBlockLibraryState());

  final TMEditorNotifier _tmEditor;
  TMBlockProjectEditor? _editor;

  void synchronize(TM? machine) {
    if (machine == null) {
      _editor = null;
      state = const TMBlockLibraryState();
      return;
    }
    if (identical(_editor?.project.rootMachine, machine)) return;
    _editor = TMBlockProjectEditor(TMBlockProject.fromFlatMachine(machine));
    _publish();
  }

  void createDefinition(String requestedName) {
    final editor = _editor;
    if (editor == null) return;
    final name = requestedName.trim();
    final id = _uniqueId(_slug(name.isEmpty ? 'block' : name));
    final root = editor.project.rootMachine;
    final initial = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(160, 160),
      isInitial: true,
    );
    final now = DateTime.now();
    final machine = TM(
      id: '$id:machine',
      name: name.isEmpty ? id : name,
      states: {initial},
      transitions: const {},
      alphabet: root.alphabet,
      initialState: initial,
      acceptingStates: const {},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: root.tapeAlphabet,
      blankSymbol: root.blankSymbol,
      tapeCount: root.tapeCount,
    );
    _apply(
      editor.createDefinition(
        TMBlockDefinition(
          id: id,
          name: name.isEmpty ? id : name,
          revision: 1,
          machine: machine,
        ),
      ),
    );
  }

  void renameDefinition(String blockId, String name) {
    final editor = _editor;
    if (editor == null) return;
    _apply(editor.renameDefinition(blockId, name));
  }

  void duplicateDefinition(String blockId) {
    final editor = _editor;
    final source = editor?.project.definitions[blockId];
    if (editor == null || source == null) return;
    final id = _uniqueId('${blockId}_copy');
    _apply(
      editor.duplicateDefinition(
        blockId,
        newId: id,
        newName: '${source.name} copy',
      ),
    );
  }

  void deleteDefinition(String blockId, {required bool detachInvocations}) {
    final editor = _editor;
    if (editor == null) return;
    _apply(
      editor.deleteDefinition(
        blockId,
        resolution: detachInvocations
            ? TMBlockDeleteResolution.detachInvocations
            : TMBlockDeleteResolution.cancel,
      ),
    );
  }

  void insertOnRootCanvas(String blockId) {
    final editor = _editor;
    final definition = editor?.project.definitions[blockId];
    if (editor == null || definition == null) return;
    final index = editor.project.rootMachine.states.length;
    final stateId = _uniqueStateId('block_$blockId');
    final anchor = State(
      id: stateId,
      label: 'Block: ${definition.name}',
      position: Vector2(140 + (index % 4) * 120, 140 + (index ~/ 4) * 120),
    );
    _apply(
      editor.insertRootInvocation(
        anchor: anchor,
        invocationId: _uniqueInvocationId('invoke_$blockId'),
        blockId: blockId,
      ),
    );
  }

  void openDefinition(String blockId) {
    if (_editor?.project.definitions.containsKey(blockId) != true) return;
    state = TMBlockLibraryState(
      project: state.project,
      navigationPath: [blockId],
      diagnostics: state.diagnostics,
      canUndo: state.canUndo,
      canRedo: state.canRedo,
      lastError: state.lastError,
      lastErrorCompatibilityDetail: state.lastErrorCompatibilityDetail,
    );
  }

  void openNestedDefinition(String blockId) {
    if (_editor?.project.definitions.containsKey(blockId) != true) return;
    state = TMBlockLibraryState(
      project: state.project,
      navigationPath: [...state.navigationPath, blockId],
      diagnostics: state.diagnostics,
      canUndo: state.canUndo,
      canRedo: state.canRedo,
      lastError: state.lastError,
      lastErrorCompatibilityDetail: state.lastErrorCompatibilityDetail,
    );
  }

  void navigateToDepth(int depth) {
    if (depth < 0 || depth > state.navigationPath.length) return;
    state = TMBlockLibraryState(
      project: state.project,
      navigationPath: state.navigationPath.sublist(0, depth),
      diagnostics: state.diagnostics,
      canUndo: state.canUndo,
      canRedo: state.canRedo,
      lastError: state.lastError,
      lastErrorCompatibilityDetail: state.lastErrorCompatibilityDetail,
    );
  }

  void undo() {
    final editor = _editor;
    if (editor != null) _apply(editor.undo());
  }

  void redo() {
    final editor = _editor;
    if (editor != null) _apply(editor.redo());
  }

  void clearError() {
    if (state.lastError == null) return;
    _publish();
  }

  void _apply(TMBlockEditResult result) {
    if (result.isSuccess) {
      _tmEditor.setTm(result.project.rootMachine);
      _publish();
    } else {
      _publish(
        lastError: result.structuredMessage,
        lastErrorCompatibilityDetail: result.compatibilityDetail,
      );
    }
  }

  void _publish({
    StructuredMessage? lastError,
    String? lastErrorCompatibilityDetail,
  }) {
    final editor = _editor;
    if (editor == null) {
      state = const TMBlockLibraryState();
      return;
    }
    final report = TMBlockDependencyAnalyzer.analyze(editor.project);
    final retainedPath = state.navigationPath
        .where(editor.project.definitions.containsKey)
        .toList(growable: false);
    state = TMBlockLibraryState(
      project: editor.project,
      navigationPath: retainedPath,
      diagnostics: report.diagnostics,
      canUndo: editor.canUndo,
      canRedo: editor.canRedo,
      lastError: lastError,
      lastErrorCompatibilityDetail: lastErrorCompatibilityDetail,
    );
  }

  String _uniqueId(String base) {
    final definitions = _editor!.project.definitions;
    if (!definitions.containsKey(base)) return base;
    var suffix = 2;
    while (definitions.containsKey('${base}_$suffix')) {
      suffix++;
    }
    return '${base}_$suffix';
  }

  String _uniqueStateId(String base) {
    final ids = _editor!.project.rootMachine.states
        .map((state) => state.id)
        .toSet();
    if (!ids.contains(base)) return base;
    var suffix = 2;
    while (ids.contains('${base}_$suffix')) {
      suffix++;
    }
    return '${base}_$suffix';
  }

  String _uniqueInvocationId(String base) {
    final ids = _editor!.project.rootInvocations.map((node) => node.id).toSet();
    if (!ids.contains(base)) return base;
    var suffix = 2;
    while (ids.contains('${base}_$suffix')) {
      suffix++;
    }
    return '${base}_$suffix';
  }

  static String _slug(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'block' : slug;
  }
}

final tmBlockLibraryProvider =
    StateNotifierProvider<TMBlockLibraryNotifier, TMBlockLibraryState>(
      (ref) => TMBlockLibraryNotifier(ref.read(tmEditorProvider.notifier)),
    );
