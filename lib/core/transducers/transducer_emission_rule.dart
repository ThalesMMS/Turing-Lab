import 'transducer_models.dart';
import 'transducer_symbols.dart';

abstract interface class TransducerEmissionRule {
  TransducerOutputWord initialOutput(TransducerState initialState);

  TransducerOutputWord transitionOutput(
    TransducerTransition transition,
    TransducerState targetState,
  );
}

final class MealyEmissionRule implements TransducerEmissionRule {
  const MealyEmissionRule();

  @override
  TransducerOutputWord initialOutput(TransducerState initialState) =>
      TransducerOutputWord.empty;

  @override
  TransducerOutputWord transitionOutput(
    TransducerTransition transition,
    TransducerState targetState,
  ) =>
      (transition as MealyTransition).output;
}

final class MooreEmissionRule implements TransducerEmissionRule {
  const MooreEmissionRule();

  @override
  TransducerOutputWord initialOutput(TransducerState initialState) =>
      (initialState as MooreState).output;

  @override
  TransducerOutputWord transitionOutput(
    TransducerTransition transition,
    TransducerState targetState,
  ) =>
      (targetState as MooreState).output;
}
