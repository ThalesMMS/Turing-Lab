import 'dart:convert';
import 'dart:io';

import 'package:turing_lab/core/interoperability/interoperability.dart';

import '../compatibility_corpus/catalog.dart';
import 'families/codec_parity.dart';

void main(List<String> arguments) {
  final catalog = CompatibilityCodecCatalog.create();
  if (arguments.length == 2 && arguments.first == '--outcome') {
    final codec = catalog.codecs[arguments.last]!;
    final fixture = File(codec.descriptor.canonicalFixtures.first);
    stdout.writeln(
      codecCanonicalOutcome(
        codec,
        DocumentPayload(
          bytes: fixture.readAsBytesSync(),
          filename: fixture.uri.pathSegments.last,
        ),
      ),
    );
    return;
  }
  stdout.writeln('const codecParityVectors = <CodecParityVector>[');
  for (final entry in catalog.codecs.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key))) {
    final codec = entry.value;
    final fixture = File(codec.descriptor.canonicalFixtures.first);
    final bytes = fixture.readAsBytesSync();
    final filename = fixture.uri.pathSegments.last;
    final digest = codecCanonicalOutcomeSha256(
      codec,
      DocumentPayload(bytes: bytes, filename: filename),
    );
    stdout.writeln('  CodecParityVector(');
    stdout.writeln("    codecId: '${entry.key}',");
    stdout.writeln("    filename: '$filename',");
    stdout.writeln("    payloadBase64: '${base64Encode(bytes)}',");
    stdout.writeln("    nativeOutcomeSha256: '$digest',");
    stdout.writeln('  ),');
  }
  stdout.writeln('];');
}
