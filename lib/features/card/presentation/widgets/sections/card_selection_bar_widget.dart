import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_menu_button.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../controllers/card_selection_controller.dart';

/// Takes every card the live filter matches (BR-167). A free function rather
/// than an inline read: `ref.read` written in `build()` reads without
/// subscribing, and the guard cannot tell the two apart — the same shape
/// `card_list_screen.dart` uses for its own commands.
Future<void> _takeAll(WidgetRef ref, String deckId) =>
    ref.read(cardSelectionProvider(deckId).notifier).includeAllMatching();

/// One bulk action, as the bar renders it.
///
/// A record rather than five parameters at three call sites: the bar decides
/// which actions get a button and which fall into the overflow, and that
/// decision is easier to read over a list than over a widget tree.
typedef CardBulkAction = ({
  String label,
  IconData icon,
  bool isDestructive,
  VoidCallback onPressed,
});

/// The contextual action bar for selection mode (UC-04 A6, BR-167).
///
/// **A band above the list, not a swapped app bar.** A contextual app bar is
/// the platform convention and it is the wrong shape here: at 320px with
/// `textScaler` 2.0 the count, Select all and five actions cannot share one
/// 56pt row, and an `AppBar` resolves that by overflowing rather than by
/// wrapping. A band owns its own layout — the count can take a second line and
/// the actions can fall into an overflow menu — which is what keeps the two
/// requirements ("show the count", "never overflow") from fighting.
///
/// **The band carries the verbs; the app bar carries the identity**
/// (SC-C4-12). It used to open with its own ✕ and print the count, while the
/// shell drew the platform back arrow above it — two controls that both left
/// selection, and a count on the band rather than in the bar that names the
/// screen. The ✕ and the count moved to `MxContentShell`'s `leading` and
/// `title`, which is where `trash_screen.dart` had already put them, and what
/// is left here is what only this band can do.
///
/// Two actions stay visible because they are the two the user came for; the
/// rest live behind one overflow, so the row's width is fixed regardless of
/// how many actions exist.
class CardSelectionBarWidget extends ConsumerWidget {
  const CardSelectionBarWidget({
    required this.deckId,
    required this.isBusy,
    required this.onMove,
    required this.onAddTag,
    required this.onFlag,
    required this.onUnflag,
    required this.onExport,
    required this.onDelete,
    super.key,
  });

  final String deckId;

  /// True while any bulk command is in flight. It comes from the screen, which
  /// watches the four command controllers: the selection itself holds no
  /// submitting flag, because the write is not its business.
  final bool isBusy;

  final VoidCallback onMove;
  final VoidCallback onAddTag;
  final VoidCallback onFlag;
  final VoidCallback onUnflag;

  /// The one read-only action on this bar (UC-11, BR-178): it opens the export
  /// sheet over the selection and leaves the selection exactly as it found it.
  final VoidCallback onExport;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(cardSelectionProvider(deckId));
    final l10n = context.l10n;
    final canAct = selection.hasSelection && !isBusy;

    final actions = <CardBulkAction>[
      (
        label: l10n.cardSelectionMoveAction,
        icon: Icons.drive_file_move_outlined,
        isDestructive: false,
        onPressed: onMove,
      ),
      (
        label: l10n.cardSelectionAddTagAction,
        icon: Icons.sell_outlined,
        isDestructive: false,
        onPressed: onAddTag,
      ),
      (
        label: l10n.cardSelectionFlagAction,
        icon: Icons.flag_outlined,
        isDestructive: false,
        onPressed: onFlag,
      ),
      (
        label: l10n.cardSelectionUnflagAction,
        icon: Icons.flag,
        isDestructive: false,
        onPressed: onUnflag,
      ),
      (
        label: l10n.cardExportSelectionAction,
        icon: Icons.share,
        isDestructive: false,
        onPressed: onExport,
      ),
      (
        label: l10n.cardSelectionDeleteAction,
        icon: Icons.delete_outline,
        // The only destructive role on the bar. Everything else stays neutral
        // so the one action that cannot be undone reads differently.
        isDestructive: true,
        onPressed: onDelete,
      ),
    ];

    return Semantics(
      container: true,
      child: ColoredBox(
        color: context.colors.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: <Widget>[
              // The count used to sit here, in a two-line label sized for
              // 320dp at double scale. It is the app-bar title now, where
              // `AppBar` ellipsizes it and no width on this row depends on how
              // long the word for "selected" is in the current locale.
              const Spacer(),
              MxIconButton(
                icon: Icons.select_all,
                semanticLabel: l10n.cardSelectAllAction,
                tooltip: l10n.cardSelectAllAction,
                onPressed: isBusy ? null : () => _takeAll(ref, deckId),
              ),
              _ActionMenu(actions: actions, isEnabled: canAct),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every bulk action behind one overflow.
///
/// **One menu rather than a responsive split.** Deciding how many icons fit
/// needs the available width, and a `LayoutBuilder` that guesses wrong at one
/// text scale is worse than a menu that is always correct: the row's width
/// stops depending on how many actions the feature grows.
class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.actions, required this.isEnabled});

  final List<CardBulkAction> actions;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return MxMenuButton(
      isEnabled: isEnabled,
      tooltip: context.l10n.cardSelectionMoreLabel,
      actions: <MxMenuAction>[
        for (final action in actions)
          MxMenuAction(
            icon: action.icon,
            label: action.label,
            isDestructive: action.isDestructive,
            onSelected: action.onPressed,
          ),
      ],
    );
  }
}
