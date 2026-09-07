import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_scheduler_picker_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/deck_reset_progress_widget.dart';
import 'package:memox/features/deck/presentation/widgets/overlays/starter_install_widget.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_section_label.dart';
import 'package:memox/shared/widgets/mx_sheet_insets.dart';

import '../../settings/domain/support/fake_app_settings_repository.dart';
import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// **One semantic element, one grammar** (SC-C5-04).
///
/// The heading over the scheduler radio group used to be drawn three ways
/// inside one unit — `labelLarge` in the picker, `labelLarge` hand-rolled again
/// in the reset sheet, `labelMedium` quiet in the starter install — with three
/// different gaps under it and no `header` role anywhere, while the sibling
/// export sheet's choice group had all three right. The group under all three
/// headings is byte-identical, because they share `DeckSchedulerPickerWidget`;
/// only the heading differed.
///
/// **Asserted in one file rather than three.** The defect was never visible
/// inside any single sheet — each was internally consistent — so a rule split
/// across the three sheets' own test files is a rule that can drift back apart
/// one file at a time, which is how it got here.
void main() {
  final english = AppLocalizationsEn();

  Finder radioRowOf(Finder scope) => find.descendant(
    of: scope,
    matching: find.byType(RadioListTile<SchedulerType>),
  );

  /// The heading, the gap under it, and the role it announces with.
  void expectSchedulerHeading(
    WidgetTester tester, {
    required Finder scope,
    required String label,
  }) {
    final Finder heading = find.descendant(
      of: scope,
      matching: find.byType(MxSectionLabel),
    );
    expect(heading, findsOneWidget);

    // Painted in caps, so the written sentence must be gone from the tree.
    expect(find.text(label.toUpperCase()), findsOneWidget);
    expect(find.text(label), findsNothing);

    // `sm` between the label and the choices it names — the step
    // `card_export_sheet_widget` already takes over its format group.
    final Rect labelRect = tester.getRect(heading);
    final Rect firstRow = tester.getRect(radioRowOf(scope).first);
    expect(firstRow.top - labelRect.bottom, AppSpacing.sm);

    // The uppercase is paint; the accessible name is the sentence the ARB
    // wrote, and the node is a header so a reader can jump to it.
    final SemanticsNode node = tester.getSemantics(heading);
    expect(node.flagsCollection.isHeader, isTrue);
    expect(node.label, label);
  }

  DeckEntity root() => DeckEntity(
    id: 'root',
    name: 'Korean',
    parentDeckId: null,
    rootDeckId: 'root',
    contentType: DeckContentType.deck,
    schedulerType: SchedulerType.eightBox,
    schedulerGeneration: 1,
    firstAnsweredAt: DateTime.utc(2026),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  Future<void> pumpResetSheet(WidgetTester tester) async {
    await pumpDeckScreen(
      tester,
      repository: FakeDeckRepository(),
      screen: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDeckResetProgressConfirm(
            context,
            deck: root(),
            hasStudyProgress: true,
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The reset sheet at the tightest combination, with the scale reaching
  /// the sheet itself.
  ///
  /// **`builder`, not a `MediaQuery` around `home`** — the trap
  /// `card_export_sheet_harness` already documents, and the one
  /// `pumpDeckScreen` falls into: a sheet is a route pushed onto the
  /// navigator, so a `MediaQuery` inside `home` sits below it and the sheet
  /// renders at 1.0x while the screen behind it scales. Written that way this
  /// test passed against the copy it was supposed to reject.
  Future<void> pumpResetSheetScaled(WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          clockProvider.overrideWithValue(() => deckTestNow),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDeckResetProgressConfirm(
                context,
                deck: root(),
                hasStudyProgress: true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> pumpStarterInstallSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deckTemplateRepositoryProvider.overrideWithValue(
            _StubTemplateRepository(),
          ),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showStarterInstallSheet(context, template: _template()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('the three sheets head the choice the same way', () {
    testWidgets('the create form, through the picker itself', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDeckApp(tester, repository: FakeDeckRepository());

      await tester.tap(find.text(english.deckCreateRootAction));
      await tester.pumpAndSettle();

      // Scoped to the picker: the deck list behind the sheet carries its own
      // `MxSectionLabel` at the `list` rung.
      expectSchedulerHeading(
        tester,
        scope: find.byType(DeckSchedulerPickerWidget),
        label: english.schedulerSectionLabel,
      );
      handle.dispose();
    });

    testWidgets('the reset sheet, which titles the section itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpResetSheet(tester);

      // The heading is a sibling above the picker here, not the picker's own —
      // this sheet used to print both, which is why `sectionLabel` is nullable.
      expectSchedulerHeading(
        tester,
        scope: find.byType(MxSheetInsets),
        label: english.deckResetProgressSchedulerLabel,
      );
      handle.dispose();
    });

    testWidgets('the starter install sheet', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStarterInstallSheet(tester);

      expectSchedulerHeading(
        tester,
        scope: find.byType(MxSheetInsets),
        label: english.starterLibrarySchedulerPrompt,
      );
      handle.dispose();
    });
  });

  testWidgets('the reset heading still fits at 320dp and textScaler 2.0', (
    tester,
  ) async {
    // `MxSectionLabel` is one line with an ellipsis; the wrapping `Text` it
    // replaced was not. That made the longest of the three headings the one
    // that could silently lose its last words, so the copy was shortened
    // against a measurement rather than a preference: at
    // "Study mode after the reset" the run needed 408.8dp of a 288dp line
    // here and `didExceedMaxLines` was true. At "Study mode" it needs 171.4.
    await pumpResetSheetScaled(tester);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(english.deckResetProgressSchedulerLabel.toUpperCase()),
    );

    expect(paragraph.didExceedMaxLines, isFalse);
  });
}

DeckTemplate _template() => DeckTemplate(
  templateId: 'starter-1',
  version: 1,
  locale: 'en',
  title: DeckName.parse('Everyday English').name!,
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

/// Enough of the contract to open the sheet; nothing here installs anything.
final class _StubTemplateRepository implements DeckTemplateRepository {
  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async => DeckTemplateInstallOutcome.installed;

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(
        const <({String templateId, int version})>{},
      );
}
