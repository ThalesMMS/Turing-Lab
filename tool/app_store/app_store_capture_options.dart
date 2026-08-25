//
//  app_store_capture_options.dart
//  Turing Lab
//
//  Parses the command line of the App Store capture pipeline and resolves it
//  into the concrete case list the runner and validator operate on.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'app_store_capture_case.dart';
import 'app_store_capture_matrix.dart';

/// Validated command line selection for a capture, plan or validate run.
class AppStoreCaptureOptions {
  const AppStoreCaptureOptions({
    required this.command,
    required this.profileIds,
    required this.screenIds,
    required this.localeCodes,
    required this.themeIds,
    required this.outputDir,
    required this.all,
    required this.timeoutSeconds,
    required this.settleBudgetFrames,
    required this.bestEffort,
    required this.runValidation,
    required this.fault,
    required this.help,
  });

  /// Default per-capture wall clock budget, including Dart compilation.
  static const int defaultTimeoutSeconds = 300;

  /// Default number of frames a bounded settle stage may pump.
  static const int defaultSettleBudgetFrames = 240;

  static const List<String> commands = <String>['run', 'plan', 'validate'];

  static const String usage = '''
Usage: tool/capture_app_store_screenshots.sh [command] [options]

Commands:
  run        Capture the selected matrix (default).
  plan       Print the resolved matrix without capturing anything.
  validate   Validate an existing output directory against the matrix.

Selection (repeatable; omitted dimensions use the release defaults):
  --profile <id>     $_profileList
  --screen <id>      $_screenList
  --locale <code>    $_localeList (default ${AppStoreCaptureCase.defaultLocale})
  --theme <id>       $_themeList (default ${AppStoreCaptureCase.defaultTheme})
  --all              Complete release-approved matrix; excludes selectors.

Output and execution:
  --output <dir>     Output root (default ${AppStoreCaptureMatrix.approvedOutputDir}).
  --timeout <secs>   Per-capture wall clock budget (default $defaultTimeoutSeconds).
  --settle <frames>  Bounded settle budget per stage (default $defaultSettleBudgetFrames).
  --best-effort      Continue after a failed capture instead of failing fast.
  --no-validate      Skip the post-run dimension/naming/completeness checks.
  --fault <name>     Inject a capture fault to exercise diagnostics
                     (block-prepare, block-settle).
  --skip-pub-get     Do not run `flutter pub get` before capturing.
  -h, --help         Print this message.

Examples:
  tool/capture_app_store_screenshots.sh \\
    --profile iphone-6.9 --screen fsa --locale en --output build/screenshots/candidate
  tool/capture_app_store_screenshots.sh --all --output build/screenshots/candidate
''';

  static const String _profileList =
      'iphone-6.9, iphone-6.5, iphone-5.5, ipad-13, macos';
  static const String _screenList = 'fsa, grammar, pda, tm, regex';
  static const String _localeList = 'en, pt';
  static const String _themeList = 'light, dark';

  /// Parses [args], throwing [FormatException] with an actionable message for
  /// unknown flags, unknown identifiers or missing values.
  factory AppStoreCaptureOptions.parse(List<String> args) {
    var command = 'run';
    final profileIds = <String>[];
    final screenIds = <String>[];
    final localeCodes = <String>[];
    final themeIds = <String>[];
    var outputDir = AppStoreCaptureMatrix.approvedOutputDir;
    var all = false;
    var timeoutSeconds = defaultTimeoutSeconds;
    var settleBudgetFrames = defaultSettleBudgetFrames;
    var bestEffort = false;
    var runValidation = true;
    String? fault;
    var help = false;

    final positional = <String>[];
    var index = 0;

    String requireValue(String flag) {
      if (index + 1 >= args.length) {
        throw FormatException('$flag requires a value.');
      }
      index++;
      return args[index];
    }

    int requireInt(String flag) {
      final raw = requireValue(flag);
      final parsed = int.tryParse(raw);
      if (parsed == null || parsed <= 0) {
        throw FormatException('$flag expects a positive integer, got "$raw".');
      }
      return parsed;
    }

    for (; index < args.length; index++) {
      final arg = args[index];
      switch (arg) {
        case '--profile':
          profileIds.add(requireValue(arg));
        case '--screen':
          screenIds.add(requireValue(arg));
        case '--locale':
          localeCodes.add(requireValue(arg));
        case '--theme':
          themeIds.add(requireValue(arg));
        case '--output':
          outputDir = requireValue(arg);
        case '--timeout':
          timeoutSeconds = requireInt(arg);
        case '--settle':
          settleBudgetFrames = requireInt(arg);
        case '--fault':
          fault = requireValue(arg);
        case '--all':
          all = true;
        case '--best-effort':
          bestEffort = true;
        case '--no-validate':
          runValidation = false;
        case '--skip-pub-get':
          break;
        case '-h':
        case '--help':
          help = true;
        default:
          if (arg.startsWith('-')) {
            throw FormatException('Unknown option "$arg".');
          }
          positional.add(arg);
      }
    }

    if (positional.length > 1) {
      throw FormatException(
        'Expected at most one command, got ${positional.join(', ')}.',
      );
    }
    if (positional.isNotEmpty) {
      command = positional.single;
      if (!commands.contains(command)) {
        throw FormatException(
          'Unknown command "$command". Valid commands: ${commands.join(', ')}.',
        );
      }
    }
    if (all &&
        (profileIds.isNotEmpty ||
            screenIds.isNotEmpty ||
            localeCodes.isNotEmpty ||
            themeIds.isNotEmpty)) {
      throw const FormatException(
        '--all captures the whole approved matrix and cannot be combined with '
        '--profile, --screen, --locale or --theme.',
      );
    }

    final options = AppStoreCaptureOptions(
      command: command,
      profileIds: List.unmodifiable(profileIds),
      screenIds: List.unmodifiable(screenIds),
      localeCodes: List.unmodifiable(localeCodes),
      themeIds: List.unmodifiable(themeIds),
      outputDir: outputDir,
      all: all,
      timeoutSeconds: timeoutSeconds,
      settleBudgetFrames: settleBudgetFrames,
      bestEffort: bestEffort,
      runValidation: runValidation,
      fault: fault,
      help: help,
    );

    if (!help) {
      // Surface unknown identifiers before any process is spawned.
      options.resolveCases();
    }
    return options;
  }

  final String command;
  final List<String> profileIds;
  final List<String> screenIds;
  final List<String> localeCodes;
  final List<String> themeIds;
  final String outputDir;
  final bool all;
  final int timeoutSeconds;
  final int settleBudgetFrames;
  final bool bestEffort;
  final bool runValidation;
  final String? fault;
  final bool help;

  /// Resolves the selection into the ordered case list to process.
  List<AppStoreCaptureCase> resolveCases() {
    if (all) {
      return AppStoreCaptureMatrix.approvedCases();
    }
    return AppStoreCaptureMatrix.resolve(
      profileIds: profileIds,
      screenIds: screenIds,
      localeCodes: localeCodes,
      themeIds: themeIds,
    );
  }

  /// True when the selection covers the whole approved matrix, which is the
  /// only situation where sweeping for unexpected files is meaningful.
  bool get coversApprovedMatrix {
    final selected = resolveCases().map((item) => item.relativePath).toSet();
    return AppStoreCaptureMatrix.approvedCases()
        .every((item) => selected.contains(item.relativePath));
  }
}
