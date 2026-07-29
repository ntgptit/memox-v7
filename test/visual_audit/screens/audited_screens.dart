import 'package:flutter/widgets.dart';
import 'package:memox/app/fallback/route_not_found_screen.dart';
import 'package:memox/features/review/presentation/review_placeholder_screen.dart';

import '../audit_allowance.dart';
import '../screen_auditor.dart';

/// Every screen in `lib/`, and how to audit it.
///
/// **One list drives two things**, and that is the point. `screen_audit_test.dart`
/// turns each entry into a running audit; `screen_audit_coverage_test.dart`
/// refuses to pass while a screen in `lib/` has no entry. Neither can be
/// satisfied without the other.
///
/// The obvious alternative — "every `*_screen.dart` must have a matching
/// `*_audit_test.dart`" — is satisfiable by an empty file. That is the shape of
/// green this project keeps having to dig back out: a task-ID regex matching
/// nothing, lints declared where they never run, a guard scope covering zero
/// files. Requiring a *registration* rather than a *file* removes the thing that
/// could be created empty.

/// Builds the screen exactly as the app builds it.
typedef ScreenBuilder = Widget Function();

/// A screen that is audited on every test run.
@immutable
class AuditedScreen {
  const AuditedScreen(
    this.screen, {
    required this.build,
    this.anchors = const <AuditAnchor>[],
    this.allowances = const <AuditSkipAllowance>[],
  });

  /// The production class. A `Type`, not a string, so a rename breaks the build
  /// instead of quietly emptying the coverage list.
  final Type screen;

  final ScreenBuilder build;
  final List<AuditAnchor> anchors;
  final List<AuditSkipAllowance> allowances;

  String get name => screen.toString();
}

/// A screen that cannot be audited yet, and the reason.
///
/// Some screens will need a `ProviderScope` override or a database before they
/// can be pumped at all. The escape hatch has to exist, and it has to expire
/// loudly — a stale entry naming a screen that no longer exists fails the gate,
/// exactly like an unused [AuditSkipAllowance]. Without that, this list fills up
/// and becomes the thing everybody scrolls past.
@immutable
class PendingAudit {
  const PendingAudit(
    this.screen, {
    required this.rationale,
    required this.wbsTask,
  });

  final Type screen;

  final String rationale;

  /// The task that will close it. A deferral with no owner is a decision to
  /// never do it, written so it does not read like one.
  final String wbsTask;

  String get name => screen.toString();
}

Widget _buildReviewPlaceholder() => const ReviewPlaceholderScreen();

Widget _buildRouteNotFound() => const RouteNotFoundScreen();

/// The screens audited today.
///
/// These are the **production** widgets, not replicas. `test/design_preview/`
/// builds look-alikes for design exploration; auditing those would only ever
/// prove that the replica is correct.
const List<AuditedScreen> auditedScreens = <AuditedScreen>[
  AuditedScreen(ReviewPlaceholderScreen, build: _buildReviewPlaceholder),
  AuditedScreen(RouteNotFoundScreen, build: _buildRouteNotFound),
];

/// Screens deferred, with a reason and an owner.
const List<PendingAudit> pendingAudits = <PendingAudit>[];
