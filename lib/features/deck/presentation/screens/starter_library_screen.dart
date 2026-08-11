import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../controllers/starter_library_controller.dart';
import '../widgets/overlays/starter_install_widget.dart';
import '../widgets/sections/deck_notice_widget.dart';

/// The published starter decks, and the way to copy one in (UC-01, AD-07).
///
/// **This screen exists because production seeds nothing.** The development
/// flavor copies every fixture in at startup; a real install starts from an
/// empty library, and its empty state has to offer content as well as a blank
/// form. Choosing from here *copies* a template (BR-33) — the copy is an
/// ordinary deck with its own ids, and updates to the template never touch it
/// (BR-35).
///
/// **The fixture notice is not decoration** (BR-87): the current starter
/// content is written by this project to exercise the app, and presenting it
/// as course content would be a claim the words cannot back.
class StarterLibraryScreen extends ConsumerWidget {
  const StarterLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxContentShell(
      title: context.l10n.starterLibraryTitle,
      body: MxAsyncView<List<StarterTemplateRow>>(
        value: ref.watch(starterLibraryProvider),
        loadingLabel: context.l10n.starterLibraryTitle,
        data: (rows) => _Catalog(rows: rows),
        error: (error, stackTrace) => MxErrorState(
          title: context.l10n.starterLibraryTitle,
          message: context.l10n.starterLibraryInstallFailed,
          onRetry: () => ref.invalidate(starterLibraryProvider),
        ),
      ),
    );
  }
}

class _Catalog extends StatelessWidget {
  const _Catalog({required this.rows});

  final List<StarterTemplateRow> rows;

  @override
  Widget build(BuildContext context) {
    // A build with no published templates is a real state, not an error: the
    // manifest is allowed to be empty.
    if (rows.isEmpty) {
      return MxEmptyState(
        icon: Icons.auto_stories_outlined,
        title: context.l10n.starterLibraryTitle,
        message: context.l10n.starterLibraryEmpty,
      );
    }

    return ListView(
      children: <Widget>[
        DeckNoticeWidget(message: context.l10n.starterLibraryFixtureNotice),
        const SizedBox(height: AppSpacing.md),
        for (final row in rows) ...<Widget>[
          _TemplateTile(row: row),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One template: what it is, where its words came from, and the way in.
class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.row});

  final StarterTemplateRow row;

  Future<void> _add(BuildContext context) async {
    // Already present: the default install path is idempotent (BR-37), so a
    // second copy exists only through BR-38's explicit confirmation. Cancel
    // copies nothing.
    if (row.isInstalled) {
      final isConfirmed = await showStarterAddAgainConfirm(context);
      if (!isConfirmed || !context.mounted) return;
    }

    final outcome = await showStarterInstallSheet(
      context,
      template: row.template,
      shouldAllowDuplicate: row.isInstalled,
    );
    if (outcome == null || !context.mounted) return;

    // Success returns to the Library, where the repository's stream is already
    // showing the new deck — nothing here reloads anything.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final template = row.template;
    final quiet = context.texts.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return MxCard(
      elevation: AppElevation.none,
      onTap: () => _add(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  template.title.value,
                  style: context.texts.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${context.l10n.starterLibraryCardCount(template.cardCount)}'
                  ' · '
                  '${context.l10n.starterLibraryLocaleLabel(template.locale)}',
                  style: quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.starterLibrarySource(template.contentSource),
                  style: quiet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // The row's state, worded: an installed template says so, an open
          // one names the way in. Weight carries the affordance rather than
          // the brand colour — `primary` at label size measured 2.90:1 on the
          // dark card, and the whole card is the target anyway.
          Text(
            row.isInstalled
                ? context.l10n.starterLibraryInstalledLabel
                : context.l10n.starterLibraryInstallAction,
            style: context.texts.labelMedium?.copyWith(
              color: row.isInstalled
                  ? context.semanticColors.success
                  : context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
