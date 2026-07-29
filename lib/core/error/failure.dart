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
  const Failure({required this.message, this.cause});

  /// Safe to show to a user as-is.
  ///
  /// MUST NOT carry SQL, a stack trace, a URL, a file path or an exception
  /// class name. `test/core/error/failure_test.dart` asserts this, because an
  /// error path is exactly where such a detail leaks: it is written while
  /// debugging and read only after release.
  ///
  /// Not localized, and deliberately so: `domain/` and `core/` cannot import
  /// Flutter, so they cannot reach the ARB bundle. This is the safe fallback.
  /// A screen that renders a failure SHOULD pick its copy from ARB by failure
  /// type and fall back to this — that wiring belongs to the first screen that
  /// actually shows an error (M5.4), not to a guess made here.
  final String message;

  /// The original error, for logs only. Never rendered.
  final Object? cause;
}

/// The device could not reach the server, or the request timed out.
final class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.cause});
}

/// Credentials are missing or no longer valid.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message, super.cause});
}

/// Authenticated, but not allowed to do this.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({required super.message, super.cause});
}

/// Input did not satisfy a business or validation rule.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    this.fieldErrors = const <String, String>{},
    super.cause,
  });

  /// Field name to the message for that field.
  ///
  /// Carried separately from [message] so a form can put each error next to the
  /// input that caused it instead of showing one summary line — the difference
  /// between "something is wrong" and "this field is wrong".
  final Map<String, String> fieldErrors;
}

/// The requested thing does not exist.
final class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message, super.cause});
}

/// The operation conflicts with the current state, e.g. a duplicate.
final class ConflictFailure extends Failure {
  const ConflictFailure({required super.message, super.cause});
}

/// Local persistence failed — a Drift or SQLite error, mapped at the boundary.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.cause});
}

/// The caller cancelled the operation. Usually not worth showing at all.
final class CancelledFailure extends Failure {
  const CancelledFailure({required super.message, super.cause});
}

/// Nothing more specific applies. Keep [cause] so the log still explains it.
final class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.cause});
}
