@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../card_audit_harness.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/card/presentation/support/fake_tag_catalog_repository.dart';

/// Strict visual audit for `TagCatalogScreen` (UC-18, wireframe M4.14 W2).
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this exists,
/// imports the screen and calls the strict helper.
///
/// **The populated state is audited** — it is the one with content to measure:
/// the search field, three rows of name + count, and each row's menu button. The
/// empty and search-empty faces carry no colour the other screens' empty states
/// do not already pin.
///
/// Rendered directly (no router), so the allowances are the app's Material
/// chrome plus the rows' ink, not the navigation shell. Every one names its
/// render type, its item and an exact count, so a control added to a row
/// surfaces as a miscount rather than vanishing into a blanket permission.
void main() {
  // Three rows with different counts, including a tag no card carries: BR-230
  // keeps that row, and it is the one whose subtitle reads as words rather than
  // a number, so the audit measures both label forms.
  FakeTagCatalogRepository loaded() =>
      FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[
        TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12),
        TagCatalogEntry(id: 't2', name: 'food', cardCount: 1),
        TagCatalogEntry(id: 't3', name: 'TOPIK II', cardCount: 0),
      ]);

  memoxProductionScreenAuditTest(
    'tag_catalog_screen',
    () => tagScreenWith(loaded(), const TagCatalogScreen()),
    anchors: <AuditAnchor>[AuditAnchor.type('shell', MxContentShell)],
    allowances: const <AuditSkipAllowance>[
      AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        rationale:
            'The route backdrop MaterialApp paints around an opaque page. It '
            'renders Colors.transparent at rest and ColorScheme.surface only '
            'mid-transition; the surface value is asserted in '
            'app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        expectedMatches: 5,
        rationale:
            'The Material ink layers of the Scaffold, the AppBar and the three '
            'row overflow buttons. Splash and highlight paint into these '
            'layers; the overlay colours are asserted in app_theme_test.dart.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        expectedMatches: 3,
        rationale:
            'The three row overflow IconButtons draw their rounded shapes '
            'through a ShapeBorder painter; the shape comes from the icon '
            'button theme and is pinned by the mx_components goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.customPainter,
        detailContains: 'no painter',
        // One, which is also the default — stated by the rationale rather than
        // by a redundant argument the analyzer flags.
        rationale:
            'A clip with no painter: the search pill clips through a '
            'CustomPaint with no painter of its own. The row overflow buttons '
            'do not — they mount a _ShapeBorderPainter instead, allowed above.',
      ),
      // The search field — the same two allowances the card list's field
      // carries, for the same reasons.
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: 'RenderEditable',
        expectedMatches: 3,
        rationale:
            'A TextField paints its text, its hint and its cursor into a '
            'RenderEditable, which reports no colour. The field takes its '
            'style from the body text theme and its fill from surfaceMuted; '
            'both states are pinned by the mx_search_field_* goldens.',
      ),
      AuditSkipAllowance(
        itemId: 'shell',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderDecoration',
        rationale:
            "InputDecorator's own render object. Every border on this field is "
            'InputBorder.none — the pill around it is the decoration — so '
            'there is nothing here to read a colour from.',
      ),
    ],
  );
}
