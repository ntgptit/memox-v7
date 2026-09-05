import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/study/presentation/widgets/overlays/study_resume_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_sheet.dart';

/// What the resume sheet **measures**: that its longest face still fits, and
/// that every one of the three ways forward can be reached.
///
/// **Pumped through the real `showMxSheet` route, not through `wrapForTest`.**
/// The harness at `support/study_widget_harness.dart` wraps whatever it is
/// given in a `SingleChildScrollView` of its own, so a sheet that does not
/// scroll looks identical to one that does — which is precisely why the
/// overflow this file exists for survived every test the widget already had.
void main() {
  group('the resume sheet geometry (BR-103)', () {
    /// The shortest surface the app supports, with an Android three-button bar
    /// eating the bottom and text at the Definition of Done's large scale.
    const Size shortest = Size(320, 568);
    const double statusBar = 24;
    const double systemBar = 48;

    Future<void> pumpResumeSheet(
      WidgetTester tester, {
      required Size surface,
      TextScaler textScaler = TextScaler.noScaling,
    }) async {
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(
        top: statusBar,
        bottom: systemBar,
      );
      tester.view.viewPadding = const FakeViewPadding(
        top: statusBar,
        bottom: systemBar,
      );
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, widget) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: widget ?? const SizedBox.shrink(),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showMxSheet<StudyResumeChoice>(
                    context,
                    builder: (_) => StudyResumeWidget(onChoice: (_) {}),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('the third way forward is reachable at 320dp × 2.0', (
      tester,
    ) async {
      // **The face that did not fit.** Title, an 86-character paragraph and
      // three full-width buttons are the longest body of the three study
      // sheets; without a scroll view the column overflowed by 65dp here and
      // painted `Review` off the bottom of the display, with nothing to drag.
      await pumpResumeSheet(
        tester,
        surface: shortest,
        textScaler: const TextScaler.linear(2),
      );

      expect(tester.takeException(), isNull);

      final Finder review = find.widgetWithText(MxActionButton, 'Review');
      await tester.scrollUntilVisible(review, 100);
      await tester.pumpAndSettle();

      final Rect rect = tester.getRect(review);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(shortest.height));
    });

    testWidgets('nothing moves at a surface the content already fits', (
      tester,
    ) async {
      // The scroll view is inert wherever the column fits: all three buttons
      // are laid out at once, in order, without a drag.
      await pumpResumeSheet(tester, surface: const Size(393, 852));

      expect(tester.takeException(), isNull);

      final Rect resume = tester.getRect(
        find.widgetWithText(MxActionButton, 'Continue'),
      );
      final Rect review = tester.getRect(
        find.widgetWithText(MxActionButton, 'Review'),
      );
      expect(resume.left, review.left);
      expect(resume.width, review.width);
      expect(review.bottom, lessThanOrEqualTo(852 - systemBar));
    });
  });
}
