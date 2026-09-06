import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/presentation/controllers/starter_library_controller.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../support/android_text_scaler.dart';

/// What a starter row gives the deck name when the words get long.
///
/// **The measurement the finding was written from** (SC-C7-01). The row put an
/// `Expanded` identity column and a non-flexible trailing word in one fixed
/// `Row`. A `RenderFlex` sizes its non-flex child at full intrinsic width
/// first, so `Add to library` — the same three words on every open row, and so
/// the half carrying no information — took what it wanted and the name took
/// what was left. Measured on the card's content band before the fix, in
/// Vietnamese at `textScaler` 2.0: 93.8dp of 329 at 393dp, 60.8 of 296 at
/// 360dp, 28.8 of 264 at 320dp. That last one is about one glyph.
///
/// The assertions are written as *shares of the band* rather than as pixel
/// counts on purpose: the numbers above move with the font and the locale, and
/// a test pinned to them would fail for reasons that are not this defect. What
/// must not move is which of the two halves gets the room.
void main() {
  DeckTemplate template(String title) => DeckTemplate(
    templateId: 'starter-1',
    version: 1,
    locale: 'vi',
    title: DeckName.parse(title).name!,
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

  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    required TextScaler scaler,
    required String title,
    Locale? locale,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The rows, not the catalog plus a repository: this test is about
          // what a row does with the width it is given, and the read that
          // produces one is somebody else's subject.
          starterLibraryProvider.overrideWith(
            (ref) async => <StarterTemplateRow>[
              (template: template(title), isInstalled: false),
            ],
          ),
        ],
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const StarterLibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const title = 'Tiếng Anh giao tiếp hằng ngày';

  const stacking = <({String name, Size size, Locale? locale})>[
    (name: 'vi 393dp', size: Size(393, 852), locale: Locale('vi')),
    (name: 'vi 360dp', size: Size(360, 780), locale: Locale('vi')),
    (name: 'vi 320dp', size: Size(320, 640), locale: Locale('vi')),
    (name: 'en 393dp', size: Size(393, 852), locale: null),
    (name: 'en 360dp', size: Size(360, 780), locale: null),
    (name: 'en 320dp', size: Size(320, 640), locale: null),
  ];

  /// **Both curves, and the non-linear one is the one that matters** (final
  /// corrective pass). The threshold used to be
  /// `textScalerOf(context).scale(320)`, which under `TextScaler.linear(2.0)`
  /// returns 640 — the row stacks and the test agrees with a broken layout.
  /// Android's table is flat past 100sp, so on a real phone at the same setting
  /// that call returned **320 unchanged** and the row stayed inline exactly
  /// where the deck name was being cut to a glyph. `AndroidTextScaler.largest`
  /// grows body rungs by 2.0 as well, so the only difference between the two
  /// harnesses is the shape of the curve.
  const curves = <({String name, TextScaler scaler})>[
    (name: 'Android 2.0', scaler: AndroidTextScaler.largest),
    (name: 'linear 2.0', scaler: TextScaler.linear(2)),
  ];

  for (final curve in curves) {
    group('at ${curve.name} the row stacks', () {
      for (final cell in stacking) {
        testWidgets('${cell.name}: the name keeps the band', (tester) async {
          await pump(
            tester,
            size: cell.size,
            scaler: curve.scaler,
            title: title,
            locale: cell.locale,
          );

          final card = tester.getRect(find.byType(MxCard).first);
          final name = tester.getRect(find.text(title));

          // Stacked, so the name is on its own line and has the whole band
          // minus the card's padding. Half is the bar the finding set; the
          // arrangement clears it by a wide margin, which is the point.
          expect(name.width, greaterThan(card.width / 2));
          // Stacked, not merely wide: the state sits below the name rather than
          // beside it, which is the transition the threshold decides.
          final state = tester.getRect(
            find.text(
              cell.locale == null
                  ? AppLocalizationsEn().starterLibraryInstallAction
                  : AppLocalizationsVi().starterLibraryInstallAction,
            ),
          );
          expect(state.top, greaterThan(name.bottom));
          // And nothing was cut to get there.
          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  testWidgets('at ordinary scale a 393dp phone still draws one line', (
    tester,
  ) async {
    await pump(
      tester,
      size: const Size(393, 852),
      scaler: TextScaler.noScaling,
      title: title,
      locale: const Locale('vi'),
    );

    final name = tester.getRect(find.text(title));
    final state = tester.getRect(
      find.text(AppLocalizationsVi().starterLibraryInstallAction),
    );

    // The reference render must not move: 393dp at scale 1.0 is the surface
    // the committed goldens and the screen gallery are shot at, and the band
    // there is 329 — comfortably over the threshold.
    expect(name.top, lessThan(state.bottom));
    expect(state.left, greaterThan(name.right));
  });
}
