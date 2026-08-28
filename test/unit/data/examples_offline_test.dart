import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';

class _NoNetworkHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError(
        'Network access is not allowed in offline examples tests.');
  }
}

class _AssetBundleHarness {
  _AssetBundleHarness({
    this.overrides = const {},
    this.missingAssets = const {},
  });

  final Map<String, String> overrides;
  final Set<String> missingAssets;
  final List<String> requestedAssetKeys = <String>[];

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) {
        return null;
      }

      final key = utf8.decode(message.buffer.asUint8List());
      requestedAssetKeys.add(key);

      if (missingAssets.contains(key)) {
        return null;
      }

      final overridden = overrides[key];
      if (overridden != null) {
        return ByteData.sublistView(
            Uint8List.fromList(utf8.encode(overridden)));
      }

      final assetFile = File(key);
      if (!assetFile.existsSync()) {
        return null;
      }

      final bytes = assetFile.readAsBytesSync();
      return ByteData.sublistView(Uint8List.fromList(bytes));
    });
  }

  void dispose() {
    for (final key in requestedAssetKeys.toSet()) {
      rootBundle.evict(key);
    }
    requestedAssetKeys.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  }
}

Future<T> _runOffline<T>(Future<T> Function() action) {
  return HttpOverrides.runWithHttpOverrides(
    action,
    _NoNetworkHttpOverrides(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline examples library', () {
    _AssetBundleHarness? harness;

    tearDown(() {
      harness?.dispose();
      harness = null;
    });

    test('loads bundled examples without network access', () async {
      final categories = await _runOffline(() async {
        harness = _AssetBundleHarness();
        harness!.install();
        final dataSource = ExamplesAssetDataSource();
        final fsa = await dataSource.loadAllTypedFsaExamples();
        final cfg = await dataSource.loadAllTypedCfgExamples();
        final pda = await dataSource.loadAllTypedPdaExamples();
        final tm = await dataSource.loadAllTypedTmExamples();
        final regex = await dataSource.loadAllTypedRegexExamples();

        expect(fsa.isSuccess, isTrue, reason: fsa.error);
        expect(cfg.isSuccess, isTrue, reason: cfg.error);
        expect(pda.isSuccess, isTrue, reason: pda.error);
        expect(tm.isSuccess, isTrue, reason: tm.error);
        expect(regex.isSuccess, isTrue, reason: regex.error);

        expect(fsa.data, hasLength(5));
        expect(cfg.data, hasLength(5));
        expect(pda.data, hasLength(5));
        expect(tm.data, hasLength(10));
        expect(regex.data, hasLength(5));

        return {
          ...fsa.data!.map((example) => example.category),
          ...cfg.data!.map((example) => example.category),
          ...pda.data!.map((example) => example.category),
          ...tm.data!.map((example) => example.category),
          ...regex.data!.map((example) => example.category),
        };
      });

      expect(
        categories,
        equals({
          ExampleCategory.dfa,
          ExampleCategory.nfa,
          ExampleCategory.cfg,
          ExampleCategory.pda,
          ExampleCategory.tm,
          ExampleCategory.regex,
        }),
      );
      expect(
        harness!.requestedAssetKeys.every(
          (key) => key.startsWith('assets/examples/'),
        ),
        isTrue,
      );
    });

    test('reports missing bundled asset failures', () async {
      final result = await _runOffline(() async {
        harness = _AssetBundleHarness(
          missingAssets: const {'assets/examples/afd_ends_with_a.json'},
        );
        harness!.install();
        return ExamplesAssetDataSource().loadTypedFsaExample(
          'AFD - Termina com A',
        );
      });

      expect(result.isFailure, isTrue);
      expect(result.error, contains('asset not found'));
    });

    test('propagates malformed asset data through the data source', () async {
      final result = await _runOffline(() async {
        harness = _AssetBundleHarness(
          overrides: const {
            'assets/examples/afd_ends_with_a.json': '{"states": "bad"}',
          },
        );
        harness!.install();

        final dataSource = ExamplesAssetDataSource();
        return dataSource.loadTypedFsaExample('AFD - Termina com A');
      });

      expect(result.isFailure, isTrue);
      expect(result.error, contains('must define states as a list'));
    });

    test('returns expected examples for every bundled category', () async {
      await _runOffline(() async {
        harness = _AssetBundleHarness();
        harness!.install();

        final dataSource = ExamplesAssetDataSource();
        final fsa = await dataSource.loadAllTypedFsaExamples();
        final cfg = await dataSource.loadAllTypedCfgExamples();
        final pda = await dataSource.loadAllTypedPdaExamples();
        final tm = await dataSource.loadAllTypedTmExamples();
        final regex = await dataSource.loadAllTypedRegexExamples();

        expect(fsa.isSuccess, isTrue, reason: fsa.error);
        expect(cfg.isSuccess, isTrue, reason: cfg.error);
        expect(pda.isSuccess, isTrue, reason: pda.error);
        expect(tm.isSuccess, isTrue, reason: tm.error);
        expect(regex.isSuccess, isTrue, reason: regex.error);

        expect(
          fsa.data!.where((example) => example.category == ExampleCategory.dfa),
          hasLength(4),
        );
        expect(
          fsa.data!.where((example) => example.category == ExampleCategory.nfa),
          hasLength(1),
        );
        expect(
          cfg.data!.every((example) => example.category == ExampleCategory.cfg),
          isTrue,
        );
        expect(
          pda.data!.every((example) => example.category == ExampleCategory.pda),
          isTrue,
        );
        expect(
          tm.data!.every((example) => example.category == ExampleCategory.tm),
          isTrue,
        );
        expect(
          regex.data!
              .every((example) => example.category == ExampleCategory.regex),
          isTrue,
        );
      });
    });
  });
}
