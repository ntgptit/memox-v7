import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/features/study/domain/models/new_card_order_model.dart';
import 'package:memox/features/study/presentation/screens/study_options_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

import '../domain/support/fake_study_repository.dart';
import 'support/study_widget_harness.dart';

/// The new-card-order pills on Study Options, pinned where they are built.
///
/// M100.92 moved the chip's resting fill, and this screen's goldens moved with
/// it, but the order picker had only the picture: no test found its pills, read
/// their selection or tapped one. At a phone and at 320dp × 2.0, in English
/// and Vietnamese: each pill keeps the 48 target, the choice in force is the
/// selected one on screen and in semantics, and a tap moves the selection,
/// arms Save, and reaches the repository.
void main() {
  Future<FakeStudyRepository> pumpOptions(
    WidgetTester tester, {
    required Size surface,
    required double scale,
    required Locale locale,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeStudyRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [studyRepositoryProvider.overrideWithValue(repository)],
        child: wrapForTest(
          const StudyOptionsScreen(deckId: 'd1'),
          isScrollable: false,
          locale: locale,
          textScaler: TextScaler.linear(scale),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Finder pill(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(MxPillButton));

  void expectSelected(WidgetTester tester, String label, {required bool is_}) {
    expect(tester.widget<MxPillButton>(pill(label)).isSelected, is_);
    // The merged node a reader focuses: a node's own flags leave out what its
    // merged children contribute.
    expect(
      tester
          .getSemantics(find.text(label))
          .getSemanticsData()
          .flagsCollection
          .isSelected,
      is_ ? Tristate.isTrue : Tristate.isFalse,
      reason: '"$label": semantics disagree with the pill on screen',
    );
  }

  for (final (String name, Locale locale, AppLocalizations l10n)
      in <(String, Locale, AppLocalizations)>[
        ('en', const Locale('en'), AppLocalizationsEn()),
        ('vi', const Locale('vi'), AppLocalizationsVi()),
      ]) {
    for (final (Size surface, double scale) in const <(Size, double)>[
      (Size(393, 852), 1),
      (Size(320, 852), 2),
    ]) {
      testWidgets(
        '$name · ${surface.width.toInt()}dp × $scale: the order pills keep '
        'their target, show the choice in force and save a new one',
        (tester) async {
          final handle = tester.ensureSemantics();
          final repository = await pumpOptions(
            tester,
            surface: surface,
            scale: scale,
            locale: locale,
          );
          final created = l10n.studyOptionsOrderCreated;
          final random = l10n.studyOptionsOrderRandom;
          expect(tester.takeException(), isNull);

          for (final label in <String>[created, random]) {
            expect(pill(label), findsOneWidget);
            expect(
              tester.getSize(pill(label)).height,
              greaterThanOrEqualTo(AppSizing.touchTarget),
              reason: '"$label": the pill is the target',
            );
          }
          // The fake opens on `NewCardOrder.created`, the choice in force.
          expect(repository.newCardOrder, NewCardOrder.created);
          expectSelected(tester, created, is_: true);
          expectSelected(tester, random, is_: false);

          final save = find.widgetWithText(
            MxActionButton,
            l10n.studyOptionsSave,
          );
          expect(
            tester.widget<MxActionButton>(save).onPressed,
            isNull,
            reason: 'a pristine draft offers nothing to save',
          );

          await tester.ensureVisible(pill(random));
          await tester.pumpAndSettle();
          await tester.tap(pill(random));
          await tester.pumpAndSettle();
          expectSelected(tester, created, is_: false);
          expectSelected(tester, random, is_: true);
          expect(tester.widget<MxActionButton>(save).onPressed, isNotNull);

          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(repository.savedOptions.last.order, NewCardOrder.random);
          expect(tester.takeException(), isNull);
          handle.dispose();
        },
      );
    }
  }
}
