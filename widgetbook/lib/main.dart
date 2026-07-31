import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:widgetbook/widgetbook.dart';

import 'components/control_components.dart';
import 'components/feedback_components.dart';
import 'components/form_components.dart';
import 'components/overlay_components.dart';
import 'support/catalog_page.dart';
import 'tokens/color_sections.dart';
import 'tokens/scale_sections.dart';
import 'tokens/typography_section.dart';

void main() {
  runApp(const MemoxWidgetbook());
}

/// The 320×568 case every memox component is tested against (M4.8b), which no
/// stock viewport preset covers.
const ViewportData compactViewport = ViewportData(
  name: 'Compact 320',
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
        ViewportAddon(<ViewportData>[
          Viewports.none,
          compactViewport,
          AndroidViewports.samsungGalaxyS20,
          AndroidViewports.mediumTablet,
        ]),
        InspectorAddon(),
      ],
      directories: <WidgetbookNode>[
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
            iconButtonComponent(),
            navigationBarComponent(),
            textFieldComponent(),
            cardComponent(),
            listTileComponent(),
            emptyStateComponent(),
            errorStateComponent(),
            loadingStateComponent(),
            confirmDialogComponent(),
            actionSheetComponent(),
          ],
        ),
      ],
    );
  }
}
