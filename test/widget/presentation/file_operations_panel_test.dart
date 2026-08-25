//
//  file_operations_panel_test.dart
//  Turing Lab
//
//  Widget tests for the file operations panel, covering contextual buttons,
//  loading states, error banners, and save/load/export callbacks. Scenarios
//  include automata and grammars on web and desktop, confirming that async
//  operations update the visual state.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/services/file_operations_service.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';
import 'package:turing_lab/presentation/widgets/file_operations_panel.dart';
import 'package:turing_lab/presentation/widgets/import_error_dialog.dart';
import 'package:vector_math/vector_math_64.dart';
part 'file_operations_panel/basic_rendering_tests.dart';
part 'file_operations_panel/automaton_operation_tests.dart';
part 'file_operations_panel/machine_operation_tests.dart';
part 'file_operations_panel/loading_error_tests.dart';
part 'file_operations_panel/message_cancellation_tests.dart';
part 'file_operations_panel/fixtures.dart';

void main() {
  late _FakeFilePicker fakeFilePicker;

  setUp(() {
    fakeFilePicker = _FakeFilePicker();
    FilePicker.platform = fakeFilePicker;
  });

  _runFileOperationsPanelBasicRenderingTests();
  _runFileOperationsPanelAutomatonOperationTests(() => fakeFilePicker);
  _runFileOperationsPanelMachineOperationTests(() => fakeFilePicker);
  _runFileOperationsPanelLoadingErrorTests(() => fakeFilePicker);
  _runFileOperationsPanelMessageCancellationTests(() => fakeFilePicker);
}
