part of 'help_page.dart';

class _LicenseTextCard extends StatefulWidget {
  const _LicenseTextCard({
    super.key,
    required this.title,
    required this.assetPath,
    required this.summary,
  });

  final String title;
  final String assetPath;
  final String summary;

  @override
  State<_LicenseTextCard> createState() => _LicenseTextCardState();
}

class _LicenseTextCardState extends State<_LicenseTextCard> {
  Future<String>? _licenseTextFuture;

  @override
  void didUpdateWidget(covariant _LicenseTextCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.assetPath != oldWidget.assetPath) {
      setState(() {
        _licenseTextFuture = null;
      });
    }
  }

  void _loadLicenseText() {
    if (_licenseTextFuture != null) return;
    setState(() {
      final licenseTextFuture = Future<String>(
        () => rootBundle.loadString(widget.assetPath),
      );
      licenseTextFuture.catchError((Object _) => '');
      _licenseTextFuture = licenseTextFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(widget.title),
        subtitle: Text(widget.summary),
        onExpansionChanged: (isExpanded) {
          if (isExpanded) {
            _loadLicenseText();
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLicenseBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseBody() {
    final l10n = jflapLocalizationsOf(context);
    final licenseTextFuture = _licenseTextFuture;
    if (licenseTextFuture == null) {
      return Text(l10n.aboutLicenseExpandPrompt);
    }

    return FutureBuilder<String>(
      future: licenseTextFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  l10n.aboutLicenseLoadFailed(snapshot.error!),
                ),
              ),
            ],
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(l10n.aboutLicenseLoading);
        }
        return SelectableText(snapshot.data ?? '');
      },
    );
  }
}
