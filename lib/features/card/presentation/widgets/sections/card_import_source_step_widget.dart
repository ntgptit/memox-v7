import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../../states/card_import_state.dart';
import '../support/card_import_labels_widget.dart';

/// Free functions for the same reason the screen's are: a `ref.read`
/// written inline in `build()` is indistinguishable from the unsubscribed
/// read the guard forbids.
void _chooseSourceKind(
  WidgetRef ref,
  String deckId,
  CardImportSourceKind kind,
) => ref.read(cardImportSourceChoiceProvider(deckId).notifier).choose(kind);

Future<void> _pickImportFile(WidgetRef ref, String deckId) =>
    ref.read(cardImportFilePickChoiceProvider(deckId).notifier).pick();

/// Step 1 — choose a source (wireframe M4.12 W2).
///
/// The paste box's [TextEditingController] belongs to the *screen*, not this
/// section: the section unmounts when the wizard moves to Preview, and the
/// pasted rows must survive that round trip (I4).
class CardImportSourceStepWidget extends ConsumerWidget {
  const CardImportSourceStepWidget({
    required this.deckId,
    required this.pasteController,
    super.key,
  });

  final String deckId;
  final TextEditingController pasteController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(cardImportSourceChoiceProvider(deckId));
    final pick = ref.watch(cardImportFilePickChoiceProvider(deckId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.cardImportChooseSourceHeading,
          style: context.texts.labelLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Two options side by side where they fit; Wrap stacks them into one
        // column at 320px or double text scale instead of overflowing (W7).
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            _SourceOption(
              title: context.l10n.cardImportUploadOptionTitle,
              subtitle: context.l10n.cardImportUploadOptionSubtitle,
              icon: Icons.upload_file_outlined,
              isSelected: kind == CardImportSourceKind.upload,
              onTap: () =>
                  _chooseSourceKind(ref, deckId, CardImportSourceKind.upload),
            ),
            _SourceOption(
              title: context.l10n.cardImportPasteOptionTitle,
              subtitle: context.l10n.cardImportPasteOptionSubtitle,
              icon: Icons.content_paste_outlined,
              isSelected: kind == CardImportSourceKind.paste,
              onTap: () =>
                  _chooseSourceKind(ref, deckId, CardImportSourceKind.paste),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (kind == CardImportSourceKind.upload)
          _UploadPanel(deckId: deckId, pick: pick)
        else
          MxTextField(
            controller: pasteController,
            label: context.l10n.cardImportPasteLabel,
            hintText: context.l10n.cardImportPastePlaceholder('\n'),
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
          ),
        const SizedBox(height: AppSpacing.lg),
        const _InfoPanel(),
      ],
    );
  }
}

/// One source card. Selection is a border, a glyph and `selected` semantics —
/// never colour alone, and never a full primary fill (W2).
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      selected: isSelected,
      button: true,
      child: MxCard(
        onTap: onTap,
        // Selection is the border, the check glyph and the semantics — no
        // background tint: a blended fill is not a palette token, and the
        // audit's palette closure is the design system's whole point.
        borderColor: isSelected ? colors.primary : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    // Secondary, not primary: the same selected-mark token the
                    // card tile's check uses — dark primary fails contrast as
                    // a glyph on dark surfaces.
                    color: isSelected
                        ? colors.secondary
                        : colors.onSurfaceVariant,
                  ),
                  if (isSelected) ...<Widget>[
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.check_circle,
                      size: AppSpacing.lg,
                      color: colors.secondary,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: context.texts.titleSmall),
              Text(
                subtitle,
                style: context.texts.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The upload half: a prompt and `Choose file`, or the picked file with a
/// Replace action. A failed pick renders its typed reason *and* keeps the
/// previous file on screen (UC-10 A5/E1).
class _UploadPanel extends ConsumerWidget {
  const _UploadPanel({required this.deckId, required this.pick});

  final String deckId;
  final CardImportFilePick pick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final file = pick.file;
    final failure = pick.failure;

    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (file == null) ...<Widget>[
            Icon(
              Icons.note_add_outlined,
              size: AppSpacing.xxl,
              color: context.colors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.cardImportChoosePrompt,
              style: context.texts.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ] else
            Row(
              children: <Widget>[
                Icon(
                  Icons.description_outlined,
                  color: context.colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        file.name,
                        style: context.texts.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Extension and size, as the wireframe asks (W2): the
                      // name alone does not say how big a paste of somebody's
                      // whole vocabulary is about to be.
                      Text(
                        context.l10n.cardImportFileMetaLabel(
                          file.format.name.toUpperCase(),
                          _formatByteSize(context, file.bytes.length),
                        ),
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (failure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  size: AppSpacing.lg,
                  color: context.colors.error,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.cardImportFailureLabel(failure),
                    style: context.texts.bodySmall?.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Filled, like the concept: inside this panel the pick *is* the
          // primary move — the sticky bar's single-primary rule is about the
          // wizard's step actions, not this panel's.
          MxActionButton(
            label: file == null
                ? context.l10n.cardImportChooseFileAction
                : context.l10n.cardImportReplaceFileAction,
            icon: Icons.folder_open_outlined,
            onPressed: () => _pickImportFile(ref, deckId),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return MxCard(
      color: colors.surfaceContainerHigh,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.info_outline,
                size: AppSpacing.lg,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.cardImportInfoTitle,
                  style: context.texts.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(context.l10n.cardImportInfoBody, style: context.texts.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.cardImportInfoBusinessHint,
            style: context.texts.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// KB below a megabyte, MB above — the two units a spreadsheet plausibly
/// arrives in. Rounded up so nothing reads as "0 KB".
String _formatByteSize(BuildContext context, int bytes) {
  const int kilobyte = 1024;
  const int megabyte = kilobyte * kilobyte;
  if (bytes >= megabyte) {
    return context.l10n.cardImportFileSizeMegabytes((bytes / megabyte).ceil());
  }

  return context.l10n.cardImportFileSizeKilobytes(
    bytes < kilobyte ? 1 : (bytes / kilobyte).ceil(),
  );
}
