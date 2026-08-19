import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart';
import 'package:widgetbook/widgetbook.dart';

import 'tag_catalog_screen_use_case.dart'
    show TagCatalogFake, TagCatalogScenario;

/// The tag filter overlay, which lives on the card list and had no entry.
///
/// **Its three faces were unreachable, and that is the gap this batch already
/// closed once.** Rename and delete were given failure scenarios so a design
/// review could open them; the filter sheet was missed because it hangs off
/// `card_list_screen.dart`, which has never been catalogued at all. UC-18 names
/// "filter overlay không chọn gì · chọn một · chọn nhiều" as states this
/// feature owes, and until now they existed only inside `flutter test`.
///
/// Staged as a standalone overlay rather than by catalguing the whole card list
/// — `MxConfirmDialog` and `MxActionSheet` are entered the same way, and the
/// sheet's only input is a deck id and the catalog behind it.
WidgetbookComponent tagFilterSheetComponent() => WidgetbookComponent(
  name: 'CardTagFilterSheet',
  useCases: <WidgetbookUseCase>[
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final scenario = context.knobs.object.dropdown<TagCatalogScenario>(
          label: 'catalog',
          options: <TagCatalogScenario>[
            TagCatalogScenario.populated,
            TagCatalogScenario.empty,
            TagCatalogScenario.readFails,
          ],
          labelBuilder: (TagCatalogScenario value) => value.label,
        );

        return _FilterSheetDemo(
          key: ValueKey<Object>(scenario),
          scenario: scenario,
        );
      },
    ),
  ],
);

class _FilterSheetDemo extends StatefulWidget {
  const _FilterSheetDemo({required this.scenario, super.key});

  final TagCatalogScenario scenario;

  @override
  State<_FilterSheetDemo> createState() => _FilterSheetDemoState();
}

class _FilterSheetDemoState extends State<_FilterSheetDemo> {
  late final TagCatalogFake _catalog = TagCatalogFake(widget.scenario);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [tagCatalogRepositoryProvider.overrideWithValue(_catalog)],
      // A button rather than an auto-opened sheet: the sheet is a route, and
      // a catalogue entry that pushes one on build cannot be closed and
      // reopened without leaving the entry.
      child: Scaffold(
        body: Center(
          child: Builder(
            builder: (sheetContext) => FilledButton(
              onPressed: () => showCardTagFilterSheet(sheetContext, 'deck-1'),
              child: const Text('Open tag filter'),
            ),
          ),
        ),
      ),
    );
  }
}
