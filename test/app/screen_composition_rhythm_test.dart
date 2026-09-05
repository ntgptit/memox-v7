/// The composition grammar, held by a test rather than by prose.
///
/// `docs/design-system/v1-freeze.md` §2 leaves the composition of a business
/// screen deliberately unfrozen, and §4 says the answer to an empty cell in the
/// enforcement table is *a guard, not another report*. This file is that guard
/// for the two grammar rules the app-wide consistency review found broken in
/// more than one feature at once
/// (`docs/reviews/app-wide-screen-consistency.md`, clusters C1 and C2).
///
/// **The grammar.** `AppSpacing` is xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32,
/// and `app_spacing.dart` defines `lg` as *"Standard screen padding **and the
/// gap between list items**"*. `md` means "inside a compact control"; a screen
/// that uses it as an item gap has borrowed a control's spacing for a page.
///
/// The scan itself is `support/composition_rhythm_scan.dart`.
///
/// ## The ratchet is per violation, not per file
///
/// The first version of this file allowlisted whole files, which meant a file
/// already on the list could grow a second, unrelated violation and stay green
/// — the allowlist exempted the file, not the defect. Each expected violation
/// now carries a **signature**:
///
///     rule | path | enclosing declaration chain | offending pattern | ordinal
///
/// No line numbers: a signature has to survive an edit above it. The ordinal
/// disambiguates two identical violations in one declaration and is assigned in
/// source order, so it is stable too.
///
/// [kExpectedViolations] is compared with the scan **in both directions**:
///
/// | what happens | why it fails |
/// |---|---|
/// | a new violation appears | its signature is not in the map |
/// | a second violation lands in an allowlisted file | same — its signature is its own |
/// | a violation is fixed but the entry stays | the entry is stale, and stale entries fail |
/// | a violation is fixed and its entry removed | both sides agree — green, ratchet tightened |
///
/// A cluster PR deletes exactly the entries it resolved. The map only shrinks.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/composition_rhythm_scan.dart';

/// Every violation that exists on `main` today, keyed by signature, valued by
/// the finding that owns it. Delete an entry in the same commit that fixes it.
const Map<String, String> kExpectedViolations = <String, String>{
  'list-item-gap|lib/features/card/presentation/widgets/sections/card_list_body_widget.dart|CardListBodyWidget.build|AppSpacing.md|0':
      'SC-C2-08 — card rows at md (12); the deck list this tile is modelled on '
      'is at lg (16)',
  'list-item-gap|lib/features/search/presentation/widgets/sections/library_search_body_widget.dart|LibrarySearchBodyWidget._group|AppSpacing.sm|0':
      'SC-C2-01 — search results at sm (8), one step below every other MxCard '
      'list in the app',
  'list-item-gap|lib/features/progress/presentation/widgets/sections/progress_deck_list_widget.dart|ProgressDeckListWidget.build|AppSpacing.md|0':
      'SC-C2-20 — progress deck rows at md (12). Found by this test, not by the '
      'review: no reviewer named it, which is the argument for the test',
  'double-gutter|lib/features/study/presentation/screens/study_entry_screen.dart|_StudyEntryScreenState.build|EdgeInsets.all(AppSpacing.lg)|0':
      'SC-C1-13 — content sits at a 32dp left edge instead of 16, and the '
      'compact step at 320dp becomes 28 instead of 12, inverting the rule',
  'double-gutter|lib/features/study/presentation/screens/study_options_screen.dart|StudyOptionsScreen.build|EdgeInsets.all(AppSpacing.lg)|0':
      'SC-C1-07 — the same second EdgeInsets.all(AppSpacing.lg)',
};

void main() {
  group('the composition grammar', () {
    late Map<String, Violation> live;

    setUpAll(() {
      live = scanRepository();
    });

    test('no violation exists that is not a known, named finding', () {
      final unexpected = <Violation>[
        for (final MapEntry<String, Violation> entry in live.entries)
          if (!kExpectedViolations.containsKey(entry.key)) entry.value,
      ];
      expect(
        unexpected,
        isEmpty,
        reason:
            'a composition-grammar violation with no entry in '
            'kExpectedViolations. Fix it, or — if it is a deliberate, reviewed '
            'exception — add its signature with the SC- finding that owns '
            'it:\n${unexpected.join('\n')}',
      );
    });

    test('no known finding has been fixed without its entry being removed', () {
      final stale = <String>[
        for (final String signature in kExpectedViolations.keys)
          if (!live.containsKey(signature))
            '$signature\n    was: ${kExpectedViolations[signature]}',
      ];
      expect(
        stale,
        isEmpty,
        reason:
            'these signatures no longer occur, so the finding is fixed — '
            'delete the entry in the same commit. The map only shrinks:\n'
            '${stale.join('\n')}',
      );
    });

    test('every expected violation names a file that still exists', () {
      final missing = <String>[
        for (final String signature in kExpectedViolations.keys)
          if (!File(signature.split('|')[1]).existsSync()) signature,
      ];
      expect(missing, isEmpty, reason: 'stale path in kExpectedViolations');
    });
  });

  // The five behaviours the ratchet has to have. Each is driven against a
  // synthetic state rather than against `lib/`, so the probes stay meaningful
  // after the real violations are fixed and the map is emptied.
  group('ratchet behaviour', () {
    const String separatorAt = '''
class Body extends StatelessWidget {
  Widget build(BuildContext context) => ListView.separated(
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.%s),
        itemBuilder: (context, index) => const Text('x'),
        itemCount: 1,
      );
}
''';

    List<String> signatures(String source) => scanSource(
      source,
      'probe.dart',
    ).map((Violation v) => v.signature).toList();

    test('1. a known violation stays green while it is allowlisted', () {
      final List<String> live = signatures(separatorAt.replaceAll('%s', 'md'));
      expect(live, hasLength(1));
      final result = compareToAllowlist(live, live.toSet());
      expect(result.unexpected, isEmpty);
      expect(result.stale, isEmpty);
    });

    test('2. a second violation in the same file fails', () {
      final List<String> one = signatures(separatorAt.replaceAll('%s', 'md'));
      final List<String> two = signatures(
        '${separatorAt.replaceAll('%s', 'md')}\n'
        '${separatorAt.replaceAll('%s', 'sm').replaceAll('class Body', 'class Other')}',
      );
      expect(two, hasLength(2));
      expect(
        compareToAllowlist(two, one.toSet()).unexpected,
        hasLength(1),
        reason: 'the file was allowlisted for its first violation only',
      );
    });

    test('2b. a second IDENTICAL violation in one declaration fails', () {
      // The ordinal is what makes this catch — without it the two collapse to
      // one signature and the new defect is invisible.
      const String twice = '''
class Body extends StatelessWidget {
  Widget build(BuildContext context) => Column(children: <Widget>[
        ListView.separated(
          separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (c, i) => const Text('x'), itemCount: 1),
        ListView.separated(
          separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (c, i) => const Text('y'), itemCount: 1),
      ]);
}
''';
      final List<String> live = signatures(twice);
      expect(live, hasLength(2), reason: 'ordinals must separate the two');
      expect(live.toSet(), hasLength(2));
      expect(
        compareToAllowlist(live, <String>{live.first}).unexpected,
        hasLength(1),
      );
    });

    test('3. fixing one violation and adding a different one fails', () {
      final List<String> before = signatures(
        separatorAt.replaceAll('%s', 'md'),
      );
      final List<String> after = signatures(separatorAt.replaceAll('%s', 'sm'));
      final result = compareToAllowlist(after, before.toSet());
      expect(result.unexpected, hasLength(1), reason: 'the new sm violation');
      expect(result.stale, hasLength(1), reason: 'the fixed md entry');
    });

    test('4. fixing a violation but leaving the entry fails', () {
      final List<String> before = signatures(
        separatorAt.replaceAll('%s', 'md'),
      );
      final List<String> after = signatures(separatorAt.replaceAll('%s', 'lg'));
      expect(after, isEmpty);
      final result = compareToAllowlist(after, before.toSet());
      expect(result.stale, hasLength(1));
      expect(result.unexpected, isEmpty);
    });

    test('5. fixing everything and emptying the allowlist is green', () {
      final List<String> live = signatures(separatorAt.replaceAll('%s', 'lg'));
      final result = compareToAllowlist(live, <String>{});
      expect(result.unexpected, isEmpty);
      expect(result.stale, isEmpty);
    });

    test('the same five hold for the double-gutter rule', () {
      const String shell = '''
class Screen extends StatelessWidget {
  Widget build(BuildContext context) => MxContentShell(
        title: 'x',
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.%s),
          child: Text('y'),
        ),
      );
}
''';
      final List<String> one = signatures(shell.replaceAll('%s', 'lg'));
      expect(one, hasLength(1));
      expect(one.single, contains(kRuleDoubleGutter));
      expect(one.single, contains('Screen.build'));

      final List<String> two = signatures(
        '${shell.replaceAll('%s', 'lg')}\n'
        '${shell.replaceAll('%s', 'xl').replaceAll('class Screen', 'class Other')}',
      );
      expect(compareToAllowlist(two, one.toSet()).unexpected, hasLength(1));

      final List<String> swapped = signatures(shell.replaceAll('%s', 'xl'));
      final swap = compareToAllowlist(swapped, one.toSet());
      expect(swap.unexpected, hasLength(1));
      expect(swap.stale, hasLength(1));

      const String fixed = '''
class Screen extends StatelessWidget {
  Widget build(BuildContext context) => MxContentShell(
        title: 'x',
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('y'),
        ),
      );
}
''';
      expect(signatures(fixed), isEmpty);
      expect(
        compareToAllowlist(signatures(fixed), one.toSet()).stale,
        hasLength(1),
      );

      final empty = compareToAllowlist(signatures(fixed), <String>{});
      expect(empty.unexpected, isEmpty);
      expect(empty.stale, isEmpty);
    });

    test('a signature survives an edit above the violation', () {
      final List<String> base = signatures(separatorAt.replaceAll('%s', 'md'));
      final List<String> shifted = signatures(
        '// a comment added above\n// and another\n'
        '${separatorAt.replaceAll('%s', 'md')}',
      );
      expect(shifted, equals(base), reason: 'no line number in the signature');
    });

    test('a SizedBox that is not a separator is not this rule’s business', () {
      const String fine = '''
class Body extends StatelessWidget {
  Widget build(BuildContext context) => const Column(
        children: <Widget>[
          Text('title'),
          SizedBox(height: AppSpacing.xs),
          Text('subtitle'),
        ],
      );
}
''';
      expect(signatures(fine), isEmpty);
    });

    test('a Padding that is not the shell’s body is not a violation', () {
      const String fine = '''
class Screen extends StatelessWidget {
  Widget build(BuildContext context) => MxContentShell(
        title: 'x',
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('y'),
            ),
          ],
        ),
      );
}
''';
      expect(signatures(fine), isEmpty);
    });
  });
}
