//
//  app_store_png_size.dart
//  Turing Lab
//
//  Minimal PNG header reader so screenshot dimension checks do not depend on
//  sips, ImageMagick or any other host tool being installed.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:io';
import 'dart:typed_data';

/// Pixel dimensions decoded from a PNG IHDR chunk.
class AppStorePngSize {
  const AppStorePngSize(this.width, this.height);

  static const List<int> _signature = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ];

  final int width;
  final int height;

  /// Decodes the IHDR width and height of [file].
  static AppStorePngSize read(File file) {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 24) {
      throw FormatException('File is too short to be a PNG: ${file.path}');
    }
    for (var index = 0; index < _signature.length; index++) {
      if (bytes[index] != _signature[index]) {
        throw FormatException('Missing PNG signature: ${file.path}');
      }
    }
    final header = ByteData.sublistView(bytes, 12, 24);
    if (String.fromCharCodes(bytes.sublist(12, 16)) != 'IHDR') {
      throw FormatException('First PNG chunk is not IHDR: ${file.path}');
    }
    return AppStorePngSize(
      header.getUint32(4),
      header.getUint32(8),
    );
  }

  @override
  String toString() => '${width}x$height';
}
