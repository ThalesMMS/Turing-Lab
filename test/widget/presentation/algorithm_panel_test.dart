import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/equivalence_comparison_result.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/language_comparison_outcome.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/widgets/algorithm_panel.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/file_operations_panel.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_controller.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_semantics.dart';
import 'package:turing_lab/presentation/widgets/language_comparison_viewer.dart';

class _TestCallbacks {
  int autoLayoutCallCount = 0;
  int clearCallCount = 0;
  int kleeneStarCallCount = 0;
  int reverseFsaCallCount = 0;
  String? lastRegexValue;

  void onClear() {
    clearCallCount++;
  }

  void onRegexToNfa(String regex) {
    lastRegexValue = regex;
  }

  void onAutoLayout() {
    autoLayoutCallCount++;
  }

  void onKleeneStar() {
    kleeneStarCallCount++;
  }

  void onReverseFsa() {
    reverseFsaCallCount++;
  }
}

class _MockFileOperationsService extends FileOperationsService {
  final Queue<Result<FSA>> automatonLoadResults = Queue<Result<FSA>>();
  Uint8List? lastWrittenBytes;

  Future<FSA?> loadAutomatonFromFile(String path) async {
    return null;
  }

  @override
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    if (automatonLoadResults.isEmpty) {
      return const Failure<FSA>('No automaton load response configured');
    }
    return automatonLoadResults.removeFirst();
  }

  @override
  Future<StringResult> writeBytes(
    Uint8List bytes,
    String filePath, {
    String mimeType = 'application/octet-stream',
  }) async {
    lastWrittenBytes = bytes;
    return Success<String>(filePath);
  }
}

class _FakeFilePicker extends FilePicker {
  final Queue<FilePickerResult?> pickResults = Queue<FilePickerResult?>();
  final Queue<String?> saveResults = Queue<String?>();
  Uint8List? lastSaveBytes;
  FileType? lastPickType;
  List<String>? lastAllowedExtensions;
  Object? pickError;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    lastPickType = type;
    lastAllowedExtensions = allowedExtensions;
    if (pickError != null) throw pickError!;
    if (pickResults.isEmpty) return null;
    return pickResults.removeFirst();
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    lastSaveBytes = bytes;
    if (saveResults.isEmpty) return null;
    return saveResults.removeFirst();
  }
}

class _AlgorithmPanelProviderHarness extends ConsumerWidget {
  const _AlgorithmPanelProviderHarness({required this.fileService});

  final FileOperationsService fileService;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlgorithmPanel(
      currentAutomaton: ref.watch(automatonStateProvider).currentAutomaton,
      fileService: fileService,
    );
  }
}

Future<void> _pumpAlgorithmPanel(
  WidgetTester tester, {
  FSA? currentAutomaton,
  VoidCallback? onNfaToDfa,
  VoidCallback? onMinimizeDfa,
  VoidCallback? onClear,
  FutureOr<void> Function(String)? onRegexToNfa,
  VoidCallback? onFaToRegex,
  VoidCallback? onRemoveLambda,
  VoidCallback? onCompleteDfa,
  VoidCallback? onComplementDfa,
  Future<void> Function(FSA)? onUnionDfa,
  Future<void> Function(FSA)? onConcatenateFsa,
  VoidCallback? onKleeneStarFsa,
  VoidCallback? onReverseFsa,
  Future<void> Function(FSA)? onIntersectionDfa,
  Future<void> Function(FSA)? onDifferenceDfa,
  VoidCallback? onPrefixClosure,
  VoidCallback? onSuffixClosure,
  VoidCallback? onFsaToGrammar,
  VoidCallback? onAutoLayout,
  Future<void> Function(FSA)? onCompareEquivalence,
  bool? equivalenceResult,
  String? equivalenceDetails,
  LanguageComparisonRunner? languageComparisonRunner,
  FileOperationsService? fileService,
  String emptyStringSymbol = kEpsilonSymbol,
}) async {
  final automatonNotifier = AutomatonStateNotifier();
  if (currentAutomaton != null) {
    automatonNotifier.updateAutomaton(currentAutomaton);
  }
  await tester.pumpWidget(
    EmptyStringNotation(
      symbol: emptyStringSymbol,
      child: ProviderScope(
        overrides: [
          automatonStateProvider.overrideWith((ref) => automatonNotifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AlgorithmPanel(
              currentAutomaton: currentAutomaton,
              onNfaToDfa: onNfaToDfa,
              onMinimizeDfa: onMinimizeDfa,
              onClear: onClear,
              onRegexToNfa: onRegexToNfa,
              onFaToRegex: onFaToRegex,
              onRemoveLambda: onRemoveLambda,
              onCompleteDfa: onCompleteDfa,
              onComplementDfa: onComplementDfa,
              onUnionDfa: onUnionDfa,
              onConcatenateFsa: onConcatenateFsa,
              onKleeneStarFsa: onKleeneStarFsa,
              onReverseFsa: onReverseFsa,
              onIntersectionDfa: onIntersectionDfa,
              onDifferenceDfa: onDifferenceDfa,
              onPrefixClosure: onPrefixClosure,
              onSuffixClosure: onSuffixClosure,
              onFsaToGrammar: onFsaToGrammar,
              onAutoLayout: onAutoLayout,
              onCompareEquivalence: onCompareEquivalence,
              equivalenceResult: equivalenceResult,
              equivalenceDetails: equivalenceDetails,
              languageComparisonRunner: languageComparisonRunner,
              fileService: fileService,
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

FSA _loadedAutomaton() {
  final state = automaton_state.State(
    id: 'loaded-state',
    label: 'loaded',
    position: Vector2.zero(),
    isInitial: true,
  );
  return FSA(
    id: 'loaded-automaton',
    name: 'Loaded automaton',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: const {},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FilePickerResult _pickedComparisonFile(String name) {
  return FilePickerResult([
    PlatformFile(
      name: '$name.jff',
      size: 1,
      bytes: Uint8List.fromList(const [1]),
    ),
  ]);
}

EquivalenceComparisonResult _comparisonResultFor(
  LanguageComparisonRequest request, {
  required bool isEquivalent,
  String? distinguishingString,
}) {
  return EquivalenceComparisonResult(
    originalAutomaton: request.automatonA,
    comparedAutomaton: request.automatonB,
    isEquivalent: isEquivalent,
    distinguishingString: distinguishingString,
    executionTimeMs: 1,
  );
}

Future<void> _tapCompareEquivalence(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Compare Equivalence'));
  await tester.tap(find.text('Compare Equivalence'));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FilePicker.platform = _FakeFilePicker();
  });

  tearDown(() {
    FilePicker.platform = _FakeFilePicker();
  });

  group('AlgorithmPanel', () {
    testWidgets('renders all algorithm buttons and regex input', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('Regex to NFA'), findsOneWidget);
      expect(find.text('NFA to DFA'), findsOneWidget);
      expect(find.text('Remove ε-transitions'), findsOneWidget);
      expect(find.text('Minimize DFA'), findsOneWidget);
      expect(find.text('Complete DFA'), findsOneWidget);
      expect(find.text('Complement DFA'), findsOneWidget);
      expect(find.text('Union of DFAs'), findsOneWidget);
      expect(find.text('Concatenation of FSAs'), findsOneWidget);
      expect(find.text('Kleene Star'), findsOneWidget);
      expect(find.text('Reverse FSA'), findsOneWidget);
      expect(find.text('Intersection of DFAs'), findsOneWidget);
      expect(find.text('Difference of DFAs'), findsOneWidget);
      expect(find.text('Prefix Closure'), findsOneWidget);
      expect(find.text('Suffix Closure'), findsOneWidget);
      expect(find.text('FA to Regex'), findsOneWidget);
      expect(find.text('Practice FA to Regex'), findsOneWidget);
      expect(find.text('FSA to Grammar'), findsOneWidget);
      expect(find.text('Practice FA to Regular Grammar'), findsOneWidget);
      expect(find.text('Auto Layout'), findsOneWidget);
      expect(find.text('Compare Equivalence'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Regular Expression'),
        findsOneWidget,
      );
    });

    testWidgets(
      'uses lambda label without changing the canonical selection key',
      (tester) async {
        var calls = 0;
        await _pumpAlgorithmPanel(
          tester,
          emptyStringSymbol: kLambdaSymbol,
          onRemoveLambda: () => calls++,
        );

        final label = find.text('Remove λ-transitions');
        expect(label, findsOneWidget);

        await tester.tap(label);
        await tester.pump();

        expect(calls, 1);
        final button = tester.widget<AlgorithmButton>(
          find.ancestor(of: label, matching: find.byType(AlgorithmButton)),
        );
        expect(button.isSelected, isTrue);
        expect(button.executionStatus, 'Completed successfully');
      },
    );

    testWidgets('triggers auto layout callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onAutoLayout: callbacks.onAutoLayout);

      expect(callbacks.autoLayoutCallCount, 0);

      await tester.ensureVisible(find.text('Auto Layout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Auto Layout'));
      await tester.pumpAndSettle();

      expect(callbacks.autoLayoutCallCount, 1);
    });

    testWidgets('triggers clear callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onClear: callbacks.onClear);

      expect(callbacks.clearCallCount, 0);

      await tester.ensureVisible(find.text('Clear'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(callbacks.clearCallCount, 1);
    });

    testWidgets('triggers Kleene star callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(
        tester,
        onKleeneStarFsa: callbacks.onKleeneStar,
      );

      await tester.ensureVisible(find.text('Kleene Star'));
      await tester.tap(find.text('Kleene Star'));
      await tester.pumpAndSettle();

      expect(callbacks.kleeneStarCallCount, 1);
    });

    testWidgets('triggers FSA reversal callback when button is tapped', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onReverseFsa: callbacks.onReverseFsa);

      await tester.ensureVisible(find.text('Reverse FSA'));
      await tester.tap(find.text('Reverse FSA'));
      await tester.pumpAndSettle();

      expect(callbacks.reverseFsaCallCount, 1);
    });

    testWidgets('triggers regex to NFA callback when button is pressed', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.enterText(find.byType(TextField), '(a|b)*');
      await tester.tap(
        find.widgetWithIcon(ElevatedButton, Icons.arrow_forward),
      );
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, '(a|b)*');
    });

    testWidgets('embedded Regex to NFA asks before replacing loaded FSA', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();
      await _pumpAlgorithmPanel(
        tester,
        currentAutomaton: _loadedAutomaton(),
        onRegexToNfa: callbacks.onRegexToNfa,
      );

      await tester.enterText(find.byType(TextField), 'a');
      await tester.tap(
        find.widgetWithIcon(ElevatedButton, Icons.arrow_forward),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('An automaton is already loaded. Do you want to replace it?'),
        findsOneWidget,
      );
      expect(callbacks.lastRegexValue, isNull);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(callbacks.lastRegexValue, isNull);
    });

    testWidgets('triggers regex to NFA callback when enter is pressed', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.enterText(find.byType(TextField), 'a*b*');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, 'a*b*');
    });

    testWidgets('does not trigger regex callback with empty input', (
      tester,
    ) async {
      final callbacks = _TestCallbacks();

      await _pumpAlgorithmPanel(tester, onRegexToNfa: callbacks.onRegexToNfa);

      expect(callbacks.lastRegexValue, isNull);

      await tester.tap(
        find.widgetWithIcon(ElevatedButton, Icons.arrow_forward),
      );
      await tester.pumpAndSettle();

      expect(callbacks.lastRegexValue, isNull);
    });

    testWidgets('displays equivalence result when result is true', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: true,
        equivalenceDetails: 'The automata accept the same language',
      );

      expect(find.text('Automata are equivalent'), findsOneWidget);
      expect(
        find.text('The automata accept the same language'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('displays equivalence result when result is false', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: false,
        equivalenceDetails: 'Distinguishing string: ab',
      );

      expect(find.text('Automata are not equivalent'), findsOneWidget);
      expect(find.text('Distinguishing string: ab'), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('displays equivalence result with null result', (tester) async {
      await _pumpAlgorithmPanel(
        tester,
        equivalenceResult: null,
        equivalenceDetails: 'Comparison in progress',
      );

      expect(find.text('Equivalence comparison'), findsOneWidget);
      expect(find.text('Comparison in progress'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('does not display equivalence result when no data provided', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Automata are equivalent'), findsNothing);
      expect(find.text('Automata are not equivalent'), findsNothing);
      expect(find.text('Equivalence comparison'), findsNothing);
    });

    testWidgets('production comparison renders typed failures in the viewer', (
      tester,
    ) async {
      final picker = _FakeFilePicker()
        ..pickResults.add(_pickedComparisonFile('invalid-nfa'));
      FilePicker.platform = picker;

      final fileService = _MockFileOperationsService()
        ..automatonLoadResults.add(Success<FSA>(_loadedAutomaton()));

      await _pumpAlgorithmPanel(
        tester,
        currentAutomaton: _loadedAutomaton().copyWith(id: 'source'),
        fileService: fileService,
        languageComparisonRunner: (_) async => const LanguageComparisonFailure(
          reason: LanguageComparisonFailureReason.determinization,
          message: 'Determinization failed for automaton B',
        ),
      );

      await _tapCompareEquivalence(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LanguageComparisonViewer), findsOneWidget);
      expect(
        find.byKey(
          LanguageComparisonSemantics.failureKey(
            LanguageComparisonFailureReason.determinization,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          LanguageComparisonSemantics.statusKey(LanguageComparisonStatus.error),
        ),
        findsOneWidget,
      );
      expect(picker.lastPickType, FileType.any);
      expect(picker.lastAllowedExtensions, isNull);
    });

    testWidgets(
      'binary operations use the Android-compatible picker and load a second FSA',
      (tester) async {
        final picker = _FakeFilePicker()
          ..pickResults.add(_pickedComparisonFile('other'));
        FilePicker.platform = picker;
        final fileService = _MockFileOperationsService()
          ..automatonLoadResults.add(Success<FSA>(_loadedAutomaton()));
        FSA? loadedOther;

        await _pumpAlgorithmPanel(
          tester,
          currentAutomaton: _loadedAutomaton(),
          fileService: fileService,
          onUnionDfa: (other) async {
            loadedOther = other;
          },
        );

        await tester.ensureVisible(find.text('Union of DFAs'));
        await tester.tap(find.text('Union of DFAs'));
        await tester.pumpAndSettle();

        expect(loadedOther, isNotNull);
        expect(picker.lastPickType, FileType.any);
        expect(picker.lastAllowedExtensions, isNull);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'binary picker failures are handled without an unhandled error',
      (tester) async {
        final picker = _FakeFilePicker()
          ..pickError = StateError('picker unavailable');
        FilePicker.platform = picker;

        await _pumpAlgorithmPanel(
          tester,
          currentAutomaton: _loadedAutomaton(),
          onUnionDfa: (_) async {},
        );

        await tester.ensureVisible(find.text('Union of DFAs'));
        await tester.tap(find.text('Union of DFAs'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          find.textContaining('Could not open the automaton file picker'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'production comparison ignores an old revision after a newer request',
      (tester) async {
        final picker = _FakeFilePicker()
          ..pickResults.addAll([
            _pickedComparisonFile('old-target'),
            _pickedComparisonFile('new-target'),
          ]);
        FilePicker.platform = picker;

        final oldTarget = _loadedAutomaton().copyWith(id: 'old-target');
        final newTarget = _loadedAutomaton().copyWith(id: 'new-target');
        final fileService = _MockFileOperationsService()
          ..automatonLoadResults.addAll([
            Success<FSA>(oldTarget),
            Success<FSA>(newTarget),
          ]);
        final oldCompletion = Completer<LanguageComparisonOutcome>();
        final requests = <LanguageComparisonRequest>[];
        Future<LanguageComparisonOutcome> runner(
          LanguageComparisonRequest request,
        ) {
          requests.add(request);
          if (request.automatonB.id == 'old-target') {
            return oldCompletion.future;
          }
          return Future.value(
            LanguageComparisonCompleted(
              _comparisonResultFor(
                request,
                isEquivalent: false,
                distinguishingString: 'new',
              ),
            ),
          );
        }

        final oldSource = _loadedAutomaton().copyWith(
          id: 'source',
          modified: DateTime.utc(2026, 1, 1),
        );
        final newSource = oldSource.copyWith(
          modified: DateTime.utc(2026, 2, 1),
        );

        await _pumpAlgorithmPanel(
          tester,
          currentAutomaton: oldSource,
          fileService: fileService,
          languageComparisonRunner: runner,
        );
        await _tapCompareEquivalence(tester);
        expect(requests, hasLength(1));

        await _pumpAlgorithmPanel(
          tester,
          currentAutomaton: newSource,
          fileService: fileService,
          languageComparisonRunner: runner,
        );
        await _tapCompareEquivalence(tester);
        await tester.pumpAndSettle();

        expect(requests, hasLength(2));
        expect(requests.last.automatonA.modified, newSource.modified);
        var viewer = tester.widget<LanguageComparisonViewer>(
          find.byType(LanguageComparisonViewer),
        );
        expect(viewer.comparisonResult?.distinguishingString, 'new');

        oldCompletion.complete(
          LanguageComparisonCompleted(
            _comparisonResultFor(requests.first, isEquivalent: true),
          ),
        );
        await tester.pumpAndSettle();

        viewer = tester.widget<LanguageComparisonViewer>(
          find.byType(LanguageComparisonViewer),
        );
        expect(viewer.comparisonResult?.distinguishingString, 'new');
        expect(
          find.byKey(
            LanguageComparisonSemantics.statusKey(
              LanguageComparisonStatus.notEquivalent,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('displays correct icons for each algorithm button', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.byIcon(Icons.transform), findsWidgets);
      expect(find.byIcon(Icons.highlight_off), findsOneWidget);
      expect(find.byIcon(Icons.compress), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.flip), findsOneWidget);
      expect(find.byIcon(Icons.merge_type), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      expect(find.byIcon(Icons.call_merge), findsOneWidget);
      expect(find.byIcon(Icons.call_split), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_top), findsOneWidget);
      expect(find.byIcon(Icons.vertical_align_bottom), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_motion), findsOneWidget);
      expect(find.byIcon(Icons.compare_arrows), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('renders within a scrollable card', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Card),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses mock file service when provided', (tester) async {
      final mockFileService = _MockFileOperationsService();

      await _pumpAlgorithmPanel(tester, fileService: mockFileService);

      expect(find.byType(AlgorithmPanel), findsOneWidget);
    });

    testWidgets('exposes FSA file operations for a loaded automaton', (
      tester,
    ) async {
      final fileService = _MockFileOperationsService();
      await _pumpAlgorithmPanel(
        tester,
        currentAutomaton: _loadedAutomaton(),
        fileService: fileService,
      );

      expect(
        find.byKey(const ValueKey<String>('interoperability_import_document')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interoperability_export_jflap-xml')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('interoperability_export_turing-lab-json'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fsa_json_import_button')),
        findsNothing,
      );
      final filePanel = tester.widget<FileOperationsPanel>(
        find.byType(FileOperationsPanel),
      );
      expect(filePanel.fileService, same(fileService));

      final replacement = _loadedAutomaton().copyWith(id: 'replacement');
      filePanel.onAutomatonLoaded!(replacement);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AlgorithmPanel)),
      );
      expect(
        container.read(automatonStateProvider).currentAutomaton?.id,
        'replacement',
      );
    });

    testWidgets('empty FSA workspace imports through generic preview', (
      tester,
    ) async {
      const jflap = '''<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>80</x><y>80</y><initial/>
    </state>
  </automaton>
</structure>''';
      final picker = _FakeFilePicker()
        ..pickResults.add(
          FilePickerResult([
            PlatformFile(
              name: 'automaton-without-extension',
              size: jflap.length,
              bytes: Uint8List.fromList(jflap.codeUnits),
            ),
          ]),
        );
      FilePicker.platform = picker;

      await _pumpAlgorithmPanel(
        tester,
        fileService: _MockFileOperationsService(),
      );

      expect(
        find.byKey(const ValueKey<String>('interoperability_import_document')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interoperability_export_jflap-xml')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fsa_json_import_button')),
        findsNothing,
      );

      final importButton = find.byKey(
        const ValueKey<String>('interoperability_import_document'),
      );
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AlgorithmPanel)),
      );
      expect(container.read(automatonStateProvider).currentAutomaton, isNull);
      expect(find.text('Review import'), findsOneWidget);

      await tester.tap(find.text('Replace document'));
      await tester.pumpAndSettle();
      expect(
        container.read(automatonStateProvider).currentAutomaton,
        isNotNull,
      );
    });

    testWidgets('host preserves imported extensions after edit and export', (
      tester,
    ) async {
      const jflapWithExtension = '''
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100</x><y>100</y><initial/><final/>
      <future-metadata enabled="true" />
    </state>
  </automaton>
</structure>
''';
      final picker = _FakeFilePicker()
        ..pickResults.add(
          FilePickerResult([
            PlatformFile(
              name: 'future.jff',
              size: jflapWithExtension.length,
              bytes: Uint8List.fromList(jflapWithExtension.codeUnits),
            ),
          ]),
        )
        ..saveResults.add(r'C:\exports\future.jff');
      FilePicker.platform = picker;
      final fileService = _MockFileOperationsService();
      final notifier = AutomatonStateNotifier();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [automatonStateProvider.overrideWith((ref) => notifier)],
          child: MaterialApp(
            home: Scaffold(
              body: _AlgorithmPanelProviderHarness(fileService: fileService),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final importButton = find.byKey(
        const ValueKey<String>('interoperability_import_document'),
      );
      await tester.ensureVisible(importButton);
      await tester.tap(importButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace document'));
      await tester.pumpAndSettle();

      final imported = notifier.currentAutomaton!;
      notifier.updateAutomaton(imported.copyWith(name: 'Edited in Turing Lab'));
      await tester.pumpAndSettle();

      final exportButton = find.byKey(
        const ValueKey<String>('interoperability_export_jflap-xml'),
      );
      await tester.ensureVisible(exportButton);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export file'));
      await tester.pumpAndSettle();

      final exported = picker.lastSaveBytes ?? fileService.lastWrittenBytes;
      expect(exported, isNotNull);
      expect(
        String.fromCharCodes(exported!),
        contains('<future-metadata enabled="true"'),
      );
    });

    testWidgets('exposes FSA imports before an automaton is loaded', (
      tester,
    ) async {
      final fileService = _MockFileOperationsService();
      await _pumpAlgorithmPanel(tester, fileService: fileService);

      expect(
        find.byKey(const ValueKey<String>('interoperability_import_document')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('interoperability_export_jflap-xml')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fsa_jflap_export_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fsa_jflap_import_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fsa_json_import_button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('fsa_json_export_button')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('fsa_svg_export_button')), findsNothing);
      expect(find.byKey(const ValueKey('fsa_png_export_button')), findsNothing);

      final filePanel = tester.widget<FileOperationsPanel>(
        find.byType(FileOperationsPanel),
      );
      expect(filePanel.fileService, same(fileService));
      expect(filePanel.onAutomatonLoaded, isNotNull);
    });

    testWidgets('displays descriptions for each algorithm button', (
      tester,
    ) async {
      await _pumpAlgorithmPanel(tester);

      expect(
        find.text('Convert non-deterministic to deterministic automaton'),
        findsOneWidget,
      );
      expect(
        find.text('Eliminate epsilon transitions from the automaton'),
        findsOneWidget,
      );
      expect(
        find.text('Minimize deterministic finite automaton'),
        findsOneWidget,
      );
      expect(find.text('Add trap state to make DFA complete'), findsOneWidget);
      expect(
        find.text('Flip accepting states after completion'),
        findsOneWidget,
      );
      expect(
        find.text('Combine this DFA with another automaton from file'),
        findsOneWidget,
      );
    });

    testWidgets('displays regex input field with hint text', (tester) async {
      await _pumpAlgorithmPanel(tester);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.labelText, 'Regular Expression');
      expect(textField.decoration?.hintText, 'e.g., (a|b)*');
    });

    testWidgets('shows binary operation buttons', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(find.text('Union of DFAs'), findsOneWidget);
      expect(find.text('Concatenation of FSAs'), findsOneWidget);
      expect(find.text('Kleene Star'), findsOneWidget);
      expect(find.text('Reverse FSA'), findsOneWidget);
      expect(find.text('Intersection of DFAs'), findsOneWidget);
      expect(find.text('Difference of DFAs'), findsOneWidget);
    });

    testWidgets('displays correct button descriptions', (tester) async {
      await _pumpAlgorithmPanel(tester);

      expect(
        find.text('Accept all prefixes of the DFA language'),
        findsOneWidget,
      );
      expect(
        find.text('Accept all suffixes of the DFA language'),
        findsOneWidget,
      );
      expect(
        find.text('Convert finite automaton to regular expression'),
        findsOneWidget,
      );
      expect(
        find.text('Convert finite automaton to regular grammar'),
        findsOneWidget,
      );
      expect(find.text('Arrange states in a circle'), findsOneWidget);
      expect(find.text('Compare two DFAs for equivalence'), findsOneWidget);
      expect(find.text('Clear current automaton'), findsOneWidget);
    });

    testWidgets('displays title text with correct styling', (tester) async {
      await _pumpAlgorithmPanel(tester);

      final titleText = find.text('Algorithms');
      expect(titleText, findsOneWidget);

      final textWidget = tester.widget<Text>(titleText);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
