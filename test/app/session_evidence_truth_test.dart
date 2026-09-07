import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/presentation/widgets/support/study_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// A study-session demo harness must swap the hint the way the screen does.
///
/// **The defect this exists for, measured.** `study_guess_states_demo_test.dart`
/// mounted `StudySessionFrameSectionWidget` directly and passed neither
/// `hintOverride` nor `onResolved`, so `guess_correct_{light,dark}.png` and
/// `guess_wrong_{light,dark}.png` rendered `studyHintGuess` — "Choose the right
/// meaning" — under a board that had already been answered. `StudySessionScreen`
/// never produces that pairing: `_guessView` hands the body an `onResolved`,
/// `_grade` fires it in the same synchronous block that records the chosen card,
/// and `_hintOverrideFor` then returns `studyModeHintResolved(guess)`. There is
/// not even a transitional frame where the two disagree, because
/// `didUpdateWidget` clears the choice in the same rebuild that clears the key.
///
/// Four committed pictures therefore showed a state the app cannot reach, and
/// **nothing was red**: no guard covers demo-harness fidelity, and
/// `study_session_frame_test.dart` asserts the six base hints without ever
/// exercising the override. `study_recall_states_demo_test.dart` had already met
/// this failure and written the reason down — the lesson was applied in one file
/// and not in its sibling. This test is what stops the next one re-learning it
/// (EV-01, `docs/reviews/impeccable-uiux-audit.md` §2).
///
/// **The rule is stated over the modes, not over the files.** The set of modes
/// that swap their hint is read from the production extension rather than
/// restated here, so a third mode joins this contract by *existing* — not by
/// somebody remembering to add it to a list.
void main() {
  /// Every mode for which the screen has a second, resolved hint to swap in.
  ///
  /// Asked of `studyModeHintResolved` itself. A literal set here would be a
  /// second copy of the answer, and the copy is what goes stale.
  Future<Set<StudyMode>> modesWithAResolvedHint(WidgetTester tester) async {
    late Set<StudyMode> modes;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            modes = <StudyMode>{
              for (final mode in StudyMode.values)
                if (context.studyModeHintResolved(mode) != null) mode,
            };
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return modes;
  }

  testWidgets('the resolved-hint set is not empty', (tester) async {
    // A guard whose subject set is empty passes for the wrong reason. If every
    // mode loses its resolved hint the contract below stops meaning anything,
    // and that should be a decision somebody makes rather than a silent pass.
    expect(
      await modesWithAResolvedHint(tester),
      isNotEmpty,
      reason:
          'studyModeHintResolved answers for no mode, so the harness contract '
          'below can never fail. If the resolved hint was removed on purpose, '
          'delete this file with it.',
    );
  });

  testWidgets(
    'a demo harness that mounts the session frame for a mode with a resolved '
    'hint wires both halves of the swap',
    (tester) async {
      final resolved = await modesWithAResolvedHint(tester);

      final harnesses = Directory('test/demo')
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('_test.dart'))
          .map(
            (File file) => (
              name: file.uri.pathSegments.last,
              source: _withoutComments(file.readAsStringSync()),
            ),
          )
          .where(
            (({String name, String source}) file) =>
                file.source.contains('StudySessionFrameSectionWidget('),
          )
          .toList();

      expect(
        harnesses,
        isNotEmpty,
        reason:
            'no demo harness mounts the session frame any more — this guard is '
            'watching nothing. Move it or delete it rather than leaving it green.',
      );

      final violations = <String>[];
      for (final file in harnesses) {
        for (final mode in resolved) {
          if (!file.source.contains('StudyMode.${mode.name}')) continue;

          // **Both halves, because either one alone is the bug wearing a fix.**
          // `hintOverride` with nothing to flip it renders the asking hint
          // forever; `onResolved` with no override renders it forever too. The
          // screen subscribes to the signal *and* feeds the frame — a harness
          // that photographs the screen has to do the same.
          if (!file.source.contains('hintOverride:')) {
            violations.add(
              '${file.name} renders ${mode.name} in the session frame but never '
              'passes hintOverride — the answered state will show '
              '"${_baseHintName(mode)}" over a body that has stopped asking.',
            );
          }
          if (!file.source.contains('onResolved:')) {
            violations.add(
              '${file.name} renders ${mode.name} in the session frame but never '
              'subscribes to onResolved, so nothing can flip the hint at the '
              'moment the body stops asking.',
            );
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'A committed picture of a study mode must show a pairing the screen '
            'can actually produce.\n${violations.join('\n')}',
      );
    },
  );
}

/// The source with its comments removed.
///
/// **Written because the first version of this guard was green against the very
/// defect it was built for.** It matched the bare word `hintOverride`, and the
/// harness's own doc comment explains the production wiring by naming
/// `_hintOverrideFor` — so the prose satisfied the check while the code did not.
/// A guard that reads documentation is a guard that passes when the
/// documentation is right and the code is wrong, which is the failure it was
/// supposed to catch. Proven by fault injection: with `hintOverride:` deleted
/// from the harness, the first version still passed and this one fails.
String _withoutComments(String source) {
  final withoutBlocks = source.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );

  return withoutBlocks
      .split('\n')
      .map((String line) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('///') || trimmed.startsWith('//')) return '';
        return line;
      })
      .join('\n');
}

/// Names the hint that would be shown wrongly, for the failure message only.
String _baseHintName(StudyMode mode) =>
    'studyHint'
    '${mode.name[0].toUpperCase()}${mode.name.substring(1)}';
