//
//  print_service.dart
//  Turing Lab
//
//  package:printing implementation of the core PrintService contract:
//  AppKit/UIKit print sheets on Apple platforms, the platform dialogs on
//  Android, Windows and Linux, and the browser print dialog on the web.
//

import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../../core/services/print_service.dart';

export '../../core/services/print_service.dart';

final class PrintingPrintService implements PrintService {
  const PrintingPrintService();

  @override
  Future<bool> printPdf(Uint8List bytes, {required String jobName}) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: jobName);
}
