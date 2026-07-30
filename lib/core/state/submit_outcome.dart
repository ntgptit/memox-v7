/// What a form asked to happen after a successful write, and what happened.
///
/// Two enums rather than one boolean, because `isDone: true` cannot express the
/// difference between "saved, close the editor" and "saved, keep the editor open
/// for the next one" — and a form that supports *Save and add another* needs both
/// (M4.11, BR-07/08 card editor).
///
/// **This is the trap the boolean set.** Deck's forms all close on success, so the
/// draft in the widget's `TextEditingController` disappeared when the widget was
/// disposed and nobody had to think about clearing it. A form that stays open has
/// three problems at once, and cloning Deck reproduces all three:
///
/// 1. the transition to done pops the sheet, so the editor closes when it should
///    not;
/// 2. if it does not close, the controller still holds the text of the record that
///    was just saved — and `reset()` on the notifier cannot reach widget-local
///    state;
/// 3. `canSubmit` was `!isSubmitting && !isDone`, so the *next* submit was blocked
///    until something called `reset()`.
///
/// Naming the disposition fixes all three: the state says which kind of success
/// happened, only `savedAndClose` closes anything, and `canSubmit` stays true
/// after `savedAndContinue`.
library;

/// What the caller wants to happen after the write succeeds.
///
/// Passed *into* submit, and only by operations that can sensibly repeat —
/// creating a record. Rename, delete, reset and move have nothing to add another
/// of, so they do not take it.
enum SubmitDisposition {
  /// Finish: the editor is going away.
  close,

  /// Stay open and take the next entry — *Save and add another*.
  addAnother;

  /// The success this disposition produces.
  ///
  /// A getter rather than a `switch` at each call site: the pairing is one-to-one
  /// and a controller re-deriving it is a controller that can get it wrong.
  SubmitOutcome get outcome => switch (this) {
    SubmitDisposition.close => SubmitOutcome.savedAndClose,
    SubmitDisposition.addAnother => SubmitOutcome.savedAndContinue,
  };
}

/// What happened, reported once so the widget can react to the transition.
///
/// Held in the submit state rather than delivered as an event, because a widget
/// rebuild must be able to tell "already handled" from "just happened" — which is
/// a comparison against the previous state, not a queue.
enum SubmitOutcome {
  /// The write succeeded and the editor should close. The widget pops; it does
  /// **not** hand the saved record back through `Navigator.pop` — the list behind
  /// re-renders because its `watch()` stream re-emitted.
  savedAndClose,

  /// The write succeeded and the editor stays open.
  ///
  /// On this transition the widget MUST, in this order: clear its own draft
  /// controllers, clear any field errors, return the submit state to idle, and
  /// move focus back to the first field. Clearing happens **only after** the
  /// repository confirmed the write — a draft cleared optimistically is a card
  /// the user typed and lost.
  savedAndContinue,
}
