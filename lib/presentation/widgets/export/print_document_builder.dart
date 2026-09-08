//
//  print_document_builder.dart
//  Turing Lab
//
//  Builds the PDF handed to the system print sheet: a clean page carrying
//  only the document title and its vector diagram (or its text listing),
//  with no application chrome. Pure Dart over package:pdf, so it is unit
//  tested without a platform.
//

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// What a workspace hands to the printer.
sealed class PrintableDocument {
  const PrintableDocument({required this.title});

  /// Job name and page heading.
  final String title;
}

/// A vector diagram, as the SVG the workspace already exports.
final class PrintableVector extends PrintableDocument {
  const PrintableVector({
    required super.title,
    required this.svg,
    required this.width,
    required this.height,
  });

  final String svg;
  final double width;
  final double height;
}

/// A text listing for workspaces without a diagram (regular expressions,
/// pumping lemma problems, grammars written as productions).
final class PrintableText extends PrintableDocument {
  const PrintableText({required super.title, required this.text});

  final String text;
}

/// Sheet size, in SVG user units, used when a workspace prints the diagram
/// it also exports as SVG.
const double kDefaultPrintSheetWidth = 800;
const double kDefaultPrintSheetHeight = 600;

/// Bundled font with the Greek letters, arrows and subscripts the
/// workspaces draw (see assets/fonts/DEJAVU_LICENSE.txt).
const String kPrintSheetFontAsset = 'assets/fonts/DejaVuSans.ttf';

abstract final class PrintDocumentBuilder {
  static const _margin = 36.0;

  /// Renders [document] to PDF bytes. [font] should cover the glyphs the
  /// workspaces use (ε, λ, arrows, subscripts); without it the built-in
  /// Type 1 fonts only draw Latin-1 text.
  static Future<Uint8List> build(
    PrintableDocument document, {
    pw.Font? font,
    pw.Font? boldFont,
  }) async {
    final theme = font == null
        ? null
        : pw.ThemeData.withFont(base: font, bold: boldFont ?? font);
    final pdf = pw.Document(
      title: document.title,
      creator: 'Turing Lab',
      theme: theme,
    );
    switch (document) {
      case PrintableVector(:final svg, :final width, :final height):
        final format = width > height
            ? PdfPageFormat.a4.landscape
            : PdfPageFormat.a4;
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: const pw.EdgeInsets.all(_margin),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _heading(document.title),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.SvgImage(
                      svg: svg,
                      fit: pw.BoxFit.contain,
                      // SVG text names CSS families the PDF has no font for;
                      // route every family to the supplied Unicode font.
                      customFontLookup: font == null
                          ? null
                          : (family, style, weight) => font,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case PrintableText(:final text):
        final lines = text.split('\n');
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(_margin),
            build: (context) => [
              _heading(document.title),
              pw.SizedBox(height: 12),
              for (final line in lines)
                pw.Text(
                  line.isEmpty ? ' ' : line,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
                  // A single logical line longer than a page continues on
                  // the next page instead of failing the layout.
                  overflow: pw.TextOverflow.span,
                ),
            ],
          ),
        );
    }
    return pdf.save();
  }

  static pw.Widget _heading(String title) => pw.Text(
    title,
    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
  );
}
