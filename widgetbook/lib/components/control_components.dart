import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
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
