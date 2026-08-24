sealed class HelpContentBlock {
  const HelpContentBlock();

  Iterable<String> get textSegments;
}

final class HelpParagraphBlock extends HelpContentBlock {
  const HelpParagraphBlock(this.text);

  final String text;

  @override
  Iterable<String> get textSegments => [text];
}

final class HelpHeadingBlock extends HelpContentBlock {
  const HelpHeadingBlock(this.text);

  final String text;

  @override
  Iterable<String> get textSegments => [text];
}

final class HelpOrderedStepsBlock extends HelpContentBlock {
  HelpOrderedStepsBlock(List<String> steps) : steps = List.unmodifiable(steps);

  final List<String> steps;

  @override
  Iterable<String> get textSegments => steps;
}

final class HelpCalloutBlock extends HelpContentBlock {
  const HelpCalloutBlock(this.text);

  final String text;

  @override
  Iterable<String> get textSegments => [text];
}
