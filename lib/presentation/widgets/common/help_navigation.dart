import 'package:flutter/material.dart';

import '../../../core/constants/help_catalog.dart';
import '../../pages/help_page.dart';

String validateHelpTopicId(String topicId) {
  if (kHelpCatalog.pathForTopic(topicId) == null) {
    throw ArgumentError.value(
      topicId,
      'topicId',
      'Must identify a topic in the Help catalog',
    );
  }
  return topicId;
}

/// Opens the unified Help catalog on the root navigator.
Future<void> openHelp(BuildContext context, {String? topicId}) {
  final validatedTopicId =
      topicId == null ? null : validateHelpTopicId(topicId);
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => HelpPage(initialTopicId: validatedTopicId),
    ),
  );
}
