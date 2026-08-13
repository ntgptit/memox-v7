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
  // Recorded as the checks run, and asserted at the end. A rule that inspects
  // nothing passes, which reads as coverage — six suffix checks in
  // `check_architecture.sh` did exactly that until M4.10.
  final scanned = <String, int>{};

  // ------------------------------------------------------------------ checks

  test('a use case exposes exactly one public method', () {
    // One interaction per use case. Two queries in one class is the same shape as
    // eight methods in one notifier, only smaller — and it was live:
    // `WatchDeckChildrenUseCase` held the children stream *and* a deck read until
    // this check was written.
    //
    // **One interaction is not one statement.** That class was later replaced by
    // `WatchDeckDetailUseCase`, which returns a deck and its children from a
    // single query — because opening a deck is one thing the user does. What this
    // rule forbids is a class exposing two entry points, not a read that answers
    // one question with a join.
    final useCases = classesUnder('/usecases/');
    scanned['usecases'] = useCases.length;
    final offenders = <String>[];

    for (final entry in useCases) {
      final methods = publicMethods(entry.type);
      if (methods.length == 1) continue;
      offenders.add(
        '${entry.path}: ${entry.type.namePart.typeName.lexeme} — ${methods.join(', ')}',
      );
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A use case is one interaction. Split it — and if the two halves are '
          'always needed together, that is a sign they belong in one read, not '
          'in one class with two methods.\n'
          '${offenders.join('\n')}',
    );
  });

  test('a command controller exposes only build, submit and reset', () {
    // `build` is the Riverpod hook, `submit` is the command, `reset` clears the
    // last attempt, `cancel` abandons the one in flight. Anything else — a
    // second command, a selection, a loader — is the growth this check exists
    // to stop.
    //
    // **`cancel` is the same command, not another one**, which is why it is
    // listed rather than exempted. The three the rule already allowed are the
    // lifecycle of a single submit — start it, clear it — and abandoning it is
    // the fourth verb of that same lifecycle: it runs no use case, touches no
    // repository, and sets no state, so it cannot have a spinner of its own and
    // cannot put one on the wrong action, which is the failure the reason below
    // describes. `ExportCards` needs it because the export sheet's `Cancel`
    // stays live while a file is being built (M4.13 W4) and the promise is that
    // no file is handed over; relying on the provider's disposal alone would
    // make that promise depend on which of two schedulers wins.
    //
    // A command controller is identified by what its state *is*: `build` returns a
    // submit state. That is the honest test, because a notifier holding a plain
    // value is not a command however it is filed.
    const allowed = <String>{'build', 'submit', 'reset', 'cancel'};
    final controllers = classesUnder('/controllers/');
    scanned['controllers'] = controllers.length;
    var commandCount = 0;
    final offenders = <String>[];

    for (final entry in controllers) {
      if (!isNotifier(entry.type)) continue;
      if (!(buildReturnType(entry.type)?.contains('SubmitState') ?? false)) {
        continue;
      }
      commandCount += 1;
      final extra = publicMethods(
        entry.type,
      ).where((String name) => !allowed.contains(name)).toSet();
      if (extra.isEmpty) continue;
      offenders.add(
        '${entry.path}: ${entry.type.namePart.typeName.lexeme} — ${extra.join(', ')}',
      );
    }

    scanned['command controllers'] = commandCount;
    expect(
      offenders,
      isEmpty,
      reason:
          'A command controller holds one command. A second one belongs in its '
          'own controller with its own submit state, or the two share a '
          'submitting flag and the spinner appears on the wrong action.\n'
          '${offenders.join('\n')}',
    );
  });

  test('a query controller exposes only build', () {
    // The third kind, which the per-file regex could not tell apart from the
    // others: a notifier whose state is data read from the repository. It has no
    // command at all — a write belongs to a command controller with its own submit
    // state, so that a failed write cannot leave a read showing an error.
    //
    // `RootDeckList` is one, and it needs to be a notifier rather than a function
    // provider only because `listenSelf` is a notifier method.
    final controllers = classesUnder('/controllers/');
    var queryCount = 0;
    final offenders = <String>[];

    for (final entry in controllers) {
      if (!isNotifier(entry.type)) continue;
      final returnType = buildReturnType(entry.type) ?? '';
      final isQuery =
          returnType.startsWith('Stream<') || returnType.startsWith('Future<');
      if (!isQuery) continue;
      queryCount += 1;
      final extra = publicMethods(
        entry.type,
      ).where((String name) => name != 'build').toSet();
      if (extra.isEmpty) continue;
      offenders.add(
        '${entry.path}: ${entry.type.namePart.typeName.lexeme} — ${extra.join(', ')}',
      );
    }

    scanned['query controllers'] = queryCount;
    expect(
      offenders,
      isEmpty,
      reason:
          'A query controller reports what the data layer says and nothing '
          'else. A command on it would put a write and a read behind one '
          'state.\n${offenders.join('\n')}',
    );
  });

  test('no controller or use case declares selection, search or navigation', () {
    // The four members of the example that are not commands at all: UI-local state
    // and side effects. Selection and search belong to the widget or to their own
    // small provider; navigation and error display belong to the widget, which is
    // where a BuildContext legitimately exists.
    //
    // **Declared names only.** The regex version scanned the whole file, so the
    // comment above — which names `navigateTo` in order to forbid it — was itself
    // a violation. A declaration is an AST node; a comment is not.
    final forbidden = RegExp(
      r'^(?:select[A-Z]\w*|search[A-Z]\w*|navigate\w*|show(?:Error|Snack)\w*)$',
    );
    final offenders = <String>[];
    var membersChecked = 0;

    for (final entry in <({String path, ClassDeclaration type})>[
      ...classesUnder('/controllers/'),
      ...classesUnder('/usecases/'),
    ]) {
      for (final ClassMember member in entry.type.body.members) {
        final names = <String>[
          if (member is MethodDeclaration) member.name.lexeme,
          if (member is FieldDeclaration)
            for (final VariableDeclaration v in member.fields.variables)
              v.name.lexeme,
        ];
        membersChecked += names.length;
        for (final String name in names) {
          if (!forbidden.hasMatch(name)) continue;
          offenders.add(
            '${entry.path}: ${entry.type.namePart.typeName.lexeme}.$name',
          );
        }
      }
    }

    scanned['controller and use-case members'] = membersChecked;
    expect(
      offenders,
      isEmpty,
      reason:
          'A controller reports state; the widget decides what to do with it.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no controller or use case mentions BuildContext', () {
    // The structural version of the rule above. A name can be worked around; a
    // type cannot — a controller that cannot hold a `BuildContext` cannot navigate,
    // cannot show a snackbar, and cannot outlive the element it captured.
    //
    // Type annotations only, which is why this needs an AST: `BuildContext` appears
    // in prose across these files constantly, including two lines up.
    final offenders = <String>[];

    for (final entry in <({String path, ClassDeclaration type})>[
      ...classesUnder('/controllers/'),
      ...classesUnder('/usecases/'),
    ]) {
      final visitor = NamedTypeCollector();
      entry.type.accept(visitor);
      for (final String type in visitor.types) {
        if (type != 'BuildContext') continue;
        offenders.add('${entry.path}: ${entry.type.namePart.typeName.lexeme}');
      }
    }

    expect(
      offenders.toSet(),
      isEmpty,
      reason:
          'Controllers never hold a BuildContext. A captured element outlives '
          'the frame it came from, and navigation from a controller runs again '
          'on every rebuild that re-reads the state.\n'
          '${offenders.toSet().join('\n')}',
    );
  });

  test('the checks above had something to inspect', () {
    // Runs last, on the counters the checks filled in. Every rule here selects its
    // subjects by path fragment, so a folder rename turns all six into checks that
    // pass because they found nothing — which is the failure mode that reads as
    // coverage. The numbers are printed so a shrinking scope is visible in CI
    // output rather than only when it reaches zero.
    // ignore: avoid_print
    print('command/query scan: $scanned');

    expect(scanned['usecases'], greaterThan(0));
    expect(scanned['controllers'], greaterThan(0));
    expect(
      scanned['command controllers'],
      greaterThan(0),
      reason:
          'no class matched "build returns a SubmitState" — the check that '
          'bounds a command controller inspected nothing',
    );
    expect(
      scanned['query controllers'],
      greaterThan(0),
      reason: 'no class matched "build returns a Stream or Future"',
    );
    // The remaining notifier kinds — input-state, session and selection —
    // moved to `notifier_kinds_test.dart` at the file-size guard, and their
    // own tally lives with them.
    expect(
      scanned['controller and use-case members'],
      greaterThan(0),
      reason:
          'the setter/operator/getter check inspected no use cases or notifiers '
          '— its scope has moved and it now guards nothing',
    );
    expect(scanned['controller and use-case members'], greaterThan(0));
  });
}
