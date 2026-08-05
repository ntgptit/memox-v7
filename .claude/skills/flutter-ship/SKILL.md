---
name: flutter-ship
description: Everything between "the features work" and "users are running it well" for this Flutter app — security review, performance profiling and rebuild scoping, logging abstraction and crash/analytics integration, CI pipeline with format/analyze/codegen-freshness/test/build gates, PR quality gates, signed flavored release builds, store metadata and Android/iOS submission, the pre-release checklist, and post-release monitoring. Use this skill when setting up or fixing CI, preparing a release or store submission, configuring signing or obfuscation, adding logging or analytics or crash reporting, doing a security or performance pass, or investigating crashes and metrics after a release. Covers checklist phases 16 through 22.
---

# Security, performance, observability, CI/CD and release

Covers checklist Phases 16–22. They share a trigger — the project is heading
toward release — and in practice several get touched in one session.

Read `references/ci.md` for the pipeline definition and release build commands.

## 16 · Security

Do this as a deliberate pass, not opportunistically. The checks that find real
problems:

- **No secrets in the repo, including in history.** `git log -p` for a key you
  once committed and removed still exposes it — rotate it rather than deleting
  the file.
- **CI secrets from the pipeline's secret store**, injected at build time via
  `--dart-define-from-file`.
- **Validate input at the domain boundary**, and do not trust server data
  either. A server field assumed non-null crashes the app when it is null.
- **Sanitize any HTML** before rendering it.
- **Nothing sensitive in logs**, at any level, including crash reports. Redact by
  key in the logging interceptor so it cannot be forgotten per call site.
- **Token expiry handled** without a refresh storm — see `flutter-data-layer`.
- **Remote logout** if the product needs it: a server-side revocation the client
  respects on the next 401.
- **Certificate pinning** only for genuinely high-risk apps. It breaks on
  certificate rotation and needs an update path planned before you enable it.
- **Dependency vulnerabilities**: `flutter pub outdated`, plus whatever scanner
  CI provides.
- **Obfuscate release builds**: `--obfuscate --split-debug-info=<dir>`. Keep the
  debug-info directory as a build artifact or crash reports become unreadable.
- **Minimum permissions.** Audit the Android manifest and iOS Info.plist — a
  plugin can add a permission you never asked for, and reviewers will ask about it.

## 17 · Performance

Measure before optimising. DevTools tells you where the time goes; intuition
reliably does not.

The changes that actually matter, in rough order of payoff:

- **Narrow rebuild scope.** `const` constructors, separate widget classes rather
  than `_buildX()` methods, and `ref.watch(p.select(...))` instead of watching a
  whole object.
- **Never build a long list with `Column` inside a `SingleChildScrollView`** —
  it builds every child. `ListView.builder` builds what is visible.
- **Paginate** anything unbounded, and lazy-load below the fold.
- **Keep heavy computation out of `build()`.** Anything measurable goes to an
  `Isolate` (`compute`) — parsing a large JSON payload on the UI thread is a
  visible freeze.
- **Resize and cache images.** A full-resolution photo in a 48px avatar costs
  memory proportional to the source, not the display size.
- **Dispose everything**: controllers, subscriptions, focus nodes, timers.
  `cancel_subscriptions` and `close_sinks` lints catch most of it.
- **Avoid nested scrollables** where a `CustomScrollView` with slivers works.

Profile in **profile mode**, never debug — debug-mode timings are meaningless.
Track startup time, frame rendering (jank), memory, network, database query time
and app size, and record a baseline in `docs/` so regressions are visible rather
than argued about.

## 18 · Logging, analytics, monitoring

One logging abstraction in `core/logging/`, with debug/info/warning/error. Every
layer uses it; nothing calls `print` (the architecture check enforces this).

Level comes from `EnvConfig`, so production stays quiet without code changes.

Crash reporting (Sentry or Crashlytics) goes in when release approaches, not at
project start — before there are users it only adds noise and a dependency.
Attach the app version, build number, flavor and a non-identifying device
descriptor to every report, because "crashes on some phones" is not actionable.

Never send PII. Scrub before sending, and remember that a stack trace can carry
user data in a message string.

Analytics: define the event names and parameters up front in a doc, and name
them consistently (`deck_created`, not `DeckCreated` in one place and
`created_deck` in another). Track the conversion flows the product actually
cares about, not every tap. Set an alert for a crash-rate regression — without
one, nobody notices until reviews arrive.

## 19 · CI/CD

The pipeline gates, in order (details in `references/ci.md`):

1. `dart run build_runner build --delete-conflicting-outputs`, then fail if
   the tree is dirty — **codegen first**: generated code is not committed, so
   analyze and test cannot even run before this step (the real ci.yml orders
   it this way).
2. `dart format --output=none --set-exit-if-changed .`
3. `flutter analyze` (the live workflow passes `--no-fatal-infos`).
4. `python code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v7` —
   **separate step**. This is the project's main guard and owns the checks
   `flutter analyze` cannot express, including the Riverpod rules that
   `riverpod_lint` used to cover (descoped — see `docs/wbs.md`). (No
   `--profile ci`: local and CI runs are identical by design.)
5. `.claude/skills/flutter-architecture/scripts/check_architecture.sh`
6. `flutter test` — per-PR ci.yml runs the golden-excluded subset; the full
   suite including goldens runs in `ci-full.yml`.
7. Build Android; build iOS if the runner supports it; build web if in scope.

Nothing merges on a red pipeline.

**PR quality gate**: small single-purpose scope, a description, a link to the
WBS item, screenshots or video for UI changes, test results, no unexplained new
dependency, no out-of-scope refactor, at least one approval.

**Delivery**: build per flavor, signing keys from CI secrets and never in the
repo, versioning agreed and automated, artifacts retained, staging before
production, and a rollback path that has actually been tried.

## 20–21 · Release preparation

Metadata: app name, icon, splash, package ID, version name, build number, store
description, screenshots, feature graphic, privacy policy URL, support email,
terms if needed.

**Android**: signing config, App Bundle, permission audit, target SDK meeting the
current Play requirement, R8 rules verified against a release build (obfuscation
breaks reflection-based code and you find out only in release), app links
verified, notifications tested, tested across several OS versions, uploaded to
internal testing, Play Console warnings cleared.

**iOS**: bundle ID, certificates, provisioning profiles, permission usage
descriptions (a missing one is an automatic rejection), universal links, push,
archive, TestFlight, App Store Connect warnings cleared.

Before shipping, the Phase 21 list, of which these are the ones most often
skipped and most damaging when wrong:

- [ ] **Upgrade tested from the previous released version**, not just a fresh
      install. Migration bugs only appear on upgrade.
- [ ] **Database migration verified** with real pre-existing data.
- [ ] Deep links work from a cold start.
- [ ] Offline behaviour correct.
- [ ] Analytics and crash reporting confirmed live in the release build — both
      are easy to leave misconfigured for production and nobody notices until a
      crash goes unreported.
- [ ] Release notes written; rollback plan exists; stakeholder approval.

## 22 · After release

Watch crash-free users, ANR rate, startup time, store reviews, API error rate
and the conversion flows. Triage by severity, hotfix what is critical, and take
the rest into the next cycle.

Then close the loop, which is the part usually skipped: review the KPIs against
what you predicted, update the roadmap, **remove feature flags that have
stabilised** (a permanent flag is permanent complexity and a permanent untested
code path), and schedule the technical debt recorded in `docs/wbs.md` rather
than letting it accumulate silently.
