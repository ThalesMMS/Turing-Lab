part of '../file_operations_panel_test.dart';

FSA _buildSampleAutomaton() {
  final state = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  return FSA(
    id: 'sample',
    name: 'Sample',
    states: {state},
    transitions: const <FSATransition>{},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

Grammar _buildSampleGrammar() {
  return Grammar(
    id: 'sample_grammar',
    name: 'Sample Grammar',
    terminals: const {'a', 'b'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: '1', leftSide: ['S'], rightSide: ['a', 'S', 'b']),
      const Production(id: '2', leftSide: ['S'], rightSide: [], isLambda: true),
    },
    type: GrammarType.contextFree,
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
  );
}

PDA _buildSamplePda() {
  final state = automaton_state.State(
    id: 'p0',
    label: 'p0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  final transition = PDATransition(
    id: 'pda_t0',
    fromState: state,
    toState: state,
    label: 'a,Z->AZ',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'AZ',
  );

  return PDA(
    id: 'sample_pda',
    name: 'Sample PDA',
    states: {state},
    transitions: {transition},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    stackAlphabet: const <String>{'A', 'Z'},
    initialStackSymbol: 'Z',
  );
}

TM _buildSampleTm() {
  final state = automaton_state.State(
    id: 't0',
    label: 't0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: true,
  );

  final transition = TMTransition(
    id: 'tm_t0',
    fromState: state,
    toState: state,
    label: '1/1,R',
    readSymbol: '1',
    writeSymbol: '1',
    direction: TapeDirection.right,
  );

  return TM(
    id: 'sample_tm',
    name: 'Sample TM',
    states: {state},
    transitions: {transition},
    alphabet: const <String>{'1'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
    tapeAlphabet: const <String>{'1', 'B'},
    blankSymbol: 'B',
  );
}

class _StubFileOperationsService extends FileOperationsService {
  _StubFileOperationsService({
    Queue<Result<String>>? saveAutomatonResponses,
    Queue<Result<String>>? saveGrammarResponses,
    Queue<Result<String>>? exportResponses,
    Queue<Result<FSA>>? loadAutomatonResponses,
    Queue<Result<Grammar>>? loadGrammarResponses,
    Queue<Result<Uint8List>>? readBytesResponses,
    Queue<Result<String>>? writeBytesResponses,
    this.serializeAutomatonException,
    this.loadJflapException,
    this.loadJsonException,
    this.exportSvgException,
    this.exportPngException,
    this.delayMs = 0,
  }) : saveAutomatonResponses =
           saveAutomatonResponses ?? Queue<Result<String>>(),
       saveGrammarResponses = saveGrammarResponses ?? Queue<Result<String>>(),
       exportResponses = exportResponses ?? Queue<Result<String>>(),
       loadAutomatonResponses = loadAutomatonResponses ?? Queue<Result<FSA>>(),
       loadGrammarResponses = loadGrammarResponses ?? Queue<Result<Grammar>>(),
       readBytesResponses = readBytesResponses ?? Queue<Result<Uint8List>>(),
       writeBytesResponses = writeBytesResponses ?? Queue<Result<String>>();

  final Queue<Result<String>> saveAutomatonResponses;
  final Queue<Result<String>> saveGrammarResponses;
  final Queue<Result<String>> exportResponses;
  final Queue<Result<FSA>> loadAutomatonResponses;
  final Queue<Result<Grammar>> loadGrammarResponses;
  final Queue<Result<Uint8List>> readBytesResponses;
  final Queue<Result<String>> writeBytesResponses;
  final CodecOperationException? serializeAutomatonException;
  final CodecOperationException? loadJflapException;
  final CodecOperationException? loadJsonException;
  final CodecOperationException? exportSvgException;
  final CodecOperationException? exportPngException;
  final int delayMs;

  int saveAutomatonCallCount = 0;
  int saveGrammarCallCount = 0;
  int exportCallCount = 0;
  int exportPngBytesCallCount = 0;
  int writePngBytesCallCount = 0;
  int exportAutomatonPngCallCount = 0;
  int loadAutomatonCallCount = 0;
  int loadGrammarCallCount = 0;
  int readBytesCallCount = 0;
  int writeBytesCallCount = 0;
  Uint8List? lastWrittenBytes;
  String? lastWrittenMimeType;
  bool? lastPngIncludeAnnotations;
  DocumentAnnotationCollection? lastPngAnnotations;
  FSA? lastFsaSvgExport;
  PDA? lastPdaSvgExport;
  Grammar? lastGrammarSvgExport;

  @override
  String serializeAutomatonToJFLAPString(FSA automaton) {
    final exception = serializeAutomatonException;
    if (exception != null) throw exception;
    return super.serializeAutomatonToJFLAPString(automaton);
  }

  @override
  Future<Result<Uint8List>> readBytes(String filePath) async {
    readBytesCallCount++;
    if (readBytesResponses.isEmpty) {
      return const Failure<Uint8List>('No read bytes response configured');
    }
    return readBytesResponses.removeFirst();
  }

  @override
  Future<StringResult> writeBytes(
    Uint8List bytes,
    String filePath, {
    String mimeType = 'application/octet-stream',
  }) async {
    writeBytesCallCount++;
    lastWrittenBytes = Uint8List.fromList(bytes);
    lastWrittenMimeType = mimeType;
    if (writeBytesResponses.isEmpty) {
      return const Failure<String>('No write bytes response configured');
    }
    return writeBytesResponses.removeFirst();
  }

  @override
  Future<StringResult> saveAutomatonToJFLAP(
    FSA automaton,
    String filePath,
  ) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    saveAutomatonCallCount++;
    if (saveAutomatonResponses.isEmpty) {
      return const Failure<String>('No save automaton response configured');
    }
    return saveAutomatonResponses.removeFirst();
  }

  @override
  Future<StringResult> saveGrammarToJFLAP(
    Grammar grammar,
    String filePath,
  ) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    saveGrammarCallCount++;
    if (saveGrammarResponses.isEmpty) {
      return const Failure<String>('No save grammar response configured');
    }
    return saveGrammarResponses.removeFirst();
  }

  @override
  Future<StringResult> exportFsaToSVG(
    FSA automaton,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (exportSvgException case final exception?) throw exception;
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    lastFsaSvgExport = automaton;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportPdaToSVG(
    PDA pda,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    lastPdaSvgExport = pda;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportGrammarModelToSVG(
    Grammar grammar,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    lastGrammarSvgExport = grammar;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportGrammarToSVG(
    dynamic grammar,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportTuringMachineToSVG(
    dynamic machine,
    String filePath, {
    SvgExportOptions? options,
    String? emptyAutomatonLabel,
    String? tmLegendLabel,
    String? emptyStringSymbol,
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    exportCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<Result<Uint8List>> exportAutomatonToPngBytes(
    FSA automaton, {
    String emptyStringSymbol = 'ε',
    bool includeAnnotations = false,
    DocumentAnnotationCollection? annotations,
  }) async {
    if (exportPngException case final exception?) throw exception;
    exportPngBytesCallCount++;
    lastPngIncludeAnnotations = includeAnnotations;
    lastPngAnnotations = annotations;
    return Success(Uint8List.fromList(<int>[137, 80, 78, 71]));
  }

  @override
  Future<StringResult> writePngBytesToPath(
    Uint8List bytes,
    String filePath,
  ) async {
    writePngBytesCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<StringResult> exportAutomatonToPNG(
    FSA automaton,
    String filePath, {
    String emptyStringSymbol = 'ε',
  }) async {
    exportAutomatonPngCallCount++;
    if (exportResponses.isEmpty) {
      return const Failure<String>('No export response configured');
    }
    return exportResponses.removeFirst();
  }

  @override
  Future<Result<FSA>> loadAutomatonFromBytes(Uint8List bytes) async {
    if (loadJflapException case final exception?) throw exception;
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadAutomatonCallCount++;
    if (loadAutomatonResponses.isEmpty) {
      return const Failure<FSA>('No load automaton response configured');
    }
    return loadAutomatonResponses.removeFirst();
  }

  @override
  Future<Result<FSA>> loadAutomatonFromJsonBytes(Uint8List bytes) async {
    if (loadJsonException case final exception?) throw exception;
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadAutomatonCallCount++;
    if (loadAutomatonResponses.isEmpty) {
      return const Failure<FSA>('No load automaton response configured');
    }
    return loadAutomatonResponses.removeFirst();
  }

  @override
  Future<Result<Grammar>> loadGrammarFromBytes(Uint8List bytes) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    loadGrammarCallCount++;
    if (loadGrammarResponses.isEmpty) {
      return const Failure<Grammar>('No load grammar response configured');
    }
    return loadGrammarResponses.removeFirst();
  }
}

class _FakeFilePicker extends FilePicker {
  _FakeFilePicker()
    : _pickResults = Queue<FilePickerResult?>(),
      _saveResults = Queue<String?>();

  final Queue<FilePickerResult?> _pickResults;
  final Queue<String?> _saveResults;
  Uint8List? lastSaveBytes;
  FileType? lastPickType;
  List<String>? lastPickAllowedExtensions;

  void enqueuePickResult(FilePickerResult? result) {
    _pickResults.add(result);
  }

  void enqueueSaveResult(String? result) {
    _saveResults.add(result);
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus p1)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    lastPickType = type;
    lastPickAllowedExtensions = allowedExtensions;
    if (_pickResults.isEmpty) {
      return null;
    }
    return _pickResults.removeFirst();
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
    if (_saveResults.isEmpty) {
      return null;
    }
    return _saveResults.removeFirst();
  }
}
