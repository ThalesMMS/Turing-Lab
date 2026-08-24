/// Acceptance conventions supported by pushdown automata.
///
/// [both] means that the complete input has been consumed, the current state
/// is accepting, and the stack is empty at the same time.
enum PDAAcceptanceMode { finalState, emptyStack, both }
