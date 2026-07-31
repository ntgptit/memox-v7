import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

void _noop() {}

void _noopSelect(int _) {}

WidgetbookComponent actionButtonComponent() {
  return WidgetbookComponent(
    name: 'MxActionButton',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Save',
          );
          final variant = context.knobs.object.dropdown<MxActionButtonVariant>(
            label: 'variant',
            options: MxActionButtonVariant.values,
            labelBuilder: (MxActionButtonVariant value) => value.name,
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isLoading = context.knobs.boolean(label: 'isLoading');
          final hasIcon = context.knobs.boolean(label: 'with icon');

          return CatalogCenterPage(
            child: MxActionButton(
              label: label,
              variant: variant,
              isLoading: isLoading,
              icon: hasIcon ? Icons.add : null,
              onPressed: isEnabled ? _noop : null,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent iconButtonComponent() {
  return WidgetbookComponent(
    name: 'MxIconButton',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final semanticLabel = context.knobs.string(
            label: 'semanticLabel',
            initialValue: 'Edit',
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );

          return CatalogCenterPage(
            child: MxIconButton(
              icon: Icons.edit_outlined,
              semanticLabel: semanticLabel,
              onPressed: isEnabled ? _noop : null,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent pillButtonComponent() {
  return WidgetbookComponent(
    name: 'MxPillButton',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Due',
          );
          final isSelected = context.knobs.boolean(
            label: 'isSelected',
            initialValue: true,
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final hasIcon = context.knobs.boolean(label: 'with icon');
          final semanticLabel = context.knobs.stringOrNull(
            label: 'semanticLabel',
            description: 'For abbreviations — what the label cannot say',
          );

          return CatalogCenterPage(
            child: MxPillButton(
              label: label,
              isSelected: isSelected,
              onPressed: isEnabled ? _noop : null,
              icon: hasIcon ? Icons.schedule : null,
              semanticLabel: semanticLabel,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent textButtonComponent() {
  return WidgetbookComponent(
    name: 'MxTextButton',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: "Show today's summary",
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );

          // Start-aligned rather than centred: the whole point of this button is
          // that its label sits flush with the column it belongs to, and a
          // centred specimen is the one layout that cannot show that.
          return CatalogCenterPage(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: MxTextButton(
                label: label,
                onPressed: isEnabled ? _noop : null,
              ),
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent breadcrumbComponent() {
  return WidgetbookComponent(
    name: 'MxBreadcrumb',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final depth = context.knobs.int.slider(
            label: 'depth',
            initialValue: 3,
            min: 2,
            max: 10,
          );
          final hasLongNames = context.knobs.boolean(
            label: 'long Vietnamese names',
          );

          final names = hasLongNames
              ? <String>[
                  'Bộ từ vựng học thuật chuyên sâu',
                  'Chương 1 · Giao tiếp công sở và thư tín',
                  'Bài 3 · Thành ngữ thường gặp',
                ]
              : <String>['Decks', 'Unit 1', 'Grammar'];

          return CatalogCenterPage(
            child: MxBreadcrumb(
              items: <MxBreadcrumbItem>[
                for (var i = 0; i < depth; i++)
                  MxBreadcrumbItem(
                    label:
                        '${names[i % names.length]}'
                        '${i >= names.length ? ' ${i + 1}' : ''}',
                    // The last step is where the user already is: no tap.
                    onTap: i == depth - 1 ? null : _noop,
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent navigationBarComponent() {
  return WidgetbookComponent(
    name: 'MxNavigationBar',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final selectedIndex = context.knobs.int.slider(
            label: 'selectedIndex',
            max: 1,
          );

          return Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: MxNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: _noopSelect,
              destinations: const <NavigationDestination>[
                NavigationDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: 'Decks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.school_outlined),
                  selectedIcon: Icon(Icons.school),
                  label: 'Review',
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}
