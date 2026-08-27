import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/core/theme/app_ink.dart';
import 'package:memox/shared/widgets/mx_icon.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/shared/widgets/mx_pressable.dart';
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
          final size = context.knobs.object.dropdown<MxActionButtonSize>(
            label: 'size',
            options: MxActionButtonSize.values,
            labelBuilder: (MxActionButtonSize value) => value.name,
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
              size: size,
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

WidgetbookComponent iconComponent() {
  return WidgetbookComponent(
    name: 'MxIcon',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final ink = context.knobs.object.dropdown<AppInk>(
            label: 'ink',
            options: AppInk.values,
            labelBuilder: (AppInk value) => value.name,
          );
          final size = context.knobs.object.dropdown<MxIconSize>(
            label: 'size',
            options: MxIconSize.values,
            labelBuilder: (MxIconSize value) => value.name,
          );
          final hasLabel = context.knobs.boolean(label: 'semantic label');

          return CatalogCenterPage(
            child: MxIcon(
              Icons.flag_outlined,
              ink: ink,
              size: size,
              semanticLabel: hasLabel ? 'Flagged' : null,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent fabComponent() {
  return WidgetbookComponent(
    name: 'MxFab',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'New deck',
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );

          return CatalogCenterPage(
            child: MxFab(
              icon: Icons.add,
              label: label,
              onPressed: isEnabled ? _noop : null,
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent pressableComponent() {
  return WidgetbookComponent(
    name: 'MxPressable',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final shape = context.knobs.object.dropdown<MxPressableShape>(
            label: 'shape',
            options: MxPressableShape.values,
            labelBuilder: (MxPressableShape value) => value.name,
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );

          return CatalogCenterPage(
            child: MxPressable(
              onTap: isEnabled ? _noop : null,
              shape: shape,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Pressable surface'),
              ),
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent buttonPairComponent() {
  return WidgetbookComponent(
    name: 'MxButtonPair',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        // The knobs are the two things that can make a pair come out uneven:
        // labels of different lengths, and an axis. The viewport and text-scale
        // addons cover the third — the row-or-stack threshold — because the
        // pair reads the screen rather than its own line.
        name: 'Playground',
        builder: (BuildContext context) {
          final primaryLabel = context.knobs.string(
            label: 'primary label',
            initialValue: 'Browse starter library',
          );
          final secondaryLabel = context.knobs.string(
            label: 'secondary label',
            initialValue: 'New deck',
            description: 'Deliberately shorter — the halves must still match',
          );
          final axis = context.knobs.object.dropdown<Axis>(
            label: 'axis',
            options: Axis.values,
            labelBuilder: (Axis value) => value == Axis.horizontal
                ? 'horizontal — a row, stacked when narrow'
                : 'vertical — always stacked',
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isSubmitting = context.knobs.boolean(
            label: 'primary isLoading',
          );

          return CatalogCenterPage(
            child: MxButtonPair(
              axis: axis,
              primary: MxActionButton(
                label: primaryLabel,
                isLoading: isSubmitting,
                onPressed: isEnabled ? _noop : null,
              ),
              secondary: MxActionButton(
                label: secondaryLabel,
                variant: MxActionButtonVariant.secondary,
                onPressed: isEnabled ? _noop : null,
              ),
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
            initialValue: 'Flag card',
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final tone = context.knobs.object.dropdown<MxIconButtonTone>(
            label: 'tone',
            options: MxIconButtonTone.values,
            labelBuilder: (MxIconButtonTone value) => value.name,
          );

          return CatalogCenterPage(
            child: MxIconButton(
              // The card editor's flag is the tone axis's first caller, so the
              // catalog shows the glyph pair it changes with rather than a
              // neutral icon: a toned button that kept the same shape would
              // suggest colour is the whole signal, which is what it must not
              // be.
              icon: tone == MxIconButtonTone.warning
                  ? Icons.flag
                  : Icons.flag_outlined,
              semanticLabel: semanticLabel,
              tone: tone,
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
          final hasLeadingIcon = context.knobs.boolean(label: 'leading icon');
          final hasTrailingIcon = context.knobs.boolean(
            label: 'trailing icon',
            initialValue: true,
          );
          final isDestructive = context.knobs.boolean(label: 'destructive');

          // Start-aligned rather than centred: the whole point of this button is
          // that its label sits flush with the column it belongs to, and a
          // centred specimen is the one layout that cannot show that.
          return CatalogCenterPage(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: MxTextButton(
                label: label,
                icon: hasLeadingIcon ? Icons.restart_alt : null,
                trailingIcon: hasTrailingIcon ? Icons.expand_more : null,
                isDestructive: isDestructive,
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
