# features/reminder

Opt-in daily study reminder (UC-17, AD-21, BR-218…BR-229). Read
`features/deck/README.md` first for the method.

## 1 · What business problem it owns

One local notification a day, at a time the user picks, telling them cards are
owed — without a server, without push infrastructure, and saying as little as
possible about *what* is owed.

Part of this feature lives in `lib/app/reminder/`: the background worker entry
point and the platform bootstrap. That is not a layering violation — a worker
entry point is a composition root, and it cannot live inside a feature.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Route | `RouteNames.reminderSettings` — its own route, not a Settings section |
| Screen | `ReminderSettingsScreen` |
| Contracts | `ReminderSettingsRepository` (the stored row), `ReminderPlatformRepository` (capability, permission, scheduling), `ReminderWorkloadRepository` (what is due) |
| Worker | `lib/app/reminder/reminder_worker_entry.dart` |

Three contracts rather than one because they have three different failure modes
and two of them are not the database.

## 3 · Data flow

Enable is an **ordered** sequence, and the order is the first line of the use
case's own documentation:

```
capability check → OS permission request → write isEnabled:true → schedule
```

A failed schedule rolls the write back. Checking capability *before* asking for
permission matters because Android grants one prompt per app — asking on a
device that can never deliver burns it for nothing.

Disable is deliberately asymmetric: no permission ask, no confirmation, the
stored time survives, and a failed cancel is **not** rolled back. The setting is
already off, and BR-220 re-checks at fire time anyway.

Delivery runs in a background isolate, re-reads live workload, and either posts
or silently skips.

## 4 · Providers, by role

`presentation/providers/` is wiring. Separate controllers for enable, disable and
change-time — and that separation is load-bearing, not cosmetic: the retry button
dispatches to whichever command actually holds the live rejection. A single
hardwired retry once turned "disable failed" into "turn it back on".

## 5 · Where the business rules are

BR-218…BR-229. The ones that shape the whole feature:

- **Off by default; the permission prompt is not requested until the user turns
  the toggle on** (BR-218, BR-228).
- **The time is a local minute-of-day, default 20:00, never converted to UTC**
  (BR-219). A reminder at 8pm means 8pm where the user is.
- **At most one summary per local day** (BR-221), keyed on the calendar day and
  backed by a fixed notification id. A WorkManager retry after a partial failure
  must not double-post.
- **Scheduling is idempotent** (BR-227) — a unique work name plus
  `ExistingWorkPolicy.replace`. Reconcile runs at launch, on enable, on disable,
  on time change and at the tail of every fired run; without idempotence that
  would stack pending runs.
- **Scheduling is inexact, and that is accepted** (BR-226) — exact alarms need a
  permission this app does not ask for.
- **Content is capped at two counts and one deck name** (BR-222). This is
  enforced by the *shape of the type*: `ReminderSummary` has no field that could
  carry card content, a tag, or history.
- **Lead-deck ranking is deterministic** (BR-223): overdue count, then age, then
  due-today, then folded name, then id. A reminder that named a different deck
  on each run for the same data would read as a bug.

## 6 · How errors are converted

`ReminderSetupRejection`, five values, each with a different recovery:

| Value | Recovery offered |
|---|---|
| `platformUnavailable` | None — the toggle stays disabled |
| `permissionDenied` | Point at system settings, **not** a retry (Android will not ask twice) |
| `scheduleFailed` | Retry the exact command that failed |
| `cancelFailed` | Tell the truth; the setting is already off |
| `settingsWriteFailed` | Retry the local write |

`permissionDenied` offering system settings rather than a retry button is the
whole reason this enum has five members instead of one.

## 7 · How to test it

`test/features/reminder/`. The harness injects `now` and the UTC offset —
nothing in this feature reads a clock, so a delivery decision is reproducible.

## 8 · Known gaps

- **A revoked permission is not detected.** `readCapability` awaits
  `areNotificationsEnabled()` and **discards the boolean**, returning
  `unsupported` only on a thrown exception; `DeliverDailyReminderUseCase` never
  checks permission before posting. If a user grants at enable-time and later
  revokes in system settings, `isEnabled` stays `true`, the screen still reports
  `supported`, delivery runs and marks itself delivered (BR-221) — and the OS
  drops the notification silently. No BR currently requires ongoing
  re-verification, so this is a gap rather than a violation. It is recorded in
  `docs/security.md` §7.
- The two `developer.log` sites — one here, one in `lib/app/reminder/` — pass `error` / `stackTrace` through verbatim. No
  evidence any of them has ever carried content — the summary and settings types
  never flow into them — but it is an inference, not a proof.
- This feature and Settings share the `app_settings` row. Each maps only its own
  columns.
