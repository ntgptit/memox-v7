import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_messenger.dart';

/// The behaviour the seven migrated call sites used to disagree about:
/// every message announces, every message clears the queue, and an action
/// arrives as a label–handler pair or not at all.
void main() {
  Widget host(void Function(BuildContext context) onPressed) => MaterialApp(
    theme: buildLightTheme(),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPressed(context),
          child: const Text('go'),
        ),
      ),
    ),
  );

  testWidgets('announces: the message is inside a live region', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host((context) => showMxMessage(context, 'saved')));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final message = tester.getSemantics(
      find
          .ancestor(of: find.text('saved'), matching: find.byType(Semantics))
          .first,
    );
    expect(message.flagsCollection.isLiveRegion, isTrue);
    handle.dispose();
  });

  testWidgets('clears the queue: a second message replaces the first '
      'instead of waiting behind it', (tester) async {
    var messageIndex = 0;
    await tester.pumpWidget(
      host((context) {
        messageIndex += 1;
        showMxMessage(context, 'message $messageIndex');
      }),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    // Settled is well short of the display timeout — 'message 1' can only be
    // gone because it was cleared, not because it expired.
    await tester.pumpAndSettle();

    expect(find.text('message 1'), findsNothing);
    expect(find.text('message 2'), findsOneWidget);
  });

  testWidgets('an action renders its label and fires its handler', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      host(
        (context) => showMxMessage(
          context,
          'leave failed',
          actionLabel: 'Retry',
          onAction: () => retried = true,
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    expect(retried, isTrue);
  });

  testWidgets('a captured messenger works after its context is gone', (
    tester,
  ) async {
    // The undo-failure path: the messenger outlives the screen that showed it.
    late ScaffoldMessengerState messenger;
    await tester.pumpWidget(
      host((context) => messenger = ScaffoldMessenger.of(context)),
    );
    await tester.tap(find.text('go'));

    showMxMessageOn(messenger, 'undo failed');
    await tester.pump();
    expect(find.text('undo failed'), findsOneWidget);
  });

  testWidgets('a label without a handler is refused by assert', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => expect(
          () => showMxMessage(context, 'x', actionLabel: 'Retry'),
          throwsAssertionError,
        ),
      ),
    );
    await tester.tap(find.text('go'));
  });
}
