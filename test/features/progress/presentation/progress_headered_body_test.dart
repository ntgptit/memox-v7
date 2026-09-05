import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/presentation/screens/progress_deck_screen.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_level_header_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// What the library level does with the space under the overview band.
///
/// The three faces that are a single box — loading, empty, error — all reach
/// the screen through `ProgressHeaderedBody`, and all three are a `Center`:
/// they centre themselves in whatever they are given. So the only question
/// that decides how they look is what the wrapper gives them, and that is one
/// contract shared by three faces rather than three separate layout bugs.
///
/// **A `Column` in a `SingleChildScrollView` gave them nothing to centre in**
/// (SC-C3-18): unbounded vertically, the `Center` shrink-wrapped and
/// top-anchored under the band, while the *loaded* face of the same screen and
/// the deck list both hand their empty state a
/// `SliverFillRemaining(hasScrollBody: false)`. These tests pin the sliver
/// contract from both sides, because both sides have already been got wrong
/// once: the state must take the space that is left when there is any, and it
/// must keep its own height when there is not.
void main() {
  final english = AppLocalizationsEn();

  /// A band short enough that there is room left under it.
  ///
  /// A stub rather than the real overview: what is being measured is the
  /// wrapper's arithmetic, and the real band is 644dp of a 716dp viewport, so
  /// a test built on it can only ever measure the no-room half. The height is
  /// stated here so the expected midpoint below is arithmetic a reader can
  /// follow rather than a number read off a run.
  const double bandHeight = 120;
  const Widget band = SizedBox(height: bandHeight);

  /// Where the shell's body ends on the harness's own 393x852 surface.
  ///
  /// The surface is left at the harness default rather than restated at every
  /// call, the way the neighbouring geometry tests do it — they pass `surface:`
  /// only where it differs. If that default ever moves, this number stops
  /// matching and the tests say so.
  ///
  /// No `NavigationBar` in [pumpProgressScreen] — `ProgressDeckScreen` is
  /// mounted on its own, so the shell body runs to the bottom of the device.
  const double bodyBottom = 852;

  group('the state takes the space the band leaves', () {
    testWidgets('an empty level fills what is left and centres in it', (
      tester,
    ) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          emptyActivitySnapshot(),
        ),
        screen: const ProgressDeckScreen(header: band),
      );

      final Rect header = tester.getRect(
        find.byType(ProgressLevelHeaderWidget),
      );
      final Rect face = tester.getRect(find.byType(MxEmptyState));

      // The band's own padding is part of it, so the state starts where the
      // band ends and runs to the bottom of the body — not 176dp of state
      // hanging off the underside of the band with the rest of the page blank.
      expect(face.top, header.bottom);
      expect(face.bottom, bodyBottom);

      // And the content is centred in that box rather than sitting at its top,
      // which is the visible half of the same claim.
      final Rect title = tester.getRect(
        find.text(english.progressEmptyDecksTitle),
      );
      expect(
        title.center.dy,
        closeTo(face.center.dy, 24),
        reason: 'the title should read as centred under the band',
      );
    });

    testWidgets('a failed read fills it the same way', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.failing(
          const DatabaseFailure(message: 'read failed'),
        ),
        screen: const ProgressDeckScreen(header: band),
      );

      final Rect header = tester.getRect(
        find.byType(ProgressLevelHeaderWidget),
      );
      final Rect face = tester.getRect(find.byType(MxErrorState));

      expect(face.top, header.bottom);
      expect(face.bottom, bodyBottom);
    });

    testWidgets('so does the level still loading', (tester) async {
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository(
          activity: (_) => const Stream<DeckActivitySnapshot>.empty(),
        ),
        screen: const ProgressDeckScreen(header: band),
      );

      final Rect header = tester.getRect(
        find.byType(ProgressLevelHeaderWidget),
      );
      final Rect face = tester.getRect(find.byType(MxLoadingState));

      expect(face.top, header.bottom);
      expect(face.bottom, bodyBottom);
    });
  });

  group('a band with no room left under it', () {
    /// The real overview band, which at 393x852 is 644dp of a 716dp viewport.
    ///
    /// This is the state the app actually ships today, and the reason the
    /// tests above use a stub: there are 72dp left under the real band, and
    /// every face is taller than that.
    testWidgets('the state keeps its own height rather than being squashed '
        'into what is left', (tester) async {
      await pumpProgressApp(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          emptyActivitySnapshot(),
        ),
      );

      final Rect header = tester.getRect(
        find.byType(ProgressLevelHeaderWidget),
      );
      final Rect face = tester.getRect(find.byType(MxEmptyState));
      final Rect bar = tester.getRect(find.byType(NavigationBar));

      // The premise, stated rather than assumed, because it is the whole
      // reason the tests above use a stub band: the real one runs 56→700 of a
      // 56→772 viewport, so 72dp are left and the face needs 176. An earlier
      // version of this test asserted `header.bottom > bar.top` instead — the
      // band overrunning the bar — which is not what the screen does and made
      // the composition look worse than it is.
      final double roomLeft = bar.top - header.bottom;
      expect(roomLeft, lessThan(face.height));

      // `hasScrollBody: false` takes the *larger* of the remaining extent and
      // the child's own height. Without that half of the contract the state
      // would be squeezed into those 72dp and scroll inside itself — the one
      // outcome worse than starting below the fold.
      expect(face.top, header.bottom);
      expect(face.height, greaterThan(roomLeft));

      // And the page scrolls far enough to bring all of it up, which is the
      // difference between *below the fold* and *cut off*. The outer scroll
      // view, not `MxEmptyState`'s own: the face nests one, and the nested one
      // has nothing to scroll.
      final ScrollPosition position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(ProgressHeaderedBody),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      expect(
        position.maxScrollExtent,
        greaterThanOrEqualTo(face.bottom - bar.top),
      );
    });

    testWidgets('every face is still built when the band alone is taller than '
        'the viewport', (tester) async {
      // **The regression this composition was rewritten to avoid.** A band and
      // a `SliverFillRemaining` as *two* slivers reads correctly and, at text
      // scale 2.0, does not build the second one at all: the band measures
      // 1084dp, and a sliver starting past the viewport plus its cache extent
      // is never laid out. The error face's `liveRegion` then announces
      // nothing, because there is no node to announce. One sliver holding both
      // starts at offset 0 and is always built.
      for (final (String name, Finder face) in <(String, Finder)>[
        ('empty', find.byType(MxEmptyState)),
        ('error', find.byType(MxErrorState)),
      ]) {
        await pumpProgressApp(
          tester,
          repository: name == 'empty'
              ? FakeProgressRepository.withSnapshot(emptyActivitySnapshot())
              : FakeProgressRepository.failing(
                  const DatabaseFailure(message: 'read failed'),
                ),
          textScale: 2,
        );

        expect(face, findsOneWidget, reason: 'the $name face at text scale 2');
      }
    });
  });

  group('inside a deck', () {
    testWidgets('there is no band, and the body is not wrapped in a scroll '
        'view of its own', (tester) async {
      // `header == null` must keep returning the body bare: the shell already
      // gives it the full height, and a scroll view here would take that bound
      // away and re-create the shrink-wrap this file is about.
      await pumpProgressScreen(
        tester,
        repository: FakeProgressRepository.withSnapshot(
          emptyActivitySnapshot(scopeDeckId: 'leaf', scopeName: 'Verbs'),
        ),
        screen: const ProgressDeckScreen(deckId: 'leaf'),
      );

      expect(find.byType(ProgressLevelHeaderWidget), findsNothing);
      expect(tester.getRect(find.byType(MxEmptyState)).bottom, bodyBottom);
    });
  });
}
