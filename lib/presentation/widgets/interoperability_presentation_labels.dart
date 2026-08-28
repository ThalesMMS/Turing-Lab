import 'package:flutter/widgets.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../l10n/app_localizations_resolver.dart';

String defaultDocumentFormatLabel(
  BuildContext context,
  DocumentFormatId format,
) {
  final l10n = appLocalizationsOf(context);
  if (format == DefaultFormalSystemIds.jflapXmlFormat) {
    return l10n.interoperabilityFormatJflapXml;
  }
  if (format == DefaultFormalSystemIds.turingLabJsonFormat) {
    return l10n.interoperabilityFormatTuringLabJson;
  }
  return format.value;
}
