import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/deck_context_model.dart';

/// Where this card sits, and the one way out of the editor into its history.
///
/// Three rows the concept puts above the form: the path, an entry to the card's
/// detail screen, and the deck the card belongs to.
///
/// **The deck row does not open a picker, and it is drawn so that it cannot
/// look like one.** The concept shows a chevron beside the deck name; moving a
/// card between decks is UC-04 A5 and is refused outright across roots and
/// generations (BR-73/BR-74), so a chevron here would be an affordance for
/// something this screen will not do. No `onTap`, no trailing glyph — it is
/// context, and it reads as context.
///
/// **The history row computes nothing.** The concept prints `14 reviews · 78%
/// recall`; BR-243 forbids a second aggregate definition built from history, so
/// this row is a labelled way *to* the screen that owns those numbers rather
/// than a second place that states them.
class CardEditorContextWidget extends StatelessWidget {
  const CardEditorContextWidget({
    required this.deckId,
    required this.cardId,
    required this.deckContext,
    super.key,
  });

  final String deckId;
  final String cardId;

  /// Null until the one deck-context read resolves. The rows that depend on it
  /// are simply absent until then rather than showing a placeholder path — a
  /// breadcrumb that says the wrong thing briefly is worse than one that
  /// arrives a frame late.
  final DeckContextModel? deckContext;

  @override
  Widget build(BuildContext context) {
    final resolved = deckContext;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (resolved != null) ...<Widget>[
          _buildBreadcrumb(context, resolved),
          const SizedBox(height: AppSpacing.md),
        ],
        _buildHistoryRow(context),
        if (resolved != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _buildDeckRow(context, resolved),
        ],
      ],
    );
  }

  /// The card list's path with one more step: `Edit`, where the user is.
  ///
  /// Built here rather than reusing `CardBreadcrumbWidget` because that one
  /// ends at the deck — its last step is the screen it belongs to. Adding a
  /// parameter to make its leaf configurable would make two screens share a
  /// widget whose whole shape is "the last crumb is me".
  Widget _buildBreadcrumb(BuildContext context, DeckContextModel deck) {
    return MxBreadcrumb(
      semanticLabel: context.l10n.deckPathSemanticLabel,
      rootIcon: Icons.home_outlined,
      collapseAfter: 3,
      items: <MxBreadcrumbItem>[
        MxBreadcrumbItem(
          label: context.l10n.deckPathRootLabel,
          onTap: () => context.goNamed(RouteNames.decks),
        ),
        for (final DeckBreadcrumbSegment segment in deck.ancestors)
          MxBreadcrumbItem(
            label: segment.name,
            onTap: () => context.goNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{
                RoutePathParams.deckId: segment.id,
              },
            ),
          ),
        MxBreadcrumbItem(
          label: deck.deckName,
          onTap: () => context.goNamed(
            RouteNames.deckDetail,
            pathParameters: <String, String>{RoutePathParams.deckId: deckId},
          ),
        ),
        // The leaf: no tap, because this is the screen the user is on.
        MxBreadcrumbItem(label: context.l10n.cardEditorBreadcrumbLabel),
      ],
    );
  }

  Widget _buildHistoryRow(BuildContext context) {
    final quiet = context.colors.onSurfaceVariant;

    return MxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: () => context.goNamed(
        RouteNames.cardDetail,
        pathParameters: <String, String>{
          RoutePathParams.deckId: deckId,
          RoutePathParams.cardId: cardId,
        },
      ),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(
              Icons.history_outlined,
              size: AppIconSize.sm,
              color: quiet,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.cardEditorHistoryLabel,
              style: context.texts.bodyMedium,
            ),
          ),
          Text(
            context.l10n.cardEditorHistoryAction,
            style: context.texts.labelLarge?.copyWith(
              color: context.semanticColors.primaryAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          ExcludeSemantics(
            child: Icon(
              Icons.chevron_right,
              size: AppIconSize.sm,
              color: context.semanticColors.primaryAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeckRow(BuildContext context, DeckContextModel deck) {
    return MxCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(
              Icons.layers_outlined,
              size: AppIconSize.sm,
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              deck.deckName,
              style: context.texts.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
