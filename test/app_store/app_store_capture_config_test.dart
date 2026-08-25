//
//  app_store_capture_config_test.dart
//  Turing Lab
//
//  Unit coverage for the App Store capture configuration: the profile and
//  screen catalogue, slot filenames, CLI selection, the run manifest, and the
//  dimension/naming/completeness/duplicate validation applied to a capture
//  directory. The image matrix itself never runs here.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/app_store/app_store_capture_case.dart';
import '../../tool/app_store/app_store_capture_manifest.dart';
import '../../tool/app_store/app_store_capture_manifest_entry.dart';
import '../../tool/app_store/app_store_capture_matrix.dart';
import '../../tool/app_store/app_store_capture_options.dart';
import '../../tool/app_store/app_store_capture_validation_issue.dart';
import '../../tool/app_store/app_store_capture_validator.dart';
import '../../tool/app_store/app_store_png_size.dart';

/// Filenames the release-approved matrix is contracted to produce.
const _approvedPaths = <String>[
  'iphone-6.9/01-fsa.png',
  'iphone-6.9/02-grammar.png',
  'iphone-6.9/03-pda.png',
  'iphone-6.9/04-tm.png',
  'iphone-6.9/05-regex.png',
  'iphone-6.5/01-fsa.png',
  'iphone-6.5/02-grammar.png',
  'iphone-6.5/03-pda.png',
  'iphone-6.5/04-tm.png',
  'iphone-6.5/05-regex.png',
  'iphone-5.5/01-fsa.png',
  'iphone-5.5/02-grammar.png',
  'iphone-5.5/03-pda.png',
  'iphone-5.5/04-tm.png',
  'iphone-5.5/05-regex.png',
  'ipad-13/01-fsa.png',
  'ipad-13/02-grammar.png',
  'ipad-13/03-pda.png',
  'ipad-13/04-tm.png',
  'ipad-13/05-regex.png',
  'macos/01-fsa.png',
  'macos/02-grammar.png',
  'macos/03-pda.png',
  'macos/04-tm.png',
  'macos/05-regex.png',
];

void main() {
  group('capture matrix', () {
    test('profiles declare unique ids and usable geometry', () {
      final ids = <String>{};
      for (final profile in AppStoreCaptureMatrix.profiles) {
        expect(ids.add(profile.id), isTrue, reason: 'duplicate ${profile.id}');
        expect(profile.pixelWidth, greaterThan(0));
        expect(profile.pixelHeight, greaterThan(0));
        expect(profile.devicePixelRatio, greaterThan(0));
        expect(
          (profile.logicalWidth * profile.devicePixelRatio).round(),
          equals(profile.pixelWidth),
        );
        expect(
          (profile.logicalHeight * profile.devicePixelRatio).round(),
          equals(profile.pixelHeight),
        );
      }
    });

    test('screens occupy contiguous one-based slots', () {
      final slots = AppStoreCaptureMatrix.screens
          .map((screen) => screen.slot)
          .toList()
        ..sort();
      expect(
        slots,
        equals(List<int>.generate(slots.length, (index) => index + 1)),
      );
      for (final screen in AppStoreCaptureMatrix.screens) {
        expect(screen.fileStem, matches(RegExp(r'^\d{2}-[a-z0-9]+$')));
      }
    });

    test('the approved matrix is exactly the tracked screenshot set', () {
      final approved = AppStoreCaptureMatrix.approvedCases();
      expect(approved, hasLength(_approvedPaths.length));
      expect(
        approved.map((item) => item.relativePath).toList(),
        equals(_approvedPaths),
      );
      expect(approved.every((item) => item.isApproved), isTrue);
    });

    test('slot filenames stay unique across the whole matrix', () {
      final everyCase = AppStoreCaptureMatrix.resolve(
        localeCodes: AppStoreCaptureMatrix.locales,
        themeIds: AppStoreCaptureMatrix.themes,
      );
      final paths = everyCase.map((item) => item.relativePath).toSet();
      expect(paths, hasLength(everyCase.length));
    });

    test('non-default locale and theme get suffixed filenames', () {
      final variants = AppStoreCaptureMatrix.resolve(
        profileIds: const ['macos'],
        screenIds: const ['regex'],
        localeCodes: const ['en', 'pt'],
        themeIds: const ['light', 'dark'],
      ).map((item) => item.relativePath);

      expect(
        variants,
        equals(<String>[
          'macos/05-regex.png',
          'macos/05-regex-dark.png',
          'macos/05-regex-pt.png',
          'macos/05-regex-pt-dark.png',
        ]),
      );
    });

    test('screens resolve through id, file stem and aliases', () {
      expect(AppStoreCaptureMatrix.screenById('fsa').slot, equals(1));
      expect(AppStoreCaptureMatrix.screenById('01-fsa').id, equals('fsa'));
      expect(AppStoreCaptureMatrix.screenById('fsa-editor').id, equals('fsa'));
      expect(AppStoreCaptureMatrix.screenById('TM').id, equals('tm'));
    });

    test('unknown identifiers list the valid values', () {
      expect(
        () => AppStoreCaptureMatrix.profileById('iphone-99'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message.toString(),
            'message',
            allOf(contains('iphone-99'), contains('ipad-13')),
          ),
        ),
      );
      expect(
        () => AppStoreCaptureMatrix.screenById('lexer'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AppStoreCaptureMatrix.localeById('de'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AppStoreCaptureMatrix.themeById('sepia'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('omitted dimensions fall back to the release defaults', () {
      final selected = AppStoreCaptureMatrix.resolve(
        profileIds: const ['iphone-6.9'],
        screenIds: const ['grammar'],
      );
      expect(selected, hasLength(1));
      expect(selected.single.locale, equals(AppStoreCaptureCase.defaultLocale));
      expect(selected.single.theme, equals(AppStoreCaptureCase.defaultTheme));
      expect(selected.single.relativePath, equals('iphone-6.9/02-grammar.png'));
    });

    test('repeated selectors are de-duplicated', () {
      final selected = AppStoreCaptureMatrix.resolve(
        profileIds: const ['macos', 'macos'],
        screenIds: const ['pda', '03-pda'],
      );
      expect(selected, hasLength(1));
    });
  });

  group('capture options', () {
    test('parses a single named capture', () {
      final options = AppStoreCaptureOptions.parse(const [
        '--profile',
        'iphone-6.9',
        '--screen',
        'fsa-editor',
        '--locale',
        'en',
        '--output',
        'build/screenshots/candidate',
      ]);

      expect(options.command, equals('run'));
      expect(options.outputDir, equals('build/screenshots/candidate'));
      final cases = options.resolveCases();
      expect(cases, hasLength(1));
      expect(cases.single.relativePath, equals('iphone-6.9/01-fsa.png'));
      expect(options.coversApprovedMatrix, isFalse);
    });

    test('--all resolves the complete approved matrix', () {
      final options = AppStoreCaptureOptions.parse(const ['--all']);
      expect(options.resolveCases(), hasLength(_approvedPaths.length));
      expect(options.coversApprovedMatrix, isTrue);
      expect(
        options.outputDir,
        equals(AppStoreCaptureMatrix.approvedOutputDir),
      );
    });

    test('defaults keep the release-approved output directory', () {
      final options = AppStoreCaptureOptions.parse(const <String>[]);
      expect(
        options.outputDir,
        equals(AppStoreCaptureMatrix.approvedOutputDir),
      );
      expect(options.bestEffort, isFalse);
      expect(options.runValidation, isTrue);
      expect(
        options.timeoutSeconds,
        equals(AppStoreCaptureOptions.defaultTimeoutSeconds),
      );
    });

    test('rejects combining --all with explicit selectors', () {
      expect(
        () => AppStoreCaptureOptions.parse(const [
          '--all',
          '--profile',
          'macos',
        ]),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects unknown flags, commands, values and identifiers', () {
      expect(
        () => AppStoreCaptureOptions.parse(const ['--sizes']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppStoreCaptureOptions.parse(const ['capture']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppStoreCaptureOptions.parse(const ['--timeout', 'soon']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppStoreCaptureOptions.parse(const ['--output']),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppStoreCaptureOptions.parse(const ['--profile', 'pixel-9']),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('help is parsed without resolving a matrix', () {
      final options = AppStoreCaptureOptions.parse(const ['--help']);
      expect(options.help, isTrue);
      expect(AppStoreCaptureOptions.usage, contains('--best-effort'));
      expect(AppStoreCaptureOptions.usage, contains('--output'));
    });
  });

  group('capture manifest', () {
    late Directory outputDir;

    setUp(() {
      outputDir = Directory.systemTemp.createTempSync('app-store-manifest');
    });

    tearDown(() {
      if (outputDir.existsSync()) {
        outputDir.deleteSync(recursive: true);
      }
    });

    test('parts are drained, merged and written in a stable order', () {
      final cases = AppStoreCaptureMatrix.resolve(
        profileIds: const ['macos'],
        screenIds: const ['regex', 'fsa'],
      );
      for (final captureCase in cases) {
        AppStoreCaptureManifest.writePart(
          outputDir,
          AppStoreCaptureManifestEntry.forCase(
            captureCase,
            revision: 'abc1234',
            capturedAt: '2026-08-24T12:00:00.000Z',
            status: AppStoreCaptureManifestEntry.statusCaptured,
          ),
        );
      }

      final drained = AppStoreCaptureManifest.drainParts(outputDir);
      expect(drained, hasLength(2));
      expect(
        Directory(
          '${outputDir.path}/${AppStoreCaptureManifest.partsDirName}',
        ).existsSync(),
        isFalse,
      );

      AppStoreCaptureManifest.read(outputDir)
          .merge(drained)
          .write(outputDir, generator: 'test');

      final reloaded = AppStoreCaptureManifest.read(outputDir);
      expect(
        reloaded.entries.map((entry) => entry.path),
        equals(<String>['macos/01-fsa.png', 'macos/05-regex.png']),
      );
      final entry = reloaded.entryForPath('macos/01-fsa.png')!;
      expect(entry.profile, equals('macos'));
      expect(entry.slot, equals(1));
      expect(entry.pixelWidth, equals(2880));
      expect(entry.pixelHeight, equals(1800));
      expect(entry.revision, equals('abc1234'));
      expect(entry.approved, isTrue);
      expect(entry.isCaptured, isTrue);
    });

    test('a rerun replaces the row for the same slot', () {
      final captureCase = AppStoreCaptureMatrix.resolve(
        profileIds: const ['ipad-13'],
        screenIds: const ['tm'],
      ).single;

      AppStoreCaptureManifest(<AppStoreCaptureManifestEntry>[
        AppStoreCaptureManifestEntry.forCase(
          captureCase,
          revision: 'old',
          capturedAt: '2026-08-01T00:00:00.000Z',
          status: AppStoreCaptureManifestEntry.statusFailed,
          failure: 'prepare: timeout',
        ),
      ]).write(outputDir, generator: 'test');

      AppStoreCaptureManifest.read(outputDir).merge(
        <AppStoreCaptureManifestEntry>[
          AppStoreCaptureManifestEntry.forCase(
            captureCase,
            revision: 'new',
            capturedAt: '2026-08-24T00:00:00.000Z',
            status: AppStoreCaptureManifestEntry.statusCaptured,
          ),
        ],
      ).write(outputDir, generator: 'test');

      final reloaded = AppStoreCaptureManifest.read(outputDir);
      expect(reloaded.entries, hasLength(1));
      expect(reloaded.entries.single.revision, equals('new'));
      expect(reloaded.entries.single.failure, isNull);
    });

    test('the manifest is machine readable JSON', () {
      AppStoreCaptureManifest(<AppStoreCaptureManifestEntry>[
        AppStoreCaptureManifestEntry.forCase(
          AppStoreCaptureMatrix.approvedCases().first,
          revision: 'abc1234',
          capturedAt: '2026-08-24T12:00:00.000Z',
          status: AppStoreCaptureManifestEntry.statusCaptured,
        ),
      ]).write(outputDir, generator: 'tool/capture');

      final decoded = jsonDecode(
        File(
          '${outputDir.path}/${AppStoreCaptureManifest.fileName}',
        ).readAsStringSync(),
      ) as Map<String, Object?>;

      expect(
        decoded['schemaVersion'],
        equals(AppStoreCaptureManifest.schemaVersion),
      );
      expect(decoded['generator'], equals('tool/capture'));
      expect(decoded['captures'], isA<List<Object?>>());
    });
  });

  group('png dimensions', () {
    test('reads the IHDR size', () {
      final file = File(
        '${Directory.systemTemp.createTempSync('app-store-png').path}/a.png',
      )..writeAsBytesSync(_fakePng(1320, 2868));
      addTearDown(() => file.parent.deleteSync(recursive: true));

      final size = AppStorePngSize.read(file);
      expect(size.width, equals(1320));
      expect(size.height, equals(2868));
      expect(size.toString(), equals('1320x2868'));
    });

    test('rejects files that are not PNGs', () {
      final file = File(
        '${Directory.systemTemp.createTempSync('app-store-png').path}/a.png',
      )..writeAsBytesSync(Uint8List(64));
      addTearDown(() => file.parent.deleteSync(recursive: true));

      expect(() => AppStorePngSize.read(file), throwsFormatException);
    });
  });

  group('capture validation', () {
    late Directory outputDir;
    late List<AppStoreCaptureCase> cases;

    setUp(() {
      outputDir = Directory.systemTemp.createTempSync('app-store-validate');
      cases = AppStoreCaptureMatrix.resolve(
        profileIds: const ['macos'],
        screenIds: const ['fsa', 'grammar'],
      );
    });

    tearDown(() {
      if (outputDir.existsSync()) {
        outputDir.deleteSync(recursive: true);
      }
    });

    void writeCapture(
      AppStoreCaptureCase captureCase, {
      int? width,
      int? height,
      List<int> tail = const <int>[],
    }) {
      final file = File('${outputDir.path}/${captureCase.relativePath}');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(
        _fakePng(
          width ?? captureCase.profile.pixelWidth,
          height ?? captureCase.profile.pixelHeight,
          tail: tail,
        ),
      );
    }

    void writeManifest(
      List<AppStoreCaptureCase> entries, {
      String status = AppStoreCaptureManifestEntry.statusCaptured,
    }) {
      AppStoreCaptureManifest(
        entries
            .map(
              (captureCase) => AppStoreCaptureManifestEntry.forCase(
                captureCase,
                revision: 'abc1234',
                capturedAt: '2026-08-24T12:00:00.000Z',
                status: status,
                failure: status == AppStoreCaptureManifestEntry.statusFailed
                    ? 'prepare: bounded wait exhausted'
                    : null,
              ),
            )
            .toList(),
      ).write(outputDir, generator: 'test');
    }

    List<AppStoreCaptureValidationIssue> validate({bool strict = true}) {
      return AppStoreCaptureValidator(
        outputDir: outputDir,
        cases: cases,
        strict: strict,
      ).validate();
    }

    test('accepts a complete, correctly sized, uniquely rendered set', () {
      writeCapture(cases[0], tail: const <int>[1, 2, 3]);
      writeCapture(cases[1], tail: const <int>[4, 5, 6]);
      writeManifest(cases);

      expect(validate(), isEmpty);
    });

    test('reports missing slots', () {
      writeCapture(cases[0], tail: const <int>[1]);
      writeManifest(<AppStoreCaptureCase>[cases[0]]);

      final issues = validate();
      expect(issues, hasLength(1));
      expect(
        issues.single.kind,
        equals(AppStoreCaptureValidationIssue.missingSlot),
      );
      expect(issues.single.path, equals(cases[1].relativePath));
    });

    test('reports wrong pixel dimensions', () {
      writeCapture(cases[0], width: 1280, height: 800, tail: const <int>[1]);
      writeCapture(cases[1], tail: const <int>[2]);
      writeManifest(cases);

      final issues = validate();
      expect(
        issues.map((issue) => issue.kind),
        contains(AppStoreCaptureValidationIssue.dimensionMismatch),
      );
      expect(
        issues
            .firstWhere(
              (issue) =>
                  issue.kind ==
                  AppStoreCaptureValidationIssue.dimensionMismatch,
            )
            .message,
        contains('2880x1800'),
      );
    });

    test('reports byte-identical slots', () {
      writeCapture(cases[0]);
      writeCapture(cases[1]);
      writeManifest(cases);

      expect(
        validate().map((issue) => issue.kind),
        contains(AppStoreCaptureValidationIssue.duplicateContent),
      );
    });

    test('reports unexpected files and invalid names', () {
      writeCapture(cases[0], tail: const <int>[1]);
      writeCapture(cases[1], tail: const <int>[2]);
      writeManifest(cases);
      File('${outputDir.path}/macos/99-unknown.png')
          .writeAsBytesSync(_fakePng(2880, 1800, tail: const <int>[3]));
      File('${outputDir.path}/macos/draft.txt').writeAsStringSync('scratch');

      final kinds = validate().map((issue) => issue.kind).toList();
      expect(kinds, contains(AppStoreCaptureValidationIssue.unexpectedFile));
      expect(kinds, contains(AppStoreCaptureValidationIssue.invalidName));
    });

    test('a partial rerun ignores files outside the selection', () {
      writeCapture(cases[0], tail: const <int>[1]);
      writeManifest(<AppStoreCaptureCase>[cases[0]]);
      File('${outputDir.path}/macos/draft.txt').writeAsStringSync('scratch');
      cases = <AppStoreCaptureCase>[cases[0]];

      expect(validate(strict: false), isEmpty);
    });

    test('reports manifest gaps and failed captures', () {
      writeCapture(cases[0], tail: const <int>[1]);
      writeCapture(cases[1], tail: const <int>[2]);
      writeManifest(<AppStoreCaptureCase>[cases[1]],
          status: AppStoreCaptureManifestEntry.statusFailed);

      final kinds = validate().map((issue) => issue.kind).toList();
      expect(
        kinds,
        contains(AppStoreCaptureValidationIssue.manifestMissingEntry),
      );
      expect(kinds, contains(AppStoreCaptureValidationIssue.captureFailed));
    });

    test('keeps release notes next to the approved captures', () {
      writeCapture(cases[0], tail: const <int>[1]);
      writeCapture(cases[1], tail: const <int>[2]);
      writeManifest(cases);
      File('${outputDir.path}/APP_STORE_CONNECT_MAPPING.md')
          .writeAsStringSync('# mapping');

      expect(validate(), isEmpty);
    });
  });

  group('default test discovery', () {
    test('only the configuration tests are discovered under test/app_store',
        () {
      final discovered = Directory('test/app_store')
          .listSync()
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .where((name) => name.endsWith('_test.dart'))
          .toList()
        ..sort();

      expect(
        discovered,
        equals(<String>[
          'app_store_capture_config_test.dart',
          'app_store_field_entry_test.dart',
        ]),
      );
    });

    test('the capture matrix entry point is never discovered', () {
      expect(
        File('test/app_store/app_store_capture_runner.dart').existsSync(),
        isTrue,
      );
      expect(
        File('test/app_store_screenshots_test.dart').existsSync(),
        isFalse,
        reason: 'the legacy discovered capture matrix must stay removed',
      );
    });
  });
}

/// Builds the smallest byte sequence the dimension reader accepts, with an
/// optional [tail] so two fixtures can differ without changing their size.
Uint8List _fakePng(int width, int height, {List<int> tail = const <int>[]}) {
  final header = ByteData(16)
    ..setUint32(0, 13)
    ..setUint32(4, 0x49484452)
    ..setUint32(8, width)
    ..setUint32(12, height);
  return Uint8List.fromList(<int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...header.buffer.asUint8List(),
    ...tail,
  ]);
}
