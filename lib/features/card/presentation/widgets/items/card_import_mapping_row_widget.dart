import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/card_transfer_field_model.dart';
import '../support/card_import_labels_widget.dart';

/// One mapping row: source column → destination dropdown (wireframe I6).
///
/// A vertical list of these instead of a desktop table, because 360px at
/// double text scale holds exactly one readable column of controls. The
/// dropdown carries every destination plus Ignore; picking a destination
/// another column holds simply takes it over — the mapping model keeps a
/// destination single-owner structurally (BR-169).
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
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: context.texts.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CardTransferField?>(
                value: field,
                isExpanded: true,
                onChanged: onAssign,
                items: <DropdownMenuItem<CardTransferField?>>[
                  DropdownMenuItem<CardTransferField?>(
                    child: Text(context.l10n.cardImportIgnoreColumnLabel),
                  ),
                  for (final destination in CardTransferField.values)
                    DropdownMenuItem<CardTransferField?>(
                      value: destination,
                      child: Text(context.cardImportFieldLabel(destination)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
