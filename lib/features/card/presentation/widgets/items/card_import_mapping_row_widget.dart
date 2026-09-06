import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_dropdown.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_transfer_field_model.dart';
import '../support/card_import_labels_widget.dart';
import '../support/card_import_pair_widget.dart';

/// One mapping row: source column → destination dropdown (wireframe I6).
///
/// A vertical list of these instead of a desktop table, because 360px at
/// double text scale holds exactly one readable column of controls. The
/// dropdown carries every destination plus Ignore; picking a destination
/// another column holds simply takes it over — the mapping model keeps a
/// destination single-owner structurally (BR-169).
///
/// **The 50/50 split is measured, not assumed** (SC-C7-02). It used to be a
/// flat `Row` of two `Expanded`s with no fallback, so at a large text scale
/// the destination — the whole decision of this step — was the half that got
/// cut: at 360×800 and `textScaler` 2.0 the dropdown's box was 144dp while
/// `Pronunciation` wanted 216.95, and `RenderParagraph.didExceedMaxLines` was
/// true. Three other components on this same screen already measure and stack;
/// this row and the sheet selector were the two that did not.
class CardImportMappingRowWidget extends StatelessWidget {
  const CardImportMappingRowWidget({
    required this.column,
    required this.headerText,
    required this.field,
    required this.onAssign,
    super.key,
  });

  final int column;

  /// The header cell's text, or empty when there is none — the label then
  /// falls back to the stable positional name (UC-10 A3).
  final String headerText;

  final CardTransferField? field;
  final ValueChanged<CardTransferField?> onAssign;

  @override
  Widget build(BuildContext context) {
    final label = headerText.trim().isEmpty
        ? context.cardImportColumnLabel(column)
        : headerText.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: CardImportPairWidget(
        label: Text(
          label,
          style: context.texts.bodyMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        control: MxDropdown<CardTransferField?>(
          value: field,
          onChanged: onAssign,
          options: <MxDropdownOption<CardTransferField?>>[
            MxDropdownOption<CardTransferField?>(
              value: null,
              label: context.l10n.cardImportIgnoreColumnLabel,
            ),
            for (final destination in CardTransferField.values)
              MxDropdownOption<CardTransferField?>(
                value: destination,
                label: context.cardImportFieldLabel(destination),
              ),
          ],
        ),
      ),
    );
  }
}
