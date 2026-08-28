import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';

final tmToGrammarOpenedReportProvider =
    StateProvider<TMToGrammarConstructionReport?>((ref) => null);
