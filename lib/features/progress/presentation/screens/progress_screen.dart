import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../core/theme/foundations/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_empty_state.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/models/progress_overview_model.dart';
import '../controllers/progress_overview_controller.dart';
import 'progress_deck_screen.dart';
import '../widgets/sections/progress_streak_hero_widget.dart';
import '../widgets/sections/progress_today_widget.dart';
import '../widgets/sections/progress_week_widget.dart';

/// The Progress branch — one screen at two levels of detail (UC-12, UC-13).
///
/// **Two features settled into one screen.** Progress overview and Progress by
/// Deck arrived in parallel and each specified `/progress` as its own root; the
/// owner settled it as a single surface — the three overview sections as a
/// header, then the range selector, the totals and the deck rows. This class is
/// where the two meet: it owns the overview read and hands the sections to
/// [ProgressDeckScreen] as a header, so the level below still knows nothing
/// about the overview and `/progress/:deckId` keeps showing the level alone.
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
/// three sections of zeros (P7) — and after the merge that means the deck level
/// too, not only the header. The argument is the one P7 already makes: three
/// zeros read as a failed load, and a list of every deck at zero underneath them
/// says the same nothing a third time. A first-time user needs the way into a
/// study session, not a chart of it. That is different from a *range* with no
/// activity, where the level does still list every deck at zero (BR-187),
/// because there the history exists and the window is the question.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // **One read, one snapshot** (AD-13). The `error:` builder runs after this
    // method has returned, so watching in there would register a dependency
    // outside the build that owns it — safe today only because it happens to be
    // the same provider. Two watches of one provider are also two answers to one
    // question, which is the thing AD-13 names.
    final AsyncValue<ProgressOverview> overview = ref.watch(
      progressOverviewControllerProvider,
    );

    // **The shell is not here for the loaded case.** With history to show, this
    // screen is `ProgressDeckScreen` with a header, and that screen owns its own
    // `MxContentShell` — the level's title comes from its snapshot. Wrapping
    // again here would give the branch two app bars. The other three faces have
    // no level to defer to, so they carry their own shell.
    Widget shell(Widget body) => MxContentShell(
      title: context.l10n.progressTitle,
      // Taller than a small screen at a large text scale, and W6 forbids buying
      // the height back by shrinking anything.
      isScrollable: true,
      body: body,
    );

    return MxAsyncView<ProgressOverview>(
      value: overview,
      loadingFrame: shell,
      loadingLabel: context.l10n.progressLoadingLabel,
      // UC-12 UI states and P8: a live refresh and a midnight rollover are
      // transitions between two loaded states, and neither may drop the screen
      // to a spinner over data it already has.
      //
      // Both of them arrive here as Riverpod *reloads* rather than refreshes,
      // because both move `progressNowProvider` — and so does every app
      // resume, which is by far the most frequent of the three. Without this
      // flag the whole screen was replaced by a spinner for the length of a
      // full scan of `study_answers`, so the longer somebody's history, the
      // longer the flash.
      shouldSkipLoadingOnReload: true,
      data: (overview) => overview.hasLifetimeActivity
          ? ProgressDeckScreen(header: _ProgressSections(overview: overview))
          : shell(const _ProgressEmptyView()),
      // The failure never reaches the user. A Drift message names tables and
      // can carry card content (BR-52); what the reader needs to know is that
      // history is append-only and a failed read cost them nothing.
      // `liveRegion`, because the failure arrives *while the user is already
      // here*: the spinner is replaced in place, and without this a screen
      // reader says nothing at all — the person is left waiting on a screen
      // that has already given up. It is set at the call site rather than
      // inside `MxErrorState`, which is also used for errors that arrive with
      // a route rather than during one.
      error: (error, stackTrace) => shell(
        Semantics(
          liveRegion: true,
          container: true,
          child: MxErrorState(
            title: context.l10n.progressErrorTitle,
            message: context.l10n.progressErrorMessage,
            retryLabel: context.l10n.progressErrorRetryAction,
            // The read the user just asked for is still running. Riverpod calls
            // a re-read of the same dependency a *refresh*, so nothing else on
            // this face changes while it runs.
            isRetrying: overview.isRefreshing,
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
