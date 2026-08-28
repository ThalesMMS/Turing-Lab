//
//  pda_simulator_extended_test.dart
//  Turing Lab
//
//  Tests covering extra PDA-simulator features
//  introduced by the part-file refactor: analisePDA, generation of
//  accepted and rejected strings, and simulation/analysis result models.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/simulation_cancelled_exception.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;
part 'pda_simulator_extended/anbn_fixture.dart';
part 'pda_simulator_extended/accepts_a_fixture.dart';
part 'pda_simulator_extended/unreachable_fixture.dart';
part 'pda_simulator_extended/model_tests.dart';
part 'pda_simulator_extended/analysis_tests.dart';
part 'pda_simulator_extended/simulation_tests.dart';

void main() {
  _runPdaModelTests();
  _runPdaAnalysisTests();
  _runPdaSimulationTests();
}
