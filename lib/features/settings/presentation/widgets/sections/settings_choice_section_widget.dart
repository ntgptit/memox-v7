import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_segmented_tray.dart';
import '../items/settings_choice_rows_widget.dart';
import '../items/settings_error_band_widget.dart';
import '../../../../../shared/widgets/mx_radio_rows.dart';
import 'settings_section_widget.dart';

/// A settings group that is one closed choice — Appearance and Language
/// (wireframe S9).
///
/// **Generic, because the two are the same widget twice.** Both are a closed
/// enum, three values, one selected, written on selection; two hand-written
/// copies would be two chances to forget the locked state or the error band.
///
/// The rows themselves are [SettingsChoiceRowsWidget], which the Study defaults
/// group also uses — what this adds is the heading, the card and the band.
///
/// **[selected] is the persisted value, never a pending one** (BR-216). A
/// failed save leaves the marked row showing what is actually stored; the
/// attempted value is remembered only so `Try again` can send it again.
class SettingsChoiceSectionWidget<T extends Enum> extends StatefulWidget {
  const SettingsChoiceSectionWidget({
    required this.sectionLabel,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    required this.isSubmitting,
    this.usesSegmentedTray = false,
    this.failure,
    super.key,
  });

  /// Already-localized heading of the group.
  final String sectionLabel;

  final List<T> values;

  /// The value currently **persisted**.
  final T selected;

  /// Already-localized label for one choice.
  final String Function(T value) labelOf;

  final ValueChanged<T> onChanged;

  /// While true the whole group is locked. The other groups stay usable —
  /// three groups are three writes.
  final bool isSubmitting;

  /// Appearance is the second settings caller of the compact shared control.
  /// Language keeps its radio rows because its labels are deliberately allowed
  /// to grow at high text scale.
  final bool usesSegmentedTray;

  final Failure? failure;

  @override
  State<SettingsChoiceSectionWidget<T>> createState() =>
      _SettingsChoiceSectionWidgetState<T>();
}

class _SettingsChoiceSectionWidgetState<T extends Enum>
    extends State<SettingsChoiceSectionWidget<T>> {
  /// What the user last asked for, which is **not** what is on screen while a
  /// save is failing. Held here rather than in the controller because it is a
  /// property of this form's last interaction, not of the write.
  T? _attempted;

  void _onChanged(T value) {
    setState(() => _attempted = value);
    widget.onChanged(value);
  }

  /// Sends the value that failed, not the one on screen. Retrying with
  /// [SettingsChoiceSectionWidget.selected] would silently re-save what is
  /// already stored and report success for a change that never happened.
  void _retry() {
    final attempted = _attempted;
    if (attempted == null) return;
    widget.onChanged(attempted);
  }

  @override
  Widget build(BuildContext context) {
    final band = widget.failure;

    return SettingsSectionWidget(
      label: widget.sectionLabel,
      child: MxCard.raised(
        // Vertical breath only: each row's touch target and ink span the full
        // card width, and every row carries the horizontal gutter itself so
        // its content still lines up with the other cards (W5).
        padding: MxCardPadding.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.usesSegmentedTray)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: mxScreenGutter(context),
                    vertical: AppSpacing.sm,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (!settingsSegmentedTrayFits<T>(
                        context: context,
                        constraints: constraints,
                        values: widget.values,
                        labelOf: widget.labelOf,
                      )) {
                        return SettingsChoiceRowsWidget<T>(
                          values: widget.values,
                          selected: widget.selected,
                          labelOf: widget.labelOf,
                          onChanged: _onChanged,
                          isSubmitting: widget.isSubmitting,
                        );
                      }

                      return Semantics(
                        enabled: !widget.isSubmitting,
                        label: widget.isSubmitting
                            ? context.l10n.settingsSavingLabel
                            : null,
                        container: widget.isSubmitting,
                        child: MxSegmentedTray<T>(
                          options: <MxSegmentedTrayOption<T>>[
                            for (final T value in widget.values)
                              MxSegmentedTrayOption<T>(
                                value: value,
                                label: widget.labelOf(value),
                              ),
                          ],
                          selected: widget.selected,
                          variant: MxSegmentedTrayVariant.settings,
                          onChanged: widget.isSubmitting ? null : _onChanged,
                        ),
                      );
                    },
                  ),
                )
              else
                SettingsChoiceRowsWidget<T>(
                  // **A list, so its rows divide** (M100.0). These rows are the
                  // whole content of their card — nothing else is in there — so
                  // the divider is what says they belong to one list. Study
                  // defaults deliberately stays a `block`: its rows sit between
                  // a field, a note and a Save button, where a line across them
                  // cuts a group instead of dividing a list.
                  shape: MxRadioRowsShape.list,
                  values: widget.values,
                  selected: widget.selected,
                  labelOf: widget.labelOf,
                  onChanged: _onChanged,
                  isSubmitting: widget.isSubmitting,
                ),
              if (band != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  // The same gutter the rows above take, not a restated
                  // `lg`: below 360dp they step to 12 and a band that did
                  // not would sit 4dp inside the thing it reports on (W5).
                  padding: EdgeInsets.symmetric(
                    horizontal: mxScreenGutter(context),
                  ),
                  child: SettingsErrorBandWidget(
                    failure: band,
                    onRetry: widget.isSubmitting ? null : _retry,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
