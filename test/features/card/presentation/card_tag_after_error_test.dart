import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'support/fake_card_repository.dart';

/// The boundary IT-ORG-009 stopped at: after a refused blank tag, can the very
/// next valid submission still go through?
///
/// On the device the field kept the blank's length counter and the error text
/// after `enterText('tag1')` — this pins whether that is the widget refusing
/// input after an error (a product bug) or the driver failing to reach the
/// field (an automation bug).
void main() {
  testWidgets('a valid tag submits right after a refused blank one', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CardTagSectionWidget(cardId: 'card-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final field = find.byType(TextField);

    // A blank is refused with the inline error.
    await tester.enterText(field, '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.textContaining("Tag can't be empty"), findsOneWidget);

    // The very next valid name must still submit.
    await tester.enterText(field, 'tag1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      repository.tagAdds.map((t) => t.name),
      contains('tag1'),
      reason: 'the refused blank left the field unable to submit',
    );
    expect(find.textContaining("Tag can't be empty"), findsNothing);
  });
}
