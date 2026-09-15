import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_progress_panel_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'support/fake_card_repository.dart';

/// **Card List's geometry contract (M4.11 D5, D13, D21), measured.**
///
/// `card_list_screen_test.dart` pins behaviour; the visual audit pins colour
/// on one loaded frame. Neither can see a laid-out rectangle, so nothing
/// previously caught a shared edge drifting or a row reflowing when selection
/// starts — both are claims the code's own comments make (`card_list_screen.dart`
/// on the shell's zeroed padding, `card_tile_widget.dart` on the state-dot/check
/// swap), restated here so a future edit that breaks either fails a test
/// instead of only a comment.
void main() {
  /// A hairline, not a design allowance: antialiasing may land a fraction
  /// either way.
  const double epsilon = 0.5;

  /// The narrowest supported phone at the largest supported scale, and two
  /// ordinary ones — the same trio `tag_catalog_alignment_test.dart` uses.
  const narrow = Size(320, 640);
  const phone = Size(390, 844);
  const wide = Size(412, 915);

  void sizeTo(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpList(
    WidgetTester tester,
    FakeCardRepository repository, {
    Size size = phone,
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    sizeTo(tester, size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // `copyWith` through a Builder, never a fresh `MediaQueryData`: a
          // new one carries a zero size, which silently changes the gutter
          // this file measures — the same reason `tag_catalog_alignment_test`
          // does it this way.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: const CardListScreen(deckId: 'deck-1'),
            ),
          ),
        ),
      ),
    );
  }

  FakeCardRepository loadedRepository({int rows = 3}) {
    final repository = FakeCardRepository.loaded(
      <dynamic>[
        for (var i = 0; i < rows; i++)
          FakeCardRepository().listItem(
            'c$i',
            front: 'front $i',
            back: 'back $i',
            state: i.isEven ? CardState.isNew : CardState.mastered,
            isFlagged: i == 0,
            dueAt: i.isOdd ? DateTime.utc(2020) : null,
          ),
      ].cast(),
      total: rows,
    );
    repository.filterCounts[CardListFilter.due] = 1;
    // Without a distribution the panel renders `SizedBox.shrink()` — this
    // geometry file needs it on screen, not the panel's own null-state.
    repository.distributionToShow = const CardStateDistributionModel(
      total: 3,
      isNew: 2,
      beginning: 0,
      reviewing: 0,
      mastered: 1,
    );

    return repository;
  }

  group('G1 — shared left/right edges', () {
    // Narrow included since the body took its gutter from `mxScreenGutter`:
    // below `AppBreakpoints.compact` the shell's subheader steps to `md`, and
    // the list now steps with it instead of holding a fixed `lg` and standing
    // 4dp outside the field — which is the width the claim matters at most.
    for (final size in <Size>[narrow, phone, wide]) {
      testWidgets('search field, progress panel and rows align at '
          '${size.width.toInt()}dp', (tester) async {
        await pumpList(tester, loadedRepository(), size: size);
        await tester.pumpAndSettle();

        final field = tester.getRect(find.byType(MxSearchField));
        final panel = tester.getRect(find.byType(CardProgressPanelWidget));
        final rows = tester.widgetList<CardTileWidget>(
          find.byType(CardTileWidget),
        );
        expect(rows, isNotEmpty);

        for (final rowFinder in [
          find.byType(CardTileWidget).first,
          find.byType(CardTileWidget).last,
        ]) {
          final row = tester.getRect(rowFinder);
          expect(
            row.left,
            moreOrLessEquals(field.left, epsilon: epsilon),
            reason: 'a row must start where the field above it starts',
          );
          expect(
            row.right,
            moreOrLessEquals(field.right, epsilon: epsilon),
            reason: 'and end where it ends',
          );
        }
        expect(panel.left, moreOrLessEquals(field.left, epsilon: epsilon));
        expect(panel.right, moreOrLessEquals(field.right, epsilon: epsilon));
      });
    }
  });

  testWidgets(
    'G2 — the trailing badge top-aligns with the front word, not the card',
    (tester) async {
      // `_TrailingBadges` is documented to sit "right-aligned and top-aligned
      // with the front word" — restated here so the claim is measured, not
      // only read from the comment.
      await pumpList(tester, loadedRepository(rows: 2));
      await tester.pumpAndSettle();

      // Row 0 is the flagged one (`loadedRepository`'s `i == 0` rule) — the
      // mark and the front text being compared must be the same row's.
      // Scoped to the tile: the `Flagged` filter pill above the list carries
      // the same glyph, and an unscoped finder would measure that instead.
      final front = tester.getRect(find.text('front 0'));
      final flagOrBadge = tester.getRect(
        find.descendant(
          of: find.byType(CardTileWidget).first,
          matching: find.byIcon(Icons.flag),
        ),
      );

      expect(
        flagOrBadge.top,
        moreOrLessEquals(front.top, epsilon: 6),
        reason:
            'a mark sitting well below the front reads as belonging to the '
            'row below it rather than to this card',
      );
    },
  );

  testWidgets('G3 — a row keeps its height when selection mode starts', (
    tester,
  ) async {
    // The state dot and the selection check share one column and swap in
    // place (`card_tile_widget.dart`); a row that grew or shrank would mean
    // the swap inserted a widget beside the dot instead of replacing it.
    await pumpList(tester, loadedRepository());
    await tester.pumpAndSettle();

    final before = tester.getRect(find.byType(CardTileWidget).first);

    await tester.longPress(find.byType(CardTileWidget).first);
    await tester.pumpAndSettle();

    final after = tester.getRect(find.byType(CardTileWidget).first);
    expect(after.height, moreOrLessEquals(before.height, epsilon: epsilon));
    expect(after.left, moreOrLessEquals(before.left, epsilon: epsilon));
    expect(after.right, moreOrLessEquals(before.right, epsilon: epsilon));
  });

  testWidgets(
    'G4 — the selection bar is edge-to-edge, wider than the row gutter',
    (tester) async {
      // A deliberate divergence from G1: the bar is a toolbar substitute, not
      // a card in the column (D13, and `trash_selection_bar_widget.dart`'s
      // independent identical choice) — measured here so it reads as a kept
      // decision rather than an edge nobody checked.
      await pumpList(tester, loadedRepository());
      await tester.pumpAndSettle();
      final row = tester.getRect(find.byType(CardTileWidget).first);

      await tester.longPress(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(CardSelectionBarWidget));
      expect(
        bar.left,
        lessThan(row.left - epsilon),
        reason: 'the bar reaches past the row column on the left',
      );
      expect(
        bar.right,
        greaterThan(row.right + epsilon),
        reason: 'and on the right',
      );
    },
  );

  testWidgets('G5 — the list ends a full clearance above the foot (D21)', (
    tester,
  ) async {
    await pumpList(tester, loadedRepository());
    await tester.pumpAndSettle();

    final padding =
        tester.widget<ListView>(find.byType(ListView)).padding! as EdgeInsets;

    expect(
      padding.bottom,
      AppSpacing.fabScrollClearance,
      reason:
          'The screen carries a floating create action since SC-C4-05, so the '
          'shell helper mxScrollEndInsetOf answers the FAB clearance rather '
          'than the bare lg end gap D21 settled on for a list with nothing '
          'over it. Re-aimed rather than relaxed: what this test measures is '
          "that the inset is still the shell's answer, and the shell's answer "
          'changed because the screen did. It read xxl once — double the lg it '
          'then wanted — which pinned a divergence instead of catching it '
          '(SC-C2-07), so the constant is named here and never spelled as a '
          'number.',
    );
  });

  group('G6 — touch targets clear 48dp', () {
    // **Add is the floating create now, not a second app-bar glyph**
    // (SC-C4-05): the deck list's grammar, adopted here by owner decision on
    // 2026-09-06. So the pair measured is one bar button and one FAB, and the
    // index walk over `MxIconButton` that used to reach the Add glyph is gone
    // — it would now land on whatever control happened to be second.
    testWidgets('the app-bar Select action and the floating create', (
      tester,
    ) async {
      await pumpList(tester, loadedRepository());
      await tester.pumpAndSettle();

      for (final finder in [
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(MxIconButton),
        ),
        find.byType(MxFab),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.width, greaterThanOrEqualTo(48 - epsilon));
        expect(rect.height, greaterThanOrEqualTo(48 - epsilon));
      }
    });

    testWidgets('the selection close and select-all actions', (tester) async {
      await pumpList(tester, loadedRepository());
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();

      // The icon glyph itself measures its own small size — the tap target
      // is the `MxIconButton` around it, the same distinction G6's app-bar
      // case draws by measuring the button type directly.
      //
      // **The ✕ is the app bar's leading now, not the band's first child**
      // (SC-C4-12): it used to sit on the band while the shell also drew the
      // platform back arrow, two controls for one act. Measured through the
      // AppBar so the move is pinned rather than merely allowed — a ✕ that
      // slid back onto the band would fail here.
      final close = tester.getRect(
        find.ancestor(
          of: find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.close),
          ),
          matching: find.byType(MxIconButton),
        ),
      );
      final selectAll = tester.getRect(
        find.ancestor(
          of: find.descendant(
            of: find.byType(CardSelectionBarWidget),
            matching: find.byIcon(Icons.select_all),
          ),
          matching: find.byType(MxIconButton),
        ),
      );
      expect(close.width, greaterThanOrEqualTo(48 - epsilon));
      expect(close.height, greaterThanOrEqualTo(48 - epsilon));
      expect(selectAll.width, greaterThanOrEqualTo(48 - epsilon));
      expect(selectAll.height, greaterThanOrEqualTo(48 - epsilon));
    });
  });

  testWidgets(
    'G7 — nothing overflows at 320dp with textScale 2.0, loaded or selecting',
    (tester) async {
      await pumpList(tester, loadedRepository(), size: narrow, textScale: 2);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // At this width and scale the progress panel and the header rows can
      // push the first card below the fold — a lazy `ListView` never builds
      // it until it is scrolled into view.
      for (
        var attempt = 0;
        attempt < 10 && tester.widgetList(find.byType(CardTileWidget)).isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }
      expect(
        find.byType(CardTileWidget),
        findsWidgets,
        reason: 'the first row never scrolled into view',
      );
      await tester.longPress(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();
      // A RenderFlex overflow throws into the binding, so reaching here with
      // no exception is the claim. The count is the app-bar title since
      // SC-C4-12, where `AppBar` ellipsizes it, so this width×scale is now a
      // claim about the band's two icon buttons and the bar's own row rather
      // than about the two-line label that used to sit between them.
      expect(tester.takeException(), isNull);

      final bar = tester.getRect(find.byType(CardSelectionBarWidget));
      expect(bar.left, greaterThanOrEqualTo(-epsilon));
      expect(bar.right, lessThanOrEqualTo(narrow.width + epsilon));
    },
  );

  testWidgets('G8 — 412dp keeps the same shared edges as 393dp', (
    tester,
  ) async {
    await pumpList(tester, loadedRepository(), size: wide);
    await tester.pumpAndSettle();

    final field = tester.getRect(find.byType(MxSearchField));
    final row = tester.getRect(find.byType(CardTileWidget).first);
    expect(row.left, moreOrLessEquals(field.left, epsilon: epsilon));
    expect(row.right, moreOrLessEquals(field.right, epsilon: epsilon));
    expect(tester.takeException(), isNull);
  });

  group('G9 — the two empty faces render clean in Vietnamese', () {
    // Reviewed as a coverage gap (M99.93 UI/UX pass): neither empty face had
    // a Vietnamese render anywhere. Stream-based, not `loadedRepository()` —
    // reaching an empty face means changing the query after the frame is up,
    // and `.loaded()`'s stream is a single fixed value the widget subscribes
    // to once.
    FakeCardRepository loadedThenEmptyRepository() {
      final repository = FakeCardRepository();
      repository.distributionToShow = const CardStateDistributionModel(
        total: 1,
        isNew: 1,
        beginning: 0,
        reviewing: 0,
        mastered: 0,
      );

      return repository;
    }

    testWidgets('a search matching nothing', (tester) async {
      final repository = loadedThenEmptyRepository();
      addTearDown(repository.dispose);
      await pumpList(tester, repository, locale: const Locale('vi'));
      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      repository.emitCount(1);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'không có');
      await tester.pump();
      repository.emitItems(<dynamic>[].cast());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a state pill matching nothing', (tester) async {
      final repository = loadedThenEmptyRepository()
        ..filterCounts[CardListFilter.isNew] = 0;
      addTearDown(repository.dispose);
      await pumpList(tester, repository, locale: const Locale('vi'));
      repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
      repository.emitCount(1);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(MxPillButton, 'Mới'));
      await tester.pump();
      repository.emitItems(<dynamic>[].cast());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('G10 — two rows sit one list-item gap apart', (tester) async {
    // The rows used to be `md` (12) apart while the deck list they are
    // modelled on used `lg` (16) — one semantic role, two spellings
    // (SC-C2-08). Measured rather than read off the source, so a later edit
    // to the separator fails here as well as in the composition ratchet.
    await pumpList(tester, loadedRepository());
    await tester.pumpAndSettle();

    final first = tester.getRect(find.byType(CardTileWidget).at(0));
    final second = tester.getRect(find.byType(CardTileWidget).at(1));

    expect(
      second.top - first.bottom,
      moreOrLessEquals(AppSpacing.lg, epsilon: epsilon),
      reason:
          'app_spacing.dart defines lg as the gap between list items, and '
          'deck_list_sliver_widget.dart separates the deck rows by it',
    );
  });

  testWidgets('G11 — the floating create clears the empty face CTA', (
    tester,
  ) async {
    // The list answers its clearance through `mxScrollEndInsetOf` (G5), but
    // the empty faces are not that list: `MxEmptyState` centres itself and
    // pads on its own, so nothing about G5 says the button cannot land on the
    // "Add card" action underneath it. Measured because the two are the same
    // verb — a FAB sitting on the CTA it duplicates is the one overlap on this
    // screen a reader would misread as a single control (SC-C4-05 risk note).
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pumpList(tester, repository);
    repository.emitItems(<dynamic>[].cast());
    repository.emitCount(0);
    await tester.pumpAndSettle();

    final fab = tester.getRect(find.byType(MxFab));
    final cta = tester.getRect(find.widgetWithText(MxActionButton, 'Add card'));

    expect(
      fab.overlaps(cta),
      isFalse,
      reason:
          "the floating create and the empty face's Add card action are the "
          'same verb; overlapping them reads as one control that half works',
    );
  });
}
