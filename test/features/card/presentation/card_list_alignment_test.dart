import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_progress_panel_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
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
    // Phone and wide only, like `tag_catalog_alignment_test.dart`'s own G1:
    // below `AppBreakpoints.compact` the shell's subheader gutter steps to
    // `md` while the list keeps its fixed `lg` — a pre-existing shell trade
    // this screen makes identically, not something this file reopens.
    for (final size in <Size>[phone, wide]) {
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
      AppSpacing.xxl,
      reason:
          'restated from card_list_body_widget.dart so the two cannot '
          'drift silently',
    );
  });

  group('G6 — touch targets clear 48dp', () {
    testWidgets('the app-bar Select and Add actions', (tester) async {
      await pumpList(tester, loadedRepository());
      await tester.pumpAndSettle();

      for (final finder in [
        find.byType(MxIconButton).first,
        find.byType(MxIconButton).at(1),
      ]) {
        final rect = tester.getRect(finder);
        expect(rect.width, greaterThanOrEqualTo(48 - epsilon));
        expect(rect.height, greaterThanOrEqualTo(48 - epsilon));
      }
    });

    testWidgets('the selection bar close and select-all actions', (
      tester,
    ) async {
      await pumpList(tester, loadedRepository());
      await tester.pumpAndSettle();
      await tester.longPress(find.byType(CardTileWidget).first);
      await tester.pumpAndSettle();

      // The icon glyph itself measures its own small size — the tap target
      // is the `MxIconButton` around it, the same distinction G6's app-bar
      // case draws by measuring the button type directly.
      final close = tester.getRect(
        find.ancestor(
          of: find.descendant(
            of: find.byType(CardSelectionBarWidget),
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
      // no exception is the claim; the selection bar's two-line count label
      // exists specifically for this width×scale (its own comment).
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
}
