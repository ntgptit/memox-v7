import 'package:flutter/material.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_metric_well.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_checkbox_row.dart';
import 'package:memox/shared/widgets/mx_dropdown.dart';
import 'package:memox/shared/widgets/mx_radio_rows.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:widgetbook/widgetbook.dart';

import '../support/catalog_page.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';

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
          final hasTrailingAction = context.knobs.boolean(
            label: 'trailingAction',
          );
          final labelPlacement = context.knobs.object
              .dropdown<MxTextFieldLabelPlacement>(
                label: 'labelPlacement',
                options: MxTextFieldLabelPlacement.values,
                labelBuilder: (MxTextFieldLabelPlacement value) => value.name,
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
              hasTrailingAction: hasTrailingAction,
              labelPlacement: labelPlacement,
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
    required this.hasTrailingAction,
    required this.labelPlacement,
  });

  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final bool isEnabled;
  final bool isReadOnly;
  final int? maxLength;
  final bool hasTrailingAction;
  final MxTextFieldLabelPlacement labelPlacement;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // So the trailing action's enabled state tracks what is typed, the way the
    // tag entry's does.
    _controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
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
      labelPlacement: widget.labelPlacement,
      trailingAction: widget.hasTrailingAction
          ? MxTextFieldAction(
              icon: Icons.add,
              semanticLabel: 'Add this tag',
              // Null on an empty field is the shape the tag entry uses: the
              // button stays where it is and stops working, rather than
              // appearing under the finger as the first character lands.
              onPressed: _controller.text.trim().isEmpty ? null : () {},
            )
          : null,
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
                'A closed surface: the recipe owns fill, edge, corner, '
                'depth and padding.',
            maxLines: 3,
          );
          final isTappable = context.knobs.boolean(label: 'tappable');
          final padding = context.knobs.object.dropdown<MxCardPadding>(
            label: 'padding',
            options: MxCardPadding.values,
            initialOption: MxCardPadding.standard,
          );
          final selection = context.knobs.object.dropdown<String>(
            label: 'isSelected',
            options: <String>['null (not selectable)', 'false', 'true'],
          );
          final treatment = context.knobs.object
              .dropdown<MxCardSelectionTreatment>(
                label: 'selectionTreatment (flat)',
                options: MxCardSelectionTreatment.values,
              );

          final isSelected = switch (selection) {
            'true' => true,
            'false' => false,
            _ => null,
          };
          final onTap = isTappable ? _noop : null;
          final child = Text(content, style: context.texts.bodyMedium);

          // Every public recipe, selectable by name — the legal API and
          // nothing beside it, so the owner can inspect each meaning without
          // opening a feature.
          final recipe = context.knobs.object.dropdown<String>(
            label: 'recipe',
            options: <String>[
              'flat',
              'raised',
              'focal',
              'recessed',
              'recessed · focus',
              'recessed · success',
              'recessed · danger',
              'feedback · danger',
              'muted',
              'tonal',
              'accent',
              'tile',
              'option',
            ],
          );

          final card = switch (recipe) {
            'raised' => MxCard.raised(
              padding: padding,
              isSelected: isSelected,
              onTap: onTap,
              child: child,
            ),
            'focal' => MxCard.focal(padding: padding, child: child),
            'recessed' => MxCard.recessed(padding: padding, child: child),
            'recessed · focus' => MxCard.recessed(
              padding: padding,
              edge: MxCardRecessedEdge.focus,
              child: child,
            ),
            'recessed · success' => MxCard.recessed(
              padding: padding,
              edge: MxCardRecessedEdge.success,
              child: child,
            ),
            'recessed · danger' => MxCard.recessed(
              padding: padding,
              edge: MxCardRecessedEdge.danger,
              child: child,
            ),
            'feedback · danger' => MxCard.feedback(
              tone: MxCardFeedbackTone.danger,
              child: child,
            ),
            'muted' => MxCard.muted(child: child),
            'tonal' => MxCard.tonal(padding: padding, child: child),
            'accent' => MxCard.accent(padding: padding, child: child),
            'tile' => MxCard.tile(child: child),
            'option' => MxCard.option(
              isSelected: isSelected ?? false,
              onTap: onTap,
              child: child,
            ),
            _ => MxCard.flat(
              padding: padding,
              isSelected: isSelected,
              selectionTreatment: treatment,
              onTap: onTap,
              child: child,
            ),
          };

          return CatalogCenterPage(child: card);
        },
      ),
      WidgetbookUseCase(
        name: 'Depth ladder',
        builder: (BuildContext context) {
          // **The three depths side by side, which the playground cannot
          // show.** A knob renders one recipe at a time, and depth is a
          // *relative* claim — a card only reads as lifted against the one that
          // is not. This is the page the shadow was designed on (M100.30) and
          // the page to review it on: switch the theme addon to dark and the
          // shade should be replaced by a crisp `outlineVariant` hairline —
          // the same one at every rung — with a drop appearing only from
          // `focal` up. Until M100.35 dark drew a bright blurred rim that grew
          // thicker with the level, and the "Repeated list" case below is
          // where that read as stripes rather than as depth.
          Widget rung(String title, String note, Widget card) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.texts.titleSmall),
                Text(
                  note,
                  style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                ),
                const SizedBox(height: AppSpacing.sm),
                card,
              ],
            ),
          );

          Widget body(String text) =>
              Text(text, style: context.texts.bodyMedium);

          return CatalogListPage(
            children: <Widget>[
              rung(
                'flat · elevation none',
                'No shade at all. A card inside a sheet, where a shadow on a '
                    'shadow reads as a rendering fault.',
                MxCard.flat(child: body('flat')),
              ),
              rung(
                'raised / tile · elevation card',
                "Tokyo's shadows.cardSm — a tight seat. The everyday list "
                    'card, and 22 of the app’s callers.',
                MxCard.raised(child: body('raised')),
              ),
              rung(
                'focal / accent · elevation raised',
                "Tokyo's shadows.card — the wide float. The study card and "
                    'the Today hero.',
                MxCard.focal(child: body('focal')),
              ),
            ],
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Repeated list',
        builder: (BuildContext context) {
          // **The shape a depth cue fails in, and the one no other page has.**
          // A single dark card wearing a bright rim looks deliberate; ten of
          // them down a phone column look like neon stripes, which is the
          // review that rejected the pre-M100.35 rim. The slider is here so
          // the count can be pushed past what any real screen shows.
          final count = context.knobs.int.slider(
            label: 'cards',
            initialValue: 10,
            min: 3,
            max: 40,
          );

          return CatalogListPage(
            children: <Widget>[
              for (int i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MxCard.raised(
                    onTap: _noop,
                    child: Text(
                      'Deck ${i + 1} · 20 cards',
                      style: context.texts.bodyMedium,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      WidgetbookUseCase(
        name: 'States',
        builder: (BuildContext context) {
          // Every state in one column with a neutral card at the top for
          // scale. The property to check is an ordering, not a colour: each
          // state edge has to stay obviously louder than the neutral depth
          // cue underneath it, in both themes.
          Widget row(String label, Widget card) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                ),
                const SizedBox(height: AppSpacing.xs),
                card,
              ],
            ),
          );
          Widget body(String text) =>
              Text(text, style: context.texts.bodyMedium);

          return CatalogListPage(
            children: <Widget>[
              row('neutral, for scale', MxCard.raised(child: body('raised'))),
              row(
                'selected · edge',
                MxCard.flat(
                  isSelected: true,
                  onTap: _noop,
                  child: body('flat'),
                ),
              ),
              row(
                'selected · tint',
                MxCard.flat(
                  isSelected: true,
                  selectionTreatment: MxCardSelectionTreatment.tint,
                  onTap: _noop,
                  child: body('flat'),
                ),
              ),
              row(
                'option · picked',
                MxCard.option(
                  isSelected: true,
                  onTap: _noop,
                  child: body('option'),
                ),
              ),
              row(
                'option · available',
                MxCard.option(
                  isSelected: false,
                  onTap: _noop,
                  child: body('option'),
                ),
              ),
              row(
                'option · disabled (M100.35)',
                MxCard.option(
                  isSelected: false,
                  onTap: null,
                  child: body('option'),
                ),
              ),
              row(
                'recessed · success',
                MxCard.recessed(
                  edge: MxCardRecessedEdge.success,
                  child: body('recessed'),
                ),
              ),
              row(
                'recessed · danger',
                MxCard.recessed(
                  edge: MxCardRecessedEdge.danger,
                  child: body('recessed'),
                ),
              ),
            ],
          );
        },
      ),
      WidgetbookUseCase(
        name: 'Edge-to-edge child',
        builder: (BuildContext context) {
          // The regression M100.33 fixed, kept visible. The state edge is a
          // foreground layer now, so an opaque child that reaches the corner
          // can no longer cover it — both cards below must still show a
          // border.
          Widget block() => const ColoredBox(
            color: Color(0xFF9AA0B5),
            child: SizedBox(height: 72, width: double.infinity),
          );

          return CatalogListPage(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Both cards hold an opaque child with no padding. Each must '
                  'still show its own edge.',
                  style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: MxCard.flat(
                  padding: MxCardPadding.none,
                  isSelected: true,
                  onTap: _noop,
                  child: block(),
                ),
              ),
              MxCard.option(isSelected: false, onTap: _noop, child: block()),
            ],
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
                  tint: isActive ? AppInk.onErrorContainer : AppInk.quiet,
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
WidgetbookComponent selectionRowsComponent() {
  return WidgetbookComponent(
    name: 'Selection rows',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'MxSwitchRow',
        builder: (BuildContext context) {
          final isOn = context.knobs.boolean(label: 'on', initialValue: true);
          final isAnnounced = context.knobs.boolean(label: 'announced variant');

          return CatalogCenterPage(
            child: MxSwitchRow(
              label: 'Enable reminders',
              isOn: isOn,
              announcedValue: isAnnounced ? (isOn ? 'On' : 'Off') : null,
              onChanged: _noopBool,
            ),
          );
        },
      ),
      WidgetbookUseCase(
        name: 'MxCheckboxRow',
        builder: (BuildContext context) => CatalogCenterPage(
          child: MxCheckboxRow(
            label: 'grammar',
            subtitle: '12 cards',
            isChecked: context.knobs.boolean(
              label: 'checked',
              initialValue: true,
            ),
            onToggle: _noop,
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'MxRadioRows',
        builder: (BuildContext context) => CatalogCenterPage(
          child: MxRadioRows<int>(
            values: const <int>[0, 1, 2],
            selected: 1,
            isEnabled: context.knobs.boolean(
              label: 'enabled',
              initialValue: true,
            ),
            onChanged: _noopIndex,
            labelOf: (int value) => 'Choice ${String.fromCharCode(65 + value)}',
          ),
        ),
      ),
      WidgetbookUseCase(
        name: 'MxDropdown',
        builder: (BuildContext context) => const CatalogCenterPage(
          child: MxDropdown<int>(
            value: 0,
            onChanged: _noopNullableIndex,
            options: <MxDropdownOption<int>>[
              MxDropdownOption<int>(value: 0, label: 'Front'),
              MxDropdownOption<int>(value: 1, label: 'Back'),
              MxDropdownOption<int>(value: 2, label: 'Ignore this column'),
            ],
          ),
        ),
      ),
    ],
  );
}

void _noopBool(bool value) {}

void _noopIndex(int value) {}

void _noopNullableIndex(int? value) {}

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
