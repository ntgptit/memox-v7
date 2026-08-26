import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

/// Mounts a component in a real theme so `context.colors` and
/// `context.semanticColors` resolve exactly as they do in the app.
Widget host(Widget child, {bool isDark = false}) => MaterialApp(
  theme: isDark ? buildDarkTheme() : buildLightTheme(),
  home: child,
);

void main() {
  group('MxActionButton', () {
    testWidgets('primary renders a FilledButton, secondary an OutlinedButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: Column(
              children: <Widget>[
                MxActionButton(label: 'Primary', onPressed: null),
                MxActionButton(
                  label: 'Secondary',
                  onPressed: null,
                  variant: MxActionButtonVariant.secondary,
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
            body: MxActionButton(
              label: 'Submit',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MxActionButton));
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
                child: MxActionButton(
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
            body: MxActionButton(label: 'Ok', onPressed: () {}),
          ),
        ),
      );

      final size = tester.getSize(find.byType(FilledButton));

      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      testWidgets('${mode.$1} · destructive resolves every state, not one', (
        tester,
      ) async {
        // The variant used to pass `FilledButton.styleFrom(backgroundColor:
        // error)`, and `styleFrom` builds a flat `WidgetStatePropertyAll`. A
        // non-null property on the widget shadows the theme's for *every*
        // state, so pressing did not darken the button and disabling it left a
        // fully red fill under a 38% label — a control that looks armed and is
        // inert.
        await tester.pumpWidget(
          host(
            Scaffold(
              body: MxActionButton(
                label: 'Delete deck',
                variant: MxActionButtonVariant.destructive,
                onPressed: () {},
              ),
            ),
            isDark: mode.$2,
          ),
        );

        final theme = mode.$2 ? buildDarkTheme() : buildLightTheme();
        final semantic = theme.extension<AppSemanticColors>()!;
        final fill = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!
            .backgroundColor!;

        expect(fill.resolve(const <WidgetState>{}), theme.colorScheme.error);
        expect(
          fill.resolve(const <WidgetState>{WidgetState.pressed}),
          isNot(theme.colorScheme.error),
          reason: '${mode.$1}: a destructive press does not darken',
        );
        expect(
          fill.resolve(const <WidgetState>{WidgetState.disabled}),
          semantic.disabledSurface,
          reason: '${mode.$1}: a disabled destructive button is still red',
        );
      });

      testWidgets('${mode.$1} · a busy destructive keeps its colours, not the '
          'disabled grey', (tester) async {
        // **The merge order is the whole test.** A loading button is disabled —
        // `isLoading` nulls `onPressed` — so the base style's disabled-first
        // resolvers would paint `disabledSurface` under `onDisabled`, which is
        // the grey `_busyStyle` exists to override once the label is painted.
        // `ButtonStyle.merge` keeps the **receiver's** non-null fields
        // (`backgroundColor ?? style.backgroundColor`), so `busy.merge(base)`
        // is the direction that lets busy win and base answer for everything
        // busy has no opinion on. Reversing it silently restores the grey, and
        // nothing else in the suite would notice.
        await tester.pumpWidget(
          host(
            Scaffold(
              body: MxActionButton(
                label: 'Deleting…',
                variant: MxActionButtonVariant.destructive,
                onPressed: () {},
                isLoading: true,
                shouldKeepLabelWhileLoading: true,
              ),
            ),
            isDark: mode.$2,
          ),
        );

        final theme = mode.$2 ? buildDarkTheme() : buildLightTheme();
        final style = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style!;

        // Disabled is the state this button is actually in while busy.
        const busyStates = <WidgetState>{WidgetState.disabled};
        expect(
          style.backgroundColor!.resolve(busyStates),
          theme.colorScheme.error,
          reason: '${mode.$1}: a busy destructive still reads as destructive',
        );
        expect(
          style.foregroundColor!.resolve(busyStates),
          theme.colorScheme.onError,
          reason: '${mode.$1}: its label is legible on that fill',
        );
        // Geometry still comes from the base style, which is what merging
        // rather than replacing buys.
        expect(style.shape, isNotNull);
        expect(style.minimumSize, isNotNull);
      });

      testWidgets('${mode.$1} · a busy destructiveOutlined keeps its edge', (
        tester,
      ) async {
        // The outlined variant carries its meaning on the border, so the same
        // merge has to reach `side` — the base's disabled resolver would
        // otherwise swap the red edge for `disabledSurface`.
        await tester.pumpWidget(
          host(
            Scaffold(
              body: MxActionButton(
                label: 'Deleting…',
                variant: MxActionButtonVariant.destructiveOutlined,
                onPressed: () {},
                isLoading: true,
                shouldKeepLabelWhileLoading: true,
              ),
            ),
            isDark: mode.$2,
          ),
        );

        final theme = mode.$2 ? buildDarkTheme() : buildLightTheme();
        final style = tester
            .widget<OutlinedButton>(find.byType(OutlinedButton))
            .style!;
        const busyStates = <WidgetState>{WidgetState.disabled};

        expect(
          style.foregroundColor!.resolve(busyStates),
          theme.colorScheme.error,
        );
        expect(
          style.side!.resolve(busyStates)!.color,
          theme.colorScheme.error,
          reason: '${mode.$1}: the edge is what carries the meaning here',
        );
        // No fill was invented for a variant that has none.
        expect(style.backgroundColor?.resolve(busyStates), isNull);
      });

      testWidgets(
        '${mode.$1} · destructiveOutlined is an outline, not a fill',
        (tester) async {
          await tester.pumpWidget(
            host(
              Scaffold(
                body: MxActionButton(
                  label: 'Delete card',
                  variant: MxActionButtonVariant.destructiveOutlined,
                  onPressed: () {},
                ),
              ),
              isDark: mode.$2,
            ),
          );

          final theme = mode.$2 ? buildDarkTheme() : buildLightTheme();
          final semantic = theme.extension<AppSemanticColors>()!;
          final style = tester
              .widget<OutlinedButton>(find.byType(OutlinedButton))
              .style!;

          expect(
            style.foregroundColor!.resolve(const <WidgetState>{}),
            theme.colorScheme.error,
          );
          expect(
            style.side!.resolve(const <WidgetState>{})!.color,
            theme.colorScheme.error,
          );
          // Every state resolves, exactly as the filled variant's test demands:
          // a disabled delete must not stay red.
          expect(
            style.foregroundColor!.resolve(const <WidgetState>{
              WidgetState.disabled,
            }),
            semantic.onDisabled,
            reason: '${mode.$1}: a disabled outline is not still red',
          );
          expect(
            style.side!.resolve(const <WidgetState>{
              WidgetState.disabled,
            })!.color,
            semantic.disabledSurface,
          );
        },
      );
    }
  });

  group('MxLoadingState', () {
    testWidgets('announces itself to a screen reader', (tester) async {
      await tester.pumpWidget(
        host(
          const Scaffold(body: MxLoadingState(semanticsLabel: 'Loading cards')),
        ),
      );

      // A bare spinner announces nothing at all: the user is told neither that
      // something is happening nor when it stops.
      expect(find.bySemanticsLabel('Loading cards'), findsOneWidget);
    });
  });

  group('MxErrorState', () {
    testWidgets('takes a String, and renders retry only when wired', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: MxErrorState(
              title: 'Something went wrong',
              message: 'This part could not be displayed.',
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(MxActionButton), findsNothing);

      var retried = 0;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: MxErrorState(
              title: 'Something went wrong',
              message: 'This part could not be displayed.',
              retryLabel: 'Try again',
              onRetry: () => retried++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MxActionButton));

      expect(retried, 1);
    });

    test('half a retry is refused at construction', () {
      // Both halves or neither. The build drops an unpaired one silently, which
      // leaves an error the user can read and cannot act on — and no test
      // anywhere fails, because the widget renders a complete-looking frame.
      expect(
        () => MxErrorState(
          title: 'Something went wrong',
          message: 'This part could not be displayed.',
          retryLabel: 'Try again',
        ),
        throwsAssertionError,
      );
      expect(
        () => MxErrorState(
          title: 'Something went wrong',
          message: 'This part could not be displayed.',
          onRetry: () {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('MxEmptyState', () {
    test('half an action is refused at construction', () {
      // Same trap, and the more likely of the two to be written: an empty state
      // whose whole purpose is the call to action, shipped with the label wired
      // and the callback forgotten.
      //
      // Non-`const` on purpose, and the reason is the better half of the news:
      // the constructor is `const`, so a `const` call site with only a label does
      // not reach a runtime assert at all — the analyzer refuses to compile it
      // (`const_eval_throws_exception`). Writing this case as a `const` made
      // `flutter analyze` fail rather than the test pass. Real screens build
      // these as `const`, so most violations are caught before the app is run.
      // This test covers the runtime path that a non-`const` call site takes.
      expect(
        () => MxEmptyState(
          title: 'No decks yet',
          actionLabel: 'Create your first deck',
        ),
        throwsAssertionError,
      );
      expect(
        () => MxEmptyState(title: 'No decks yet', onAction: () {}),
        throwsAssertionError,
      );
    });

    test('neither half is the valid empty case', () {
      // Nothing-due is a normal state, not a failure (BR-29), so an empty state
      // with no action must stay constructible.
      expect(const MxEmptyState(title: 'Nothing due today'), isNotNull);
    });
  });

  group('small screen and large text', () {
    /// Every component, in the two conditions that actually break layouts.
    final cases = <String, Widget>{
      'MxCard': const MxCard(
        child: Text('A prompt long enough to wrap on a narrow phone screen'),
      ),
      'MxContentShell': const MxContentShell(
        title: 'MemoX',
        body: Text('Body'),
      ),
      'MxActionButton': const MxActionButton(
        label: 'Remembered',
        onPressed: null,
      ),
      'MxLoadingState': const MxLoadingState(semanticsLabel: 'Loading'),
      'MxEmptyState': const MxEmptyState(
        title: 'Nothing due today',
        message: 'You have finished every card scheduled for now.',
      ),
      'MxErrorState': const MxErrorState(
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
            Builder(
              // `copyWith`, never a fresh `MediaQueryData`: constructing one
              // zeroes `size`, so this test would set a 320-wide view and then
              // tell the widget the screen is 0 wide.
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                // Scaffold-less components need a Material ancestor for text.
                child: entry.value is MxContentShell
                    ? entry.value
                    : Scaffold(body: entry.value),
              ),
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
