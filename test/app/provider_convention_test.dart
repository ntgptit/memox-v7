import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/provider_scan.dart';

/// The provider taxonomy, enforced instead of described.
///
/// Deck settled a four-way split — infrastructure, query, command, input state —
/// and the split is only worth anything if the second feature inherits it. A
/// convention that lives in a README decays at the first clone; these three
/// checks are the parts of it a machine can hold.
///
/// The classification also has a property worth stating, because it is what
/// removes a whole class of bug: **every dependency edge runs from a
/// shorter-lived provider to a longer-lived one.** Queries and commands are
/// `autoDispose` and depend on `keepAlive` infrastructure; the single
/// autoDispose-to-autoDispose edge (`rootDeckSummaries` watching
/// `deckListNow`) is one-way. A dependency cycle would need an edge back up the
/// lifetime order, so keeping the layers honest is also what keeps the graph
/// acyclic — Riverpod would otherwise only tell you at runtime, on the path
/// nobody exercised.
void main() {
  /// Every non-generated Dart file under a feature's `presentation/`.
  List<File> presentationFiles() {
    final root = Directory('lib/features');

    return root.listSync(recursive: true).whereType<File>().where((file) {
      final path = file.path.replaceAll(r'\', '/');

      return path.contains('/presentation/') &&
          path.endsWith('.dart') &&
          !path.endsWith('.g.dart') &&
          !path.endsWith('.freezed.dart');
    }).toList();
  }

  String relative(File file) =>
      file.path.replaceAll(r'\', '/').replaceFirst(RegExp('^.*?lib/'), 'lib/');

  test('no feature provider is keepAlive', () {
    // `keepAlive` in a feature means a stream, and the database rows behind it,
    // outliving every screen that wanted them. Infrastructure that genuinely
    // must survive — the database, the repository, the clock, the config — lives
    // in `core/` or `app/di/`, where its lifetime is a deliberate decision
    // rather than a side effect of where someone happened to be typing.
    final offenders = <String>[];

    for (final file in presentationFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('keepAlive')) continue;
        if (lines[i].trimLeft().startsWith('///')) continue;
        offenders.add('${relative(file)}:${i + 1}: ${lines[i].trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A provider under features/*/presentation/ must be autoDispose. Move '
          'anything that has to outlive a screen to core/ or app/di/.\n'
          '${offenders.join('\n')}',
    );
  });

  test('every family key is a primitive', () {
    // A family caches one provider instance per key, compared with `==`. A key
    // with identity equality — an entity, a list, a record built in `build()` —
    // produces a fresh instance on every rebuild, and the old ones are kept
    // alive by their own listeners. The leak has no symptom until the instance
    // count matters.
    //
    // Deck's families are all keyed by a deck id, which is a client-generated
    // UUID string (AD-01) and therefore stable across rebuilds by construction.
    final allowed = <String>{'String', 'int'};
    final builder = RegExp(
      r'(?:^|\s)(?:[A-Za-z0-9_<>, ]+\s+)?build\(([^)]*)\)',
    );
    final functionProvider = RegExp(r'\(\s*Ref\s+ref\s*,\s*([^)]*)\)');
    final offenders = <String>[];

    void checkParameters(String parameters, String where) {
      if (parameters.trim().isEmpty) return;
      for (final parameter in parameters.split(',')) {
        final parts = parameter
            .trim()
            .replaceAll(RegExp(r'^(required|this\.)\s*'), '')
            .split(RegExp(r'\s+'));
        if (parts.length < 2) continue;
        final type = parts.first.replaceAll('?', '');
        if (allowed.contains(type)) continue;
        offenders.add('$where: $type');
      }
    }

    for (final file in presentationFiles()) {
      final source = file.readAsStringSync();
      // Only files that actually declare providers.
      if (!source.contains('@riverpod') && !source.contains('@Riverpod')) {
        continue;
      }

      for (final match in builder.allMatches(source)) {
        checkParameters(match.group(1)!, relative(file));
      }
      for (final match in functionProvider.allMatches(source)) {
        checkParameters(match.group(1)!, relative(file));
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Family keys must be String or int. An object key is compared by '
          'identity, so a new instance is cached on every rebuild.\n'
          '${offenders.join('\n')}',
    );
  });

  group('async providers disable automatic retry', () {
    // The one that will actually be forgotten on the next clone. Riverpod 3
    // retries a failed provider ten times with a backoff reaching 6.4s, and
    // reports `AsyncLoading` the whole time — so a failed local read shows a
    // spinner for roughly thirteen seconds and then an error, with the original
    // exception named nowhere. A local SQLite read that failed will fail again;
    // the ladder buys nothing and costs the user the only signal they had.
    //
    // Synchronous providers are exempt: a write controller returns its submit
    // state and catches `Failure` itself, so it never enters the retry path.
    //
    // **Discovery is an AST walk now, and that is the whole point of this
    // block.** The regex it replaces matched an annotation immediately followed
    // by `Stream<`/`Future<`, which is the function-provider shape; a class
    // provider's next line is `class Foo extends _$Foo {` and its async
    // `build()` carries only `@override`. Nine of this repo's async providers
    // are class-shaped and four of them had no retry policy at all while the
    // test stayed green.

    List<ProviderDeclaration> allProviders() => <ProviderDeclaration>[
      for (final file in presentationFiles())
        ...scanProviders(file.readAsStringSync(), path: relative(file)),
    ];

    test('every one of them, in either shape', () {
      final offenders = <String>[
        for (final provider in allProviders())
          if (provider.isAsync && !provider.disablesRetry) '$provider',
      ];

      expect(
        offenders,
        isEmpty,
        reason:
            'An async provider under features/*/presentation/ must carry '
            '@Riverpod(retry: noAutomaticRetry) — see '
            'core/state/retry_policy.dart for the thirteen seconds it buys '
            'back.\n${offenders.join('\n')}',
      );
    });

    test('and the scan can still see both shapes', () {
      // **A guard that finds nothing passes.** The regex this replaced was
      // green for a year over four unannotated providers, because they were
      // outside its sample space rather than inside it and compliant. So the
      // sample space itself is asserted: if a refactor makes either shape
      // invisible, this fails instead of the rule quietly ceasing to apply.
      final providers = allProviders().where((p) => p.isAsync).toList();

      expect(
        providers.where((p) => p.isClassShaped),
        isNotEmpty,
        reason: 'no class-shaped async provider found — discovery is broken',
      );
      expect(
        providers.where((p) => !p.isClassShaped),
        isNotEmpty,
        reason: 'no function-shaped async provider found — discovery is broken',
      );
    });

    test('a class-shaped provider without the policy is caught', () {
      // Fault injection, against a synthetic source rather than by editing
      // `lib/` — the shape that used to slip through, verbatim.
      const source = r'''
@riverpod
class StudySomething extends _$StudySomething {
  @override
  Future<int> build(String deckId) => Future<int>.value(1);
}
''';

      final found = scanProviders(source, path: 'synthetic.dart');

      expect(found, hasLength(1));
      expect(found.single.isClassShaped, isTrue);
      expect(found.single.isAsync, isTrue);
      expect(found.single.disablesRetry, isFalse);
    });

    test('and one with it is not', () {
      const source = r'''
@Riverpod(retry: noAutomaticRetry)
class StudySomething extends _$StudySomething {
  @override
  Stream<int> build(String deckId) => const Stream<int>.empty();
}
''';

      expect(
        scanProviders(source, path: 'synthetic.dart').single.disablesRetry,
        isTrue,
      );
    });

    test('a synchronous provider of either shape is exempt', () {
      const source = r'''
@riverpod
class CardEditor extends _$CardEditor {
  @override
  CardEditorState build(String id) => const CardEditorState();
}

@riverpod
int cardCount(Ref ref) => 0;
''';

      final found = scanProviders(source, path: 'synthetic.dart');

      expect(found, hasLength(2));
      expect(found.every((p) => !p.isAsync), isTrue);
    });
  });
}
