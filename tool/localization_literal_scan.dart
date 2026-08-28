import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:crypto/crypto.dart';

enum LocalizationLiteralClassification {
  localizedUserFacing,
  deliberateNotationOrAcronym,
  fixtureOrExample,
  debugOrInternal,
  approvedPlatformConstant,
  unapprovedUserFacing,
}

class LocalizationLiteralAllowance {
  const LocalizationLiteralAllowance({
    required this.path,
    required this.literal,
    required this.classification,
    required this.rationale,
    this.maxOccurrences = 1,
  });

  final String path;
  final String literal;
  final LocalizationLiteralClassification classification;
  final String rationale;
  final int maxOccurrences;

  factory LocalizationLiteralAllowance.fromJson(Map<String, Object?> json) {
    return LocalizationLiteralAllowance(
      path: json['path']! as String,
      literal: json['literal']! as String,
      classification: LocalizationLiteralClassification.values.byName(
        json['classification']! as String,
      ),
      rationale: json['rationale']! as String,
      maxOccurrences: json['maxOccurrences'] as int? ?? 1,
    );
  }
}

class LocalizationLiteralFinding {
  const LocalizationLiteralFinding({
    required this.path,
    required this.line,
    required this.literal,
    required this.classification,
    required this.rationale,
  });

  final String path;
  final int line;
  final String literal;
  final LocalizationLiteralClassification classification;
  final String rationale;

  bool get isViolation =>
      classification == LocalizationLiteralClassification.unapprovedUserFacing;

  Map<String, Object> toJson() => {
    'path': path,
    'line': line,
    'literal': literal,
    'classification': classification.name,
    'rationale': rationale,
  };
}

class LocalizationLiteralInventoryEntry {
  const LocalizationLiteralInventoryEntry({
    required this.path,
    required this.sourceDigestSha256,
    required this.violationDigestSha256,
    required this.violationCount,
  });

  final String path;
  final String sourceDigestSha256;
  final String violationDigestSha256;
  final int violationCount;

  factory LocalizationLiteralInventoryEntry.fromJson(
    Map<String, Object?> json,
  ) {
    return LocalizationLiteralInventoryEntry(
      path: json['path']! as String,
      sourceDigestSha256: json['sourceDigestSha256']! as String,
      violationDigestSha256: json['violationDigestSha256']! as String,
      violationCount: json['violationCount']! as int,
    );
  }

  Map<String, Object> toJson() => {
    'path': path,
    'sourceDigestSha256': sourceDigestSha256,
    'violationDigestSha256': violationDigestSha256,
    'violationCount': violationCount,
  };
}

class LocalizationLiteralInventoryAudit {
  const LocalizationLiteralInventoryAudit({
    required this.knownLegacyPaths,
    required this.staleEntries,
    required this.unapprovedViolations,
  });

  final Set<String> knownLegacyPaths;
  final List<String> staleEntries;
  final List<LocalizationLiteralFinding> unapprovedViolations;
}

class LocalizationLiteralScanner {
  LocalizationLiteralScanner({
    Iterable<LocalizationLiteralAllowance> allowlist = const [],
  }) : _allowlist = List.unmodifiable(allowlist);

  final List<LocalizationLiteralAllowance> _allowlist;

  List<LocalizationLiteralFinding> scanSource({
    required String path,
    required String source,
  }) {
    final normalizedPath = path.replaceAll('\\', '/');
    final findings = <LocalizationLiteralFinding>[];
    final allowanceCounts = <LocalizationLiteralAllowance, int>{};
    final lines = source.split('\n');
    final parseResult = parseString(
      content: source,
      path: normalizedPath,
      throwIfDiagnostics: false,
    );
    if (parseResult.errors.isNotEmpty) {
      throw FormatException(
        'Cannot scan malformed Dart source $normalizedPath: '
        '${parseResult.errors.first.message}',
      );
    }
    final collector = _StringLiteralCollector(
      source: source,
      lineInfo: parseResult.lineInfo,
    );
    parseResult.unit.accept(collector);

    for (final token in collector.tokens) {
      final literal = token.literal;
      if (literal.isEmpty) continue;
      final allowance = _matchingAllowance(normalizedPath, literal);
      if (allowance != null) {
        final count = (allowanceCounts[allowance] ?? 0) + 1;
        allowanceCounts[allowance] = count;
        findings.add(
          LocalizationLiteralFinding(
            path: normalizedPath,
            line: token.line,
            literal: literal,
            classification: count <= allowance.maxOccurrences
                ? allowance.classification
                : LocalizationLiteralClassification.unapprovedUserFacing,
            rationale: count <= allowance.maxOccurrences
                ? allowance.rationale
                : 'Allowlisted literal exceeds maxOccurrences=${allowance.maxOccurrences}.',
          ),
        );
        continue;
      }
      final line = lines[token.line - 1];
      findings.add(
        _classify(
          path: normalizedPath,
          lineNumber: token.line,
          line: line,
          statementContext: token.context,
          literal: literal,
        ),
      );
    }
    return findings;
  }

  LocalizationLiteralAllowance? _matchingAllowance(
    String path,
    String literal,
  ) {
    for (final allowance in _allowlist) {
      if (allowance.path == path && allowance.literal == literal) {
        return allowance;
      }
    }
    return null;
  }

  LocalizationLiteralFinding _classify({
    required String path,
    required int lineNumber,
    required String line,
    required String statementContext,
    required String literal,
  }) {
    LocalizationLiteralClassification classification;
    String rationale;
    final trimmed = line.trimLeft();

    if (path.startsWith('test/') || path.contains('/fixtures/')) {
      classification = LocalizationLiteralClassification.fixtureOrExample;
      rationale = 'Test or fixture data is not shipped as interface copy.';
    } else if (_literalIsLocalizationArgument(statementContext)) {
      classification = LocalizationLiteralClassification.localizedUserFacing;
      rationale =
          'Literal is an identifier or input handled by localization code.';
    } else if (trimmed.startsWith('import ') ||
        trimmed.startsWith('export ') ||
        trimmed.startsWith('part ') ||
        statementContext.contains('ValueKey') ||
        statementContext.contains('Key(') ||
        statementContext.contains('debugLabel') ||
        statementContext.contains('RegExp(') ||
        _literalIsContainsArgument(statementContext) ||
        statementContext.contains('routeName') ||
        statementContext.contains('assetName') ||
        literal.contains('://') ||
        _looksLikeResourcePath(literal)) {
      classification = LocalizationLiteralClassification.debugOrInternal;
      rationale = 'Language, diagnostic, identity, or resource plumbing.';
    } else if (statementContext.contains('debugPrint') ||
        statementContext.contains('log(') ||
        RegExp(
          r'\b_?(?:log[A-Z][A-Za-z0-9_]*|[A-Za-z][A-Za-z0-9_]*Log)\s*\(',
        ).hasMatch(statementContext) ||
        statementContext.contains('assert(') ||
        statementContext.contains('ArgumentError') ||
        statementContext.contains('FormatException') ||
        statementContext.contains('StateError') ||
        statementContext.contains('UnsupportedError(')) {
      classification = LocalizationLiteralClassification.debugOrInternal;
      rationale = 'Diagnostic or developer-only statement.';
    } else if (_looksLikeNotation(literal)) {
      classification =
          LocalizationLiteralClassification.deliberateNotationOrAcronym;
      rationale = 'Formal notation, acronym, extension, or protocol token.';
    } else if (_looksUserFacing(statementContext, literal)) {
      classification = LocalizationLiteralClassification.unapprovedUserFacing;
      rationale =
          'Probable interface copy is not routed through AppLocalizations.';
    } else {
      classification = LocalizationLiteralClassification.debugOrInternal;
      rationale = 'Internal identifier or non-interface value.';
    }

    return LocalizationLiteralFinding(
      path: path,
      line: lineNumber,
      literal: literal,
      classification: classification,
      rationale: rationale,
    );
  }

  bool _looksLikeNotation(String literal) {
    if (!RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(literal)) return true;
    if (RegExp(
      r'^\$\{[^}\n]+\}\.[a-z0-9]{1,8}$',
      caseSensitive: false,
    ).hasMatch(literal)) {
      return true;
    }
    if (RegExp(r'^\.[a-z0-9]{1,8}$', caseSensitive: false).hasMatch(literal)) {
      return true;
    }
    if (!literal.contains(' ') &&
        literal.length <= 12 &&
        (literal.toUpperCase() == literal ||
            RegExp(r'^[a-z][a-z0-9]*[._-][a-z0-9._-]*$').hasMatch(literal) ||
            RegExp(r'^[a-z]+[0-9][a-z0-9]*$').hasMatch(literal))) {
      return true;
    }
    return false;
  }

  bool _looksLikeResourcePath(String literal) {
    if (RegExp(r'\s').hasMatch(literal)) return false;
    return RegExp(
      r'^(?:package:|assets[\\/]|[A-Za-z]:[\\/]|\.{0,2}[\\/])',
    ).hasMatch(literal);
  }

  bool _literalIsLocalizationArgument(String statementContext) {
    return RegExp(
      r'(?:localizeWorkflowText|_?l10n\.[A-Za-z0-9_]+)\s*\([^;]*$',
      multiLine: true,
    ).hasMatch(statementContext);
  }

  bool _literalIsContainsArgument(String statementContext) {
    return RegExp(
      r'\.contains\s*\([^;]*$',
      multiLine: true,
    ).hasMatch(statementContext);
  }

  bool _looksUserFacing(String line, String literal) {
    const markers = <String>[
      'Text(',
      'TextSpan(',
      'SelectableText(',
      'tooltip:',
      'label:',
      'labelText:',
      'hintText:',
      'helperText:',
      'errorText:',
      'semanticLabel:',
      'Semantics(',
      'SnackBar(',
      'AlertDialog(',
      'title:',
      'subtitle:',
      'message:',
      'fileName:',
    ];
    if (markers.any(line.contains)) return true;
    return literal.contains(' ') &&
        RegExp(r'[A-Za-zÀ-ÿ]{3}').hasMatch(literal) &&
        !literal.contains('/') &&
        !literal.contains('://');
  }
}

class _CollectedStringLiteral {
  const _CollectedStringLiteral({
    required this.literal,
    required this.line,
    required this.context,
  });

  final String literal;
  final int line;
  final String context;
}

class _StringLiteralCollector extends RecursiveAstVisitor<void> {
  _StringLiteralCollector({required this.source, required this.lineInfo});

  final String source;
  final LineInfo lineInfo;
  final List<_CollectedStringLiteral> tokens = <_CollectedStringLiteral>[];

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    _add(node, _valueOf(node));
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _add(node, node.value);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _add(node, _valueOf(node));
  }

  void _add(StringLiteral node, String literal) {
    tokens.add(
      _CollectedStringLiteral(
        literal: literal,
        line: lineInfo.getLocation(node.offset).lineNumber,
        context: _contextOf(node),
      ),
    );
  }

  String _contextOf(StringLiteral node) {
    AstNode? current = node.parent;
    while (current != null) {
      if (current is ArgumentList) {
        final invocation = current.parent ?? current;
        final argument = current.arguments.firstWhere(
          (candidate) =>
              candidate.offset <= node.offset && candidate.end >= node.end,
        );
        return source.substring(
              invocation.offset,
              current.leftParenthesis.end,
            ) +
            source.substring(argument.offset, argument.end);
      }
      if (current is AssertStatement || current is AssertInitializer) {
        return source.substring(
          current.offset,
          current.offset + current.length,
        );
      }
      current = current.parent;
    }
    return source.substring(node.offset, node.offset + node.length);
  }

  String _valueOf(StringLiteral node) {
    if (node.stringValue case final value?) return value;
    if (node is AdjacentStrings) {
      return node.strings.map(_valueOf).join();
    }
    if (node is StringInterpolation) {
      final buffer = StringBuffer();
      for (final element in node.elements) {
        if (element is InterpolationString) {
          buffer.write(element.value);
        } else {
          buffer.write(
            source.substring(element.offset, element.offset + element.length),
          );
        }
      }
      return buffer.toString();
    }
    return source.substring(node.offset, node.offset + node.length);
  }
}

List<String> discoverLocalizationScopeFiles(
  Directory root,
  Map<String, Object?> scope,
) {
  final paths = <String>{};
  final files = scope['files'];
  if (files != null) {
    if (files is! List<Object?> || files.any((value) => value is! String)) {
      throw const FormatException('scope.files must be a list of paths.');
    }
    paths.addAll(files.cast<String>().map(_normalizePath));
  }

  final roots = scope['roots'];
  if (roots != null) {
    if (roots is! List<Object?> || roots.any((value) => value is! String)) {
      throw const FormatException('scope.roots must be a list of paths.');
    }
    for (final relativeRoot in roots.cast<String>()) {
      final normalizedRoot = _normalizePath(relativeRoot);
      final directory = Directory.fromUri(root.uri.resolve('$normalizedRoot/'));
      if (!directory.existsSync()) {
        throw FormatException(
          'Scoped localization root does not exist: $normalizedRoot',
        );
      }
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          paths.add(_relativePath(root, entity));
        }
      }
    }
  }

  if (paths.isEmpty) {
    throw const FormatException(
      'Localization scope must declare at least one file or root.',
    );
  }
  return paths.toList()..sort();
}

List<LocalizationLiteralInventoryEntry> buildLocalizationLiteralInventory({
  required Map<String, String> sources,
  required List<LocalizationLiteralFinding> violations,
}) {
  final violationsByPath = <String, List<LocalizationLiteralFinding>>{};
  for (final violation in violations) {
    violationsByPath.putIfAbsent(violation.path, () => []).add(violation);
  }
  final entries = <LocalizationLiteralInventoryEntry>[];
  for (final entry in violationsByPath.entries) {
    final source = sources[entry.key];
    if (source == null) {
      throw StateError('Missing source for localization path ${entry.key}.');
    }
    entries.add(
      LocalizationLiteralInventoryEntry(
        path: entry.key,
        sourceDigestSha256: _digest(source),
        violationDigestSha256: _violationDigest(entry.value),
        violationCount: entry.value.length,
      ),
    );
  }
  entries.sort((left, right) => left.path.compareTo(right.path));
  return entries;
}

LocalizationLiteralInventoryAudit auditLocalizationLiteralInventory({
  required Map<String, String> sources,
  required List<LocalizationLiteralFinding> violations,
  required Iterable<LocalizationLiteralInventoryEntry> inventory,
}) {
  final violationsByPath = <String, List<LocalizationLiteralFinding>>{};
  for (final violation in violations) {
    violationsByPath.putIfAbsent(violation.path, () => []).add(violation);
  }
  final inventoryByPath = <String, LocalizationLiteralInventoryEntry>{};
  final staleEntries = <String>[];
  for (final entry in inventory) {
    if (inventoryByPath.containsKey(entry.path)) {
      staleEntries.add('Duplicate inventory entry: ${entry.path}');
    } else {
      inventoryByPath[entry.path] = entry;
    }
  }

  final knownLegacyPaths = <String>{};
  for (final entry in inventoryByPath.values) {
    final source = sources[entry.path];
    final pathViolations = violationsByPath[entry.path] ?? const [];
    if (source == null) {
      staleEntries.add(
        'Inventory path is outside the current scope: ${entry.path}',
      );
      continue;
    }
    if (_digest(source) != entry.sourceDigestSha256 ||
        pathViolations.length != entry.violationCount ||
        _violationDigest(pathViolations) != entry.violationDigestSha256) {
      staleEntries.add('Inventory entry is stale: ${entry.path}');
      continue;
    }
    knownLegacyPaths.add(entry.path);
  }

  return LocalizationLiteralInventoryAudit(
    knownLegacyPaths: knownLegacyPaths,
    staleEntries: staleEntries..sort(),
    unapprovedViolations: violations
        .where((violation) => !knownLegacyPaths.contains(violation.path))
        .toList(),
  );
}

String _violationDigest(List<LocalizationLiteralFinding> violations) {
  final canonical =
      violations
          .map(
            (violation) =>
                '${violation.line}\u0000${violation.literal}\u0000${violation.rationale}',
          )
          .toList()
        ..sort();
  return _digest(canonical.join('\n'));
}

String _digest(String value) => sha256
    .convert(utf8.encode(value.replaceAll('\r\n', '\n').replaceAll('\r', '\n')))
    .toString();

String _relativePath(Directory root, File file) {
  final rootPath = _normalizePath(
    root.absolute.path,
  ).replaceFirst(RegExp(r'/\.$'), '');
  final filePath = _normalizePath(file.absolute.path);
  if (!filePath.startsWith('$rootPath/')) {
    throw StateError('Scoped file is outside the repository root: $filePath');
  }
  return filePath.substring(rootPath.length + 1);
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

Future<void> main(List<String> arguments) async {
  final root = Directory(_option(arguments, '--root') ?? '.').absolute;
  final scopePath =
      _option(arguments, '--scope') ??
      'tool/localization/shared_ui_scope.v1.json';
  final allowlistPath =
      _option(arguments, '--allowlist') ??
      'tool/localization/shared_ui_allowlist.v1.json';
  final inventoryPath = _option(arguments, '--inventory');
  final writeInventoryPath = _option(arguments, '--write-inventory');
  final outputPath = _option(arguments, '--json');

  final scopeJson = _readJsonObject(root, scopePath);
  final allowlistJson = _readJsonObject(root, allowlistPath);
  final files = discoverLocalizationScopeFiles(root, scopeJson);
  final allowances = (allowlistJson['entries']! as List<Object?>)
      .cast<Map<String, Object?>>()
      .map(LocalizationLiteralAllowance.fromJson);
  final scanner = LocalizationLiteralScanner(allowlist: allowances);
  final findings = <LocalizationLiteralFinding>[];
  final sources = <String, String>{};

  for (final path in files) {
    final file = File.fromUri(root.uri.resolve(path));
    if (!file.existsSync()) {
      stderr.writeln('Scoped localization file does not exist: $path');
      exitCode = 2;
      return;
    }
    final source = await file.readAsString();
    sources[path] = source;
    findings.addAll(scanner.scanSource(path: path, source: source));
  }

  final violations = findings.where((finding) => finding.isViolation).toList();
  if (writeInventoryPath != null) {
    final inventory = <String, Object>{
      'schemaVersion': 1,
      'qaOwnerIssue': 346,
      'migrationOwnerIssue': 343,
      'status': violations.isEmpty
          ? 'no-unapproved-user-facing-prose'
          : 'migration-in-progress',
      'zeroUserVisibleProseClaim': violations.isEmpty,
      'scope': _normalizePath(scopePath),
      'summary': <String, Object>{
        'fileCount': files.length,
        'legacyViolationFileCount': violations
            .map((violation) => violation.path)
            .toSet()
            .length,
        'legacyViolationCount': violations.length,
      },
      'entries': buildLocalizationLiteralInventory(
        sources: sources,
        violations: violations,
      ).map((entry) => entry.toJson()).toList(),
    };
    final output = File.fromUri(root.uri.resolve(writeInventoryPath));
    await output.parent.create(recursive: true);
    await output.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(inventory)}\n',
    );
  }

  LocalizationLiteralInventoryAudit? inventoryAudit;
  if (inventoryPath != null || writeInventoryPath != null) {
    final effectiveInventoryPath = inventoryPath ?? writeInventoryPath!;
    final inventoryJson = _readJsonObject(root, effectiveInventoryPath);
    final rawEntries = inventoryJson['entries'];
    if (rawEntries is! List<Object?> ||
        rawEntries.any((entry) => entry is! Map<String, Object?>)) {
      throw const FormatException(
        'Localization literal inventory entries must be objects.',
      );
    }
    inventoryAudit = auditLocalizationLiteralInventory(
      sources: sources,
      violations: violations,
      inventory: rawEntries.cast<Map<String, Object?>>().map(
        LocalizationLiteralInventoryEntry.fromJson,
      ),
    );
  }
  final unapprovedViolations =
      inventoryAudit?.unapprovedViolations ?? violations;
  final staleEntries = inventoryAudit?.staleEntries ?? const <String>[];
  final knownLegacyViolationCount = inventoryAudit == null
      ? 0
      : violations.length - unapprovedViolations.length;
  final blockingIssueCount = unapprovedViolations.length + staleEntries.length;
  final report = <String, Object>{
    'schemaVersion': 1,
    'status': blockingIssueCount == 0 ? 'passed' : 'failed',
    'scope': _normalizePath(scopePath),
    'allowlist': _normalizePath(allowlistPath),
    if (inventoryPath != null || writeInventoryPath != null)
      'inventory': _normalizePath(inventoryPath ?? writeInventoryPath!),
    'filesScanned': files.length,
    'findingCount': findings.length,
    'violationCount': violations.length,
    'knownLegacyViolationCount': knownLegacyViolationCount,
    'unapprovedViolationCount': unapprovedViolations.length,
    'inventoryDriftCount': staleEntries.length,
    'blockingIssueCount': blockingIssueCount,
    'inventoryDrift': staleEntries,
    'findings': findings.map((finding) => finding.toJson()).toList(),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  if (outputPath != null) {
    final output = File.fromUri(root.uri.resolve(outputPath));
    await output.parent.create(recursive: true);
    await output.writeAsString('$encoded\n');
  } else {
    stdout.writeln(encoded);
  }
  for (final message in staleEntries) {
    stderr.writeln(message);
  }
  for (final violation in unapprovedViolations) {
    stderr.writeln('${violation.path}:${violation.line}: ${violation.literal}');
  }
  if (blockingIssueCount != 0) exitCode = 1;
}

Map<String, Object?> _readJsonObject(Directory root, String path) {
  return (jsonDecode(File.fromUri(root.uri.resolve(path)).readAsStringSync())
      as Map<String, Object?>);
}

String? _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index == -1) return null;
  if (index + 1 == arguments.length) {
    throw FormatException('Missing value after $name.');
  }
  return arguments[index + 1];
}
