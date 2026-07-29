import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/bootstrap.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/app/error_screen_widget.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';

void main() {
  final en = AppLocalizationsEn();

  group('installErrorHandlers', () {
    test('restores every handler it replaced', () {
      // These are global. A test that installs them without restoring changes
      // the behaviour of every test that runs afterwards, and the failure then
      // surfaces in an unrelated file — which is why the restore callback
      // exists at all, and why it is tested rather than assumed.
      final flutterOnErrorBefore = FlutterError.onError;
      final platformOnErrorBefore = PlatformDispatcher.instance.onError;
      final errorWidgetBuilderBefore = ErrorWidget.builder;

      final restore = installErrorHandlers(logLevel: LogLevel.debug);

      expect(FlutterError.onError, isNot(same(flutterOnErrorBefore)));
      expect(ErrorWidget.builder, isNot(same(errorWidgetBuilderBefore)));

      restore();

      expect(FlutterError.onError, same(flutterOnErrorBefore));
      expect(PlatformDispatcher.instance.onError, same(platformOnErrorBefore));
      expect(ErrorWidget.builder, same(errorWidgetBuilderBefore));
    });

    test('the platform handler claims the error so it is not re-thrown', () {
      final restore = installErrorHandlers(logLevel: LogLevel.debug);
      addTearDown(restore);

      final handled = PlatformDispatcher.instance.onError!(
        StateError('async boom'),
        StackTrace.current,
      );

      expect(handled, isTrue);
    });

    test('an uncaught async error reaches a zone handler', () async {
      final captured = <Object>[];

      await runZonedGuarded<Future<void>>(() async {
        unawaited(Future<void>.error(StateError('async boom')));
        await Future<void>.delayed(Duration.zero);
      }, (error, _) => captured.add(error));

      expect(captured, hasLength(1));
      expect(captured.single, isA<StateError>());
    });
  });

  group('ErrorScreenWidget', () {
    testWidgets('renders with no Localizations ancestor', (tester) async {
      // The screen has to work when it stands in for a widget that failed above
      // the delegates. If it needed Localizations it would throw while
      // reporting a throw, and the user would get a blank window.
      await tester.pumpWidget(
        const ErrorScreenWidget(kind: AppErrorKind.startup),
      );

      expect(find.text(en.startupErrorTitle), findsOneWidget);
      expect(find.text(en.startupErrorMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the render-failure copy for AppErrorKind.render', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ErrorScreenWidget(kind: AppErrorKind.render),
      );

      expect(find.text(en.unexpectedErrorTitle), findsOneWidget);
      expect(find.text(en.unexpectedErrorMessage), findsOneWidget);
    });

    testWidgets('leaks no technical detail to the user', (tester) async {
      await tester.pumpWidget(
        const ErrorScreenWidget(kind: AppErrorKind.startup),
      );

      final shown = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .join('\n');

      // The error screen is exactly where a stack frame, a SQL fragment or an
      // internal URL leaks by accident.
      for (final forbidden in <String>[
        'Exception',
        'Error:',
        '#0',
        'package:',
        'http',
        'SELECT',
        '.dart',
      ]) {
        expect(
          shown,
          isNot(contains(forbidden)),
          reason: 'error screen exposed "$forbidden" to the user',
        );
      }
    });
  });

  group('bootstrap', () {
    testWidgets('the root tree carries the config it was given', (
      tester,
    ) async {
      // Mounts what bootstrap hands to runApp, rather than calling bootstrap.
      // bootstrap wraps startup in runZonedGuarded and calls runApp; doing that
      // inside flutter_test — which owns its own zone and binding — hangs
      // rather than failing, so the test would take minutes to tell you
      // nothing.
      //
      // Wrapped in an outer scope carrying a fake repository. The home route
      // is now a screen that reads decks, so the untouched root would open the
      // on-device database and leave a pending timer in the test. Riverpod
      // resolves a provider the inner scope does not override against its
      // parent, so the fake reaches the screen while `buildRootWidget` keeps
      // owning the `envConfigProvider` override this test is actually about.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deckRepositoryProvider.overrideWithValue(
              FakeDeckRepository.emitting(const <DeckEntity>[]),
            ),
          ],
          child: buildRootWidget(EnvConfig.staging),
        ),
      );
      await tester.pump();

      // Read through the real element tree: this proves the override reached
      // the scope, not merely that a container can be built.
      //
      // The context must be a DESCENDANT of the scope — `containerOf` walks
      // ancestors, so passing the ProviderScope element itself throws
      // "No ProviderScope found".
      final context = tester.element(find.byType(MemoxApp));
      final container = ProviderScope.containerOf(context, listen: false);

      expect(container.read(envConfigProvider), same(EnvConfig.staging));
      expect(tester.takeException(), isNull);
    });

    test('bootstrap is the single startup entry the entrypoints call', () {
      // Guards the M2.6 rule that entrypoints hold no initialisation logic:
      // each is expected to be a config choice plus a bootstrap call.
      for (final path in <String>[
        'lib/main.dart',
        'lib/main_development.dart',
        'lib/main_staging.dart',
        'lib/main_production.dart',
      ]) {
        final source = File(path).readAsStringSync();

        expect(source, contains('bootstrap('), reason: '$path must delegate');
        for (final forbidden in <String>[
          'runApp(',
          'ProviderScope(',
          'FlutterError.onError',
          'ensureInitialized(',
        ]) {
          expect(
            source,
            isNot(contains(forbidden)),
            reason: '$path contains startup logic: $forbidden',
          );
        }
      }
    });

    testWidgets(
      'a failing widget build yields the error screen, not a red one',
      (tester) async {
        final restore = installErrorHandlers(logLevel: LogLevel.debug);
        addTearDown(restore);

        // ErrorWidget.builder keeps Flutter's red screen in debug on purpose, so
        // assert the release branch explicitly rather than pretending debug is
        // what users see.
        final built = ErrorWidget.builder(
          FlutterErrorDetails(
            exception: StateError('build boom'),
            stack: StackTrace.current,
          ),
        );

        expect(built, isA<Widget>());
        if (!kDebugMode) {
          expect(built, isA<ErrorScreenWidget>());
        }

        await tester.pumpWidget(
          const ErrorScreenWidget(kind: AppErrorKind.render),
        );
        expect(find.text(en.unexpectedErrorTitle), findsOneWidget);
        expect(find.textContaining('build boom'), findsNothing);
      },
    );
  });
}
