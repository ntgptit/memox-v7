import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:widgetbook/widgetbook.dart';

import 'components/control_components.dart';
import 'components/feedback_components.dart';
import 'components/form_components.dart';
import 'components/overlay_components.dart';
import 'screens/card_detail_screen_use_case.dart';
import 'screens/card_editor_screen_use_case.dart';
import 'screens/card_export_sheet_use_case.dart';
import 'screens/card_import_screen_use_case.dart';
import 'screens/deck_list_screen_use_case.dart';
import 'screens/progress_deck_screen_use_case.dart';
import 'screens/progress_screen_use_case.dart';
import 'screens/reminder_screen_use_case.dart';
import 'screens/settings_screen_use_case.dart';
import 'screens/library_search_screen_use_case.dart';
import 'screens/study_screens_use_case.dart';
import 'screens/tag_catalog_screen_use_case.dart';
import 'screens/tag_filter_sheet_use_case.dart';
import 'screens/trash_screen_use_case.dart';
import 'support/catalog_page.dart';
import 'tokens/color_sections.dart';
import 'tokens/scale_sections.dart';
import 'tokens/typography_section.dart';

void main() {
  runApp(const MemoxWidgetbook());
}

/// Galaxy S23 Ultra — the reference device this catalog opens on, per the
/// project owner: Android is the release target (AD-04), so the default frame
/// is a phone, not the browser canvas. 1440×3088 physical at 3.75 dpr gives
/// 384×823 logical; safe areas mirror Widgetbook's other Samsung presets.
/// Not a stock preset, hence defined here.
const ViewportData galaxyS23UltraViewport = ViewportData(
  name: 'Galaxy S23 Ultra',
  width: 384,
  height: 823,
  pixelRatio: 3.75,
  platform: TargetPlatform.android,
  safeAreas: EdgeInsets.only(top: 36, bottom: 24),
);

/// The 320×568 case every memox component is tested against (M4.8b). Kept as
/// the hard lower bound, not as the representative small phone — real small
/// phones are the iPhone 13 Mini / SE presets beside it in the addon list.
const ViewportData compactViewport = ViewportData(
  name: 'Compact 320 (M4.8b floor)',
  width: 320,
  height: 568,
  pixelRatio: 2,
  platform: TargetPlatform.android,
);

/// The catalog: memox's real themes as the theme addon, its tokens and every
/// `Mx*` shared component as knob-driven use-cases.
///
/// Composed manually rather than through `widgetbook_generator`: 13 components
/// do not justify a second codegen surface, and the manual tree keeps the
/// whole catalog readable in one place.
class MemoxWidgetbook extends StatelessWidget {
  const MemoxWidgetbook({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: <WidgetbookAddon<dynamic>>[
        // The app's own theme builders — not re-declared colours — so the
        // catalog can never drift from what the product renders.
        MaterialThemeAddon(
          themes: <WidgetbookTheme<ThemeData>>[
            WidgetbookTheme<ThemeData>(name: 'Light', data: buildLightTheme()),
            WidgetbookTheme<ThemeData>(name: 'Dark', data: buildDarkTheme()),
          ],
        ),
        TextScaleAddon(),
        // Screens read ARB copy through `context.l10n`; without the delegates
        // the first mounted screen throws. Components take pre-localized
        // strings and ignore this addon, which is correct — they are below
        // the layer that owns copy.
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
        // First entry is the addon's default (`viewports.first`), so the
        // catalog opens every use-case inside the phone frame rather than
        // stretched across the browser canvas — a screen judged at desktop
        // width is a screen judged in a shape no user ever sees. `None` stays
        // available for full-canvas inspection of wide token tables.
        // Small screens are represented by real devices — iPhone 13 Mini
        // (375×812) and iPhone SE (375×667, the iPhone 8's logical size) —
        // because a catalog whose only small option is the synthetic 320
        // floor makes every small-screen check an extreme-case check. The
        // 320 floor stays, as the bound M4.8b actually tests against.
        ViewportAddon(<ViewportData>[
          galaxyS23UltraViewport,
          IosViewports.iPhone13Mini,
          IosViewports.iPhoneSE,
          compactViewport,
          AndroidViewports.samsungGalaxyS20,
          AndroidViewports.mediumTablet,
          Viewports.none,
        ]),
        InspectorAddon(),
        // Last on purpose — the addon list nests first→outermost, so this one
        // sits inside both the theme addon's `Theme` and the viewport addon's
        // simulated `MediaQuery`. That is what lets the 320 viewport exercise
        // the same compact clauses the app applies at runtime; without it the
        // catalog rendered the roomy theme at every width, and a compact
        // regression could not be caught here.
        BuilderAddon(
          name: 'Compact scale',
          builder: (context, child) => CompactScaleWidget(child: child),
        ),
      ],
      directories: <WidgetbookNode>[
        WidgetbookCategory(
          name: 'Screens',
          children: <WidgetbookNode>[
            cardDetailScreenComponent(),
            cardEditorScreenComponent(),
            cardExportSheetComponent(),
            cardImportScreenComponent(),
            deckListScreenComponent(),
            progressScreenComponent(),
            settingsScreenComponent(),
            reminderSettingsScreenComponent(),
            tagCatalogScreenComponent(),
            tagFilterSheetComponent(),
            librarySearchScreenComponent(),
            ...studyScreenComponents(),
            progressDeckScreenComponent(),
            trashScreenComponent(),
          ],
        ),
        WidgetbookCategory(
          name: 'Design tokens',
          children: <WidgetbookNode>[
            WidgetbookUseCase(
              name: 'Colors',
              builder: (context) => const CatalogListPage(
                children: <Widget>[TokenColorSectionsWidget()],
              ),
            ),
            WidgetbookUseCase(
              name: 'Typography',
              builder: (context) => const CatalogListPage(
                children: <Widget>[TokenTypographySectionWidget()],
              ),
            ),
            WidgetbookUseCase(
              name: 'Scale & motion',
              builder: (context) => const CatalogListPage(
                children: <Widget>[TokenScaleSectionsWidget()],
              ),
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Components',
          children: <WidgetbookNode>[
            actionButtonComponent(),
            fabComponent(),
            iconComponent(),
            menuButtonComponent(),
            pressableComponent(),
            buttonPairComponent(),
            breadcrumbComponent(),
            iconButtonComponent(),
            pillButtonComponent(),
            textButtonComponent(),
            navigationBarComponent(),
            textFieldComponent(),
            cardComponent(),
            metricWellComponent(),
            listTileComponent(),
            selectionRowsComponent(),
            toggleComponent(),
            sessionTopBarComponent(),
            emptyStateComponent(),
            errorStateComponent(),
            loadingStateComponent(),
            confirmDialogComponent(),
            formDialogComponent(),
            alertDialogComponent(),
            actionSheetComponent(),
          ],
        ),
      ],
    );
  }
}
