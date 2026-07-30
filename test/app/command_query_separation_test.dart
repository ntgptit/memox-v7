import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Command and query stay apart, enforced instead of reviewed.
///
/// The failure mode is a `DeckNotifier` that grows `loadDecks`, `createDeck`,
/// `deleteDeck`, `selectDeck`, `searchDeck`, `navigateToDeck`, `showError` — each
/// addition individually reasonable, the result a class nobody can change safely.
/// It never arrives as one commit, so a review will not catch it; a method count
/// will.
///
/// Three checks, each with a number rather than a judgement:
///
/// 1. a use case exposes **one** method — one interaction;
/// 2. a command controller exposes only `build`, `submit` and `reset`;
/// 3. an input-state notifier holds one value and one mutator;
/// 4. no controller carries UI-selection, search or navigation.
void main() {
  List<File> dartFilesUnder(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) return <File>[];

    return directory
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              !file.path.endsWith('.g.dart') &&
              !file.path.endsWith('.freezed.dart'),
        )
        .toList();
  }

  String relative(File file) =>
      file.path.replaceAll(r'\', '/').replaceFirst(RegExp('^.*?lib/'), 'lib/');

  /// Public methods declared at class-member indentation.
  ///
  /// Deliberately crude: it counts declarations, and a class whose *count* is
  /// wrong is the thing being guarded against. A getter is not a method and does
  /// not count — reading a value is not an interaction.
  List<String> publicMethodsIn(String source) {
    final method = RegExp(
      r'^  (?!//|///)(?:Future|Stream|void|[A-Z][A-Za-z0-9]*)'
      r'[A-Za-z0-9<>,?\s]*\s([a-z][A-Za-z0-9]*)\s*\(',
      multiLine: true,
    );

    return method
        .allMatches(source)
        .map((match) => match.group(1)!)
        .where((name) => !name.startsWith('_'))
        .toList();
  }

  test('a use case exposes exactly one method', () {
    // One interaction per use case. Two queries in one class is the same shape as
    // eight methods in one notifier, only smaller — and it was live:
    // `WatchDeckChildrenUseCase` held the children stream *and* a deck read until
    // this check was written.
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      if (!file.path.replaceAll(r'\', '/').contains('/usecases/')) continue;
      final methods = publicMethodsIn(file.readAsStringSync());
      if (methods.length == 1) continue;
      offenders.add('${relative(file)}: ${methods.join(', ')}');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A use case is one interaction. Split it, and compose in the '
          'controller — that is what a controller is for.\n'
          '${offenders.join('\n')}',
    );
  });

  test('a command controller exposes only build, submit and reset', () {
    // `build` is the Riverpod hook, `submit` is the command, `reset` clears the
    // last attempt. Anything else — a second command, a selection, a loader — is
    // the growth this check exists to stop.
    //
    // A command controller is identified by what its state *is*: `build` returns
    // a submit state. That is the honest test, because a notifier holding a plain
    // value is not a command however it is filed — see the next case.
    const allowed = <String>{'build', 'submit', 'reset'};
    final buildsSubmitState = RegExp(
      r'^  \w*SubmitState build\(',
      multiLine: true,
    );
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.contains('/controllers/')) continue;
      final source = file.readAsStringSync();
      if (!buildsSubmitState.hasMatch(source)) continue;

      final extra = publicMethodsIn(
        source,
      ).where((name) => !allowed.contains(name)).toSet();
      if (extra.isEmpty) continue;
      offenders.add('${relative(file)}: ${extra.join(', ')}');
    }

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

  test('an input-state notifier holds one value and one mutator', () {
    // The other kind of notifier: `DeckListNow` holds the instant the due counts
    // are measured against, with `refresh` to re-read the clock. It is neither a
    // query of the data layer nor a command against it — it is a value the UI owns
    // that a query is parameterized by.
    //
    // Not exempted, bounded: `build` plus at most one mutator. That is what stops
    // "the thing that holds the odds and ends" from becoming the God Notifier by a
    // different route.
    final buildsSubmitState = RegExp(
      r'^  \w*SubmitState build\(',
      multiLine: true,
    );
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.contains('/controllers/')) continue;
      final source = file.readAsStringSync();
      if (!source.contains('extends _\$')) continue;
      if (buildsSubmitState.hasMatch(source)) continue;

      final methods = publicMethodsIn(source);
      if (methods.length <= 2) continue;
      offenders.add('${relative(file)}: ${methods.join(', ')}');
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'An input-state notifier is one value and one way to change it. More '
          'than that is a second responsibility looking for a home.\n'
          '${offenders.join('\n')}',
    );
  });

  test('no controller holds selection, search or navigation', () {
    // The four members of the example that are not commands at all: UI-local
    // state and side effects. Selection and search belong to the widget or to
    // their own small provider; navigation and error display belong to the
    // widget, which is where a BuildContext legitimately exists.
    final forbidden = RegExp(
      r'\b(?:select[A-Z]\w*|search[A-Z]\w*|navigateTo\w*|show(?:Error|Snack)\w*)',
    );
    final offenders = <String>[];

    for (final file in dartFilesUnder('lib/features')) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.contains('/controllers/') && !path.contains('/usecases/')) {
        continue;
      }
      for (final match in forbidden.allMatches(file.readAsStringSync())) {
        offenders.add('${relative(file)}: ${match.group(0)}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A controller reports state; the widget decides what to do with it.\n'
          '${offenders.join('\n')}',
    );
  });
}
