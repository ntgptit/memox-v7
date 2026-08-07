import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/command_query_scan.dart';

/// Command and query stay apart, enforced instead of reviewed.
///
/// The failure mode is a `DeckNotifier` that grows `loadDecks`, `createDeck`,
/// `deleteDeck`, `selectDeck`, `searchDeck`, `navigateToDeck`, `showError` — each
/// addition individually reasonable, the result a class nobody can change safely.
/// It never arrives as one commit, so a review will not catch it; a method count
/// will.
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
    // last attempt. Anything else — a second command, a selection, a loader — is
    // the growth this check exists to stop.
    //
    // A command controller is identified by what its state *is*: `build` returns a
    // submit state. That is the honest test, because a notifier holding a plain
    // value is not a command however it is filed.
    const allowed = <String>{'build', 'submit', 'reset'};
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
    const sessionAllowed = <String>{'build', 'start', 'answer', 'leave'};
    final controllers = classesUnder('/controllers/');
    var inputCount = 0;
    var sessionCount = 0;
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

      inputCount += 1;
      final methods = publicMethods(entry.type);
      if (methods.length <= 2) continue;
      offenders.add(
        '${entry.path}: ${entry.type.namePart.typeName.lexeme} — ${methods.join(', ')}',
      );
    }

    scanned['input-state notifiers'] = inputCount;
    scanned['session controllers'] = sessionCount;
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
    expect(
      scanned['input-state notifiers'],
      greaterThan(0),
      reason: 'no class matched the remaining notifier kind',
    );
    expect(
      scanned['setter/operator surface subjects'],
      greaterThan(0),
      reason:
          'the setter/operator/getter check inspected no use cases or notifiers '
          '— its scope has moved and it now guards nothing',
    );
    expect(scanned['controller and use-case members'], greaterThan(0));
  });
}
