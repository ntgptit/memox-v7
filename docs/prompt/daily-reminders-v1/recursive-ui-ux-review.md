# Recursive UI/UX Review — Daily Reminders v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa reminder settings flow, permission recovery, geometry và accessible copy |
| **Scope** | Reminder section, time picker, permission/error states và notification/deep-link presentation |
| **Source of truth for** | Quy trình recursive UI/UX review Daily Reminders v1 |
| **Depends on** | `docs/prompt/daily-reminders-v1/implementation.md`, reminder wireframe và MemoX tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production Settings reminder states. `AUDIT_ONLY` inspect-only;
`APPLY_FIXES`/standalone sửa/rerender đệ quy. Không commit/push/PR/merge.

Inspect off, enabling, on default/custom time, permission denied with recovery,
platform unavailable, schedule error/retry, time picker and notification-tap
arrival; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin `getRect` for section
gutters/shared edges, toggle/time baselines, supporting/privacy copy width,
error/CTA placement, dialog actions and bottom-nav/safe-area clearance.

Verify copy states due-only and lock-screen disclosure without alarmist tone;
toggle state not color-only; permission request follows user action; denied flow
does not dead-end; 48dp targets, TalkBack roles/values, time localization and no
layout jump while enabling. Compare production renders to wireframe and add
geometry assertions for each fix. Clean stop when all states inspected, no
unapproved divergence/P0/P1/P2 and visual/semantics tests pass.
