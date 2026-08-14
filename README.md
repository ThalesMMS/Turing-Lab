# Turing Lab

Turing Lab is a Flutter reimplementation of the JFLAP educational tool. It offers an interactive, touch-first workspace for creating, analysing, and simulating finite automata, grammars, pushdown automata, Turing machines, and regular expressions. The current release focus is Apple v1.0 for iPhone, iPad, and macOS, with Android build support and preview web/desktop targets tracked separately.

<p align="center">
  <img src="./screenshots/screenshot1.png" alt="Automaton canvas screenshot" width="600" />
  <img src="./screenshots/screenshot2.png" alt="Regex module screenshot" width="600" />
  <img src="./screenshots/screenshot3.png" alt="Grammar editor screenshot" width="300" />
</p>

## Project Status

**Status:** Work in Progress. The Apple v1.0 release scope is frozen to the FSA, Grammar, PDA, TM, Regex, and Pumping Lemma workspaces documented in `V1_SCOPE.md`.

- Release notes: `CHANGELOG.md`
- Roadmap and deferred JFLAP parity work: `ROADMAP.md`
- Current Apple v1.0 scope and limitations: `V1_SCOPE.md`

## Public Links

- Website: https://thalesmms.github.io/JFlutter/
- Support: https://thalesmms.github.io/JFlutter/support.html
- Privacy Policy: https://thalesmms.github.io/JFlutter/privacy.html
- Issues: https://github.com/ThalesMMS/jflutter/issues

## Highlights

### Learning tools
- Touch-friendly canvas for creating and editing automata
- Step-by-step simulators for finite automata, pushdown automata, and Turing machines
- Grammar editors with validation and conversion helpers
- Regular-expression workflows for validation, testing, comparison, and conversion
- Inline explanations and diagnostics to support classroom use

### Algorithms shipped in the app
- Conversions between NFA, DFA, and regular expressions
- DFA minimisation and automaton simulation traces
- Grammar analysis utilities for the shipped release workflows
- Single-tape Turing machine construction and execution

### User experience and performance
- Material 3 interface with light and dark themes
- Adaptive layouts for phones, tablets, desktops, and the web
- Optimised canvas rendering (viewport culling, level-of-detail drawing, and highlight tracing)
- Workspace-scoped import/export flows aligned to the v1.0 release contract in `V1_SCOPE.md`

### Offline examples
The repository bundles ready-to-use examples covering DFAs, NFAs, CFGs, PDAs, and Turing Machines in `assets/examples/`. They are declared in `pubspec.yaml` so the material is available without a network connection.

## Architecture

### Clean Architecture Implementation
```
┌─────────────────────────────────────┐
│        Presentation Layer           │
│  (UI Components, Pages, Providers)  │
├─────────────────────────────────────┤
│         Core Layer                  │
│  (Algorithms, Models, Business)     │
├─────────────────────────────────────┤
│          Data Layer                 │
│  (Services, Repositories, Storage)  │
└─────────────────────────────────────┘
```

### Project Structure
```
lib/
├── app.dart                        # Root widget and global configuration
├── core/                           # Core business logic
│   ├── algorithms/                 # Automata algorithms and utilities
│   ├── constants/                  # Shared constants and definitions
│   ├── entities/                   # Domain entities shared across layers
│   ├── models/                     # Immutable data models and value objects
│   ├── parsers/                    # File/grammar parsing helpers
│   ├── regex/                      # Regex helpers and transformation pipeline
│   ├── repositories/               # Repository contracts
│   ├── services/                   # Core services (diagnostics, trace, etc.)
│   ├── use_cases/                  # Application-specific business rules
│   ├── validators/                 # Input and semantic validators
│   ├── error_handler.dart          # Error handling helpers
│   └── result.dart                 # Result/Either pattern implementation
├── data/                           # Data layer implementations
│   ├── data_sources/               # Concrete data sources (e.g., file system)
│   ├── models/                     # DTOs and serialization helpers
│   ├── repositories/               # Repository implementations
│   ├── services/                   # High-level services used by the app
│   └── storage/                    # Persistent storage adapters (e.g., SharedPreferences)
├── features/                       # Cross-cutting feature modules
│   ├── canvas/                     # Canvas orchestration layers
│   │   └── graphview/              # GraphView controllers, mappers, and highlight channels
│   └── layout/                     # Layout helpers and view-specific configs
├── injection/                      # Dependency injection setup
│   └── dependency_injection.dart   # Service registration and bootstrap
├── main.dart                       # Application entry point
└── presentation/                   # UI layer and state management
    ├── pages/                      # Screens and navigation flows
    ├── providers/                  # Riverpod providers
    ├── theme/                      # App theming (Material 3)
    └── widgets/                    # Reusable UI components
```

## Getting Started

### Prerequisites
- Flutter SDK 3.27.0+
- Dart SDK 3.6.0+
- Android Studio / VS Code (recommended)

### Installation

```bash
# Clone the repository
git clone https://github.com/ThalesMMS/jflutter.git turing-lab
cd turing-lab

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Android release signing

Android release builds are signed with the `thalesmms.turinglab` application ID. The Gradle script loads release keystore
credentials from `android/key.properties`, which can now be generated from environment variables using
`android/scripts/create_key_properties.sh`.

1. Generate or obtain a release keystore (for example `android/keystores/turing-lab-release.jks`). Keep this file out of
   version control.
2. Export the following environment variables before building or running the helper script:
   - `TURING_LAB_KEYSTORE_PASSWORD`
   - `TURING_LAB_KEY_ALIAS`
   - `TURING_LAB_KEY_PASSWORD`
   - *(optional)* `TURING_LAB_KEYSTORE_PATH` (defaults to `keystores/turing-lab-release.jks`, relative to `android/`)
3. Run `./android/scripts/create_key_properties.sh` to generate `android/key.properties` from the exported values.

For CI/CD, store the keystore and credential values as encrypted secrets. During the workflow, recreate the keystore file
and call the helper script before `flutter build`. Example (GitHub Actions):

```bash
mkdir -p android/keystores
echo "$TURING_LAB_KEYSTORE_BASE64" | base64 --decode > android/keystores/turing-lab-release.jks
export TURING_LAB_KEYSTORE_PASSWORD="$TURING_LAB_KEYSTORE_PASSWORD"
export TURING_LAB_KEY_ALIAS="$TURING_LAB_KEY_ALIAS"
export TURING_LAB_KEY_PASSWORD="$TURING_LAB_KEY_PASSWORD"
./android/scripts/create_key_properties.sh
```

### Platform Support

Turing Lab is a Flutter project with multiple build targets, but release support
depends on documented signing, QA, and distribution evidence.

- **iOS / iPadOS** - Apple v1.0 release target. Release QA is tracked in
  `release/APPLE_QA_MATRIX.md`.
- **macOS** - Apple v1.0 release target. Release validation is tracked in
  `release/MACOS_QA_CHECKLIST.md`,
  `release/MACOS_PLATFORM_VALIDATION.md`, and the Apple release docs.
- **Android** - Supported build target with release signing documented above.
  A full Android QA checklist is still a follow-up item.
- **Web** - Preview/classroom-demo target. The responsive UI is maintained, but
  web has platform-specific limitations such as no PNG export.
- **Windows / Linux** - Development and community-supported preview targets.
  The platform folders are present, but the repository does not yet include
  Windows or Linux release checklists. Do not treat these as release-supported
  until matching `release/WINDOWS_*` and `release/LINUX_*` evidence exists.

## How to Use

### Creating an Automaton
1. Open the **FSA** workspace.
2. Add states with the **+** action and drag them into place.
3. Choose the arrow tool to connect states with transitions.
4. Double tap to edit state names or toggle initial/final markers.
5. Run conversions or minimisation from the algorithms panel.

### Testing Strings
1. Enter a string in the simulation panel.
2. Select **Simulate** to execute the automaton.
3. Inspect the trace output or canvas highlights to understand each step.

### Working with Grammars
1. Open the **Grammar** workspace.
2. Provide the grammar metadata and production rules.
3. Use the available algorithms to convert or analyse the grammar.
4. Test sample strings directly within the editor.

## Testing

### Test Suite Overview

Run `flutter test` (Flutter 3.27.0+ / Dart 3.6.0+) to execute the full suite. For the current repository baseline and known-failure counts, refer to `AGENTS.md`. Tests are organised to mirror the architecture:

- **Algorithm validation** – `test/unit/` keeps DFA/NFA conversions, grammar analysis, and regex tooling aligned with the references.
- **Core services** – `test/core/services/` verifies utilities such as the simulation highlight broadcaster.
- **Canvas features** – `test/features/canvas/graphview/` exercises controllers, mappers, and models for the interactive canvas.
- **Integration** – `test/integration/io/` performs round-trips across JFLAP XML, JSON, SVG, and the offline example bundle.
- **Widget harnesses** – `test/widget/presentation/` drives UI flows while production widgets are completed.

### Placeholder and Pending Work

- `test/widget/presentation/ux_error_handling_test.dart` is an active widget suite covering import-error UX flows.

#### Running Tests

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/unit/                    # Core algorithm suites
flutter test test/features/                # Feature-level canvas suites
flutter test test/integration/             # Integration tests
flutter test test/widget/                  # Widget harnesses

# Golden visual regression tests
./run_golden_tests.sh
./tool/update_goldens.sh                   # Re-record intentional golden changes

# Run with code coverage
flutter test --coverage
lcov --list coverage/lcov.info

# Static analysis
flutter analyze
```

## Reference Implementation Methodology

During the ongoing migration, algorithm parity is tracked through `docs/reference-deviations.md` and stable upstream source links. The historical local reference snapshots are not committed in this checkout, so the Dart repositories and Python `automata-main` module are used through their upstream anchors as validation checkpoints while the Flutter core is rebuilt.

### Validation Approach
Each algorithm modification is cross-validated against the recorded upstream reference anchors and the local automated suites to ensure correctness and maintainability.

### Reference Usage Process
1. **Algorithm Development** - Implement new algorithms based on reference implementations
2. **Cross-Validation** - Compare outputs with reference implementations
3. **Test Suite Validation** - Validate against reference test cases
4. **Performance Benchmarking** - Ensure performance meets or exceeds references
5. **Documentation** - Record any deviations with rationale in `docs/reference-deviations.md`

### Quality Assurance
- **Algorithm Coverage** - Deterministic automata, grammar, and regex suites in `test/unit/` back the domain layer.
- **Integration Guardrails** - Serialization and examples are validated through the IO round-trip suites in `test/integration/io/`.
- **UI Exercisers** - Canvas and control widgets are kept regression-safe via the harnesses in `test/widget/presentation/` and the component golden suites in `test/goldens/`.
- **Performance Monitoring** - Regular benchmarking against reference implementations.
- **Deviation Tracking** - All deviations documented with impact assessment and cross-checked with references.
- **Continuous Validation** - Ongoing comparison with reference implementations.

### Reference Maintenance
- **Version Control** - Reference targets are tracked as upstream source anchors instead of local snapshots
- **Update Process** - Update `docs/reference-deviations.md` whenever parity targets or intentional deviations change
- **Compatibility** - Ensure compatibility with reference API changes
- **Documentation** - Keep reference usage documentation current

## Project Overview

### Completed Features
- Validated automata algorithms covering DFA/NFA conversions, regex tooling, and grammar processing
- Riverpod-based state management with a clean-architecture layout
- Responsive UI components for automata, grammars, PDAs, and Turing machines
- Offline example library and import/export flows for JFLAP interoperability

### Future Enhancements
- Richer visual explanations for algorithm steps
- Expanded export formats and sharing workflows
- Guided tutorials for first-time learners
- Additional grammar analysis tooling and PDA/TM canvas refinements

## Development

### Code Quality
- **Clean Architecture** - Separation of concerns
- **Type Safety** - Strong typing throughout
- **Error Handling** - Comprehensive error management
- **Testing** - Unit, integration, and contract tests
- **Documentation** - Inline documentation and examples
- **Responsive Design** - Mobile-first approach

### Contributing
1. Fork the repository
2. Create a feature branch
3. Follow the coding standards
4. Add tests for new features
5. Submit a pull request
Try to maintain compatibility. Avoid changing core automata/grammar/pda/turing machine algorithms without discussing it first.

### Development Guidelines
- Optimise for phone, tablet, and desktop layouts with accessibility in mind
- Keep tests and documentation current
- Coordinate changes to shared algorithms before altering behaviour

## Educational Value

Turing Lab is designed for:
- **Computer Science Students** - Learning automata theory
- **Educators** - Teaching formal languages
- **Researchers** - Prototyping automata
- **Developers** - Understanding regular expressions

## License

This project is distributed under a dual license structure:

### Turing Lab
- **License**: Apache License 2.0
- **Copyright**: 2025–present Turing Lab contributors (see [Contributors](#community--contributors))
- **Contact**: thalesmmsradio@gmail.com
- **File**: [LICENSE.txt](LICENSE.txt)

### Original JFLAP Code
- **License**: JFLAP 7.1 License (Non-commercial)
- **Copyright**: 2002-2009 Susan H. Rodger (Duke University)
- **File**: [LICENSE_JFLAP.txt](LICENSE_JFLAP.txt)

### License Summary
- The **Flutter port** (all new code) is licensed under Apache 2.0, allowing free use, modification, and distribution with proper attribution
- Turing Lab is treated conservatively as a **JFLAP derivative work** where it includes JFLAP-derived algorithms, concepts, data structures, XML import/export behavior, and `.jff` compatibility
- The **original JFLAP algorithms and concepts** remain under the original JFLAP license, which prohibits commercial use
- This dual structure ensures compliance with the original license while allowing the Flutter port to be freely used and modified

### Distribution
- Turing Lab may be distributed via the Apple App Store for iOS, iPadOS, and macOS, and via Google Play Store, as a free application only
- Commercial distribution, paid downloads, in-app purchases, subscriptions, and advertising are prohibited by the JFLAP license
- See [LEGAL_DISTRIBUTION.md](LEGAL_DISTRIBUTION.md) for the full legal analysis
- Distributed binaries must include `LICENSE.txt` and `LICENSE_JFLAP.txt`, and the app must keep both license texts accessible to users

## Acknowledgments & References

### Development
- **Thales Matheus Mendonça Santos** - Complete Turing Lab development until 2025-10-07, graphview fork optimization for loop transitions rendering
- **Email**: thalesmmsradio@gmail.com
- **Year**: 2025

### Original Project & Primary Inspiration
- **Susan H. Rodger** (Duke University) - Original JFLAP creator and maintainer
- **JFLAP Team** - Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, Henry Qin
- **Duke University** - For the foundational educational tool
- **Website**: http://www.jflap.org

### Reference Implementations & Algorithm Sources

#### Core Algorithm References
- **automata-main upstream** - Python implementation of automata algorithms
  - **Source**: [automata-main](https://github.com/caleb531/automata) by Caleb Evans
  - **Usage**: Primary reference for NFA to DFA conversion, DFA minimization, regex operations
  - **Validation**: All core algorithms validated against this implementation

- **dart-petitparser-examples upstream** - Dart parser examples and utilities
  - **Source**: [dart-petitparser-examples](https://github.com/petitparser/dart-petitparser-examples) by PetitParser
  - **Usage**: Regex parsing, grammar analysis, parser construction
  - **Validation**: Parser implementations validated against these examples

- **AutomataTheory upstream** - Dart automata theory implementations
  - **Source**: [AutomataTheory](https://github.com/dart-lang/samples/tree/master/automata_theory) by Pedro Lemos
  - **Usage**: Finite automata operations, language theory concepts
  - **Validation**: Automaton operations validated against this reference

- **nfa_2_dfa upstream** - NFA to DFA conversion algorithms
  - **Source**: [nfa_2_dfa](https://github.com/7Na7iD7/nfa_2_dfa) by Na7iD
  - **Usage**: NFA to DFA conversion algorithms, state minimization
  - **Validation**: Conversion algorithms validated against this implementation

#### Educational & Design Inspiration
- **JFLAP Educational Philosophy** - Interactive learning approach
- **Material Design 3** - Modern UI/UX principles
- **Flutter Best Practices** - Mobile-first development patterns
- **Academic Automata Theory** - Hopcroft, Ullman, and Sipser algorithms

### Technology Stack & Frameworks
- **Flutter Team** - For the excellent cross-platform framework
- **Dart Team** - For the programming language
- **Riverpod Team** - For state management solutions
- **GraphView Contributors** - For the graph rendering toolkit powering the native automaton canvas
- **Material Design Team** - For design system and components
- **Open Source Community** - For inspiration and support

### Community & Contributors
- **Prof. Zenilton Kleber Gonçalves do Patrocínio Júnior** - For educational guidance and feedback
- **[@Gaok1](https://github.com/Gaok1)** - Luis Phillip Lemos Martins - For inspiring this Flutter project
