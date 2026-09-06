import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_radio_rows.dart';

/// A closed choice, as radio rows (wireframe S9, W6).
///
/// **In `items/` rather than `sections/`** (AD-15): three groups on this screen
/// render it — Appearance, Language and the order half of Study defaults — so
/// it is a repeated part, not a band one screen composes.
///
/// **Radio rows rather than pills or a segmented button, and the surviving
/// reason is W1, not W6.** This screen renders three closed choices —
/// Appearance, Language and the order half of Study defaults — and W1 draws
/// them as one control family; splitting them would make one screen ask the
/// same kind of question in two ways.
///
/// **The reason this comment used to give is no longer true, and saying so is
/// the point** (SC-C8-02). It read: `MxPillButton` over `ChoiceChip` cannot
/// satisfy W6's "not by colour alone", because `buildChipTheme` sets
/// `showCheckmark: false` and resolves `side` for disabled and focused only,
/// so a selected pill differs from an unselected one in fill and label colour
/// and in nothing else. That was measured and correct when it was written, and
/// M100.36 4M closed it: `mx_pill_button.dart` now composes its own tick into
/// an always-laid-out leading slot, so a selected pill carries a glyph and the
/// state survives being seen without colour. A stale justification is worse
/// than none — it answers the next reader's question with a fact they have no
/// reason to re-check.
///
/// What that leaves open is the divergence itself: `StudyOptionsScreen` still
/// edits `NewCardOrder` as pills while this screen edits it as radio rows,
/// under the same heading and the same two labels. That split is a decision of
/// `docs/wireframes/m99-settings.md` S9/S9a, which is `active` — so it is
/// re-decided there, not here. The `Deferred and descoped` table in
/// `docs/wbs.md` records that the premise S9a rests on is gone.
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
    this.shape = MxRadioRowsShape.block,
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

  /// See [MxRadioRowsShape]. The gutter follows it: a `list` supplies the
  /// screen gutter so the row's target and ink span the card while its content
  /// stays on the screen's one column (W5); a `block` supplies none.
  final MxRadioRowsShape shape;

  @override
  Widget build(BuildContext context) => Semantics(
    // The lock is announced, not only painted: a group that merely greys out
    // reports its state by colour alone (W6).
    enabled: !isSubmitting,
    label: isSubmitting ? context.l10n.settingsSavingLabel : null,
    container: isSubmitting,
    // MxRadioRows carries the transparent Material a ListTile's splash
    // needs inside a decorated card, and the per-tile lock — the two fixes
    // this widget used to hand-write.
    child: MxRadioRows<T>(
      values: values,
      selected: selected,
      isEnabled: !isSubmitting,
      onChanged: onChanged,
      labelOf: labelOf,
      shape: shape,
    ),
  );
}
