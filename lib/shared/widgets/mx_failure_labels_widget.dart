import 'package:flutter/widgets.dart';

import '../../core/error/failure.dart';
import '../../l10n/l10n_extension.dart';

/// A failure, as copy the user can act on — the half that is not any one
/// feature's.
///
/// Maps the `Failure` **type**, never its message: `Failure.message` is written
/// for whoever reads a log and can name a table or an exception.
///
/// **Every subtype is listed and there is no `_` branch**, which is the whole
/// reason `Failure` is sealed. Deck's copy of this switch used to end in a
/// catch-all, and that defeated the type: a new failure subtype would have
/// compiled straight into "something went wrong" with nothing failing anywhere.
/// Keeping the exhaustive switch in one place means the next feature inherits
/// that compile-time forcing instead of re-deriving it — and re-deriving it is
/// how one of the two copies ends up with a `_`.
///
/// **Two subtypes are the caller's, and they are the two that carry meaning.**
/// A [NotFoundFailure] answers *what* is gone — the deck you were adding to, or
/// the card you were editing — and the recoveries differ. A [ConflictFailure]
/// carries its reason as an enum, and the enums are per-feature by definition.
/// Everything else has one honest answer: the write did not land, try again.
/// Passing the two as required callbacks is what stops a feature from quietly
/// falling back to the generic line for them.
extension MxFailureLabels on BuildContext {
  String mxWriteFailure(
    Failure failure, {
    required String Function(NotFoundFailure) onNotFound,
    required String Function(ConflictFailure) onConflict,
  }) => switch (failure) {
    NotFoundFailure() => onNotFound(failure),
    ConflictFailure() => onConflict(failure),

    // Reachable, and there is nothing more useful to say: the write did not
    // land and retrying is the only move.
    DatabaseFailure() => l10n.writeErrorMessage,
    UnknownFailure() => l10n.writeErrorMessage,

    // A cancelled write is usually not worth a message at all, but an error
    // state renders whenever `failure != null`, so silence here would be an
    // empty banner. Revisit if a flow ever cancels deliberately.
    CancelledFailure() => l10n.writeErrorMessage,

    // Should never arrive: a controller peels `ValidationFailure` off into the
    // per-field problems before the state is built. Listed rather than grouped
    // so that if that ever changes, this line is where someone looks.
    ValidationFailure() => l10n.writeErrorMessage,

    // Unreachable today — no network (AD-05) and no auth (AD-03), so nothing
    // can construct these. They are enumerated instead of swept under a `_` so
    // that M9 has to come here and decide, rather than inheriting a generic
    // string it never chose. A session that expired mid-write is not "an error
    // occurred".
    NetworkFailure() => l10n.writeErrorMessage,
    UnauthorizedFailure() => l10n.writeErrorMessage,
    ForbiddenFailure() => l10n.writeErrorMessage,
  };
}
