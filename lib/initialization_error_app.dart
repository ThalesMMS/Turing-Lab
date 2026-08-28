part of 'main.dart';

class _InitializationErrorApp extends StatelessWidget {
  const _InitializationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: AppLocalePolicy.resolve(
        persistedLocaleCode: null,
        platformLocales: View.of(context).platformDispatcher.locales,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalePolicy.supportedLocales,
      home: const _InitializationErrorBody(),
    );
  }
}

class _InitializationErrorBody extends StatelessWidget {
  const _InitializationErrorBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      l10n.initializationErrorTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.initializationErrorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
