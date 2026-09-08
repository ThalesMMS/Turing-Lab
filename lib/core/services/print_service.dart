//
//  print_service.dart
//  Turing Lab
//
//  Contract for handing a rendered PDF to the operating system's print
//  sheet. The platform-backed implementation lives in the data layer and
//  is resolved through the injection layer, so presentation code depends
//  only on this interface.
//

import 'dart:typed_data';

abstract interface class PrintService {
  /// Opens the system print sheet with [bytes]; resolves to whether the
  /// user completed the dialog. Throws when the platform cannot print.
  Future<bool> printPdf(Uint8List bytes, {required String jobName});
}
