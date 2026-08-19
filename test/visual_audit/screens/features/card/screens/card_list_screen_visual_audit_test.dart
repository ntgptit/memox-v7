@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_card_repository.dart';

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

/// Strict visual audit for `CardListScreen` (UC-04 W1).
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this exists,
/// imports the screen, and calls the strict helper. The loaded state is audited
/// because it is the one with content to measure — the list, the count line and
/// two tile faces.
///
/// Rendered directly (no router), so the allowances are the app's Material
/// chrome plus the tiles' ink, not the navigation shell — see
/// `card_audit_harness.dart`. Every one names its render type, its item and an
/// exact count, so a control added to the row surfaces as a miscount rather than
/// vanishing into a blanket permission.
void main() {
  // Two rows in different states, one flagged and tagged, plus a progress
  // distribution — so the audit measures the panel (ring, bar, legend), the
  // state dots and label (D5), the tag chips (BR-93) and the flag (BR-92).
  FakeCardRepository loaded() {
    final repository = FakeCardRepository.loaded(
      <dynamic>[
        FakeCardRepository().listItem(
          'c1',
          // Korean fronts, because that is what the screen carries in use and
          // Hangul is what the audit then measures — full-width syllables set
          // taller than Latin, so the row height and the ascender the label
          // contrast is read against are both the real ones.
          front: '사과',
          back: 'apple / quả táo',
          isFlagged: true,
          tagNames: <String>['noun', 'food'],
        ),
        FakeCardRepository().listItem(
          'c2',
          front: '안녕하세요',
          back: 'hello / xin chào',
          state: CardState.mastered,
          // Scheduled and overdue, so the row draws its due badge and the audit
          // measures that pill's fill and label. A never-scheduled card renders
          // none, and c1 above is exactly that — one row of each.
          dueAt: DateTime.utc(2020),
        ),
      ].cast(),
      total: 214,
    );
    repository.distributionToShow = const CardStateDistributionModel(
      total: 214,
      isNew: 40,
      beginning: 34,
      reviewing: 34,
      mastered: 106,
    );
    // Something due, so the panel's Start-study action renders and its
    // `onPrimary` label is measured on the brand fill — the pairing that failed
    // at 2.33:1 on the deck card before it was stated explicitly.
    repository.filterCounts[CardListFilter.due] = 23;

    return repository;
  }

  memoxProductionScreenAuditTest(
    'card_list_screen',
    () => cardScreenWith(loaded(), const CardListScreen(deckId: 'deck-1')),
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    // The distribution stream lands a frame after the list, so give the panel a
    // second settle before capture — otherwise it is still SizedBox.shrink.
    drive: _settle,
    allowances: const <AuditSkipAllowance>[
      // The MaterialApp's own surfaces, above the screen.
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The route backdrop MaterialApp paints around an opaque page. It '
            'renders Colors.transparent at rest and ColorScheme.surface only '
            'mid-transition; the surface value is asserted in app_theme_test.dart.',
      ),
      // The shell: Scaffold, AppBar, the app-bar add action and the four filter
      // chips.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // 12 since M99.16: the app bar gained the Select action, the visible
        // way into selection mode, and an IconButton is one more ink host.
        // 14 since M99.30: the filter bar gained the Tags pill (BR-231).
        expectedMatches: 14,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar, the app-bar '
            'Select and add IconButtons, the panel Start-study button, the two MxCard card '
            'rows and the five filter chips. Splash and highlight paint into '
            'these layers; the overlay colours are asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        // 4 since M99.16, for the same reason: the Select action is a second
        // app-bar IconButton.
        expectedMatches: 5,
        rationale:
            'The app-bar Select and add IconButtons and the panel Start-study pill draw '
            'their rounded shapes through a ShapeBorder painter; both shapes '
            'come from the component themes and are pinned by the mx_components '
            'goldens.',
      ),
      // The four filter chips (D3). Their fill, border and label come from
      // ChipThemeData and are pinned by the mx_components chip goldens; the
      // _RenderChip render object lays them out and paints no colour of its own.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.unknownRenderType,
        detailContains: '_RenderChip',
        // 5 since M99.30: All, Due, New, Flagged and Tags (BR-231, M4.14 T3).
        expectedMatches: 5,
        rationale:
            'The five filter pills, MxPillButton over ChoiceChip; their '
            'colours come from ChipThemeData, pinned by the mx_components chip '
            'goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterNotFlat,
        detailContains: 'covers only 0%',
        rationale:
            'An unselected chip declares a surface tint that its transparent '
            'rest state does not fill; the chip colours are pinned by the '
            'mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        expectedMatches: 8,
        rationale:
            'A clip with no painter: the five filter chips, the two MxCard card '
            'rows and the search pill each clip through a CustomPaint with no '
            'painter of its own.',
      ),
      // The search field (S1) — the same two allowances the deck list's field
      // carries, for the same reasons; see `deck_audit_allowances.dart`.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: 'RenderEditable',
        expectedMatches: 3,
        rationale:
            'A TextField paints its text, its hint and its cursor into a '
            'RenderEditable, which reports no colour. The field takes its style '
            'from the body text theme and its fill from surfaceMuted; both '
            'states are pinned by the mx_search_field_* goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderDecoration',
        rationale:
            "InputDecorator's own render object. Every border on this field is "
            'InputBorder.none — the pill around it is the decoration — so there '
            'is nothing here to read a colour from.',
      ),
      // The progress ring (D5, BR-88).
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_CircularProgressIndicatorPainter',
        rationale:
            'The mastered ring draws its arc through the CircularProgressIndicator '
            'painter; the arc is semantic.success and the track semantic.'
            'progressTrack, both asserted in app_theme_test.dart.',
      ),
    ],
  );

  // **The export sheet is deliberately not a second state here.** It was tried
  // (M99.21 phase 6) and the harness cannot read it yet, for a reason that is
  // about modal routes rather than about this sheet: the raster cross-check
  // compares each render object's declared colour against the pixels inside its
  // own rect, and a modal barrier paints a scrim over everything behind it. With
  // the sheet open, seventeen elements of the screen underneath report
  // `declaredRasterMismatch` — every one a correct declaration read through a
  // scrim. Allowing them individually would allow away the whole screen's colour
  // coverage; restricting traversal to the topmost route is the real fix, and it
  // is a harness change that moves every existing companion's allowance counts.
  // Recorded as a gap in `docs/wbs.md` under M99.21, with the two findings that
  // argue for doing it. Until then the sheet's geometry is proven in
  // `card_export_alignment_test.dart` and its colour tokens in
  // `card_export_sheet_test.dart`.
}
