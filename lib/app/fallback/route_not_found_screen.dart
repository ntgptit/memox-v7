import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extension.dart';
import '../../shared/widgets/mx_error_state.dart';
import '../../shared/widgets/mx_content_shell.dart';
import '../router/route_names.dart';

/// Shown when a location matches no route.
///
/// **An app-level fallback, not a feature.** It lives in `app/fallback/` because
/// it has no domain, no use case, no repository and no data source — a
/// `features/not_found/` folder would be three empty layers wrapped around one
/// widget. It is not a shared component either: it knows `GoRouter` and
/// [RouteNames], and anything in `shared/widgets/` that knew those would drag
/// routing into every widget test in the project.
///
/// It builds nothing of its own. `MxContentShell` and `MxErrorState`
/// already decide padding, typography and the danger colour; re-implementing the
/// layout here is how a 404 ends up looking like a different app than the one it
/// interrupts.
///
/// The requested URL is deliberately absent from the screen. A user cannot act
/// on it, and echoing a location back can put whatever was in that string —
/// including a card's content in a future deep link — onto a screenshot.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MxContentShell(
      body: MxErrorState(
        title: context.l10n.pageNotFoundTitle,
        message: context.l10n.pageNotFoundMessage,
        retryLabel: context.l10n.goHomeAction,
        // By name. The literal `'/'` would work today and break silently the
        // first time home stops being the root — landing the user on this same
        // screen, from the button meant to escape it.
        onRetry: () => context.goNamed(RouteNames.decks),
      ),
    );
  }
}
