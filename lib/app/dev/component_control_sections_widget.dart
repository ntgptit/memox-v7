import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/mx_action_button.dart';
import '../../shared/widgets/mx_icon_button.dart';
import '../../shared/widgets/mx_navigation_bar.dart';
import 'showcase_section_widget.dart';

/// The control demos of the component gallery: `MxActionButton`,
/// `MxIconButton` and `MxNavigationBar`, each in every variant and
/// interaction state it has.
class ComponentControlSectionsWidget extends StatelessWidget {
  const ComponentControlSectionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ActionButtonSection(),
        _IconButtonSection(),
        _NavigationBarSection(),
      ],
    );
  }
}

void _noop() {}

void _noopSelect(int _) {}

class _ActionButtonSection extends StatelessWidget {
  const _ActionButtonSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxActionButton',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'primary · enabled / loading / disabled',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              MxActionButton(label: 'Save', onPressed: _noop),
              MxActionButton(
                label: 'Saving',
                onPressed: _noop,
                isLoading: true,
              ),
              MxActionButton(label: 'Save', onPressed: null),
            ],
          ),
        ),
        ShowcaseItemWidget(
          label: 'secondary · enabled / disabled',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              MxActionButton(
                label: 'Cancel',
                onPressed: _noop,
                variant: MxActionButtonVariant.secondary,
              ),
              MxActionButton(
                label: 'Cancel',
                onPressed: null,
                variant: MxActionButtonVariant.secondary,
              ),
            ],
          ),
        ),
        ShowcaseItemWidget(
          label: 'destructive · with icon',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              MxActionButton(
                label: 'Delete',
                onPressed: _noop,
                variant: MxActionButtonVariant.destructive,
              ),
              MxActionButton(
                label: 'Add card',
                onPressed: _noop,
                icon: Icons.add,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconButtonSection extends StatelessWidget {
  const _IconButtonSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxIconButton',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'enabled / disabled',
          child: Row(
            children: <Widget>[
              MxIconButton(
                icon: Icons.edit_outlined,
                semanticLabel: 'Edit (demo)',
                onPressed: _noop,
              ),
              MxIconButton(
                icon: Icons.delete_outline,
                semanticLabel: 'Delete (demo)',
                onPressed: null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationBarSection extends StatelessWidget {
  const _NavigationBarSection();

  @override
  Widget build(BuildContext context) {
    return const ShowcaseSectionWidget(
      title: 'MxNavigationBar',
      children: <Widget>[
        ShowcaseItemWidget(
          label: 'two destinations, first selected',
          child: MxNavigationBar(
            selectedIndex: 0,
            onDestinationSelected: _noopSelect,
            destinations: <NavigationDestination>[
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
        ),
      ],
    );
  }
}
