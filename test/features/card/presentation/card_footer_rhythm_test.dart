import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_import_action_bar_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';

import 'support/card_editor_harness.dart';
import 'support/card_import_wizard_harness.dart';
import 'support/fake_card_repository.dart';

/// **One rhythm for the two `MxContentShell.footer` bands.**
///
/// The app has exactly two footer callers and they draw the same anatomy: an
/// action row over a centred quiet line. They drifted apart anyway — the
/// import bar padded itself `sm`/`sm` and set its caption `xs` under the
/// buttons, so it stood 84dp tall against the editor's 96, with the
/// icon-to-label step of the scale doing a control-to-caption job.
///
/// Nothing else could see it. Both bars are token-clean, so the guard passes;
/// each is internally consistent, so its own layout test passes; and a golden
/// only compares one screen with yesterday's copy of itself, which is exactly
/// how two screens drift while both stay green. What catches it is one
/// expected rhythm that both bands are measured against — the shared literal
/// below is the contract, and either bar moving away from it fails here.
///
/// **Two tests, not one.** Riverpod refuses to swap a `ProviderScope`'s
/// override set inside a single test, so the two screens cannot be mounted in
/// the same body; sharing the constant is what keeps the claim joint.
void main() {
  final h = installCardImportWizardHarness();

  const Size surface = Size(393, 852);
  const ({double top, double bottom, double gap}) expected = (
    top: AppSpacing.md,
    bottom: AppSpacing.md,
    // `sm`, not `xs`: `xs` is the icon-to-label step of the scale.
    gap: AppSpacing.sm,
  );

  /// Read off the laid-out boxes rather than the `EdgeInsets` — a token handed
  /// to the wrong widget still reads correct in source.
  ({double top, double bottom, double gap}) rhythmOf(
    WidgetTester tester, {
    required Finder bar,
    required Finder actions,
    required Finder caption,
  }) {
    final Rect band = tester.getRect(bar);
    final Rect column = tester.getRect(
      find.descendant(of: bar, matching: find.byType(Column)).first,
    );

    return (
      top: column.top - band.top,
      bottom: band.bottom - column.bottom,
      gap: tester.getRect(caption).top - tester.getRect(actions).bottom,
    );
  }

  testWidgets('the import bar keeps the shared footer rhythm', (tester) async {
    await h.pump(tester, surface: surface);

    final Finder bar = find.byType(CardImportActionBarWidget);

    expect(
      rhythmOf(
        tester,
        bar: bar,
        actions: find.descendant(
          of: bar,
          matching: find.byType(MxActionButton),
        ),
        caption: find.text(h.english.cardImportBarSourceHint),
      ),
      expected,
    );
  });

  testWidgets('the editor bar keeps the shared footer rhythm', (tester) async {
    final FakeCardRepository repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: 'old front',
      back: 'old back',
    );
    await pumpCardEditor(tester, repository, surfaceSize: surface);

    final Finder bar = find.byType(CardEditorActionBarWidget);

    expect(
      rhythmOf(
        tester,
        bar: bar,
        actions: find.descendant(of: bar, matching: find.byType(MxButtonPair)),
        caption: find.text(h.english.cardEditorLocalOnlyNote),
      ),
      expected,
    );
  });
}
