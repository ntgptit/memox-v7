import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/trash/di/trash_repository_provider.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/models/trash_item_type_model.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_row_widget.dart';
import 'package:memox/features/trash/presentation/widgets/sections/trash_selection_bar_widget.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

import 'support/fake_trash_repository.dart';

/// The geometry and responsive contracts the Trash wireframe writes down.
///
/// **M99.33 shipped with none of these measured, and said so.** Its own entry
/// recorded the gap in plain words — *"Không có test geometry/semantics nào cho
/// Trash"* — and the reconciliation at M100.9 confirmed it against the code: at
/// that point `test/features/trash/presentation/` contained **zero** uses of
/// `getRect`. The behaviour tests beside this file are good and cover what the
/// screen *does*; nothing covered where anything *sits*.
///
/// The contracts are `docs/wireframes/m99-33-trash-restore.md` G1…G8 and
/// R1…R6. This file measures the ones a widget test can see. The ones it
/// cannot are named at the bottom with the reason, because an unmeasured
/// contract that nobody has written down as unmeasured is indistinguishable
/// from one that passed.
void main() {
  final english = AppLocalizationsEn();
  final now = DateTime.utc(2026, 8, 15, 12);

  Future<void> pumpTrash(
    WidgetTester tester, {
    required List<TrashBatchEntity> batches,
    Size size = const Size(393, 852),
    double textScale = 1,
  }) async {
    final repository = FakeTrashRepository(batches: batches);
    addTearDown(repository.dispose);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trashRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const TrashScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<TrashBatchEntity> twoRows() => <TrashBatchEntity>[
    fakeBatch(
      id: 'b1',
      name: 'give up',
      originDeckName: 'Phrasal verbs',
      deletedAt: DateTime.utc(2026, 8, 13, 12),
    ),
    fakeBatch(
      id: 'b2',
      itemType: TrashItemType.deck,
      name: 'Idioms',
      originDeckName: 'Grammar',
      deckCount: 3,
      cardCount: 37,
      deletedAt: DateTime.utc(2026, 8, 4, 12),
    ),
  ];

  /// Rounded, because layout arithmetic lands on values like 15.999999999999998
  /// and a contract about a shared edge is not a contract about a float.
  double left(WidgetTester tester, Finder finder) =>
      double.parse(tester.getRect(finder).left.toStringAsFixed(1));

  /// The right edge of the last glyph a subtree paints, rounded like [left].
  double glyphRight(WidgetTester tester, Finder of) => double.parse(
    tester
        .getRect(find.descendant(of: of, matching: find.byType(Icon)).last)
        .right
        .toStringAsFixed(1),
  );

  /// The page gutters every contract below is written against, and how much of
  /// the trailing side the overflow button's own inset cannot give back.
  ///
  /// **Two surfaces, not one.** `mxScreenGutter` steps down to `md` under
  /// `AppBreakpoints.compact`, so a shared-edge contract measured at a single
  /// width cannot see the tier where the edges actually come apart — which is
  /// how the selection bar held a literal 16 while everything above it went
  /// to 12.
  ///
  /// The third figure is the trailing residue. The row buys its right edge by
  /// paying `xs` outside a button that centres a 24dp glyph in a 48dp box, so
  /// 4 + 12 lands on 16 — exactly the gutter at regular width, and 4dp inside
  /// it on the compact tier, where the button's half-box does not step down
  /// with the gutter. `deck_tile_widget.dart:113-117` makes the same trade for
  /// the same reason; buying the last 4dp would mean a zero trailing pad at
  /// 320dp, which is a different decision from this one.
  const List<(Size, double, double)> surfaces = <(Size, double, double)>[
    (Size(320, 640), AppSpacing.md, AppSpacing.xs),
    (Size(393, 852), AppSpacing.lg, 0),
  ];

  group('G1 · one left edge for the whole screen', () {
    for (final (Size size, double gutter, _) in surfaces) {
      testWidgets(
        'chip, explanation, row and selection bar start at $gutter at '
        '${size.width.toInt()}dp',
        (tester) async {
          await pumpTrash(tester, batches: twoRows(), size: size);

          // Read before the long press: the chips are the shell's subheader,
          // and the screen drops it while a selection is held.
          final chip = left(tester, find.byType(MxPillButton).first);

          await tester.longPress(find.text('give up'));
          await tester.pumpAndSettle();

          // The row is full-bleed — its own rect starts at 0 and its padding
          // makes the inset — so what G1 constrains is the first thing the row
          // *paints*, which in selection is the checkbox glyph.
          final rowLeading = left(
            tester,
            find
                .descendant(
                  of: find.byType(TrashRowWidget),
                  matching: find.byType(Icon),
                )
                .first,
          );

          expect(
            <double>{
              chip,
              left(tester, find.text(english.trashRetentionNotice)),
              rowLeading,
              left(
                tester,
                find.descendant(
                  of: find.byType(TrashSelectionBarWidget),
                  matching: find.byType(MxActionButton),
                ),
              ),
            },
            <double>{gutter},
            reason:
                'G1: the first chip, the explanation line, every row and the '
                'selection bar share one left edge, and it is the gutter — '
                '$gutter at ${size.width.toInt()}dp',
          );
        },
      );
    }
  });

  group('G2 · the row lines its trailing glyph up with the gutter', () {
    for (final (Size size, double gutter, double residue) in surfaces) {
      testWidgets('the kebab ends one gutter in at ${size.width.toInt()}dp', (
        tester,
      ) async {
        await pumpTrash(tester, batches: twoRows(), size: size);

        // The row pays `xs` outside the overflow button rather than the
        // gutter, because the button is a 48 box around a 24 glyph and carries
        // 12dp of its own inset. It used to pay the gutter there, which put
        // the glyph 28dp from the edge against a 16dp left one.
        expect(
          glyphRight(tester, find.byType(TrashRowWidget).first),
          size.width - gutter - residue,
          reason:
              'G2: the row\'s trailing glyph sits on the same edge the chips, '
              'the notice and its own leading icon use, less the $residue the '
              'button\'s half-box keeps on the compact tier',
        );
      });
    }

    testWidgets('a selecting row keeps the real gutter on that side', (
      tester,
    ) async {
      await pumpTrash(tester, batches: twoRows());

      await tester.longPress(find.text('give up'));
      await tester.pumpAndSettle();

      // Nothing trailing left to absorb the button's own inset, so the
      // conditional hands the row its full gutter back and the body ends where
      // the glyphs did. This is the assertion that stops the conditional being
      // 'simplified' into a constant `xs`.
      final body = tester.getRect(
        find
            .descendant(
              of: find.byType(TrashRowWidget).first,
              matching: find.byType(Expanded),
            )
            .first,
      );

      expect(double.parse(body.right.toStringAsFixed(1)), 393 - AppSpacing.lg);
    });

    testWidgets('what is left of the violation is the AppBar\'s own inset', (
      tester,
    ) async {
      await pumpTrash(tester, batches: twoRows());

      final rowOverflow = glyphRight(tester, find.byType(TrashRowWidget).first);
      final barOverflow = glyphRight(tester, find.byType(AppBar));

      // **G2 asks for these to be equal, and they still are not — but the
      // remainder is no longer the row's.** The row's half is fixed by the
      // cases above; what is left is Material's `AppBar` action padding, which
      // every screen in the app shares, so moving it is a kit-wide decision
      // and not part of giving Trash its measurements.
      //
      // Kept as an assertion rather than deleted, so the open half of G2 stays
      // visible the way `app_high_contrast_test.dart` pins "the normal theme
      // still cannot". When someone aligns the AppBar this fails, and the fix
      // is to invert it into `expect(rowOverflow, barOverflow)`.
      expect(
        barOverflow - rowOverflow,
        4.0,
        reason:
            'G2 is still open by 4dp, and all of it is the AppBar\'s '
            '(row=$rowOverflow, bar=$barOverflow). If this number changed, '
            'either the AppBar was aligned too — invert this into '
            '`expect(rowOverflow, barOverflow)` — or the row regressed.',
      );
    });
  });

  group('G3 · the three text lines share an edge the icon sits outside', () {
    testWidgets('name, deleted-ago and origin align; the glyph does not', (
      tester,
    ) async {
      await pumpTrash(tester, batches: twoRows());

      final name = left(tester, find.text('give up'));
      final deletedAgo = left(
        tester,
        find.text(english.trashDeletedDaysAgo(2)),
      );
      final origin = left(
        tester,
        find.textContaining('Phrasal verbs', findRichText: true),
      );

      expect(
        <double>{name, deletedAgo, origin},
        <double>{name},
        reason:
            'G3: the three lines of a row share one left edge. '
            'name=$name deletedAgo=$deletedAgo origin=$origin',
      );

      final glyph = left(
        tester,
        find
            .descendant(
              of: find.byType(TrashRowWidget),
              matching: find.byType(Icon),
            )
            .first,
      );

      expect(
        glyph,
        lessThan(name),
        reason: 'G3: the type icon sits outside the text column, at $glyph',
      );
    });
  });

  group('G7 · the purge dialog offers the way out first', () {
    testWidgets('read in the axis the pair actually used', (tester) async {
      await pumpTrash(tester, batches: twoRows());

      await tester.longPress(find.text('give up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.trashPurgeAction).last);
      await tester.pumpAndSettle();

      // Scoped to the dialog: `trashPurgeAction` and `trashPurgeConfirmAction`
      // are the same string, so an unscoped finder also picks up the selection
      // bar's button sitting behind the barrier.
      final dialog = find.byType(AlertDialog);
      Rect inDialog(String label) => tester.getRect(
        find.descendant(of: dialog, matching: find.text(label)),
      );

      final cancel = inDialog(english.trashPurgeCancelAction);
      final destructive = inDialog(english.trashPurgeConfirmAction);

      // **G7 is written for a row, and `MxButtonPair` does not always give one.**
      // It measures both labels and stacks when they will not fit, which is what
      // happens here — `Delete permanently` beside `Cancel` does not fit a
      // dialog's action row. Asserting `cancel.left < destructive.left` against
      // a stack is asserting a contract the layout is not in, and it fails while
      // nothing is wrong: the first draft of this test did exactly that.
      //
      // So the axis is read first. `mx_button_pair.dart` states the stacked
      // order in its own words — the primary is "Right in a row, **top** when
      // stacked" — so G7's *end* position is the bottom of a stack, and the way
      // out is the one further from the thumb's resting place either way.
      final stacked = destructive.top != cancel.top;

      if (stacked) {
        expect(
          destructive.top,
          lessThan(cancel.top),
          reason:
              'G7 (stacked): MxButtonPair puts the primary on top, so the '
              'irreversible action is above and Cancel below it',
        );
        return;
      }

      expect(
        cancel.left,
        lessThan(destructive.left),
        reason:
            'G7 (row): the way out sits at the start and the irreversible '
            'action at the end',
      );
    });
  });

  group('T4 · the age and the countdown are two facts, not one line', () {
    testWidgets('a separator and a full item gap part them at 393dp', (
      tester,
    ) async {
      await pumpTrash(tester, batches: twoRows());

      final age = tester.getRect(find.text(english.trashDeletedDaysAgo(2)));
      final countdown = tester.getRect(find.text(english.trashDaysLeft(28)));
      final dot = tester.getRect(
        find.descendant(
          of: find.byType(TrashRowWidget).first,
          matching: find.text('·'),
        ),
      );

      // Same run, or the gap below is a line break rather than a gap.
      expect(
        age.top,
        countdown.top,
        reason:
            'T4: at 393dp both facts fit one line; if they no longer do, the '
            'measurement below is reading across a wrap',
      );

      // **W2 draws the row as `Deleted 2 days ago · 27 days left`.** The two
      // facts used to sit `xs` apart with nothing between them, and `xs` is
      // the icon-to-label step — at that distance the only boundary left was
      // an ink shift the light theme barely carries, so the line read as one
      // sentence. The dot is the boundary; `sm` on each side of it is the gap
      // `deck_workload_line_widget.dart` gives the same kind of row.
      expect(
        <double>[
          double.parse((dot.left - age.right).toStringAsFixed(1)),
          double.parse((countdown.left - dot.right).toStringAsFixed(1)),
        ],
        <double>[AppSpacing.sm, AppSpacing.sm],
        reason:
            'T4: the middle dot sits one item gap from each fact — '
            'age=$age dot=$dot countdown=$countdown',
      );
    });
  });

  group('R1 · 320dp at 2.0x text scale', () {
    testWidgets('nothing overflows horizontally', (tester) async {
      final overflows = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception.toString().contains('overflowed')) {
          overflows.add(details.exception.toString().split('\n').first);
          return;
        }
        previous?.call(details);
      };
      addTearDown(() => FlutterError.onError = previous);

      await pumpTrash(
        tester,
        batches: twoRows(),
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(
        overflows,
        isEmpty,
        reason:
            'R1: the row must survive the narrowest supported screen at the '
            'text scale most likely to be on. ${overflows.join(' | ')}',
      );
    });

    testWidgets('the days-left figure is never the thing that gets cut', (
      tester,
    ) async {
      await pumpTrash(
        tester,
        batches: twoRows(),
        size: const Size(320, 640),
        textScale: 2,
      );

      // R1 names this explicitly: the name and the path may ellipsise, the
      // remaining-days figure may not. It is the only number on the row that
      // expires, so a clipped one is worse than a clipped name.
      final finder = find.text(english.trashDaysLeft(28));
      expect(finder, findsOneWidget);

      final text = tester.widget<Text>(finder);
      expect(
        text.overflow,
        isNot(TextOverflow.ellipsis),
        reason: 'R1: `N days left` must not be the line that ellipsises',
      );
    });

    testWidgets('the separator never becomes a run of its own', (tester) async {
      // **The cost of a separator that is its own `Wrap` child, measured
      // rather than assumed.** The two facts do not fit one line at 320dp —
      // that was already true before the dot existed — so the dot lands
      // wherever the run breaks, and where that is depends on the scale:
      // at 1.0 it stays behind the age (`Deleted 2 days ago ·` / `28 days
      // left`), at 2.0 the age fills the line alone and the dot leads the
      // second run (`· 28 days left`). Both are legible; neither is what a
      // reviewer would draw. What must not happen is the third case — a line
      // holding nothing but the dot — and that is what this pins, because it
      // is the one that reads as a rendering fault rather than as a wrap.
      for (final double scale in <double>[1, 2]) {
        await pumpTrash(
          tester,
          batches: twoRows(),
          size: const Size(320, 640),
          textScale: scale,
        );

        final row = find.byType(TrashRowWidget).first;
        Rect inRow(Finder matching) =>
            tester.getRect(find.descendant(of: row, matching: matching).first);

        final age = inRow(find.text(english.trashDeletedDaysAgo(2)));
        final dot = inRow(find.text('·'));
        final countdown = inRow(find.text(english.trashDaysLeft(28)));

        expect(
          dot.top == age.top || dot.top == countdown.top,
          isTrue,
          reason:
              'R1: at 320dp @${scale}x the middle dot shares a run with one of '
              'the two facts — age=$age dot=$dot countdown=$countdown',
        );
      }
    });
  });

  group('R4 · every icon-only control announces itself', () {
    testWidgets('each MxIconButton carries a semantic label', (tester) async {
      await pumpTrash(tester, batches: twoRows());

      final buttons = tester.widgetList<MxIconButton>(
        find.byType(MxIconButton),
      );
      expect(buttons, isNotEmpty, reason: 'no icon-only control was rendered');

      for (final button in buttons) {
        expect(
          button.semanticLabel,
          isNotNull,
          reason:
              'R4: an icon-only control with no label is a control a screen '
              'reader announces as nothing',
        );
        expect(button.semanticLabel, isNotEmpty);
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Contracts this file does not measure, and why — because an unmeasured
// contract nobody wrote down as unmeasured looks exactly like a passing one.
//
// * **G4** (`Restore` baseline == the name line's baseline). A widget test can
//   read rects, not baselines, and the two texts are different sizes so
//   comparing rect bottoms would assert something else and call it G4.
// * **G5** (selection bar anchored to the safe bottom; the list takes a bottom
//   inset equal to the bar's height). Needs a non-zero `viewPadding.bottom` to
//   mean anything, which is a device fact rather than a widget-test one.
// * **G6** (the sheet keeps its height between state 10 and state 8). M99.33
//   already recorded that state 8 is not built, so there is nothing to compare
//   against yet.
// * **G8** (the undo snackbar clears the FAB and the navigation bar). Both come
//   from the app shell, and this file pumps the screen without it.
// * **R2** (all copy from ARB) — covered by `trash_screen_test.dart`, which
//   asserts against `AppLocalizationsEn` throughout rather than literals.
// * **R3** (destructive contrast in both themes) — the role, not the screen:
//   `app_palette_test.dart` and `control_border_grounds_test.dart` measure
//   `danger` against every ground it is drawn on.
// * **R5** (a row reads as one semantics node) — covered by
//   `trash_screen_test.dart`: *"a row narrates once"*.
// * **R6** (undo snackbar duration and a readable action) — `MxUndoSnackBar`
//   owns both, and `mx_stress_test.dart` excludes it for the same reason: it
//   configures Material's own `SnackBar` and has no layout of its own.
