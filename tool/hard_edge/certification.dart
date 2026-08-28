import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'cross_family_certification.dart';
import 'models.dart';
import 'mutation.dart';
import 'repository_algorithm_inventory.dart';
import 'runner.dart';

enum HardEdgeCertificationStatus { passed, failed, skipped, notRun }

String hardEdgeCertificationStatusName(HardEdgeCertificationStatus status) =>
    status == HardEdgeCertificationStatus.notRun ? 'not_run' : status.name;

final class HardEdgeMutationThreshold {
  const HardEdgeMutationThreshold({
    required this.family,
    required this.minimumKillRatio,
    required this.maximumSurvivors,
    required this.rationale,
  });

  final String family;
  final double minimumKillRatio;
  final int maximumSurvivors;
  final String rationale;

  factory HardEdgeMutationThreshold.parse(Object? source, String path) {
    if (source is! Map) throw FormatException('$path must be an object.');
    final json = _stringKeyedMap(source);
    _requireExactKeys(
        json,
        const {
          'family',
          'minimumKillRatio',
          'maximumSurvivors',
          'rationale',
        },
        path);
    final family = json['family'];
    final ratio = json['minimumKillRatio'];
    final maximum = json['maximumSurvivors'];
    final rationale = json['rationale'];
    if (family is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(family)) {
      throw FormatException('$path.family is invalid.');
    }
    if (ratio is! num || ratio < 0 || ratio > 1) {
      throw FormatException('$path.minimumKillRatio must be between 0 and 1.');
    }
    if (maximum is! int || maximum < 0) {
      throw FormatException('$path.maximumSurvivors must be non-negative.');
    }
    if (rationale is! String || rationale.trim().isEmpty) {
      throw FormatException('$path.rationale must not be empty.');
    }
    return HardEdgeMutationThreshold(
      family: family,
      minimumKillRatio: ratio.toDouble(),
      maximumSurvivors: maximum,
      rationale: rationale,
    );
  }

  Map<String, Object?> toJson() => {
        'family': family,
        'maximumSurvivors': maximumSurvivors,
        'minimumKillRatio': minimumKillRatio,
        'rationale': rationale,
      };
}

final class HardEdgeQuarantineRecord {
  const HardEdgeQuarantineRecord({
    required this.checkId,
    required this.issue,
    required this.owner,
    required this.reason,
    required this.reviewCondition,
  });

  final String checkId;
  final int issue;
  final String owner;
  final String reason;
  final String reviewCondition;

  factory HardEdgeQuarantineRecord.parse(Object? source, String path) {
    if (source is! Map) throw FormatException('$path must be an object.');
    final json = _stringKeyedMap(source);
    _requireExactKeys(
        json,
        const {
          'checkId',
          'issue',
          'owner',
          'reason',
          'reviewCondition',
        },
        path);
    final checkId = json['checkId'];
    final issue = json['issue'];
    final owner = json['owner'];
    final reason = json['reason'];
    final review = json['reviewCondition'];
    if (checkId is! String || checkId.trim().isEmpty) {
      throw FormatException('$path.checkId must not be empty.');
    }
    if (issue is! int || issue <= 0) {
      throw FormatException('$path.issue must be positive.');
    }
    for (final entry in {
      'owner': owner,
      'reason': reason,
      'reviewCondition': review,
    }.entries) {
      if (entry.value is! String || (entry.value! as String).trim().isEmpty) {
        throw FormatException('$path.${entry.key} must not be empty.');
      }
    }
    return HardEdgeQuarantineRecord(
      checkId: checkId,
      issue: issue,
      owner: owner! as String,
      reason: reason! as String,
      reviewCondition: review! as String,
    );
  }

  Map<String, Object?> toJson() => {
        'checkId': checkId,
        'issue': issue,
        'owner': owner,
        'reason': reason,
        'reviewCondition': reviewCondition,
        'status': 'skipped',
      };
}

final class HardEdgeCertificationPolicy {
  HardEdgeCertificationPolicy({
    required Iterable<HardEdgeMutationThreshold> mutationThresholds,
    required Iterable<HardEdgeQuarantineRecord> quarantines,
  })  : mutationThresholds = Map.unmodifiable({
          for (final threshold in mutationThresholds)
            threshold.family: threshold,
        }),
        quarantines = List.unmodifiable(quarantines) {
    if (this.mutationThresholds.length != mutationThresholds.length) {
      throw const FormatException(
          'Mutation threshold families must be unique.');
    }
    final quarantineIds = this.quarantines.map((item) => item.checkId).toSet();
    if (quarantineIds.length != this.quarantines.length) {
      throw const FormatException('Quarantine check IDs must be unique.');
    }
  }

  final Map<String, HardEdgeMutationThreshold> mutationThresholds;
  final List<HardEdgeQuarantineRecord> quarantines;

  static Future<HardEdgeCertificationPolicy> load(File file) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException catch (error) {
      throw FormatException('Invalid certification policy: ${error.message}');
    }
    if (decoded is! Map) {
      throw const FormatException('Certification policy must be an object.');
    }
    final json = _stringKeyedMap(decoded);
    _requireExactKeys(
      json,
      const {'schemaVersion', 'mutationThresholds', 'quarantines'},
      r'$',
    );
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported certification policy schema.');
    }
    final thresholds = json['mutationThresholds'];
    final quarantines = json['quarantines'];
    if (thresholds is! List || quarantines is! List) {
      throw const FormatException(
        'Certification thresholds and quarantines must be arrays.',
      );
    }
    return HardEdgeCertificationPolicy(
      mutationThresholds: [
        for (var index = 0; index < thresholds.length; index++)
          HardEdgeMutationThreshold.parse(
            thresholds[index],
            '\$.mutationThresholds[$index]',
          ),
      ],
      quarantines: [
        for (var index = 0; index < quarantines.length; index++)
          HardEdgeQuarantineRecord.parse(
            quarantines[index],
            '\$.quarantines[$index]',
          ),
      ],
    );
  }
}

final class HardEdgeToolchainRecord {
  const HardEdgeToolchainRecord({
    required this.name,
    required this.status,
    required this.version,
    required this.command,
    required this.message,
  });

  final String name;
  final HardEdgeCertificationStatus status;
  final String? version;
  final String command;
  final String message;

  Map<String, Object?> toJson() => {
        'command': command,
        'message': message,
        'name': name,
        'status': hardEdgeCertificationStatusName(status),
        'version': version,
      };
}

final class HardEdgeCertificationEnvironment {
  const HardEdgeCertificationEnvironment({
    required this.revision,
    required this.dirty,
    required this.operatingSystem,
    required this.operatingSystemVersion,
    required this.toolchains,
  });

  final String? revision;
  final bool? dirty;
  final String operatingSystem;
  final String operatingSystemVersion;
  final List<HardEdgeToolchainRecord> toolchains;

  Map<String, Object?> toJson() => {
        'dirty': dirty,
        'operatingSystem': operatingSystem,
        'operatingSystemVersion': operatingSystemVersion,
        'revision': revision,
        'toolchains': toolchains.map((item) => item.toJson()).toList(),
      };
}

final class HardEdgeCertificationOptions {
  const HardEdgeCertificationOptions({
    this.family,
    this.property,
    this.seedStart,
    this.seedCount,
    this.repeats = 1,
    this.jobs = 1,
    this.caseTimeout = const Duration(seconds: 60),
    this.maximumCases = 10000,
    this.mutationOnly = false,
    this.regressionOnly = false,
    required this.command,
  });

  final String? family;
  final String? property;
  final int? seedStart;
  final int? seedCount;
  final int repeats;
  final int jobs;
  final Duration caseTimeout;
  final int maximumCases;
  final bool mutationOnly;
  final bool regressionOnly;
  final String command;

  void validate() {
    if (mutationOnly && regressionOnly) {
      throw const FormatException(
        '--mutation-only and --regression-only are mutually exclusive.',
      );
    }
    HardEdgeRunOptions(
      family: family,
      property: property,
      seedStart: seedStart,
      seedCount: seedCount,
      repeats: repeats,
      jobs: jobs,
      caseTimeout: caseTimeout,
      maximumCases: maximumCases,
      regressionOnly: regressionOnly,
    ).validate();
  }
}

final class HardEdgeCertificationPhase {
  const HardEdgeCertificationPhase({
    required this.name,
    required this.status,
    required this.reason,
    required this.duration,
  });

  final String name;
  final HardEdgeCertificationStatus status;
  final String reason;
  final Duration duration;

  Map<String, Object?> toJson() => {
        'durationMicros': duration.inMicroseconds,
        'name': name,
        'reason': reason,
        'status': hardEdgeCertificationStatusName(status),
      };
}

final class HardEdgeMutationFamilySummary {
  const HardEdgeMutationFamilySummary({
    required this.family,
    required this.threshold,
    required this.total,
    required this.killed,
    required this.survived,
    required this.notRun,
    required this.killRatio,
    required this.thresholdMet,
    required this.survivorIds,
  });

  final String family;
  final HardEdgeMutationThreshold threshold;
  final int total;
  final int killed;
  final int survived;
  final int notRun;
  final double? killRatio;
  final bool thresholdMet;
  final List<String> survivorIds;

  Map<String, Object?> toJson() => {
        'family': family,
        'killRatio': killRatio,
        'killed': killed,
        'not_run': notRun,
        'survived': survived,
        'survivorIds': survivorIds,
        'threshold': threshold.toJson(),
        'thresholdMet': thresholdMet,
        'total': total,
      };
}

final class HardEdgeCertificationReport {
  const HardEdgeCertificationReport({
    required this.status,
    required this.startedAtUtc,
    required this.duration,
    required this.command,
    required this.environment,
    required this.prerequisites,
    required this.phases,
    required this.propertyRun,
    required this.mutationRun,
    required this.mutationFamilies,
    required this.regressionIndex,
    required this.seedCatalog,
    required this.quarantines,
    required this.jflapParity,
    required this.crossFamily,
    required this.repositoryInventory,
    required this.repositoryRegressionIndex,
    required this.inventoryEvidence,
    required this.artifacts,
  });

  final HardEdgeCertificationStatus status;
  final DateTime startedAtUtc;
  final Duration duration;
  final String command;
  final HardEdgeCertificationEnvironment environment;
  final List<HardEdgeToolchainRecord> prerequisites;
  final List<HardEdgeCertificationPhase> phases;
  final HardEdgeRunResult? propertyRun;
  final HardEdgeMutationRunResult? mutationRun;
  final List<HardEdgeMutationFamilySummary> mutationFamilies;
  final List<Map<String, Object?>> regressionIndex;
  final List<Map<String, Object?>> seedCatalog;
  final List<HardEdgeQuarantineRecord> quarantines;
  final HardEdgeJflapParitySummary jflapParity;
  final HardEdgeCrossFamilySummary? crossFamily;
  final HardEdgeRepositoryInventorySummary repositoryInventory;
  final Map<String, Object?> repositoryRegressionIndex;
  final List<HardEdgeInventoryEvidenceResult> inventoryEvidence;
  final List<String> artifacts;

  bool get hasMissingRequiredPrerequisite => prerequisites.any(
        (item) => item.status != HardEdgeCertificationStatus.passed,
      );

  Map<String, Object?> toJson() => {
        'artifacts': artifacts,
        'command': command,
        'crossFamily': crossFamily?.toJson(),
        'durationMicros': duration.inMicroseconds,
        'environment': environment.toJson(),
        'flakiness': {
          'caseIds': propertyRun?.flakyCaseIds ?? const <String>[],
          'status': propertyRun?.flakyCaseIds.isNotEmpty == true
              ? 'failed'
              : propertyRun == null
                  ? 'not_run'
                  : 'passed',
        },
        'generatedAtUtc': startedAtUtc.toIso8601String(),
        'jflapParity': jflapParity.toJson(),
        'inventoryEvidence':
            inventoryEvidence.map((item) => item.toJson()).toList(),
        'mutationFamilies':
            mutationFamilies.map((item) => item.toJson()).toList(),
        'mutationRun': mutationRun?.toJson(),
        'phases': phases.map((item) => item.toJson()).toList(),
        'prerequisites': prerequisites.map((item) => item.toJson()).toList(),
        'propertyRun': propertyRun?.toJson(),
        'propertyRunDurations': [
          for (final item in propertyRun?.cases ?? const <HardEdgeCaseResult>[])
            {
              'durationMicros': item.elapsed.inMicroseconds,
              'id': item.testCase.id,
              'repeatIndex': item.repeatIndex,
            },
        ],
        'quarantines': quarantines.map((item) => item.toJson()).toList(),
        'regressionIndex': regressionIndex,
        'repositoryInventory': repositoryInventory.toJson(),
        'repositoryRegressionIndex': repositoryRegressionIndex,
        'remotelyVerified': false,
        'schemaVersion': 1,
        'seedCatalog': seedCatalog,
        'status': hardEdgeCertificationStatusName(status),
      };
}

final class HardEdgeCertificationRunner {
  HardEdgeCertificationRunner({
    required this.catalog,
    required this.propertyExecutor,
    required this.mutationExecutor,
    required this.policy,
    required this.environment,
    HardEdgeToolProbe? toolProbe,
    Future<HardEdgeRepositoryInventorySummary> Function(Directory)?
        inventoryLoader,
    Future<Map<String, Object?>> Function(Directory)? regressionIndexLoader,
    HardEdgeInventoryEvidenceRunner? inventoryEvidenceRunner,
    Future<HardEdgeCrossFamilySummary> Function(HardEdgeCertificationOptions)?
        crossFamilyRunner,
  })  : _toolProbe = toolProbe ?? localToolAvailable,
        _inventoryLoader = inventoryLoader ?? readHardEdgeRepositoryInventory,
        _regressionIndexLoader =
            regressionIndexLoader ?? readRepositoryRegressionIndex,
        _inventoryEvidenceRunner =
            inventoryEvidenceRunner ?? runHardEdgeInventoryEvidence,
        _crossFamilyRunner = crossFamilyRunner;

  final HardEdgeCatalog catalog;
  final HardEdgePropertyExecutor propertyExecutor;
  final HardEdgeMutationExecutor mutationExecutor;
  final HardEdgeCertificationPolicy policy;
  final HardEdgeCertificationEnvironment environment;
  final HardEdgeToolProbe _toolProbe;
  final Future<HardEdgeRepositoryInventorySummary> Function(Directory)
      _inventoryLoader;
  final Future<Map<String, Object?>> Function(Directory) _regressionIndexLoader;
  final HardEdgeInventoryEvidenceRunner _inventoryEvidenceRunner;
  final Future<HardEdgeCrossFamilySummary> Function(
    HardEdgeCertificationOptions,
  )? _crossFamilyRunner;

  Future<HardEdgeCertificationReport> run(
    HardEdgeCertificationOptions options,
  ) async {
    options.validate();
    final started = DateTime.now().toUtc();
    final stopwatch = Stopwatch()..start();
    final selectedCases = catalog.manifest.cases
        .where(
            (item) => options.family == null || item.family == options.family)
        .where(
          (item) =>
              options.property == null || item.property == options.property,
        )
        .where(
          (item) =>
              !options.regressionOnly ||
              item.sourceKind == HardEdgeSourceKind.historicalRegression,
        )
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final selectedMutations = catalog.manifest.mutations
        .where(
            (item) => options.family == null || item.family == options.family)
        .where(
          (item) =>
              options.property == null || item.property == options.property,
        )
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final requiredToolNames = <String>{'dart', 'git'};
    if (!options.mutationOnly &&
        !options.regressionOnly &&
        options.family == null &&
        options.property == null) {
      requiredToolNames.add('flutter');
    }
    if (!options.mutationOnly) {
      requiredToolNames.addAll(
        selectedCases.map((item) => item.requiredTool).whereType<String>(),
      );
    }
    if (!options.regressionOnly) {
      requiredToolNames.addAll(
        selectedMutations.map((item) => item.requiredTool).whereType<String>(),
      );
    }
    final prerequisites = <HardEdgeToolchainRecord>[];
    for (final name in requiredToolNames.toList()..sort()) {
      final environmentRecord =
          environment.toolchains.where((item) => item.name == name).firstOrNull;
      final available = switch (name) {
        'git' => environment.revision != null &&
            environmentRecord?.status == HardEdgeCertificationStatus.passed,
        'dart' ||
        'flutter' =>
          environmentRecord?.status == HardEdgeCertificationStatus.passed,
        _ => await _toolProbe(name),
      };
      prerequisites.add(
        HardEdgeToolchainRecord(
          name: name,
          status: available
              ? HardEdgeCertificationStatus.passed
              : HardEdgeCertificationStatus.failed,
          version: environmentRecord?.version,
          command: name == 'git' ? 'git rev-parse HEAD' : '$name --version',
          message: available
              ? 'Required local prerequisite is available.'
              : 'Required local prerequisite is unavailable.',
        ),
      );
    }

    HardEdgeRunResult? propertyRun;
    HardEdgeMutationRunResult? mutationRun;
    final phases = <HardEdgeCertificationPhase>[];
    final inventoryWatch = Stopwatch()..start();
    final repositoryInventory = await _inventoryLoader(
      catalog.repositoryRoot,
    );
    final repositoryRegressionIndex = await _regressionIndexLoader(
      catalog.repositoryRoot,
    );
    inventoryWatch.stop();
    phases.add(HardEdgeCertificationPhase(
      name: 'repository-inventory',
      status: repositoryInventory.validationIssues.isEmpty
          ? HardEdgeCertificationStatus.passed
          : HardEdgeCertificationStatus.failed,
      reason: repositoryInventory.validationIssues.isEmpty
          ? '${repositoryInventory.entries} owned entries and '
              '${repositoryInventory.exclusions} reviewed exclusions match '
              'the production tree.'
          : '${repositoryInventory.validationIssues.length} inventory '
              'validation errors were found.',
      duration: inventoryWatch.elapsed,
    ));
    final fullSelection = !options.mutationOnly &&
        !options.regressionOnly &&
        options.family == null &&
        options.property == null;
    final parityWatch = Stopwatch()..start();
    final jflapParity = await readHardEdgeJflapParity(catalog.repositoryRoot);
    parityWatch.stop();
    phases.add(HardEdgeCertificationPhase(
      name: 'jflap-parity',
      status: jflapParity.residualGaps.isEmpty
          ? HardEdgeCertificationStatus.passed
          : HardEdgeCertificationStatus.failed,
      reason: jflapParity.residualGaps.isEmpty
          ? '${jflapParity.totalRows} parity rows have no residual gap.'
          : '${jflapParity.residualGaps.length} parity rows remain partial, '
              'planned, or missing.',
      duration: parityWatch.elapsed,
    ));
    phases.add(HardEdgeCertificationPhase(
      name: 'quarantine',
      status: policy.quarantines.isEmpty
          ? HardEdgeCertificationStatus.passed
          : HardEdgeCertificationStatus.skipped,
      reason: policy.quarantines.isEmpty
          ? 'No check is quarantined.'
          : '${policy.quarantines.length} checks are explicitly quarantined; '
              'the overall result cannot pass.',
      duration: Duration.zero,
    ));
    final prerequisiteFailure = prerequisites.any(
      (item) => item.status == HardEdgeCertificationStatus.failed,
    );
    final inventoryEvidence = <HardEdgeInventoryEvidenceResult>[];
    if (!fullSelection) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'inventory-evidence',
        status: HardEdgeCertificationStatus.skipped,
        reason: 'Only an unfiltered full certification runs owner commands.',
        duration: Duration.zero,
      ));
    } else if (prerequisiteFailure ||
        repositoryInventory.validationIssues.isNotEmpty) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'inventory-evidence',
        status: HardEdgeCertificationStatus.notRun,
        reason: 'Prerequisite or inventory validation failed before evidence.',
        duration: Duration.zero,
      ));
    } else {
      final evidenceWatch = Stopwatch()..start();
      for (var index = 0;
          index < repositoryInventory.evidenceCommands.length;
          index++) {
        inventoryEvidence.add(
          await _inventoryEvidenceRunner(
            repositoryInventory.evidenceCommands[index],
            catalog.repositoryRoot,
            options.caseTimeout,
            index,
          ),
        );
      }
      evidenceWatch.stop();
      phases.add(HardEdgeCertificationPhase(
        name: 'inventory-evidence',
        status: inventoryEvidence.isEmpty
            ? HardEdgeCertificationStatus.notRun
            : inventoryEvidence.any(
                (item) => item.status == HardEdgeCertificationStatus.failed,
              )
                ? HardEdgeCertificationStatus.failed
                : inventoryEvidence.any(
                    (item) => item.status == HardEdgeCertificationStatus.notRun,
                  )
                    ? HardEdgeCertificationStatus.notRun
                    : HardEdgeCertificationStatus.passed,
        reason: inventoryEvidence.isEmpty
            ? 'No owner evidence command was registered.'
            : 'Executed ${inventoryEvidence.length} unique owner commands.',
        duration: evidenceWatch.elapsed,
      ));
    }
    if (options.mutationOnly) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'properties',
        status: HardEdgeCertificationStatus.skipped,
        reason: 'Explicit --mutation-only selection.',
        duration: Duration.zero,
      ));
    } else if (prerequisiteFailure) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'properties',
        status: HardEdgeCertificationStatus.notRun,
        reason: 'Required prerequisites failed before execution.',
        duration: Duration.zero,
      ));
    } else {
      final phaseWatch = Stopwatch()..start();
      propertyRun = await HardEdgeRunner(
        catalog: catalog,
        executor: propertyExecutor,
        toolProbe: _toolProbe,
      ).run(
        HardEdgeRunOptions(
          family: options.family,
          property: options.property,
          seedStart: options.seedStart,
          seedCount: options.seedCount,
          repeats: options.repeats,
          jobs: options.jobs,
          caseTimeout: options.caseTimeout,
          maximumCases: options.maximumCases,
          regressionOnly: options.regressionOnly,
        ),
      );
      phaseWatch.stop();
      phases.add(HardEdgeCertificationPhase(
        name: 'properties',
        status: _runStatus(propertyRun.status),
        reason: propertyRun.cases.isEmpty
            ? 'No property case matched the selection.'
            : 'Executed ${propertyRun.cases.length} property case runs.',
        duration: phaseWatch.elapsed,
      ));
    }

    HardEdgeCrossFamilySummary? crossFamily;
    final filtered = options.family != null || options.property != null;
    if (options.mutationOnly || options.regressionOnly || filtered) {
      phases.add(HardEdgeCertificationPhase(
        name: 'cross-family',
        status: HardEdgeCertificationStatus.skipped,
        reason: options.mutationOnly
            ? 'Explicit --mutation-only selection.'
            : options.regressionOnly
                ? 'Explicit --regression-only selection.'
                : 'Family or property filter excludes repository-wide checks.',
        duration: Duration.zero,
      ));
    } else if (prerequisiteFailure) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'cross-family',
        status: HardEdgeCertificationStatus.notRun,
        reason: 'Required prerequisites failed before execution.',
        duration: Duration.zero,
      ));
    } else {
      final phaseWatch = Stopwatch()..start();
      crossFamily = await (_crossFamilyRunner ?? _runCrossFamily)(options);
      phaseWatch.stop();
      phases.add(HardEdgeCertificationPhase(
        name: 'cross-family',
        status: crossFamily.expectedOutcomesMatched && !crossFamily.flaky
            ? HardEdgeCertificationStatus.passed
            : HardEdgeCertificationStatus.failed,
        reason: crossFamily.expectedOutcomesMatched
            ? '${crossFamily.report.observations.length} outcomes matched the '
                'declared matrix; ${crossFamily.report.inconclusiveCount} '
                'remain explicitly boundedUnknown.'
            : 'One or more outcomes did not match the declared matrix.',
        duration: phaseWatch.elapsed,
      ));
    }

    if (options.regressionOnly) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'mutations',
        status: HardEdgeCertificationStatus.skipped,
        reason: 'Explicit --regression-only selection.',
        duration: Duration.zero,
      ));
    } else if (prerequisiteFailure) {
      phases.add(const HardEdgeCertificationPhase(
        name: 'mutations',
        status: HardEdgeCertificationStatus.notRun,
        reason: 'Required prerequisites failed before execution.',
        duration: Duration.zero,
      ));
    } else {
      _validateMutationPolicies(selectedMutations);
      final phaseWatch = Stopwatch()..start();
      mutationRun = await HardEdgeMutationRunner(
        catalog: catalog,
        executor: mutationExecutor,
        toolProbe: _toolProbe,
      ).run(family: options.family, property: options.property);
      phaseWatch.stop();
      phases.add(HardEdgeCertificationPhase(
        name: 'mutations',
        status: _runStatus(mutationRun.status),
        reason: mutationRun.mutations.isEmpty
            ? 'No mutation matched the selection.'
            : 'Executed ${mutationRun.mutations.length} mutation probes.',
        duration: phaseWatch.elapsed,
      ));
    }

    final mutationFamilies = mutationRun == null
        ? const <HardEdgeMutationFamilySummary>[]
        : _summarizeMutations(mutationRun);
    if (mutationFamilies.any((item) => !item.thresholdMet)) {
      final index = phases.indexWhere((item) => item.name == 'mutations');
      if (index >= 0) {
        final previous = phases[index];
        phases[index] = HardEdgeCertificationPhase(
          name: previous.name,
          status: previous.status == HardEdgeCertificationStatus.notRun
              ? previous.status
              : HardEdgeCertificationStatus.failed,
          reason: 'One or more family mutation thresholds were not met.',
          duration: previous.duration,
        );
      }
    }
    stopwatch.stop();
    final status = _overallStatus(
      prerequisites: prerequisites,
      phases: phases,
      quarantines: policy.quarantines,
    );
    return HardEdgeCertificationReport(
      status: status,
      startedAtUtc: started,
      duration: stopwatch.elapsed,
      command: options.command,
      environment: environment,
      prerequisites: prerequisites,
      phases: phases,
      propertyRun: propertyRun,
      mutationRun: mutationRun,
      mutationFamilies: mutationFamilies,
      regressionIndex: _regressionIndex(catalog.manifest.cases),
      seedCatalog: _seedCatalog(selectedCases),
      quarantines: policy.quarantines,
      jflapParity: jflapParity,
      crossFamily: crossFamily,
      repositoryInventory: repositoryInventory,
      repositoryRegressionIndex: repositoryRegressionIndex,
      inventoryEvidence: inventoryEvidence,
      artifacts: [
        'certification-report.json',
        'certification-report.md',
        'certification-report.html',
        if (propertyRun != null) ...[
          'hard-edge-report.json',
          'hard-edge-report.md',
        ],
        if (mutationRun != null) ...[
          'mutation-report.json',
          'mutation-report.md',
        ],
        for (final evidence in inventoryEvidence) evidence.artifact,
      ],
    );
  }

  void _validateMutationPolicies(List<HardEdgeMutation> selected) {
    final families = selected.map((item) => item.family).toSet();
    final missing = families.difference(policy.mutationThresholds.keys.toSet());
    if (missing.isNotEmpty) {
      throw HardEdgeConfigurationException(
        'Certification policy has no mutation threshold for: '
        '${(missing.toList()..sort()).join(', ')}.',
      );
    }
  }

  List<HardEdgeMutationFamilySummary> _summarizeMutations(
    HardEdgeMutationRunResult result,
  ) {
    final families =
        result.mutations.map((item) => item.mutation.family).toSet();
    final summaries = <HardEdgeMutationFamilySummary>[];
    for (final family in families.toList()..sort()) {
      final threshold = policy.mutationThresholds[family]!;
      final records = result.mutations
          .where((item) => item.mutation.family == family)
          .toList();
      final killed = records
          .where((item) => item.status == HardEdgeMutationStatus.killed)
          .length;
      final survived = records
          .where((item) => item.status == HardEdgeMutationStatus.survived)
          .length;
      final notRun = records
          .where((item) => item.status == HardEdgeMutationStatus.notRun)
          .length;
      final executed = killed + survived;
      final ratio = executed == 0 ? null : killed / executed;
      summaries.add(HardEdgeMutationFamilySummary(
        family: family,
        threshold: threshold,
        total: records.length,
        killed: killed,
        survived: survived,
        notRun: notRun,
        killRatio: ratio,
        thresholdMet: notRun == 0 &&
            survived <= threshold.maximumSurvivors &&
            ratio != null &&
            ratio >= threshold.minimumKillRatio,
        survivorIds: records
            .where((item) => item.status == HardEdgeMutationStatus.survived)
            .map((item) => item.mutation.id)
            .toList()
          ..sort(),
      ));
    }
    return summaries;
  }

  Future<HardEdgeCrossFamilySummary> _runCrossFamily(
    HardEdgeCertificationOptions options,
  ) async {
    final matrix = await _readCrossFamilyMatrix(
      catalog.resolve(
        'test/fixtures/hard_edge/cross_family/matrix.v1.json',
        mustExist: true,
      ),
    );
    final seedStart = options.seedStart ?? 342;
    final seedCount = options.seedCount ?? 1;
    final reports =
        <({int seed, int repeat, CrossFamilyCertificationReport report})>[];
    final executions = <Map<String, Object?>>[];
    final previousDirectory = Directory.current;
    try {
      Directory.current = catalog.repositoryRoot;
      for (var offset = 0; offset < seedCount; offset++) {
        final seed = seedStart + offset;
        for (var repeat = 0; repeat < options.repeats; repeat++) {
          final report = await CrossFamilyCertification.run(seed: seed);
          reports.add((seed: seed, repeat: repeat, report: report));
          executions.add({
            'outcomes': {
              for (final observation in report.observations)
                observation.id: observation.outcome.name,
            },
            'repeat': repeat,
            'seed': seed,
          });
        }
      }
    } finally {
      Directory.current = previousDirectory;
    }
    final flakySeeds = <int>[];
    for (var offset = 0; offset < seedCount; offset++) {
      final seed = seedStart + offset;
      final fingerprints = reports
          .where((item) => item.seed == seed)
          .map((item) => jsonEncode(item.report.toJson()))
          .toSet();
      if (fingerprints.length > 1) flakySeeds.add(seed);
    }
    return HardEdgeCrossFamilySummary(
      report: reports.first.report,
      expectedOutcomes: matrix,
      expectedOutcomesMatched: reports.every(
        (item) => item.report.matchesExpectedOutcomes(matrix),
      ),
      repeats: options.repeats,
      flaky: flakySeeds.isNotEmpty,
      seed: seedStart,
      seeds: [
        for (var offset = 0; offset < seedCount; offset++) seedStart + offset,
      ],
      executionOutcomes: executions,
      flakySeeds: flakySeeds,
    );
  }
}

final class HardEdgeRepositoryInventorySummary {
  const HardEdgeRepositoryInventorySummary({
    required this.entries,
    required this.exclusions,
    required this.validationIssues,
    required this.mutationExclusions,
    required this.path,
    required this.evidenceCommands,
  });

  final int entries;
  final int exclusions;
  final List<String> validationIssues;
  final List<Map<String, Object?>> mutationExclusions;
  final String path;
  final List<String> evidenceCommands;

  Map<String, Object?> toJson() => {
        'entries': entries,
        'evidenceCommands': evidenceCommands,
        'excludedSupportFiles': exclusions,
        'mutationExclusions': mutationExclusions,
        'path': path,
        'status': validationIssues.isEmpty ? 'passed' : 'failed',
        'validationIssues': validationIssues,
      };
}

Future<HardEdgeRepositoryInventorySummary> readHardEdgeRepositoryInventory(
  Directory repositoryRoot,
) async {
  const relative =
      'test/fixtures/hard_edge/repository_algorithm_inventory.v1.json';
  final file = File(
    '${repositoryRoot.path}${Platform.pathSeparator}'
    '${relative.replaceAll('/', Platform.pathSeparator)}',
  );
  if (!file.existsSync()) {
    throw const HardEdgeConfigurationException(
      'Repository algorithm inventory is missing.',
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FormatException catch (error) {
    throw HardEdgeConfigurationException(
      'Invalid repository algorithm inventory: ${error.message}',
    );
  }
  if (decoded is! Map) {
    throw const HardEdgeConfigurationException(
      'Repository algorithm inventory must be an object.',
    );
  }
  final json = _stringKeyedMap(decoded);
  final entries = json['entries'];
  final exclusions = json['exclusions'];
  if (json['schema'] != repositoryAlgorithmInventorySchema ||
      entries is! List ||
      exclusions is! List) {
    throw const HardEdgeConfigurationException(
      'Repository algorithm inventory has an invalid schema.',
    );
  }
  final discovered = RepositoryAlgorithmInventory.discover(repositoryRoot);
  final issues = discovered.validate(repositoryRoot);
  if (canonicalJsonEncode(entries) != canonicalJsonEncode(discovered.entries)) {
    issues
        .add('Committed inventory entries do not match production discovery.');
  }
  if (canonicalJsonEncode(exclusions) !=
      canonicalJsonEncode(discovered.exclusions)) {
    issues.add(
      'Committed inventory exclusions do not match production discovery.',
    );
  }
  final mutationExclusions = <Map<String, Object?>>[];
  final evidenceCommands = <String>{};
  for (final raw in entries) {
    if (raw is! Map) continue;
    final entry = _stringKeyedMap(raw);
    final evidenceCommand = entry['evidenceCommand'];
    if (evidenceCommand is String && evidenceCommand.trim().isNotEmpty) {
      evidenceCommands.add(evidenceCommand);
    }
    final mutation = entry['mutation'];
    if (mutation is! Map) continue;
    final decision = _stringKeyedMap(mutation);
    if (decision['inScope'] == false) {
      mutationExclusions.add({
        'family': entry['family'],
        'id': entry['id'],
        'rationale': decision['rationale'],
        'status': 'reviewed_exclusion',
      });
    }
  }
  return HardEdgeRepositoryInventorySummary(
    entries: entries.length,
    exclusions: exclusions.length,
    validationIssues: issues..sort(),
    mutationExclusions: mutationExclusions
      ..sort((left, right) => '${left['id']}'.compareTo('${right['id']}')),
    path: relative,
    evidenceCommands: evidenceCommands.toList()..sort(),
  );
}

typedef HardEdgeInventoryEvidenceRunner
    = Future<HardEdgeInventoryEvidenceResult> Function(
  String command,
  Directory repositoryRoot,
  Duration timeout,
  int index,
);

final class HardEdgeInventoryEvidenceResult {
  const HardEdgeInventoryEvidenceResult({
    required this.command,
    required this.status,
    required this.duration,
    required this.exitCode,
    required this.message,
    required this.stdout,
    required this.stderr,
    required this.artifact,
  });

  final String command;
  final HardEdgeCertificationStatus status;
  final Duration duration;
  final int? exitCode;
  final String message;
  final String stdout;
  final String stderr;
  final String artifact;

  Map<String, Object?> toJson() => {
        'artifact': artifact,
        'command': command,
        'durationMicros': duration.inMicroseconds,
        'exitCode': exitCode,
        'message': message,
        'status': hardEdgeCertificationStatusName(status),
      };
}

Future<HardEdgeInventoryEvidenceResult> runHardEdgeInventoryEvidence(
  String command,
  Directory repositoryRoot,
  Duration timeout,
  int index,
) async {
  final stopwatch = Stopwatch()..start();
  final artifact =
      'inventory-evidence/${(index + 1).toString().padLeft(2, '0')}.log';
  Process process;
  try {
    process = await Process.start(
      Platform.isWindows ? 'cmd.exe' : '/bin/sh',
      Platform.isWindows ? ['/d', '/s', '/c', command] : ['-c', command],
      workingDirectory: repositoryRoot.path,
      runInShell: false,
    );
  } on ProcessException catch (error) {
    stopwatch.stop();
    return HardEdgeInventoryEvidenceResult(
      command: command,
      status: HardEdgeCertificationStatus.notRun,
      duration: stopwatch.elapsed,
      exitCode: null,
      message: 'Evidence command could not start: $error',
      stdout: '',
      stderr: '$error',
      artifact: artifact,
    );
  }
  final output =
      process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
  final errors =
      process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
  try {
    final exitCode = await process.exitCode.timeout(timeout);
    final streams = await Future.wait([output, errors]);
    stopwatch.stop();
    return HardEdgeInventoryEvidenceResult(
      command: command,
      status: exitCode == 0
          ? HardEdgeCertificationStatus.passed
          : HardEdgeCertificationStatus.failed,
      duration: stopwatch.elapsed,
      exitCode: exitCode,
      message: exitCode == 0
          ? 'Owner evidence command passed.'
          : 'Owner evidence command exited with code $exitCode.',
      stdout: streams[0],
      stderr: streams[1],
      artifact: artifact,
    );
  } on TimeoutException {
    await _terminateCertificationTree(process);
    final streams = await Future.wait([output, errors]).timeout(
      const Duration(seconds: 3),
      onTimeout: () => const [
        '',
        'Evidence descendants retained output pipes after termination.',
      ],
    );
    stopwatch.stop();
    return HardEdgeInventoryEvidenceResult(
      command: command,
      status: HardEdgeCertificationStatus.failed,
      duration: stopwatch.elapsed,
      exitCode: null,
      message: 'Owner evidence command exceeded ${timeout.inSeconds} seconds.',
      stdout: streams[0],
      stderr: streams[1],
      artifact: artifact,
    );
  }
}

Future<void> _terminateCertificationTree(Process process) async {
  if (Platform.isWindows) {
    await Process.run(
      'taskkill.exe',
      ['/pid', '${process.pid}', '/t', '/f'],
      runInShell: false,
    ).timeout(const Duration(seconds: 3));
  } else {
    final tree = await _posixCertificationTree(process.pid);
    for (final pid in tree.reversed) {
      Process.killPid(pid, ProcessSignal.sigkill);
    }
  }
  try {
    await process.exitCode.timeout(const Duration(seconds: 3));
  } on TimeoutException {
    throw StateError(
      'Evidence process ${process.pid} did not terminate after timeout.',
    );
  }
}

Future<List<int>> _posixCertificationTree(int rootPid) async {
  final result = await Process.run(
    'ps',
    const ['-eo', 'pid=,ppid='],
    runInShell: false,
  );
  if (result.exitCode != 0) {
    throw StateError('Could not enumerate evidence descendants: '
        '${result.stderr}');
  }
  final children = <int, List<int>>{};
  for (final line in '${result.stdout}'.split('\n')) {
    final fields = line.trim().split(RegExp(r'\s+'));
    if (fields.length != 2) continue;
    final pid = int.tryParse(fields[0]);
    final parent = int.tryParse(fields[1]);
    if (pid == null || parent == null) continue;
    children.putIfAbsent(parent, () => <int>[]).add(pid);
  }
  final tree = <int>[rootPid];
  for (var index = 0; index < tree.length; index++) {
    tree.addAll(children[tree[index]] ?? const <int>[]);
  }
  return tree;
}

Future<Map<String, Object?>> readRepositoryRegressionIndex(
  Directory repositoryRoot,
) async {
  const relative = 'test/fixtures/hard_edge/repository/regression_index.json';
  final file = File(
    '${repositoryRoot.path}${Platform.pathSeparator}'
    '${relative.replaceAll('/', Platform.pathSeparator)}',
  );
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FileSystemException catch (error) {
    throw HardEdgeConfigurationException(
      'Repository regression index is unavailable: ${error.message}',
    );
  } on FormatException catch (error) {
    throw HardEdgeConfigurationException(
      'Invalid repository regression index: ${error.message}',
    );
  }
  if (decoded is! Map) {
    throw const HardEdgeConfigurationException(
      'Repository regression index must be an object.',
    );
  }
  final json = _stringKeyedMap(decoded);
  final defects = json['historicalDefects'];
  if (json['schema'] != 'turing-lab.repository-regression-index.v1' ||
      json['ownerIssue'] != 342 ||
      defects is! List ||
      json['rationale'] is! String) {
    throw const HardEdgeConfigurationException(
      'Repository regression index has an invalid schema.',
    );
  }
  return {
    ...json,
    'path': relative,
    'status': 'passed',
  };
}

final class HardEdgeCrossFamilySummary {
  const HardEdgeCrossFamilySummary({
    required this.report,
    required this.expectedOutcomes,
    required this.expectedOutcomesMatched,
    required this.repeats,
    required this.flaky,
    required this.seed,
    this.seeds = const [],
    this.executionOutcomes = const [],
    this.flakySeeds = const [],
  });

  final CrossFamilyCertificationReport report;
  final Map<String, CrossFamilyOutcome> expectedOutcomes;
  final bool expectedOutcomesMatched;
  final int repeats;
  final bool flaky;
  final int seed;
  final List<int> seeds;
  final List<Map<String, Object?>> executionOutcomes;
  final List<int> flakySeeds;

  Map<String, Object?> toJson() => {
        'boundedUnknownCount': report.inconclusiveCount,
        'certifiedCount': report.certificationCount,
        'expectedOutcomes': {
          for (final id in expectedOutcomes.keys.toList()..sort())
            id: expectedOutcomes[id]!.name,
        },
        'expectedOutcomesMatched': expectedOutcomesMatched,
        'executionOutcomes': executionOutcomes,
        'flaky': flaky,
        'flakySeeds': flakySeeds,
        'observations':
            report.observations.map((item) => item.toJson()).toList(),
        'repeats': repeats,
        'seed': seed,
        'seeds': seeds.isEmpty ? [seed] : seeds,
        'status': expectedOutcomesMatched && !flaky ? 'passed' : 'failed',
      };
}

Future<Map<String, CrossFamilyOutcome>> _readCrossFamilyMatrix(
  File file,
) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on FormatException catch (error) {
    throw HardEdgeConfigurationException(
      'Invalid cross-family matrix: ${error.message}',
    );
  }
  if (decoded is! Map) {
    throw const HardEdgeConfigurationException(
      'Cross-family matrix must be an object.',
    );
  }
  final json = _stringKeyedMap(decoded);
  final checks = json['checks'];
  if (json['schemaVersion'] != 1 || checks is! List) {
    throw const HardEdgeConfigurationException(
      'Cross-family matrix has an invalid schema.',
    );
  }
  final result = <String, CrossFamilyOutcome>{};
  for (var index = 0; index < checks.length; index++) {
    final raw = checks[index];
    if (raw is! Map) {
      throw HardEdgeConfigurationException(
        'Cross-family matrix check $index must be an object.',
      );
    }
    final check = _stringKeyedMap(raw);
    final id = check['id'];
    final expected = check['expectedOutcome'];
    if (id is! String || expected is! String) {
      throw HardEdgeConfigurationException(
        'Cross-family matrix check $index has an invalid schema.',
      );
    }
    final outcome = CrossFamilyOutcome.values
        .where((item) => item.name == expected)
        .firstOrNull;
    if (outcome == null || result.containsKey(id)) {
      throw HardEdgeConfigurationException(
        'Cross-family matrix check "$id" is invalid or duplicated.',
      );
    }
    result[id] = outcome;
  }
  return Map.unmodifiable(result);
}

final class HardEdgeJflapParitySummary {
  const HardEdgeJflapParitySummary({
    required this.totalRows,
    required this.statusCounts,
    required this.residualGaps,
    required this.fragments,
  });

  final int totalRows;
  final Map<String, int> statusCounts;
  final List<Map<String, Object?>> residualGaps;
  final List<String> fragments;

  Map<String, Object?> toJson() => {
        'fragments': fragments,
        'residualGaps': residualGaps,
        'status': residualGaps.isEmpty ? 'passed' : 'failed',
        'statusCounts': statusCounts,
        'totalRows': totalRows,
      };
}

Future<HardEdgeJflapParitySummary> readHardEdgeJflapParity(
  Directory repositoryRoot,
) async {
  final directory = Directory(
    '${repositoryRoot.path}${Platform.pathSeparator}docs'
    '${Platform.pathSeparator}jflap-parity',
  );
  if (!directory.existsSync()) {
    throw const HardEdgeConfigurationException(
      'docs/jflap-parity is required for final certification.',
    );
  }
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  if (files.isEmpty) {
    throw const HardEdgeConfigurationException(
      'No JFLAP parity fragments were found.',
    );
  }
  const acceptedStatuses = {
    'complete',
    'intentionalDeviation',
    'outOfScope',
    'partial',
    'planned',
    'missing',
  };
  const residualStatuses = {'partial', 'planned', 'missing'};
  final counts = <String, int>{};
  final gaps = <Map<String, Object?>>[];
  final fragments = <String>[];
  final rowIds = <String>{};
  for (final file in files) {
    final Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException catch (error) {
      throw HardEdgeConfigurationException(
        'Invalid JFLAP parity fragment ${file.path}: ${error.message}',
      );
    }
    if (decoded is! Map) {
      throw HardEdgeConfigurationException(
        'JFLAP parity fragment ${file.path} must be an object.',
      );
    }
    final fragment = _stringKeyedMap(decoded);
    if (file.uri.pathSegments.last == 'metadata.json') {
      if (fragment['schemaVersion'] != 1) {
        throw const HardEdgeConfigurationException(
          'JFLAP parity metadata has an invalid schema.',
        );
      }
      continue;
    }
    final name = fragment['fragment'];
    final rows = fragment['rows'];
    if (name is! String || name.isEmpty || rows is! List) {
      throw HardEdgeConfigurationException(
        'JFLAP parity fragment ${file.path} has an invalid schema.',
      );
    }
    fragments.add(name);
    for (var index = 0; index < rows.length; index++) {
      final raw = rows[index];
      if (raw is! Map) {
        throw HardEdgeConfigurationException(
          'JFLAP parity row $name[$index] must be an object.',
        );
      }
      final row = _stringKeyedMap(raw);
      final id = row['id'];
      final turingLab = row['turingLab'];
      if (id is! String || id.isEmpty || turingLab is! Map) {
        throw HardEdgeConfigurationException(
          'JFLAP parity row $name[$index] has an invalid schema.',
        );
      }
      if (!rowIds.add(id)) {
        throw HardEdgeConfigurationException(
          'Duplicate JFLAP parity row ID "$id".',
        );
      }
      final local = _stringKeyedMap(turingLab);
      final status = local['status'];
      if (status is! String || !acceptedStatuses.contains(status)) {
        throw HardEdgeConfigurationException(
          'JFLAP parity row "$id" has an invalid status.',
        );
      }
      counts.update(status, (value) => value + 1, ifAbsent: () => 1);
      if (residualStatuses.contains(status)) {
        final issues = local['issues'];
        final ownerIssues = issues is List
            ? issues.whereType<int>().where((issue) => issue > 0).toList()
            : const <int>[];
        gaps.add({
          'id': id,
          'ownerIssues': ownerIssues,
          'status': status,
          'unowned': ownerIssues.isEmpty,
        });
      }
    }
  }
  return HardEdgeJflapParitySummary(
    totalRows: rowIds.length,
    statusCounts: {
      for (final status in acceptedStatuses) status: counts[status] ?? 0,
    },
    residualGaps: gaps
      ..sort((left, right) => '${left['id']}'.compareTo('${right['id']}')),
    fragments: fragments..sort(),
  );
}

Future<HardEdgeCertificationEnvironment> collectHardEdgeEnvironment(
  Directory repositoryRoot,
) async {
  final gitRevision = await _runLocalCommand(
    'git',
    const ['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot.path,
  );
  final gitStatus = await _runLocalCommand(
    'git',
    const ['status', '--porcelain'],
    workingDirectory: repositoryRoot.path,
  );
  final flutter = await _runLocalCommand(
    Platform.isWindows ? 'cmd.exe' : 'flutter',
    Platform.isWindows
        ? const ['/d', '/s', '/c', 'flutter', '--version', '--machine']
        : const ['--version', '--machine'],
    workingDirectory: repositoryRoot.path,
  );
  String? flutterVersion;
  if (flutter.exitCode == 0) {
    try {
      final decoded = jsonDecode(flutter.stdout);
      if (decoded is Map && decoded['frameworkVersion'] is String) {
        flutterVersion = decoded['frameworkVersion'] as String;
      }
    } on FormatException {
      flutterVersion = flutter.stdout.trim().split('\n').firstOrNull;
    }
  }
  return HardEdgeCertificationEnvironment(
    revision: gitRevision.exitCode == 0 ? gitRevision.stdout.trim() : null,
    dirty: gitStatus.exitCode == 0 ? gitStatus.stdout.trim().isNotEmpty : null,
    operatingSystem: Platform.operatingSystem,
    operatingSystemVersion: Platform.operatingSystemVersion,
    toolchains: [
      HardEdgeToolchainRecord(
        name: 'dart',
        status: HardEdgeCertificationStatus.passed,
        version: Platform.version.split(' ').first,
        command: 'dart --version',
        message: 'Dart runtime executing the certification command.',
      ),
      HardEdgeToolchainRecord(
        name: 'flutter',
        status: flutter.exitCode == 0
            ? HardEdgeCertificationStatus.passed
            : HardEdgeCertificationStatus.notRun,
        version: flutterVersion,
        command: 'flutter --version --machine',
        message: flutter.exitCode == 0
            ? 'Flutter version was recorded locally.'
            : 'Flutter was unavailable; Flutter-backed checks cannot pass.',
      ),
      HardEdgeToolchainRecord(
        name: 'git',
        status: gitRevision.exitCode == 0
            ? HardEdgeCertificationStatus.passed
            : HardEdgeCertificationStatus.notRun,
        version: gitRevision.exitCode == 0 ? gitRevision.stdout.trim() : null,
        command: 'git rev-parse HEAD',
        message: gitRevision.exitCode == 0
            ? 'Source revision was recorded locally.'
            : 'Source revision could not be recorded.',
      ),
    ],
  );
}

Future<({int exitCode, String stdout, String stderr})> _runLocalCommand(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  Process process;
  try {
    process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );
  } on ProcessException catch (error) {
    return (exitCode: 127, stdout: '', stderr: '$error');
  }
  final stdoutFuture = process.stdout.transform(utf8.decoder).join();
  final stderrFuture = process.stderr.transform(utf8.decoder).join();
  try {
    final exitCode =
        await process.exitCode.timeout(const Duration(seconds: 10));
    return (
      exitCode: exitCode,
      stdout: await stdoutFuture,
      stderr: await stderrFuture,
    );
  } on TimeoutException {
    process.kill();
    try {
      await process.exitCode.timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // The failed probe remains not_run. Do not claim that it completed.
    }
    return (exitCode: 124, stdout: '', stderr: 'Command timed out.');
  }
}

HardEdgeCertificationStatus _runStatus(HardEdgeRunStatus status) =>
    switch (status) {
      HardEdgeRunStatus.passed => HardEdgeCertificationStatus.passed,
      HardEdgeRunStatus.failed => HardEdgeCertificationStatus.failed,
      HardEdgeRunStatus.incomplete => HardEdgeCertificationStatus.notRun,
    };

HardEdgeCertificationStatus _overallStatus({
  required List<HardEdgeToolchainRecord> prerequisites,
  required List<HardEdgeCertificationPhase> phases,
  required List<HardEdgeQuarantineRecord> quarantines,
}) {
  if (prerequisites.any(
        (item) => item.status == HardEdgeCertificationStatus.failed,
      ) ||
      phases.any((item) => item.status == HardEdgeCertificationStatus.failed)) {
    return HardEdgeCertificationStatus.failed;
  }
  if (quarantines.isNotEmpty ||
      phases.any((item) => item.status == HardEdgeCertificationStatus.notRun)) {
    return HardEdgeCertificationStatus.notRun;
  }
  if (phases.any((item) => item.status == HardEdgeCertificationStatus.passed)) {
    return HardEdgeCertificationStatus.passed;
  }
  return HardEdgeCertificationStatus.notRun;
}

List<Map<String, Object?>> _regressionIndex(
  List<HardEdgeCatalogCase> cases,
) =>
    [
      for (final item in cases)
        if (item.sourceKind == HardEdgeSourceKind.historicalRegression)
          {
            'family': item.family,
            'fixture': item.fixture,
            'id': item.id,
            'issue': item.regressionIssue,
            'property': item.property,
            'reproductionCommand': 'dart run tool/hard_edge_cases.dart certify '
                '--regression-only --family ${item.family} '
                '--property ${item.property}',
            'seed': item.seed,
          },
    ]..sort((left, right) => '${left['id']}'.compareTo('${right['id']}'));

List<Map<String, Object?>> _seedCatalog(List<HardEdgeCatalogCase> cases) => [
      for (final item in cases)
        {
          'family': item.family,
          'id': item.id,
          'property': item.property,
          'seed': item.seed,
          'sourceKind': item.sourceKind.name,
        },
    ];

Map<String, Object?> _stringKeyedMap(Map source) => {
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };

void _requireExactKeys(
  Map<String, Object?> source,
  Set<String> expected,
  String path,
) {
  final missing = expected.difference(source.keys.toSet());
  final unknown = source.keys.toSet().difference(expected);
  if (missing.isNotEmpty || unknown.isNotEmpty) {
    throw FormatException(
      '$path has invalid keys; missing '
      '${(missing.toList()..sort()).join(', ')}, unknown '
      '${(unknown.toList()..sort()).join(', ')}.',
    );
  }
}
