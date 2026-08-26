import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    required this.onLeave,
    super.key,
  });

  final String deckId;
  final String cardId;

  /// The one read this screen makes for its path, in every state.
  ///
  /// **An `AsyncValue`, not a nullable model, and that is a correction.** It
  /// was `DeckContextModel?` — which flattened loading, error and "this deck no
  /// longer exists" into the same `null` and silently rendered the screen with
  /// no path at all. The two are not the same thing to a user: one is a frame
  /// away, the other is a screen that will never say where they are.
  final AsyncValue<DeckContextModel> deckContext;

  /// Runs a navigation **through the editor's exit coordinator**.
  ///
  /// **Every crumb is a way out, and they were not guarded.** The screen's
  /// whole contract is that leaving with unsaved work asks first; the back
  /// arrow, Cancel and the system gesture all honoured it while four
  /// `goNamed` calls in here walked straight past it and dropped the draft
  /// without a word. The callback takes the navigation as a thunk so the guard
  /// decides *whether* it happens, not this widget.
  final void Function(VoidCallback navigate) onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ...deckContext.when(
          data: (DeckContextModel deck) => <Widget>[
            _buildBreadcrumb(context, deck),
            const SizedBox(height: AppSpacing.md),
          ],
          // A frame, not a state worth drawing furniture for.
          loading: () => const <Widget>[],
          // **Said, not swallowed.** A deck that was deleted or a read that
          // failed used to look exactly like a deck that had not arrived yet:
          // the path simply was not there. The row below names what is
          // unavailable so the missing path is a fact rather than an absence.
          error: (Object error, StackTrace stackTrace) => <Widget>[
            Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.cardEditorContextUnavailable,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.error,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
        _buildHistoryRow(context),
        ...deckContext.when(
          data: (DeckContextModel deck) => <Widget>[
            const SizedBox(height: AppSpacing.sm),
            _buildDeckRow(context, deck),
          ],
          loading: () => const <Widget>[],
          error: (Object error, StackTrace stackTrace) => const <Widget>[],
        ),
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
          onTap: () => onLeave(() => context.goNamed(RouteNames.decks)),
        ),
        for (final DeckBreadcrumbSegment segment in deck.ancestors)
          MxBreadcrumbItem(
            label: segment.name,
            onTap: () => onLeave(
              () => context.goNamed(
                RouteNames.deckDetail,
                pathParameters: <String, String>{
                  RoutePathParams.deckId: segment.id,
                },
              ),
            ),
          ),
        MxBreadcrumbItem(
          label: deck.deckName,
          onTap: () => onLeave(
            () => context.goNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{RoutePathParams.deckId: deckId},
            ),
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
      // **`push`, not `go`, and no discard guard.** `go` replaced the stack, so
      // opening the history was a one-way trip: back from the detail screen
      // landed on the deck rather than on the form the user was halfway
      // through. Pushing leaves the editor alive underneath with its draft
      // intact, which is also why this is the one navigation here that does not
      // have to ask about unsaved work — nothing is being left.
      onTap: () => context.pushNamed(
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
