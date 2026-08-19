import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_async_view.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

/// `MxAsyncView`, which exists to make one policy explicit rather than to save
/// four lines of `switch`.
///
/// The two assertions that matter are the ones nobody writes by hand: that a
/// *refresh* keeps the previous value on screen instead of flashing a spinner
/// over good data, and that a screen which cannot put a shell around all three
/// branches still gets one around its loading state.
void main() {
  const loadingLabel = 'Loading things';

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  Widget viewOf(
    AsyncValue<String> value, {
    Widget Function(Widget)? loadingFrame,
  }) => MxAsyncView<String>(
    value: value,
    loadingLabel: loadingLabel,
    loadingFrame: loadingFrame,
    data: (data) => Text(data),
    error: (error, stackTrace) => Text('failed: $error'),
  );

  group('the three cases', () {
    testWidgets('loading renders the shared spinner with its label', (
      tester,
    ) async {
      await pump(tester, viewOf(const AsyncLoading<String>()));

      expect(
        tester
            .widget<MxLoadingState>(find.byType(MxLoadingState))
            .semanticsLabel,
        loadingLabel,
      );
    });

    testWidgets('data renders the builder', (tester) async {
      await pump(tester, viewOf(const AsyncData<String>('hello')));

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(MxLoadingState), findsNothing);
    });

    testWidgets('error renders the caller’s builder, not a default', (
      tester,
    ) async {
      // No default error UI on purpose: a generic "something went wrong" is how
      // every screen ends up with the same unhelpful sentence.
      await pump(
        tester,
        viewOf(const AsyncError<String>('boom', StackTrace.empty)),
      );

      expect(find.text('failed: boom'), findsOneWidget);
    });
  });

  group('the loading policy', () {
    testWidgets('a refresh keeps the previous value on screen', (tester) async {
      // Driven through a real provider rather than by hand-building the state:
      // `AsyncValue.copyWithPrevious` is `@internal`, and reaching for it would
      // also test my idea of what a refresh looks like instead of what Riverpod
      // actually produces.
      var answer = 'first';
      final provider = FutureProvider<String>((ref) async => answer);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildLightTheme(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) => Column(
                  children: <Widget>[
                    Expanded(
                      child: MxAsyncView<String>(
                        value: ref.watch(provider),
                        loadingLabel: loadingLabel,
                        data: (data) => Text(data),
                        error: (error, stackTrace) => Text('failed: $error'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('first'), findsOneWidget);

      answer = 'second';
      await tester.tap(find.text('again'));
      // One frame only: the re-read has not completed, so this is the moment a
      // spinner would appear if the flag were wrong.
      await tester.pump();

      expect(find.text('first'), findsOneWidget);
      expect(find.byType(MxLoadingState), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('the first read always shows loading, never stale data', (
      tester,
    ) async {
      // With no previous value there is nothing to keep showing, so the flag
      // above cannot cause a screen to present stale data as fresh.
      await pump(tester, viewOf(const AsyncLoading<String>()));

      expect(find.byType(MxLoadingState), findsOneWidget);
    });

    /// A **reload** — a dependency changed — is the other half of the policy,
    /// and until now nothing in the repository built one.
    ///
    /// Both directions are asserted, and the `false` case reaches the default
    /// by **omitting the argument**. That distinction is the finding: a version
    /// of this loop that passed `false` explicitly still left the constructor
    /// default measured by nothing, so flipping it to `true` — which this
    /// widget's own doc calls the thing that would let stale values sit on
    /// screen everywhere — made no test in the repository fail.
    for (final ({String name, bool? shouldSkip, bool expectSpinner}) mode
        in const <({String name, bool? shouldSkip, bool expectSpinner})>[
          // `null` means **do not pass the argument**, which is the whole point
          // of this case: passing `false` explicitly would test the parameter
          // and leave the constructor default — the thing that decides every
          // other screen's behaviour — measured by nothing. Flipping the
          // default then makes this case, and only this case, fail.
          (
            name: 'by default drops to the spinner',
            shouldSkip: null,
            expectSpinner: true,
          ),
          (
            name: 'keeps the previous value when opted in',
            shouldSkip: true,
            expectSpinner: false,
          ),
        ]) {
      testWidgets('a reload ${mode.name}', (tester) async {
        // Driven through two real providers so the state is the one Riverpod
        // builds for a dependency change, not one hand-assembled here.
        // `Provider` + `invalidate` rather than a state notifier: Riverpod 3
        // dropped `StateProvider`, and what this needs is only that the value
        // `provider` watches comes back different.
        var seed = 1;
        final dependency = Provider<int>((ref) => seed);
        final provider = FutureProvider<String>(
          (ref) async => 'value ${ref.watch(dependency)}',
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: buildLightTheme(),
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, child) => Column(
                    children: <Widget>[
                      Expanded(
                        child: mode.shouldSkip == null
                            ? MxAsyncView<String>(
                                value: ref.watch(provider),
                                loadingLabel: loadingLabel,
                                data: (data) => Text(data),
                                error: (error, stackTrace) =>
                                    Text('failed: $error'),
                              )
                            : MxAsyncView<String>(
                                value: ref.watch(provider),
                                loadingLabel: loadingLabel,
                                shouldSkipLoadingOnReload: mode.shouldSkip!,
                                data: (data) => Text(data),
                                error: (error, stackTrace) =>
                                    Text('failed: $error'),
                              ),
                      ),
                      TextButton(
                        onPressed: () {
                          seed += 1;
                          ref.invalidate(dependency);
                        },
                        child: const Text('change'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('value 1'), findsOneWidget);

        await tester.tap(find.text('change'));
        // One frame: the re-read has not completed, which is the only moment
        // the two policies look different.
        await tester.pump();

        expect(
          find.byType(MxLoadingState),
          mode.expectSpinner ? findsOneWidget : findsNothing,
        );

        await tester.pumpAndSettle();
        expect(find.text('value 2'), findsOneWidget);
      });
    }
  });

  group('loadingFrame', () {
    testWidgets('is absent by default, so the spinner is used as-is', (
      tester,
    ) async {
      await pump(tester, viewOf(const AsyncLoading<String>()));

      expect(find.byType(MxContentShell), findsNothing);
    });

    testWidgets('wraps the spinner when a screen needs chrome', (tester) async {
      // The regression this parameter exists for: a screen whose app-bar title
      // comes from the loaded data cannot wrap all three branches in one shell,
      // and without a shell the spinner has no Scaffold — on a pushed route the
      // page below shows through, because the transition backdrop is transparent
      // at rest.
      await pump(
        tester,
        viewOf(
          const AsyncLoading<String>(),
          loadingFrame: (loading) => MxContentShell(body: loading),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MxContentShell),
          matching: find.byType(MxLoadingState),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not wrap the data or error branches', (tester) async {
      // It frames the loading state only. Wrapping data too would give a screen
      // two shells the moment it built its own.
      await pump(
        tester,
        viewOf(
          const AsyncData<String>('hello'),
          loadingFrame: (loading) => MxContentShell(body: loading),
        ),
      );

      expect(find.byType(MxContentShell), findsNothing);
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
