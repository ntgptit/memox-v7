import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/app/mobile_frame_widget.dart';

import 'features/deck/presentation/support/fake_deck_repository.dart';

void main() {
  testWidgets('app builds and exposes its root widget', (tester) async {
    // The root now renders a screen that reads from the deck repository, so the
    // scope is real and the contract behind it is faked. Without the override
    // this would open the on-device database from a widget test.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
        ],
        child: const MemoxApp(),
      ),
    );

    expect(find.byType(MemoxApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('MobileFrameWidget', () {
    // kIsWeb is false under flutter test, so isEnabled is driven explicitly.
    Widget wrap({required bool isEnabled}) => MaterialApp(
      home: MobileFrameWidget(
        isEnabled: isEnabled,
        child: Builder(
          builder: (context) => Text('${MediaQuery.sizeOf(context)}'),
        ),
      ),
    );

    testWidgets('passes the child through untouched when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(isEnabled: false));

      expect(find.byType(ClipRect), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports phone size to the child when the window is larger', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(isEnabled: true));

      // The MediaQuery override is the point of the widget: the child must see
      // phone dimensions, not the 1600x1200 window it is actually painted in.
      expect(find.text('$kMobileFrameSize'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'does not frame — or overflow — when the window is already small',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(isEnabled: true));

        expect(find.text('${const Size(360, 640)}'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
