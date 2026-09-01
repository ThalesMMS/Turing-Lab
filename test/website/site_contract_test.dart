import 'dart:io';

import 'package:test/test.dart';

void main() {
  const legacyProductName =
      'J'
      'Flutter';
  const legacyRepositorySlug =
      'j'
      'flutter';
  final docsDirectory = Directory('docs');
  late String index;
  late String support;
  late String privacy;
  late String stylesheet;

  setUpAll(() {
    index = File('${docsDirectory.path}/index.html').readAsStringSync();
    support = File('${docsDirectory.path}/support.html').readAsStringSync();
    privacy = File('${docsDirectory.path}/privacy.html').readAsStringSync();
    stylesheet = File(
      '${docsDirectory.path}/assets/site.css',
    ).readAsStringSync();
  });

  test('publishes the approved technical scope and platform maturity', () {
    expect(
      index,
      contains(
        'A Flutter-based toolkit for constructing, transforming, and '
        'simulating formal language models.',
      ),
    );
    expect(
      index,
      contains(
        'Apple and Android distribution validation remains in progress, '
        'and the web app is published here.',
      ),
    );

    for (final workspace in <String>[
      'Finite-state automata',
      'Context-free grammars',
      'Unrestricted grammars',
      'Pushdown automata',
      'Turing machines',
      'Regular expressions',
      'Pumping lemma',
      'Mealy and Moore',
      'L-systems',
    ]) {
      expect(index, contains(workspace), reason: 'Missing $workspace');
    }

    for (final entry in <String, (String, String)>{
      'iOS and iPadOS': ('Testing', 'testing'),
      'macOS': ('Testing', 'testing'),
      'Android': ('Testing', 'testing'),
      'Web': ('Published', 'testing'),
      'Windows': ('Experimental', 'experimental'),
      'Linux': ('Experimental', 'experimental'),
    }.entries) {
      final (status, statusClass) = entry.value;
      expect(
        index,
        contains(
          '<tr><th scope="row">${entry.key}</th><td>'
          '<span class="status status-$statusClass">$status</span>'
          '</td></tr>',
        ),
        reason: 'Incorrect status for ${entry.key}',
      );
    }

    expect(
      RegExp(r'<span class="status status-testing">').allMatches(index),
      hasLength(4),
    );
    expect(
      RegExp(
        r'<span class="status status-experimental">Experimental</span>',
      ).allMatches(index),
      hasLength(2),
    );
    expect(index, isNot(contains(legacyProductName)));
    expect(index, isNot(contains('<script')));
  });

  test('exposes semantic metadata and accessible image contracts', () {
    expect(
      index,
      contains(
        '<title>Turing Lab | Formal Language and Automata Toolkit</title>',
      ),
    );
    expect(
      index,
      contains(
        '<meta name="description" content="Turing Lab is a Flutter environment '
        'for formal languages, automata, grammars, transducers, Turing '
        'machines, and L-systems.">',
      ),
    );
    expect(
      index,
      contains(
        '<link rel="canonical" '
        'href="https://thalesmms.github.io/Turing-Lab/">',
      ),
    );
    expect(
      index,
      contains(
        '<meta property="og:title" '
        'content="Turing Lab | Formal Language and Automata Toolkit">',
      ),
    );
    expect(
      index,
      contains(
        '<meta property="og:description" content="A Flutter-based toolkit '
        'for constructing, transforming, and simulating formal language '
        'models.">',
      ),
    );
    expect(
      index,
      contains(
        '<meta property="og:url" '
        'content="https://thalesmms.github.io/Turing-Lab/">',
      ),
    );
    expect(
      index,
      contains(
        '<meta property="og:image" '
        'content="https://thalesmms.github.io/Turing-Lab/'
        'assets/social-preview.png">',
      ),
    );
    expect(
      index,
      contains('<link rel="icon" type="image/png" href="assets/favicon.png">'),
    );
    expect(index, contains('<link rel="stylesheet" href="assets/site.css">'));
    expect(index, contains('<a href="#overview">Overview</a>'));
    expect(stylesheet, contains('--focus: #0070c0;'));
    expect(stylesheet, contains('--focus: #efb83f;'));
    expect(
      index,
      contains('<a class="skip-link" href="#main-content">Skip to content</a>'),
    );
    expect(RegExp(r'<main\b').allMatches(index), hasLength(1));
    expect(RegExp(r'<h1\b').allMatches(index), hasLength(1));

    final images = RegExp(
      r'<img\b[^>]*>',
    ).allMatches(index).map((match) => match.group(0)!);
    expect(images, isNotEmpty);
    for (final image in images) {
      expect(image, matches(RegExp(r'''\balt=["'][^"']+["']''')));
      expect(image, matches(RegExp(r'''\bwidth=["']\d+["']''')));
      expect(image, matches(RegExp(r'''\bheight=["']\d+["']''')));
    }

    // Every workspace screenshot ships with the site, appears in the gallery,
    // and loads lazily. Only the hero image above the fold is eager.
    final screenshots =
        Directory('${docsDirectory.path}/assets/screenshots')
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => name.endsWith('.webp'))
            .toList()
          ..sort();
    expect(screenshots, isNotEmpty);
    for (final screenshot in screenshots) {
      expect(
        index,
        matches(RegExp('<img[^>]+$screenshot[^>]+loading="lazy"')),
        reason: '$screenshot must appear in the gallery and load lazily',
      );
    }
  });

  test('keeps runtime resources local and every relative target present', () {
    final sourcePattern = RegExp(r'''\bsrc=["']([^"']+)["']''');
    for (final match in sourcePattern.allMatches(index)) {
      final source = match.group(1)!;
      expect(
        source,
        isNot(startsWith('http://')),
        reason: 'Remote runtime resource: $source',
      );
      expect(
        source,
        isNot(startsWith('https://')),
        reason: 'Remote runtime resource: $source',
      );
    }

    for (final target in _localTargets(index)) {
      expect(
        File('${docsDirectory.path}/$target').existsSync(),
        isTrue,
        reason: 'Missing local target: $target',
      );
    }
  });

  test('uses canonical project links across public pages', () {
    for (final html in <String>[index, support, privacy]) {
      expect(html, isNot(contains('thalesmms.github.io/$legacyProductName')));
      expect(
        html,
        isNot(contains('github.com/ThalesMMS/$legacyRepositorySlug')),
      );
    }

    expect(support, contains('https://github.com/ThalesMMS/Turing-Lab/issues'));
    expect(support, contains('https://github.com/ThalesMMS/Turing-Lab#readme'));
    expect(
      privacy,
      contains('https://thalesmms.github.io/Turing-Lab/APP_PRIVACY_APPLE.md'),
    );
  });
}

Iterable<String> _localTargets(String html) sync* {
  final attributePattern = RegExp(r'''(?:href|src)=["']([^"']+)["']''');
  for (final match in attributePattern.allMatches(html)) {
    final target = match.group(1)!;
    if (target.startsWith('#') ||
        target.startsWith('https://') ||
        target.startsWith('mailto:')) {
      continue;
    }
    yield target.split('#').first.split('?').first;
  }
}
