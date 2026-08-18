import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The auditable half of BR-257: **every statement that reads `cards` or
/// `decks` either excludes tombstones or is on this list with a reason.**
///
/// BR-257 is the only rule in the document that constrains a *shape* rather
/// than an outcome, and this file is why. "Do not show deleted rows" spread
/// over sixty statements is a rule that will be right in fifty-nine places, and
/// the sixtieth is the one nobody looks at. A new query that forgets the
/// predicate fails here, at the moment it is written, rather than as a card
/// reappearing in someone's study session.
///
/// **What this test can and cannot see.** It is a text scan, so it proves that
/// a statement *mentions* the exclusion, not that the mention covers every
/// table reference in it — aliases repeat across CTE scopes and no regex tells
/// those apart. The semantic half is `trash_leak_test.dart`, which drives the
/// real repositories over a database holding tombstones and asserts nothing
/// comes back. Neither replaces the other: this one catches the statement that
/// was never considered, that one catches the statement that was considered
/// wrongly.
void main() {
  /// Statements that read `cards`/`decks` and deliberately do **not** exclude
  /// tombstones. Every entry is a decision recorded in AD-22, not a backlog.
  const exempt = <String, String>{
    'updateSubtreeRootDeck':
        'AD-22 — a tombstone inside a moved subtree must follow it to the new '
        'root, or invariant 6 fires and a later restore hands back a branch '
        'naming a root it does not belong to.',
    'resetTreeStudyStates':
        'AD-22 — a card in Trash is still in the tree, and invariant 9 compares '
        'every state generation with its root. Skipping tombstones would strand '
        'them at the old generation with no way to repair them.',
  };

  /// Files whose whole purpose is reading tombstones.
  const exemptFiles = <String>{'trash.drift'};

  // ---- the alias-level pass, done by hand and recorded here ---------------
  //
  // The scan below is per *statement*. A per-*alias* sweep was also run over
  // every statement in `queries/`, and four aliases legitimately carry no
  // predicate of their own. They are listed so the next reader does not have to
  // re-derive the argument, and so that if invariants 31/32 ever break, this is
  // the note that says what else breaks with them:
  //
  //   card.drift  deckContextById.d  — the ancestry walk upward from an active
  //     deck. An active deck cannot have a deleted parent (invariant 32), so
  //     every row the walk reaches is active.
  //   deck.drift  childDeckLevel.root — read only for `scheduler_type`, joined
  //     from an already-filtered `child`. Same invariant.
  //   deck.drift  cardMoveTargets.p  — the target's parent, read only for its
  //     name; `d` is filtered, so `p` is active.
  //   study.drift lockRootSchedulerIfUnlocked.d — the deck of an already
  //     filtered card. An active card cannot sit in a deleted deck
  //     (invariant 31).
  //
  // The two statements that read tombstones on purpose are in `exempt` below,
  // with their reasons.

  final queryDir = Directory('lib/core/database/queries');

  /// `name:` or `name AS Row:` on its own line opens a statement; the next line
  /// ending in `;` closes it. That is the whole grammar drift uses for a query
  /// file, and parsing it here rather than importing a SQL parser keeps the
  /// guard readable by whoever it fails on.
  final statementHead = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)(\s+AS\s+\w+)?:\s*$');

  /// Any reference to the two tables that carry a tombstone column.
  final tableRef = RegExp(
    r'\b(?:FROM|JOIN|UPDATE|INTO)\s+(cards|decks)\b',
    caseSensitive: false,
  );

  Map<String, String> statementsIn(File file) {
    final statements = <String, String>{};
    final lines = file.readAsLinesSync();
    String? current;
    final body = StringBuffer();

    for (final line in lines) {
      if (current == null) {
        final head = statementHead.firstMatch(line);
        if (head == null) continue;
        current = head.group(1);
        body.clear();
        continue;
      }

      body.writeln(line);
      if (!line.trimRight().endsWith(';')) continue;

      statements[current] = body.toString();
      current = null;
    }

    return statements;
  }

  test('the query files exist and are being scanned', () {
    // A guard that silently scans nothing is the failure mode this whole file
    // exists to prevent, so it refuses to pass on an empty scan.
    expect(queryDir.existsSync(), isTrue);
    final files = queryDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.drift'))
        .toList();

    expect(files, isNotEmpty);
  });

  test('every active statement reading cards or decks excludes tombstones', () {
    final offenders = <String>[];
    var scanned = 0;

    for (final file in queryDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.drift')) continue;
      final name = file.uri.pathSegments.last;
      if (exemptFiles.contains(name)) continue;

      statementsIn(file).forEach((statement, sql) {
        if (!tableRef.hasMatch(sql)) return;
        scanned++;
        if (exempt.containsKey(statement)) return;
        if (sql.contains('delete_batch_id')) return;

        offenders.add('$name: $statement');
      });
    }

    // The count is asserted as well as the offenders: a parser that stopped
    // recognising statement heads would report zero offenders out of zero
    // statements and look perfect.
    expect(
      scanned,
      greaterThan(30),
      reason:
          'scanned only $scanned statements — the parser has stopped '
          'seeing statement heads',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'these statements read cards/decks without excluding tombstones '
          '(BR-257). Add the predicate, or add the statement to `exempt` with '
          'the reason: ${offenders.join(', ')}',
    );
  });

  test('every exemption names a statement that still exists', () {
    // An exemption outliving its statement is a licence nobody revoked, and the
    // next statement to take that name would inherit it.
    final known = <String>{};
    for (final file in queryDir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.drift')) continue;
      known.addAll(statementsIn(file).keys);
    }

    expect(known, containsAll(exempt.keys));
  });

  test('every exemption carries a reason that cites a decision', () {
    for (final entry in exempt.entries) {
      expect(
        entry.value,
        contains('AD-22'),
        reason: '${entry.key} is exempt without citing where that was decided',
      );
    }
  });
}
