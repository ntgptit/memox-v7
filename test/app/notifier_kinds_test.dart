import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/command_query_scan.dart';

/// Command and query stay apart, enforced instead of reviewed.
///
/// The failure mode is a `DeckNotifier` that grows `loadDecks`, `createDeck`,
/// `deleteDeck`, `selectDeck`, `searchDeck`, `navigateToDeck`, `showError` — each
/// addition reasonable, the result a class nobody can change safely. It never
/// arrives as one commit, so a review will not catch it; a method count will.
///
/// **Parsed, not matched.** The scanning machinery — which walks a real Dart AST
/// so a comment or a string literal cannot produce a false hit — lives in
/// `support/command_query_scan.dart`. This file is the checks themselves.
///
/// Seven checks, each a number rather than a judgement, plus one that fails if the
/// scan found nothing to look at.
void main() {
  // Its own tally, like the file this was split from: a check that inspected
  // nothing would pass silently.
  final scanned = <String, int>{};

  test('an input-state notifier holds one value and one mutator, and a '
      'session controller holds exactly its three', () {
    // The remaining kind: `DeckListNow` holds the instant the due counts are
    // measured against, with `refresh` to re-read the clock. It is neither a query
    // of the data layer nor a command against it — it is a value the UI owns that
    // a query is parameterized by.
    //
    // Not exempted, bounded: `build` plus at most one mutator. That is what stops
    // "the thing that holds the odds and ends" from becoming the God Notifier by a
    // different route.
    // The fifth kind, bounded like the session rather than exempted: a
    // selection notifier holds the rows the user pointed at and writes
    // nothing — each bulk mutation is its own command controller with its own
    // submit state (BR-166), so the spinner never lives on the set. `begin`
    // (Select action) and `beginWith` (long-press) do not collapse: an empty
    // and a one-card selection put different things on screen.
    const selectionAllowed = <String>{
      'build',
      'begin',
      'beginWith',
      'toggle',
      'clear',
      'includeAllMatching',
    };
    const sessionAllowed = <String>{
      'build',
      'start',
      'submitAnswer',
      'advance',
      'pause',
      'leave',
      'markBrowsed',
    };
    final controllers = classesUnder('/controllers/');
    var inputCount = 0;
    var sessionCount = 0;
    var selectionCount = 0;
    final offenders = <String>[];

    for (final entry in controllers) {
      if (!isNotifier(entry.type)) continue;
      final returnType = buildReturnType(entry.type) ?? '';
      if (returnType.contains('SubmitState')) continue;
      if (returnType.startsWith('Stream<') ||
          returnType.startsWith('Future<')) {
        continue;
      }
      // A session controller is the fourth kind, and it is bounded rather than
      // exempt. A study session is a machine with a life: it opens, it takes
      // answers, and it closes — and the three cannot collapse into one
      // `submit`, because each has its own failure and its own task flag.
      //
      // Folding them into an input-state notifier was tried and is wrong for the
      // reason this test exists: `answer` failing must leave the card on screen,
      // while `start` failing must leave nothing on screen, and one mutator
      // cannot mean both. Splitting them across three notifiers is worse — they
      // share the session, so the split would put one value behind three
      // owners.
      //
      // `pause` joined them for BR-133: a turn interrupted mid-clock has to keep
      // what was left of it, and that is the counterpart of `leave` rather than
      // another command.
      //
      // `markBrowsed` is the browse move that **writes** (BR-155). The offset it
      // used to arrive with has left: the look-back position is view state — the
      // card it puts on screen is already `completed`, no row is rewritten — and
      // it is `StudyBrowseTrailController` now, one value and one mutator like
      // every other input-state notifier.
      //
      // An earlier note here said that offset could not have an owner of its
      // own, because it must be cleared when the turn changes and a second owner
      // would put one value behind two. That was wrong: clearing it is a
      // *listener* on the turn, not a second writer of it.
      //
      // `answer` became `submitAnswer` **plus** `advance`, and that is one
      // responsibility split rather than two added. Writing an answer and
      // fetching what comes next happen at different moments for every mode:
      // the write when the user acts (BR-25), the fetch once the answer has
      // been on screen long enough to read. While they were one call the fetch
      // began the instant the write returned, so every mode's verdict was
      // drawn into a widget already being unmounted — and `match`, which
      // answers five pairs on one board, paid for five reloads a board.
      //
      // The set stays closed. An eighth name is a new responsibility and
      // belongs somewhere else.
      if (returnType.endsWith('SessionState')) {
        sessionCount += 1;
        final extra = publicMethods(
          entry.type,
        ).where((String name) => !sessionAllowed.contains(name)).toSet();
        if (extra.isEmpty) continue;
        offenders.add(
          '${entry.path}: ${entry.type.namePart.typeName.lexeme} — '
          '${extra.join(', ')}',
        );

        continue;
      }

      if (returnType.endsWith('SelectionState')) {
        selectionCount += 1;
        final extra = publicMethods(
          entry.type,
        ).where((String name) => !selectionAllowed.contains(name)).toSet();
        if (extra.isEmpty) continue;
        offenders.add(
          '${entry.path}: ${entry.type.namePart.typeName.lexeme} — '
          '${extra.join(', ')}',
        );

        continue;
      }

      inputCount += 1;
      final methods = publicMethods(entry.type);
      if (methods.length <= 2) continue;
      offenders.add(
        '${entry.path}: ${entry.type.namePart.typeName.lexeme} — ${methods.join(', ')}',
      );
    }

    scanned['input-state notifiers'] = inputCount;
    scanned['session controllers'] = sessionCount;
    scanned['selection notifiers'] = selectionCount;
    expect(
      offenders,
      isEmpty,
      reason:
          'An input-state notifier is one value and one way to change it. More '
          'than that is a second responsibility looking for a home.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no use case or controller exposes a setter, operator, getter or '
      'mutable field', () {
    // The bypass this closes. Every check above counts *methods*; a setter, an
    // operator and a getter are none, so `set selectedDeck(String id) {}` on a
    // controller or `int get operationCount => 0` on a use case slipped past all
    // of them. Read the members the counts cannot, and reject them.
    //
    // Scoped to the interaction types — every use case, and every generated-base
    // notifier under `/controllers/` — because those are what the counts bound. A
    // plain value class that happened to live under one of these folders and
    // legitimately overrode `operator ==` is not one of them; there are none, and
    // this stays aimed at the classes the rule is about.
    final subjects = <({String path, ClassDeclaration type})>[
      ...classesUnder('/usecases/'),
      ...classesUnder('/controllers/').where((e) => isNotifier(e.type)),
    ];
    scanned['setter/operator surface subjects'] = subjects.length;
    final offenders = <String>[];

    for (final entry in subjects) {
      for (final member in forbiddenSurface(entry.type)) {
        offenders.add(
          '${entry.path}: ${entry.type.namePart.typeName.lexeme} — '
          '${member.kind}: ${member.name}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use cases and controllers expose plain methods only. A public setter '
          'or operator is an interaction wearing a different syntax; a public '
          'getter is state read off a bespoke surface instead of `state`; a '
          'public mutable field is exposed mutable state. Each is a way around '
          'the count checks.\n${offenders.join('\n')}',
    );
  });

  test('the kind checks had something to inspect', () {
    expect(scanned['input-state notifiers'], greaterThan(0));
    expect(scanned['session controllers'], greaterThan(0));
    expect(scanned['selection notifiers'], greaterThan(0));
  });
}
