import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/models/progress_overview_model.dart';
import '../controllers/progress_overview_controller.dart';
import '../widgets/sections/progress_streak_hero_widget.dart';
import '../widgets/sections/progress_today_widget.dart';
import '../widgets/sections/progress_week_widget.dart';

/// The Progress branch (UC-12).
///
/// **It replaced a placeholder, and nothing around it moved.** `/progress`, its
/// route name and its branch index are the same as they were: that stability is
/// the whole thing AD-19 bought by scaffolding the branch before the feature
/// existed, and spending it here would have made the earlier decision pointless.
///
/// **Read-only, and structurally so** (BR-190). The screen reads one provider,
/// which reads one use case, which reads a repository with no write method on
/// it. Opening the tab, retrying after a failure, leaving and coming back write
/// nothing at all.
///
/// **The lifetime-empty face replaces the whole screen**, rather than showing
/// three sections of zeros (P7). Three zeros read as a failed load, and the one
/// thing a first-time user needs is not a chart of nothing — it is the way into
/// a study session.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxContentShell(
      title: context.l10n.progressTitle,
      // The three sections are taller than a small screen at a large text
      // scale, and W6 forbids buying the height back by shrinking anything.
      isScrollable: true,
      body: MxAsyncView<ProgressOverview>(
        value: ref.watch(progressOverviewControllerProvider),
        loadingLabel: context.l10n.progressLoadingLabel,
        data: (overview) => overview.hasLifetimeActivity
            ? _ProgressSections(overview: overview)
            : const _ProgressEmptyView(),
        // The failure never reaches the user. A Drift message names tables and
        // can carry card content (BR-52); what the reader needs to know is that
        // history is append-only and a failed read cost them nothing.
        // `liveRegion`, because the failure arrives *while the user is already
        // here*: the spinner is replaced in place, and without this a screen
        // reader says nothing at all — the person is left waiting on a screen
        // that has already given up. It is set at the call site rather than
        // inside `MxErrorState`, which is also used for errors that arrive with
        // a route rather than during one.
        error: (error, stackTrace) => Semantics(
          liveRegion: true,
          container: true,
          child: MxErrorState(
            title: context.l10n.progressErrorTitle,
            message: context.l10n.progressErrorMessage,
            retryLabel: context.l10n.progressErrorRetryAction,
            // Re-opens the read. `invalidate` rebuilds the stream provider with
            // the same `now`; the clock only moves when the day does, which is
            // `progressNowProvider`'s job.
            onRetry: () => ref.invalidate(progressOverviewControllerProvider),
          ),
        ),
      ),
    );
  }
}

/// The three sections, sharing one content column (W1, G2–G4).
///
/// `CrossAxisAlignment.stretch` is what pins the shared edges: each section
/// takes the full content width instead of the width its own text happens to
/// need, so a hero with a short streak and a chart with long labels still line
/// up on both sides.
class _ProgressSections extends StatelessWidget {
  const _ProgressSections({required this.overview});

  final ProgressOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ProgressStreakHeroWidget(overview: overview),
        const SizedBox(height: AppSpacing.xl),
        ProgressTodayWidget(today: overview.today),
        const SizedBox(height: AppSpacing.xl),
        ProgressWeekWidget(days: overview.lastSevenDays),
      ],
    );
  }
}

/// Nobody has answered a card yet (A2).
///
/// The action navigates for real. A call to action that only restates the empty
/// state is a control that says "not yet" twice, which is the mistake the
/// placeholder this screen replaced deliberately avoided by having no button at
/// all.
class _ProgressEmptyView extends StatelessWidget {
  const _ProgressEmptyView();

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.insights_outlined,
      title: context.l10n.progressEmptyTitle,
      message: context.l10n.progressEmptyMessage,
      actionLabel: context.l10n.progressEmptyAction,
      // `goNamed` on another branch's route switches the shell branch and keeps
      // that branch's own stack, which is what makes this the same arrival as
      // tapping the Study tab.
      onAction: () => context.goNamed(RouteNames.study),
    );
  }
}
