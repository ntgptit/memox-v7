import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/presentation/states/deck_list_view_state.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_list_toolbar_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';

/// The room the sort control is allowed to take on the list heading row.
///
/// **96, and the number is the whole point of the second pass.** The pill it
/// replaced measured 149.8px on a 393 screen — 41.5% of the row, against an
/// 88.6px heading — so the control outweighed the thing it named. A budget
/// stated as a constant and checked by measurement is what stops the label
/// creeping back to a full sentence one translation at a time.
const double sortControlWidthBudget = 96;

/// Every order, in every locale, inside the budget.
///
/// **A test rather than a clamp.** A `maxWidth` would have ellipsized the one
/// word that answers "sorted by what", which is exactly the fact the second
/// pass exists to put back. Measuring instead means a label that outgrows the
/// row fails here, where a person can pick a shorter word, rather than on a
/// device where it silently turns into `Recentl…`.
///
/// Scale 1 only, deliberately: the budget is a layout decision about the
/// resting row. At `textScaler` 2.0 the control grows past it and the heading
/// gives way — it is the `Expanded` — which `deck_list_screen_test.dart`
/// already covers as an overflow case.
void main() {
  Future<void> pumpToolbar(
    WidgetTester tester, {
    required String locale,
    required DeckListSort sort,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildLightTheme(),
        home: Scaffold(
          body: Padding(
            // The screen's own gutter, so the row is the width it really is.
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DeckListToolbarWidget(
              filter: DeckListFilter.all,
              sort: sort,
              visibleCount: 3,
              onFilterChanged: (_) {},
              onSortChanged: (_) {},
              isRootLevel: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocalizations.supportedLocales) {
    for (final sort in DeckListSort.values) {
      testWidgets('the sort control fits its budget — ${locale.languageCode} · '
          '${sort.name}', (tester) async {
        await pumpToolbar(tester, locale: locale.languageCode, sort: sort);

        final width = tester.getRect(find.byType(MxTextButton)).width;

        expect(
          width,
          lessThanOrEqualTo(sortControlWidthBudget),
          reason:
              'the sort control measured ${width.toStringAsFixed(1)}px in '
              '${locale.languageCode} — the heading has to outweigh it',
        );
      });
    }
  }

  testWidgets('the sort glyph leads the word it qualifies', (tester) async {
    // **Position is a claim about what the glyph is.** Trailing is where a
    // *disclosure* chevron goes — `expand_more` on the old show-summary link.
    // `swap_vert` is not a disclosure; it names the axis, and in the chevron's
    // seat it reads as an arrow belonging to nothing (owner review,
    // 2026-08-25). Leading, the pair reads as one phrase: "sort: recent".
    //
    // Asserted by geometry rather than by argument order, because a caller can
    // pass `icon:` and still have it painted last if the component's `Row`
    // ever changes underneath.
    await pumpToolbar(tester, locale: 'en', sort: DeckListSort.dateAdded);

    final glyph = tester.getRect(find.byIcon(Icons.swap_vert));
    final word = tester.getRect(
      find
          .descendant(
            of: find.byType(MxTextButton),
            matching: find.byType(Text),
          )
          .first,
    );

    expect(
      glyph.left,
      lessThan(word.left),
      reason: 'the glyph names the axis, so it comes before the value',
    );
  });

  testWidgets('the control keeps the 48 target the row is built around', (
    tester,
  ) async {
    // The budget is horizontal. Nothing about it is allowed to shrink the
    // target: `AppSizing.touchTarget` is the floor a finger needs, and
    // the first pass already proved that a target which only *reports* 48 is
    // not one — a 48 box overflowing a 32 slot passes
    // `androidTapTargetGuideline` and never receives the tap.
    await pumpToolbar(tester, locale: 'en', sort: DeckListSort.dateAdded);

    expect(tester.getRect(find.byType(MxTextButton)).height, 48);

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
