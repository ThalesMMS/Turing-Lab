//
//  main.dart
//  Turing Lab
//
//  Ponto de entrada que inicializa o binding do Flutter, configura as
//  dependências compartilhadas com o injetor e executa o TuringLabApp como
//  aplicação raiz para iniciar a experiência multiplataforma.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'injection/dependency_injection.dart';
import 'app.dart';
import 'presentation/providers/unified_trace_provider.dart';

part 'startup_error_helpers.dart';
part 'initialization_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandler();

  try {
    final prefs = await initializeSharedPreferences();

    runApp(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const TuringLabApp(),
      ),
    );
  } catch (error, stackTrace) {
    _reportInitializationFailure(error, stackTrace);
    runApp(const _InitializationErrorApp());
  }
}
