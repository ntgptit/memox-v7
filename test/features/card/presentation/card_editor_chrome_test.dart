import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_trash_action_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/card_editor_harness.dart';
import 'support/fake_card_repository.dart';

/// The editor's chrome, after the slots were put the right way round
/// (SC-C4-03).
///
/// **The inversion this pins.** `MxContentShell.subheader` exists because a
/// breadcrumb that scrolls away stops answering "where am I" at exactly the
/// moment a long body makes the question worth asking — its own doc names a
/// body-mounted breadcrumb as the defect it was added to fix. This screen had
/// the path as the first row of the *scroll* and a transient flag-write
/// failure alone in the pinned band. The path is chrome; the failure sits
/// under it.
void main() {
  final english = AppLocalizationsEn();

  FakeCardRepository seed() {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card(
      'card-1',
      front: '감사합니다',
      back: 'thank you',
    );

    return repository;
  }

  testWidgets('the path is pinned, not scrolled', (tester) async {
    await pumpCardEditor(tester, seed(), surfaceSize: const Size(393, 852));

    final Rect atRest = tester.getRect(find.byType(MxBreadcrumb));

    // The end of the scroll, which is where the old composition lost the path
    // entirely. `ensureVisible`, not `scrollUntilVisible`: the latter wants
    // exactly one `Scrollable` and this screen has more than one.
    await tester.ensureVisible(find.byType(CardTrashActionWidget));
    await tester.pumpAndSettle();

    final Rect afterScroll = tester.getRect(find.byType(MxBreadcrumb));
    expect(
      afterScroll,
      atRest,
      reason: 'the strip does not move with the body',
    );
    expect(afterScroll.top, greaterThanOrEqualTo(0));
    expect(afterScroll.bottom, lessThanOrEqualTo(852));
  });

  testWidgets('the path is chrome: above the body, outside its scroll', (
    tester,
  ) async {
    await pumpCardEditor(tester, seed(), surfaceSize: const Size(393, 852));

    expect(
      find.ancestor(
        of: find.byType(CardEditorBreadcrumbWidget),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      tester.getRect(find.byType(CardEditorBreadcrumbWidget)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(CardEditorFormWidget)).top),
    );
  });

  testWidgets('a flag failure joins the path in the band, it does not '
      'replace it', (tester) async {
    final repository = seed()
      ..nextFlagFailure = const DatabaseFailure(message: 'disk full');
    await pumpCardEditor(tester, repository, surfaceSize: const Size(393, 852));

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();

    final Finder failure = find.text(english.cardEditorFlagFailed);
    expect(failure, findsOneWidget);
    expect(find.byType(MxBreadcrumb), findsOneWidget);
    // Under the path, in one band — not at the opposite corner from it, and
    // not instead of it.
    expect(
      tester.getRect(failure).top,
      greaterThanOrEqualTo(tester.getRect(find.byType(MxBreadcrumb)).bottom),
    );
  });

  testWidgets('the band still fits at 320dp and text scale 2.0', (
    tester,
  ) async {
    await pumpCardEditor(
      tester,
      seed(),
      surfaceSize: const Size(320, 640),
      textScale: 2,
    );

    // The strip left the scroll for a bar that already carries a leading, a
    // title and two actions, above a form that already pins a footer. The
    // question this asks is whether the chrome now costs more than the screen
    // has — the case the finding flagged before the move was made.
    expect(tester.takeException(), isNull);
    final Rect strip = tester.getRect(find.byType(MxBreadcrumb));
    expect(strip.left, greaterThanOrEqualTo(0));
    expect(strip.right, lessThanOrEqualTo(320));
    expect(strip.bottom, lessThanOrEqualTo(640));
  });
}
