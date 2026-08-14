part of 'main.dart';

void _installGlobalErrorHandler() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[Startup] Unhandled Flutter error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };
}

void _reportInitializationFailure(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'Turing Lab startup',
      context: ErrorDescription('while initializing dependency injection'),
    ),
  );
  debugPrint('[Startup] Failed to initialize app: $error');
  debugPrintStack(stackTrace: stackTrace);
}
