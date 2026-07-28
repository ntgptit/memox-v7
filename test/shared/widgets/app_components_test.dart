import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/app_button_widget.dart';
import 'package:memox/shared/widgets/app_card_surface_widget.dart';
import 'package:memox/shared/widgets/app_empty_state_widget.dart';
import 'package:memox/shared/widgets/app_error_state_widget.dart';
import 'package:memox/shared/widgets/app_loading_state_widget.dart';
import 'package:memox/shared/widgets/app_scaffold_widget.dart';

/// Mounts a component in a real theme so `context.colors` and
/// `context.semanticColors` resolve exactly as they do in the app.
Widget host(Widget child, {bool isDark = false}) => MaterialApp(
  theme: isDark ? buildDarkTheme() : buildLightTheme(),
  home: child,
);

void main() {
  group('AppButtonWidget', () {
    testWidgets('primary renders a FilledButton, secondary an OutlinedButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Column(
              children: <Widget>[
                AppButtonWidget(label: 'Primary', onPressed: null),
                AppButtonWidget(
                  label: 'Secondary',
                  onPressed: null,
                  variant: AppButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('loading disables the button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AppButtonWidget(
              label: 'Submit',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AppButtonWidget));
      await tester.pump();

      // The double-submit bug in its most common form: a second tap while the
      // first is still in flight.
      expect(taps, 0);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('loading does not change the button width', (tester) async {
      Future<double> widthFor({required bool isLoading}) async {
        await tester.pumpWidget(
          host(
            Scaffold(
              body: Center(
                child: AppButtonWidget(
                  label: 'Remembered',
                  isLoading: isLoading,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        return tester.getSize(find.byType(FilledButton)).width;
      }

      final idle = await widthFor(isLoading: false);
      final loading = await widthFor(isLoading: true);

      // A button that shrinks to spinner width moves everything beside it, at
      // exactly the moment the user is watching to see what happened.
      expect(loading, idle);
    });

    testWidgets('meets the 48x48 touch target', (tester) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AppButtonWidget(label: 'Ok', onPressed: () {}),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));

      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('AppLoadingStateWidget', () {
    testWidgets('announces itself to a screen reader', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: AppLoadingStateWidget(semanticsLabel: 'Loading cards'),
          ),
        ),
      );

      // A bare spinner announces nothing at all: the user is told neither that
      // something is happening nor when it stops.
      expect(find.bySemanticsLabel('Loading cards'), findsOneWidget);
    });
  });

  group('AppErrorStateWidget', () {
    testWidgets('takes a String, and renders retry only when wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: AppErrorStateWidget(
              title: 'Something went wrong',
              message: 'This part could not be displayed.',
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(AppButtonWidget), findsNothing);

      var retried = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AppErrorStateWidget(
              title: 'Something went wrong',
              message: 'This part could not be displayed.',
              retryLabel: 'Try again',
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(AppButtonWidget));

      expect(retried, 1);
    });
  });

  group('small screen and large text', () {
    /// Every component, in the two conditions that actually break layouts.
    final cases = <String, Widget>{
      'AppCardSurface': const AppCardSurface(
        child: Text('A prompt long enough to wrap on a narrow phone screen'),
      ),
      'AppScaffoldWidget': const AppScaffoldWidget(
        title: 'MemoX',
        body: Text('Body'),
      ),
      'AppButtonWidget': const AppButtonWidget(
        label: 'Remembered',
        onPressed: null,
      ),
      'AppLoadingStateWidget': const AppLoadingStateWidget(
        semanticsLabel: 'Loading',
      ),
      'AppEmptyStateWidget': const AppEmptyStateWidget(
        title: 'Nothing due today',
        message: 'You have finished every card scheduled for now.',
      ),
      'AppErrorStateWidget': const AppErrorStateWidget(
        title: 'Something went wrong',
        message: 'This part could not be displayed.',
      ),
    };

    for (final entry in cases.entries) {
      testWidgets('${entry.key} survives 320x568 at textScale 2.0', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          host(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              // Scaffold-less components need a Material ancestor for text.
              child: entry.value is AppScaffoldWidget
                  ? entry.value
                  : Scaffold(body: entry.value),
            ),
          ),
        );
        await tester.pump();

        // takeException catches the overflow assertion, which is how a
        // RenderFlex overflow reports itself in a test.
        expect(tester.takeException(), isNull, reason: entry.key);
      });
    }
  });
}
