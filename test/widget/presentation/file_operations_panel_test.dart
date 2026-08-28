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
// feature-localization-contract: interoperability-notes-and-export
// feature-localization-surface: localized-import-export
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
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
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_binding.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';
import 'package:turing_lab/presentation/widgets/error_banner.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';
import 'package:turing_lab/presentation/widgets/file_operations_panel.dart';
import 'package:turing_lab/presentation/widgets/import_error_dialog.dart';
import 'package:turing_lab/presentation/widgets/registered_file_operation.dart';
import 'package:turing_lab/presentation/widgets/utils/platform_file_loader.dart';
import 'package:turing_lab/presentation/widgets/visual_export_binding.dart';
import 'package:vector_math/vector_math_64.dart';
part 'file_operations_panel/basic_rendering_tests.dart';
part 'file_operations_panel/automaton_operation_tests.dart';
part 'file_operations_panel/machine_operation_tests.dart';
part 'file_operations_panel/loading_error_tests.dart';
part 'file_operations_panel/message_cancellation_tests.dart';
part 'file_operations_panel/fixtures.dart';
part 'file_operations_panel/registered_module_tests.dart';
part 'file_operations_panel/interoperability_tests.dart';

StructuredMessage _parserFailureMessage(String namespace, String code) =>
    StructuredMessage(
      namespace: namespace,
      code: code,
      category: StructuredMessageCategory.interoperability,
      severity: StructuredMessageSeverity.error,
    );

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
  _runRegisteredModuleFileOperationTests(() => fakeFilePicker);
  _runInteroperabilityFileOperationTests(() => fakeFilePicker);
}
