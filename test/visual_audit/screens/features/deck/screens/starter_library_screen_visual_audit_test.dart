@Tags(<String>['golden', 'screen-audit'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/di/deck_template_provider.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_template_repository.dart';
import 'package:memox/features/deck/presentation/screens/starter_library_screen.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:flutter/widgets.dart';

import '../../../../audit_allowance.dart';
import '../../../../audit_model.dart';
import '../../../../audit_rules.dart';
import '../../../../memox_audit.dart';
import '../../../../screen_auditor.dart';
import '../../../../../features/deck/presentation/support/fake_deck_repository.dart';

/// Strict visual audit for `StarterLibraryScreen` (UC-01).
///
/// Companion of the screen at the mirrored path; MX-VIS-001 checks this file
/// exists, imports the screen, and calls the strict helper.
///
/// **The loaded catalog is the state audited.** It is the one with everything
/// on it: the BR-87 fixture notice, a template row with its three metadata
/// lines and its trailing action word. The empty and error states are the
/// shared `MxEmptyState`/`MxErrorState`, audited on the deck list.
void main() {
  memoxProductionScreenAuditTest(
    'starter_library_screen',
    () {
      final router = createAppRouter(initialLocation: '/starter');
      addTearDown(router.dispose);

      return ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          deckTemplateCatalogProvider.overrideWith(
            (ref) async => <DeckTemplate>[
              DeckTemplate(
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
                        front: CardText.parse(
                          'hello',
                          side: CardSide.front,
                        ).text!,
                        back: CardText.parse(
                          'xin chào',
                          side: CardSide.back,
                        ).text!,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          deckTemplateRepositoryProvider.overrideWithValue(
            _NothingInstalledTemplateRepository(),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
        ],
        child: Router.withConfig(config: router),
      );
    },
    // This screen declares one surface column (M99.19a): every row of
    // cards spans it, or stacks. Opted in explicitly, because a layout
    // rule is a screen's own declaration — not something the harness
    // infers from seeing `MxCard`.
    surfaceFinder: find.byType(MxCard),
    additionalRules: const <AuditRule>[SurfaceColumnRule()],
    anchors: <AuditAnchor>[
      AuditAnchor.type('starter_screen', StarterLibraryScreen),
      AuditAnchor.type('navigation_bar', MxNavigationBar),
    ],
    drive: (tester) => tester.pumpAndSettle(),
    allowances: <AuditSkipAllowance>[
      const AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderColoredBox',
        expectedMatches: 3,
        rationale:
            'Page-transition backdrops from _FadeForwardsPageTransition, one '
            'per Navigator (harness MaterialApp, GoRouter root, branch). At '
            'rest each paints Colors.transparent; mid-transition it paints '
            'ColorScheme.surface, which is a palette token. Verified against '
            'page_transitions_theme.dart in the pinned SDK.',
      ),
      const AuditSkipAllowance(
        itemId: 'screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        rationale:
            "The navigation shell Scaffold's Material layer. A Material paints "
            'its own background, splash and highlight into this layer, so none '
            'of the three is readable from a render object; the colours are '
            'asserted in app_theme_test.dart.',
      ),
      const AuditSkipAllowance(
        itemId: 'navigation_bar',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        rationale:
            'NavigationBar paints its selection indicator into a Material ink '
            'layer, so the pill has no render object of its own. Its colour is '
            'secondaryContainer, set in navigationBarTheme, and the states are '
            'pinned by the mx_navigation_bar_* goldens.',
      ),
      // The starter screen's own Material layers: its Scaffold, its AppBar
      // (title + automatic back), and the one tappable template card.
      const AuditSkipAllowance(
        itemId: 'starter_screen',
        reason: SkipReason.rasterOnly,
        detailContains: '_RenderInkFeatures',
        // Scaffold, AppBar, the back IconButton's host, and the card.
        expectedMatches: 4,
        rationale:
            'The screen Material layers: its Scaffold and its AppBar from '
            'MxContentShell, plus the back button and the tappable template '
            'MxCard. A Material '
            'paints background, splash and highlight into a layer no render '
            'object reports; the card surface is asserted in '
            'app_theme_test.dart.',
      ),
      const AuditSkipAllowance(
        itemId: 'starter_screen',
        reason: SkipReason.customPainter,
        detailContains: 'CustomPaint (no painter)',
        rationale:
            "The rounded clip the template card's InkWell paints for its "
            'ripple. It has no painter to interrogate because the shape is the '
            'ripple boundary rather than a drawn stroke — the visible border '
            'is the DecoratedBox behind it, which the audit does read.',
      ),
      const AuditSkipAllowance(
        itemId: 'starter_screen',
        reason: SkipReason.customPainter,
        detailContains: '_ShapeBorderPainter',
        rationale:
            'The AppBar back button is an IconButton, which draws its shape '
            'with a CustomPainter, so the outline exists in no render object. '
            'The button states are pinned by the mx_icon_button_* goldens.',
      ),
    ],
  );
}

/// A catalog with nothing installed, so the row shows the add path.
final class _NothingInstalledTemplateRepository
    implements DeckTemplateRepository {
  @override
  Future<DeckTemplateInstallOutcome> installTemplate(
    DeckTemplate template, {
    SchedulerType? schedulerType,
    bool allowDuplicate = false,
  }) async => DeckTemplateInstallOutcome.installed;

  @override
  Future<Set<({String templateId, int version})>> installedTemplateKeys() =>
      Future<Set<({String templateId, int version})>>.value(
        <({String templateId, int version})>{},
      );
}
