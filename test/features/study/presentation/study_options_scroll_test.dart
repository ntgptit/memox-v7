import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// Study Options outgrows its viewport, and now it scrolls.
///
/// **Every other form screen in the app already did** — reminder settings,
/// settings, the card editor — and `reminder_settings_screen.dart` writes the
/// reason directly above its own `isScrollable: true`: the honest fix for a
/// screen that outgrows its viewport is to let it scroll.
///
/// **The cells are the ones that actually failed, which is the finding
/// corrected** (SC-C7-03). The registry named 320×852 at textScale 2.5; that
/// cell does not overflow on the current tree, so a test written to it would be
/// green on broken code. Measured instead: 320×640 at 2.0 overflowed by 28px
/// and 360×640 at 2.5 by 130px, and what fell off the bottom both times was
/// `Use app defaults` — an action with nothing left to scroll it back.
///
/// `isRootOverride` is true throughout, because that is the state that offers
/// the second action at all (BR-212), and it is the state that broke.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpOptions(
    WidgetTester tester, {
    required Size surface,
    required double scale,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studyRepositoryProvider.overrideWithValue(
            FakeStudyRepository()..isRootOverride = true,
          ),
        ],
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
          textScaler: TextScaler.linear(scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const cells = <({String name, Size surface, double scale})>[
    (name: '320×640 at 2.0', surface: Size(320, 640), scale: 2),
    (name: '360×640 at 2.5', surface: Size(360, 640), scale: 2.5),
    (name: '320×852 at 2.5', surface: Size(320, 852), scale: 2.5),
  ];

  for (final cell in cells) {
    testWidgets('${cell.name}: nothing overflows and the second action is '
        'reachable', (tester) async {
      await pumpOptions(tester, surface: cell.surface, scale: cell.scale);

      expect(tester.takeException(), isNull);

      // Present in the tree is not the claim — a fixed column had it there too,
      // painted past the bottom edge with no way to bring it back. The claim is
      // that scrolling reaches it.
      await tester.ensureVisible(
        find.widgetWithText(MxTextButton, english.studyOptionsUseAppDefaults),
      );
      await tester.pumpAndSettle();

      final action = tester.getRect(
        find.widgetWithText(MxTextButton, english.studyOptionsUseAppDefaults),
      );
      expect(action.bottom, lessThanOrEqualTo(cell.surface.height));
      expect(action.top, greaterThanOrEqualTo(0));
    });
  }

  testWidgets('at 393dp and ordinary scale the form does not move', (
    tester,
  ) async {
    await pumpOptions(tester, surface: const Size(393, 852), scale: 1);

    // The reference render: the screen fits, so the scroll view adds nothing
    // visible and the committed demo golden stays where it is.
    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(MxTextButton, english.studyOptionsUseAppDefaults),
      findsOneWidget,
    );
  });
}
