import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_metric_well.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';

void _noop() {}

WidgetbookComponent textFieldComponent() {
  return WidgetbookComponent(
    name: 'MxTextField',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final label = context.knobs.string(
            label: 'label',
            initialValue: 'Deck name',
          );
          final hintText = context.knobs.stringOrNull(
            label: 'hintText',
            initialValue: 'e.g. Academic Word List',
          );
          final helperText = context.knobs.stringOrNull(label: 'helperText');
          final errorText = context.knobs.stringOrNull(label: 'errorText');
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isReadOnly = context.knobs.boolean(label: 'readOnly');
          final maxLength = context.knobs.intOrNull.slider(
            label: 'maxLength',
            min: 10,
            max: 200,
          );

          return CatalogCenterPage(
            child: _TextFieldDemo(
              label: label,
              hintText: hintText,
              helperText: helperText,
              errorText: errorText,
              isEnabled: isEnabled,
              isReadOnly: isReadOnly,
              maxLength: maxLength,
            ),
          );
        },
      ),
    ],
  );
}

/// Owns the controller so it survives knob-driven rebuilds — a controller
/// created inside the use-case builder would be recreated (and leaked) on
/// every knob change.
class _TextFieldDemo extends StatefulWidget {
  const _TextFieldDemo({
    required this.label,
    required this.hintText,
    required this.helperText,
    required this.errorText,
    required this.isEnabled,
    required this.isReadOnly,
    required this.maxLength,
  });

  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isEnabled;
  final bool isReadOnly;
  final int? maxLength;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MxTextField(
      controller: _controller,
      label: widget.label,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      isEnabled: widget.isEnabled,
      isReadOnly: widget.isReadOnly,
      maxLength: widget.maxLength,
    );
  }
}

WidgetbookComponent cardComponent() {
  return WidgetbookComponent(
    name: 'MxCard',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final content = context.knobs.string(
            label: 'content',
            initialValue:
                'The app’s one raised surface: bordered, unshadowed, '
                'radius lg.',
            maxLines: 3,
          );
          final isTappable = context.knobs.boolean(label: 'tappable');
          // A **role**, never a free colour — the same contract `color` has.
          // `fill`'s answer card wears its verdict on this edge rather than in a
          // panel drawn inside it.
          final edge = context.knobs.object.dropdown<String>(
            label: 'borderColor',
            options: <String>['default', 'success', 'danger', 'focusRing'],
          );

          return CatalogCenterPage(
            child: MxCard(
              onTap: isTappable ? _noop : null,
              borderColor: switch (edge) {
                'success' => context.semanticColors.success,
                'danger' => context.semanticColors.danger,
                'focusRing' => context.semanticColors.focusRing,
                _ => null,
              },
              child: Text(content, style: context.texts.bodyMedium),
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent metricWellComponent() {
  return WidgetbookComponent(
    name: 'MxMetricWell',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          // The two states every caller has: a metric with something in it, and
          // one at rest. What the catalogue is for here is that the *shape*
          // does not move between them — the deck summary, Study Home and
          // Progress all anchor on this, and a well that changed size with its
          // state would break three grids at once.
          final isActive = context.knobs.boolean(
            label: 'has something waiting',
            initialValue: true,
          );

          return CatalogCenterPage(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MxMetricWell(
                  icon: isActive ? Icons.event_busy : Icons.event_busy_outlined,
                  tint: isActive
                      ? context.colors.onErrorContainer
                      : context.colors.onSurfaceVariant,
                  wellColor: isActive
                      ? context.colors.errorContainer
                      : context.semanticColors.surfaceMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isActive ? '12 overdue' : '0 overdue',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    ],
  );
}

WidgetbookComponent listTileComponent() {
  return WidgetbookComponent(
    name: 'MxListTile',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (BuildContext context) {
          final title = context.knobs.string(
            label: 'title',
            initialValue: 'Academic Word List',
          );
          final subtitle = context.knobs.stringOrNull(
            label: 'subtitle',
            initialValue: '120 cards · 8 due',
          );
          final hasLeading = context.knobs.boolean(
            label: 'with leading icon',
            initialValue: true,
          );
          final hasTrailing = context.knobs.boolean(
            label: 'with trailing chevron',
            initialValue: true,
          );
          final isEnabled = context.knobs.boolean(
            label: 'enabled',
            initialValue: true,
          );
          final isSelected = context.knobs.boolean(label: 'selected');

          return Scaffold(
            body: SafeArea(
              child: Center(
                child: MxListTile(
                  title: title,
                  subtitle: subtitle,
                  leading: hasLeading
                      ? const Icon(Icons.folder_outlined)
                      : null,
                  trailing: hasTrailing
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _noop,
                  isEnabled: isEnabled,
                  isSelected: isSelected,
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

/// The two binary toggles, side by side and in every state.
///
/// **Raw `Switch` and `Checkbox`, not an `Mx` wrapper, because that is what the
/// app renders.** There is no shared component here to catalogue — the reminder
/// screen and the tag filter sheet build Material's own widgets and let the
/// theme dress them. So what this page is for is the *theme*: the resting thumb
/// that had to leave Material's `outline` to clear 3:1, and the track outline
/// that changes colour instead of disappearing when the switch turns on. Both
/// are decisions a number can defend and only a screen can approve.
WidgetbookComponent toggleComponent() {
  return WidgetbookComponent(
    name: 'Switch and Checkbox',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Every state',
        builder: (BuildContext context) =>
            const CatalogCenterPage(child: _ToggleMatrix()),
      ),
    ],
  );
}

/// On and off, enabled and disabled, for both controls at once.
///
/// A matrix rather than knobs: the states have to be visible *together*. The
/// question these answer — does the off switch read as off, and is the on one
/// still bounded against the card — is a comparison, and a knob shows one at a
/// time.
class _ToggleMatrix extends StatelessWidget {
  const _ToggleMatrix();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ToggleRow(label: 'enabled', isEnabled: true),
        SizedBox(height: 24),
        _ToggleRow(label: 'disabled', isEnabled: false),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.label, required this.isEnabled});

  final String label;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final value in <bool>[false, true]) ...<Widget>[
              Switch(value: value, onChanged: isEnabled ? (_) {} : null),
              Checkbox(value: value, onChanged: isEnabled ? (_) {} : null),
              const SizedBox(width: 16),
            ],
          ],
        ),
      ],
    );
  }
}
