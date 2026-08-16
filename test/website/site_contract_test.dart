import 'dart:io';

import 'package:test/test.dart';

void main() {
  const legacyProductName = 'J' 'Flutter';
  const legacyRepositorySlug = 'j' 'flutter';
  final docsDirectory = Directory('docs');
  late String index;
  late String support;
  late String privacy;

  setUpAll(() {
    index = File('${docsDirectory.path}/index.html').readAsStringSync();
    support = File('${docsDirectory.path}/support.html').readAsStringSync();
    privacy = File('${docsDirectory.path}/privacy.html').readAsStringSync();
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
      contains('Apple and Android builds are currently under testing.'),
    );

    for (final workspace in <String>[
      'Finite-state automata',
      'Context-free grammars',
      'Pushdown automata',
      'Turing machines',
      'Regular expressions',
      'Pumping lemma',
    ]) {
      expect(index, contains(workspace), reason: 'Missing $workspace');
    }

    for (final platform in <String>[
      'iOS and iPadOS',
      'macOS',
      'Android',
      'Web',
      'Windows',
      'Linux',
    ]) {
      expect(index, contains(platform), reason: 'Missing $platform');
    }

    expect(
      RegExp(
        r'<span class="status status-testing">Testing</span>',
      ).allMatches(index),
      hasLength(3),
    );
    expect(
      RegExp(
        r'<span class="status status-experimental">Experimental</span>',
      ).allMatches(index),
      hasLength(3),
    );
    expect(index, isNot(contains(legacyProductName)));
    expect(index, isNot(contains('<script')));
  });

  test('exposes semantic metadata and accessible image contracts', () {
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
        '<meta property="og:image" '
        'content="https://thalesmms.github.io/Turing-Lab/'
        'assets/social-preview.png">',
      ),
    );
    expect(
      index,
      contains(
        '<a class="skip-link" href="#main-content">Skip to content</a>',
      ),
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

    for (final screenshot in <String>['grammar.webp', 'tm.webp']) {
      expect(
        index,
        matches(RegExp('<img[^>]+$screenshot[^>]+loading="lazy"')),
        reason: '$screenshot must be loaded lazily',
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
      expect(
        html,
        isNot(contains('thalesmms.github.io/$legacyProductName')),
      );
      expect(
        html,
        isNot(contains('github.com/ThalesMMS/$legacyRepositorySlug')),
      );
    }

    expect(
      support,
      contains('https://github.com/ThalesMMS/Turing-Lab/issues'),
    );
    expect(
      support,
      contains('https://github.com/ThalesMMS/Turing-Lab#readme'),
    );
    expect(
      privacy,
      contains(
        'https://thalesmms.github.io/Turing-Lab/APP_PRIVACY_APPLE.md',
      ),
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
