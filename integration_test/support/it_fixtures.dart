import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import 'it_harness.dart';

/// The learned-state fixtures of `00-agent-execution-guide.md` §6.
///
/// | | |
/// |---|---|
/// | Artifact path | `integration_test/support/it_fixtures.dart` |
/// | Version | [version] |
/// | Load | `ItFixtures.loadDueLibrary` / `ItFixtures.loadLargeDeck` |
/// | Reset | each loader wipes first, so loading twice equals loading once |
/// | Clock | callers pin the harness to [kT0] before `launchApp` |
///
/// **Content goes through the real repositories; learned state does not,
/// because it cannot.** Decks and cards are created via the same contracts the
/// UI calls, with the harness clock moved per card so `created_at` carries the
/// spread the scenarios sort by. The *review states* are then written with a
/// direct table update: the only production writer of a non-initial state is
/// the scheduler, which is M5 and does not exist. When it does, the honest
/// upgrade is to replace those updates with recorded reviews — until then this
/// is the seam the guide's `FIXTURE-BLOCKED` rows were waiting for.
///
/// All content is fake and disposable; nothing here is personal data.
abstract final class ItFixtures {
  static const String version = 'v1';

  /// `S-DUE` / `S-PROGRESS` — the due-library tree, measured at [kT0]:
  ///
  /// ```text
  /// Due library (root, Eight Box)
  /// ├── Mixed due (card deck)          4 cards, one per display state
  /// └── No due group (deck)
  ///     └── Future only (card deck)    1 card, due after T0
  /// ```
  ///
  /// Expected aggregates at `T0`: All 4 · Due 2 · New 1 · Flagged 1 ·
  /// Mastered 1/4 (25%). The root tile reads 5 cards, 2 due, 2 sub-decks.
  static Future<void> loadDueLibrary(ItHarness harness) async {
    await harness.wipeAllData();
    final container = harness.seedContainer();
    try {
      final decks = container.read(deckRepositoryProvider);
      final cards = container.read(cardRepositoryProvider);

      harness.setNow(kT0.subtract(const Duration(hours: 5)));
      final root = await decks.createRootDeck(
        name: _deckName('Due library'),
        schedulerType: SchedulerType.eightBox,
      );
      final mixed = await decks.createSubDeck(
        name: _deckName('Mixed due'),
        parentDeckId: root.id,
      );
      final noDue = await decks.createSubDeck(
        name: _deckName('No due group'),
        parentDeckId: root.id,
      );
      final futureOnly = await decks.createSubDeck(
        name: _deckName('Future only'),
        parentDeckId: noDue.id,
      );

      // Creation order is the reverse of the newest-first order the scenarios
      // assert, and each card is created "at" its own instant so `created_at`
      // genuinely differs — the sort has something real to order by.
      harness.setNow(kT0.subtract(const Duration(hours: 4)));
      final master = await _card(cards, mixed.id, 'mastered-visible');
      harness.setNow(kT0.subtract(const Duration(hours: 3)));
      final review = await _card(cards, mixed.id, 'reviewing-visible');
      harness.setNow(kT0.subtract(const Duration(hours: 2)));
      final begin = await _card(cards, mixed.id, 'beginning-visible');
      harness.setNow(kT0.subtract(const Duration(hours: 1)));
      await _card(cards, mixed.id, 'new-visible');

      harness.setNow(
        kT0
            .add(const Duration(days: 2))
            .subtract(const Duration(hours: 47, minutes: 30)),
      );
      final future = await _card(cards, futureOnly.id, 'future-only');

      // BR-90/BR-91 display bands, one row each. `new-visible` keeps the state
      // its creation wrote: answer_count 0, due immediately.
      await _promote(
        harness.database,
        begin.id,
        box: 2,
        reviews: 3,
        dueAt: kT0.subtract(const Duration(minutes: 5)),
      );
      // **`T0 − 1 day`, from the profile in `00-agent-execution-guide.md` §S-DUE.**
      // It said `T0 + 2 days`, which is the *Future only* card's date, and that
      // made `Due` one rather than two. It went unnoticed while BR-22 counted a
      // card with `due_at IS NULL` as due — the never-learned card made the
      // number two by accident. BR-142 dropped that clause, and the fixture's
      // own error became the visible one.
      await _promote(
        harness.database,
        review.id,
        box: 5,
        reviews: 6,
        dueAt: kT0.subtract(const Duration(days: 1)),
      );
      await _promote(
        harness.database,
        master.id,
        box: kMasteredBox,
        reviews: 12,
        dueAt: kT0.add(const Duration(days: 30)),
      );
      await _promote(
        harness.database,
        future.id,
        box: 5,
        reviews: 6,
        dueAt: kT0.add(const Duration(days: 2)),
      );

      // The one flag, set through the same write the editor uses (BR-92).
      await cards.setCardFlag(cardId: begin.id, isFlagged: true);
    } finally {
      container.dispose();
      harness.setNow(kT0);
    }
  }

  /// `S-LARGE` — `Large deck 65`: 65 all-new cards, `card-001` created first.
  ///
  /// A root cannot hold cards (BR-58), so the deck the scenario opens is a
  /// child; the wrapper root exists only to satisfy the tree rules.
  static Future<void> loadLargeDeck(ItHarness harness) async {
    await harness.wipeAllData();
    final container = harness.seedContainer();
    try {
      final decks = container.read(deckRepositoryProvider);
      final cards = container.read(cardRepositoryProvider);

      harness.setNow(kT0.subtract(const Duration(hours: 2)));
      final root = await decks.createRootDeck(
        name: _deckName('Large library'),
        schedulerType: SchedulerType.eightBox,
      );
      final deck = await decks.createSubDeck(
        name: _deckName('Large deck 65'),
        parentDeckId: root.id,
      );

      for (var i = 1; i <= 65; i++) {
        harness.setNow(kT0.subtract(Duration(minutes: 66 - i)));
        final number = i.toString().padLeft(3, '0');
        await _card(cards, deck.id, 'card-$number', back: 'meaning-$number');
      }
    } finally {
      container.dispose();
      harness.setNow(kT0);
    }
  }

  static DeckName _deckName(String raw) {
    final parsed = DeckName.parse(raw);
    final name = parsed.name;
    if (name == null) {
      throw StateError('fixture deck name refused: $raw (${parsed.problem})');
    }

    return name;
  }

  static Future<CardEntityLike> _card(
    CardRepository cards,
    String deckId,
    String front, {
    String? back,
  }) async {
    final parsedFront = CardText.parse(front, side: CardSide.front);
    final parsedBack = CardText.parse(
      back ?? 'nghĩa của $front',
      side: CardSide.back,
    );
    final f = parsedFront.text;
    final b = parsedBack.text;
    if (f == null || b == null) {
      throw StateError('fixture card refused: $front');
    }
    final created = await cards.createCard(deckId: deckId, front: f, back: b);

    return (id: created.id);
  }

  /// Moves an existing initial review state into a learned band.
  ///
  /// A raw table update on purpose — see the class comment. Only the columns a
  /// review would change are touched; scheduler type, version and generation
  /// keep what card creation wrote.
  /// When a promoted card finished the learning chain.
  ///
  /// Well before [kT0] and before every `due_at` these loaders write, because
  /// that is what "already learned, now on a schedule" means. The exact instant
  /// is never asserted; that it exists is (BR-149).
  static final DateTime _kLearnedAt = kT0.subtract(const Duration(days: 60));

  static Future<void> _promote(
    AppDatabase db,
    String cardId, {
    required int box,
    required int reviews,
    required DateTime dueAt,
  }) async {
    final changed =
        await (db.update(
          db.cardStudyStates,
        )..where((tbl) => tbl.cardId.equals(cardId))).write(
          CardStudyStatesCompanion(
            currentBox: Value<int?>(box),
            answerCount: Value<int>(reviews),
            dueAt: Value<DateTime?>(dueAt),
            lastAnsweredAt: Value<DateTime?>(
              dueAt.subtract(const Duration(days: 1)),
            ),
            // **`learned_at` travels with `due_at`, and leaving it out is what
            // broke six scenarios at once.** Since schema v5 "new" means
            // `learned_at IS NULL` (BR-90) and "due" means it is set *and*
            // `due_at` has arrived (BR-151) — so a fixture that promoted a card
            // by writing only `due_at` produced a card the app reads as New
            // forever, with a schedule it is not allowed to have (BR-149,
            // invariant 28). Every due badge, due filter and progress pill in
            // the fixture scenarios was asserting against that.
            learnedAt: Value<DateTime?>(_kLearnedAt),
          ),
        );
    if (changed != 1) {
      throw StateError('fixture promote touched $changed rows for $cardId');
    }
  }
}

/// The one field the loaders need back from a create.
typedef CardEntityLike = ({String id});
