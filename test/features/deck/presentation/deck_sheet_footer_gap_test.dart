import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/states/deck_submit_state.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_scheduler_picker_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_form_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_scheduler_change_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/starter_install_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// One number for the step from a sheet's last content to its commit
/// (SC-C2-14).
///
/// **Five sheets in this unit end the same way — content, a gap, an action —
/// and the gap was four `xl` and one `lg`.** The odd one out was
/// `starter_install_widget`, which is the *same interaction* as the scheduler
/// sheet: choose a schedule with the same `DeckSchedulerPickerWidget`, then
/// commit. Nothing about what that sheet does explained why its action sat
/// 8dp closer to the picker than everyone else's did.
///
/// The measurement is deliberately cross-sheet rather than one assertion per
/// file. A per-file gap assertion is what the app already had implicitly, and
/// it is exactly what let a fifth sheet diverge without anything noticing: a
/// number is only a grammar if the same test reads it in every place it is
/// supposed to hold. So the sheets are listed here, and a sixth one added to
/// this unit joins the list rather than choosing for itself.
///
/// The measurement is taken from `DeckSchedulerPickerWidget` in all five,
/// because in the pristine state — no in-flow failure — the picker is the last
/// content element on every one of them.
void main() {
  DeckEntity deck({
    bool isLocked = false,
    SchedulerType scheduler = SchedulerType.eightBox,
  }) => DeckEntity(
    id: 'root',
    name: 'Korean',
    parentDeckId: null,
    rootDeckId: 'root',
    contentType: DeckContentType.deck,
    schedulerType: scheduler,
    schedulerGeneration: 1,
    firstAnsweredAt: isLocked ? DateTime.utc(2026) : null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  DeckTemplate template() => DeckTemplate(
    templateId: 'starter-1',
    version: 1,
    locale: 'en',
    title: DeckName.parse('Everyday English').name!,
    contentSource: 'memox-fixture',
    defaultSchedulerType: SchedulerType.eightBox,
    children: <DeckTemplateNode>[
      DeckTemplateNode.leaf(
        name: DeckName.parse('Basics').name!,
        cards: <DeckTemplateCard>[
          DeckTemplateCard(
            front: CardText.parse('hello', side: CardSide.front).text!,
            back: CardText.parse('xin chào', side: CardSide.back).text!,
          ),
        ],
      ),
    ],
  );

  /// Opens [open] from a throwaway screen and returns once it has settled.
  Future<void> pumpSheet(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository(),
      screen: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => open(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The step from the last content element to the top of the commit footer.
  double footerGap(WidgetTester tester, Finder footer) =>
      tester.getRect(footer).top -
      tester.getRect(find.byType(DeckSchedulerPickerWidget)).bottom;

  testWidgets('the create-root-deck form steps to its footer at xl', (
    tester,
  ) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository(),
      screen: Scaffold(
        body: SingleChildScrollView(
          child: DeckFormWidget(
            title: 'New deck',
            submitLabel: 'Create',
            // The only form that carries the picker (BR-11), which is what
            // makes it comparable with the other four sheets.
            isSchedulerRequired: true,
            state: const DeckSubmitState(),
            onSubmit: (_, _) {},
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(footerGap(tester, find.byType(MxButtonPair)), AppSpacing.xl);
  });

  testWidgets('the locked scheduler sheet steps to its footer at xl', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      (context) => showDeckSchedulerSheet(context, deck: deck(isLocked: true)),
    );

    expect(footerGap(tester, find.byType(MxButtonPair)), AppSpacing.xl);
  });

  testWidgets('the unlocked scheduler sheet steps to its footer at xl', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      (context) => showDeckSchedulerSheet(context, deck: deck()),
    );

    expect(footerGap(tester, find.byType(MxButtonPair)), AppSpacing.xl);
  });

  testWidgets('the reset sheet steps to its footer at xl', (tester) async {
    await pumpSheet(
      tester,
      (context) => showDeckResetProgressConfirm(
        context,
        deck: deck(),
        hasLearnedCards: true,
      ),
    );

    expect(footerGap(tester, find.byType(MxButtonPair)), AppSpacing.xl);
  });

  testWidgets('the starter install sheet steps to its footer at xl', (
    tester,
  ) async {
    // The one that was at `lg`. Its footer is a lone full-width action rather
    // than a pair — that difference is a separate, app-wide question about
    // where a commit sheet's Cancel lives, and it is not what this measures.
    await pumpSheet(
      tester,
      (context) => showStarterInstallSheet(context, template: template()),
    );

    expect(footerGap(tester, find.byType(MxActionButton)), AppSpacing.xl);
  });
}
