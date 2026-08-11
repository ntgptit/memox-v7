import '../models/deck_template_model.dart';
import '../models/scheduler_type_model.dart';

/// What one install attempt did.
///
/// Named rather than a `bool` because "nothing happened" is the *expected*
/// outcome on every launch after the first, and a caller reading `false` has to
/// guess whether that meant "already there" or "it failed".
enum DeckTemplateInstallOutcome {
  /// A copy was written: root, sub-decks, cards and study states (BR-33).
  installed,

  /// A copy of this `(template_id, version)` already existed, so nothing was
  /// written (BR-37).
  alreadyPresent,
}

/// Copying published starter decks into the user's own data (AD-07, UC-01).
///
/// **A separate contract from `DeckRepository`, because it is a separate
/// question.** `DeckRepository` is what the deck screens call; nothing on those
/// screens installs a template, and nothing here is needed to render a deck. The
/// split also keeps the deck contract from growing a method whose only caller is
/// startup.
abstract interface class DeckTemplateRepository {
  /// Copies [template] into the user's decks, once.
  ///
  /// **Idempotent on `(source_template_id, source_template_version)` (BR-37).**
  /// Re-opening the app must not duplicate a deck, and the check is inside the
  /// same transaction as the write — outside it, two launches racing (a cold
  /// start that opens the database twice, a test running installs in parallel)
  /// would both see "absent" and both write.
  ///
  /// **One transaction for the whole tree (BR-39).** A partially copied deck is
  /// worse than none: it looks like a real deck, and the user cannot tell which
  /// half is missing.
  ///
  /// [schedulerType] defaults to the template's own suggestion. A template only
  /// *may* suggest (BR-34) — the choice belongs to the copy, and it locks after
  /// the first review.
  ///
  /// Returns [DeckTemplateInstallOutcome.alreadyPresent] without writing when a
  /// copy is already there, rather than throwing: on the path that calls this
  /// — startup — "already installed" is the normal case, not an error.
  /// [allowDuplicate] is BR-38's deliberate exception: a user who has
  /// confirmed "this already exists" may add a second copy on purpose. It
  /// bypasses only the idempotency short-circuit — the copy itself is the same
  /// transaction — and nothing automatic may ever pass true: the seed path and
  /// the default install stay idempotent (BR-37).
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  });

  /// The identities of templates the library already holds a copy of, as the
  /// same `(template_id, version)` pairs the idempotency check uses (BR-37).
  ///
  /// One read for the whole catalog rather than a per-template probe: the
  /// starter screen marks every row from one snapshot, and a loop of existence
  /// checks would be the N+1 UC-06 names.
  ///
  /// **Advisory, never authoritative.** The install transaction re-checks
  /// inside itself; this exists so the screen can *say* a template is already
  /// added instead of offering a copy that BR-37 will refuse to make.
  Future<Set<({String templateId, int version})>> installedTemplateKeys();
}
