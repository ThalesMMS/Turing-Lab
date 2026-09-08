part of '../file_operations_panel.dart';

/// Direct system print of the active document: the same vector the SVG
/// export produces, or a text listing for workspaces without a diagram,
/// rendered to a clean PDF page and handed to the platform print sheet.
extension _FileOperationsPanelPrint on _FileOperationsPanelState {
  bool get _canPrint =>
      widget.automaton != null ||
      widget.grammar != null ||
      widget.pda != null ||
      widget.turingMachine != null ||
      (widget.visualExport?.producers.containsKey(
            DefaultFormalSystemIds.svgFormat,
          ) ??
          false) ||
      widget.printable != null;

  Widget _buildPrintSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Tooltip(
          message: _l10n.printDocumentDescription,
          child: _buildButton(
            _l10n.printDocument,
            Icons.print_outlined,
            _printDocument,
            key: const ValueKey<String>('print_document_button'),
          ),
        ),
      ],
    );
  }

  Future<PrintableDocument?> _resolvePrintable() async {
    final includeAnnotations = _includeAnnotationsInVisualExports;
    PrintableVector vector(String title, String svg) => PrintableVector(
      title: title,
      svg: svg,
      width: kDefaultPrintSheetWidth,
      height: kDefaultPrintSheetHeight,
    );
    if (widget.automaton case final automaton?) {
      return vector(
        automaton.name,
        _fileService.exportFsaToSvgString(
          automaton,
          emptyAutomatonLabel: _svgEmptyAutomatonLabel,
          tmLegendLabel: _svgTmLegendLabel,
          emptyStringSymbol: _emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: widget.annotations,
        ),
      );
    }
    if (widget.pda case final pda?) {
      return vector(
        pda.name,
        _fileService.exportPdaToSvgString(
          pda,
          emptyAutomatonLabel: _svgEmptyAutomatonLabel,
          tmLegendLabel: _svgTmLegendLabel,
          emptyStringSymbol: _emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: widget.annotations,
        ),
      );
    }
    if (widget.turingMachine case final tm?) {
      return vector(
        tm.name,
        _fileService.exportTuringMachineToSvgString(
          _convertTmToEntity(tm),
          emptyAutomatonLabel: _svgEmptyAutomatonLabel,
          tmLegendLabel: _svgTmLegendLabel,
          emptyStringSymbol: _emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: widget.annotations,
        ),
      );
    }
    if (widget.grammar case final grammar?) {
      return vector(
        grammar.name,
        _fileService.exportGrammarModelToSvgString(
          grammar,
          emptyAutomatonLabel: _svgEmptyAutomatonLabel,
          tmLegendLabel: _svgTmLegendLabel,
          emptyStringSymbol: _emptyStringSymbol,
          includeAnnotations: includeAnnotations,
          annotations: widget.annotations,
        ),
      );
    }
    final producer =
        widget.visualExport?.producers[DefaultFormalSystemIds.svgFormat];
    if (producer != null) {
      final artifact = await producer(includeAnnotations: includeAnnotations);
      return PrintableVector(
        title: artifact.filename.replaceFirst(RegExp(r'\.svg$'), ''),
        svg: utf8.decode(artifact.bytes),
        width: artifact.width.toDouble(),
        height: artifact.height.toDouble(),
      );
    }
    return widget.printable?.call();
  }

  Future<void> _printDocument() async {
    _updatePanelState(() {
      _isLoading = true;
      _feedback = null;
    });
    try {
      final document = await _resolvePrintable();
      if (document == null) {
        _showErrorMessage(_l10n.printNothingToPrint);
        return;
      }
      final font = await _printFont();
      final bytes = await PrintDocumentBuilder.build(document, font: font);
      await _printService.printPdf(bytes, jobName: document.title);
    } catch (error, stackTrace) {
      _showErrorMessage(
        _l10n.printFailed,
        retryOperation: _printDocument,
        stackTrace: stackTrace,
      );
    } finally {
      _updatePanelState(() => _isLoading = false);
    }
  }

  /// The bundled DejaVu Sans covers the Greek letters, arrows and
  /// subscripts the workspaces draw; the built-in PDF fonts do not.
  Future<pw.Font?> _printFont() async {
    try {
      final data = await rootBundle.load(kPrintSheetFontAsset);
      return pw.Font.ttf(data);
    } catch (_) {
      return null;
    }
  }
}
