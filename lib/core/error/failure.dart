/// The single error language every layer above `data/` speaks.
///
/// Sealed so a `switch` over it is exhaustive and the compiler names the place
/// that needs updating when a new failure type appears. That is the whole point
/// of the type: a `default` branch is where a new failure silently becomes
/// "something went wrong" forever.
///
/// Pure Dart — no Flutter, no Drift, no Dio. Data-layer exceptions are mapped
/// here at the repository boundary and never travel further.
///
/// Implements [Exception] because repositories throw failures across the
/// boundary (M4.9) and `only_throw_errors` rightly refuses anything that is
/// neither an Error nor an Exception.
sealed class Failure implements Exception {
  const Failure({required this.message, this.cause, this.reason});

  /// A sanitized diagnostic string. **Not a UI API.**
  ///
  /// MUST NOT carry SQL, a stack trace, a URL, a file path or an exception
  /// class name. `test/core/error/failure_test.dart` asserts this, because an
  /// error path is exactly where such a detail leaks: it is written while
  /// debugging and read only after release.
  ///
  /// **Production UI MUST NOT render it.** It is not localized — `domain/` and
  /// `core/` cannot import Flutter, so they cannot reach the ARB bundle — and a
  /// screen that showed it would present English to a Vietnamese user with no
  /// test failing anywhere. Screens map the failure **type** to ARB copy; see
  /// `features/deck/presentation/widgets/support/deck_labels_widget.dart` for the switch, and
  /// `MxAsyncView` for why no shared default exists.
  ///
  /// It is sanitized rather than raw because it does reach places a person
  /// reads: a log line, a test failure message, a `toString()` in a debugger.
  /// Being safe to *print* is not the same as being fit to *display*.
  ///
  /// This settles a contract that was left open when this file was written: the
  /// doc used to call it a display fallback and defer the ARB wiring to M5.4.
  /// The wiring arrived earlier, at M4.10, and arrived without a fallback —
  /// deliberately, because "fall back to the English diagnostic" is a rule that
  /// only ever fires on the paths nobody looked at.
  final String message;

  /// The original error, for logs only. Never rendered.
  final Object? cause;

  /// *Why*, as a value the UI can switch on.
  ///
  /// Typed as `Enum?` rather than a feature type, because `core/` must not import
  /// a feature (`check_architecture.sh` rule 4) and because `Failure` is
  /// **sealed** — a feature cannot add its own subtype, so the reason has to
  /// travel on an existing one.
  ///
  /// This exists because the alternative was worse and was live: fifteen
  /// different conflicts in the Deck repository each threw
  /// `ConflictFailure(message: '<its own English sentence>')`, and the one place
  /// that maps a failure to copy could only say
  /// `ConflictFailure() => l10n.deckConflictMessage`. Fifteen distinct reasons
  /// arrived at the user as one sentence, because the reason was encoded in a
  /// string the UI is forbidden to render.
  ///
  /// A feature declares its own enum in `domain/failures/` and matches on it:
  ///
  /// ```dart
  /// ConflictFailure(reason: final DeckMoveRejection rejection) =>
  ///     context.deckMoveRejection(rejection),
  /// ```
  ///
  /// The switch inside that helper is exhaustive over the feature's enum, so a
  /// new reason fails to compile until it has copy. `null` means the failure has
  /// no reason worth distinguishing — not that one was forgotten.
  final Enum? reason;
}

/// The device could not reach the server, or the request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.cause, super.reason});
}

/// Credentials are missing or no longer valid.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.cause,
    super.reason,
  });
}

/// Authenticated, but not allowed to do this.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required super.message, super.cause, super.reason});
}

/// Input did not satisfy a business or validation rule.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.problems = const <Enum>{},
    super.cause,
    super.reason,
  });

  /// Every rule the input broke, as values.
  ///
  /// A `Set` and not [Failure.reason] because a form can fail on two inputs at
  /// once — a blank name *and* an unchosen mandatory option — and `reason` holds
  /// one value. A set of enums rather than a `Map<String, String>` of field names
  /// to messages, because both halves of that map were wrong: the key was a
  /// string literal repeated at every site, and the value was a message the UI is
  /// forbidden to render, so the screen had to *re-derive* the problem from the
  /// raw input to find out which field to mark. Re-deriving made the presentation
  /// layer a second owner of the rule.
  ///
  /// Each value names the field **and** the reason — `nameEmpty`, `nameTooLong`,
  /// `schedulerMissing` — so the screen switches on it exhaustively and the ARB
  /// copy is chosen without the rule being evaluated again.
  ///
  /// Typed `Enum` rather than a feature type for the same reason as
  /// [Failure.reason]: `core/` must not import a feature.
  final Set<Enum> problems;
}

/// The requested thing does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.cause, super.reason});
}

/// The operation conflicts with the current state, e.g. a duplicate.
final class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.cause, super.reason});
}

/// Local persistence failed — a Drift or SQLite error, mapped at the boundary.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.cause, super.reason});
}

/// The caller cancelled the operation. Usually not worth showing at all.
final class CancelledFailure extends Failure {
  const CancelledFailure({required super.message, super.cause, super.reason});
}

/// Nothing more specific applies. Keep [cause] so the log still explains it.
final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.cause, super.reason});
}
