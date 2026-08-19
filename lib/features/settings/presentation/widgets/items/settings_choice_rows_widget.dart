import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';

/// A closed choice, as radio rows (wireframe S9, W6).
///
/// **In `items/` rather than `sections/`** (AD-15): three groups on this screen
/// render it — Appearance, Language and the order half of Study defaults — so
/// it is a repeated part, not a band one screen composes.
///
/// **Radio rows rather than pills or a segmented button, and the reason is a
/// MUST rather than a preference.** W6 requires a selected state not to rest on
/// colour alone. `MxPillButton` over `ChoiceChip` cannot satisfy that today:
/// `buildChipTheme` sets `showCheckmark: false` and resolves `side` for
/// disabled and focused only, so a selected pill differs from an unselected one
/// in fill and label colour and in nothing else. A radio carries a glyph, so
/// the state survives being seen without colour. (The pill's own gap belongs to
/// `app_chip_theme.dart` and to the web kit that mirrors it — see the M99.28
/// note in `docs/wbs.md`; fixing it here would have been a second, private
/// answer to a shared component's question.)
///
/// Three choices with labels as long as `Theo hệ thống` at `textScaler` 2.0 on
/// a 320dp screen also do not fit a segmented control, which then truncates or
/// shrinks the text.
///
/// **[selected] is the persisted value, never a pending one** (BR-216).
class SettingsChoiceRowsWidget<T extends Enum> extends StatelessWidget {
  const SettingsChoiceRowsWidget({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    required this.isSubmitting,
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final List<T> values;

  /// The value currently **persisted**.
  final T selected;

  /// Already-localized label for one choice.
  final String Function(T value) labelOf;

  final ValueChanged<T> onChanged;

  /// While true the whole group is locked and says so (BR-216, W3 state 4).
  final bool isSubmitting;

  /// The gutter each row supplies for itself.
  ///
  /// Zero inside a card that already pads its content; `AppSpacing.lg`
  /// horizontally inside a card padded vertically only, so the row's target and
  /// ink span the card while its content stays on the screen's one column (W5).
  final EdgeInsetsGeometry contentPadding;

  /// `RadioGroup.onChanged` is required and non-nullable, so the locked state
  /// lives on each tile instead. Both are set for the reason
  /// `DeckSchedulerPickerWidget` gives: `enabled` greys the row and takes it out
  /// of the focus order, and the guarded callback means a tap that somehow
  /// lands mid-write changes nothing.
  void _ignoreChange(T? _) {}

  void _onChanged(T? value) {
    if (value == null) return;
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    // The lock is announced, not only painted: a group that merely greys out
    // reports its state by colour alone (W6).
    enabled: !isSubmitting,
    label: isSubmitting ? context.l10n.settingsSavingLabel : null,
    container: isSubmitting,
    child: RadioGroup<T>(
      groupValue: selected,
      onChanged: isSubmitting ? _ignoreChange : _onChanged,
      // **A transparent `Material`, and the framework asserts about its
      // absence.** `ListTile` paints its splash and its selected fill onto the
      // nearest `Material` ancestor, and `MxCard` only hosts one when the whole
      // card is tappable — which none of these are. Without this the nearest
      // Material is the Scaffold, *behind* the card's opaque decoration, so
      // every ripple is drawn and then covered.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final value in values)
              RadioListTile<T>(
                value: value,
                enabled: !isSubmitting,
                title: Text(labelOf(value)),
                contentPadding: contentPadding,
              ),
          ],
        ),
      ),
    ),
  );
}
