import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/constants/help_content.dart';

void main() {
  test('fit and reset help link to the companion zoom tools', () {
    expect(
      kHelpContent['tool_fit_content']!.relatedConcepts,
      containsAll(['tool_zoom_in', 'tool_zoom_out', 'tool_reset_view']),
    );
    expect(
      kHelpContent['tool_reset_view']!.relatedConcepts,
      containsAll(['tool_zoom_in', 'tool_zoom_out', 'tool_fit_content']),
    );
  });
}
