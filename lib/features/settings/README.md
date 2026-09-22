# features/settings

App-wide preferences (UC-16, BR-210…BR-217). Read `features/deck/README.md`
first for the method.

## 1 · What business problem it owns

The four global, non-content preferences — study defaults, theme, language — plus
a reset action and an entry point into Reminder.

It owns **app-wide** policy only. A root deck's own study override
(`decks.study_config`) belongs to Deck, and the single most important rule here
is that nothing in this feature may touch it.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Route | `RouteNames.settings` |
| Screen | `SettingsScreen` |
| Contract | `AppSettingsRepository` |
| Read model | `AppSettingsModel` — four fields, one row, one stream |

## 3 · Data flow

```
widget → controller → use case → AppSettingsRepository → AppSettingsDao
                                                        → settings.drift → SQLite
```

**The contract has no `read()` method, only `watch()`.** That is deliberate: a
one-shot read would let a caller cache a snapshot and become a second source of
truth for a row that every screen shows.

`app_settings` is exactly one row, enforced by `CHECK (id = 1)` — the single-row
constraint is in the schema, not in code.

### The four settings

| Setting | Values | Default | What changes |
|---|---|---|---|
| `cardLimit` | 1–200 | 20 | Ceiling on distinct cards per study session, unless a deck overrides it |
| `newCardOrder` | `created` \| `random` | `created` | Order new cards enter a **`learning`** session only — no effect on reviewing |
| `themeMode` | `system` \| `light` \| `dark` | `system` | Resolved brightness, live |
| `language` | `system` \| `en` \| `vi` | `system` | App locale, resolved at the composition root |

`themeMode` and `language` store **the user's choice, not the resolved value**
(AD-11). `system` is a stored value, not a resolved-then-forgotten one — this is
why the enum has three members and not two.

## 4 · Providers, by role

`presentation/providers/` is wiring. `AppSettingsController` watches; four write
controllers each carry **their own** `isSubmitting` and failure.

That separation is the point, not tidiness: one shared `isLoading` would put a
spinner on a control the user did not touch.

## 5 · Where the business rules are

BR-210…BR-217. Three worth stating plainly:

- **`saveStudyDefaults` must not touch `decks.study_config`** (BR-212). An
  app-wide save silently overwriting a deck's own override is the failure this
  forbids, and `app_settings_repository_test.dart` seeds an override specifically
  to prove the write does not reach it.
- **`resetToDefaults` is not Reset learning progress** (BR-42/BR-217). It writes
  four columns. It touches no deck override, no study state, no history, no
  session, no content. Two actions named "reset" in one app is a real hazard;
  the confirmation copy exists to keep them apart.
- **Card-limit bounds are parsed by exactly one type.** `StudyCardLimit` lives in
  `features/study/domain/` and this feature imports it rather than restating
  1–200 (BR-211). Two parsers for one column would eventually accept different
  ranges on two screens.

Also: a running session's ceiling does **not** move when defaults change
(BR-139/BR-213). Nothing here enforces that — the ceiling is frozen into
`study_sessions.card_limit` at open time, so no code path in this feature can
reach it. The absence of a guard *is* the mechanism.

## 6 · How errors are converted

`ValidationFailure` carrying `StudyCardLimitProblem` (`notANumber` / `tooSmall` /
`tooLarge`) — the field shows which bound broke. Anything else is a mapped
database failure: per-group error band with retry, or a screen-level error with
retry if the initial read failed.

## 7 · How to test it

`test/features/settings/`. `app_settings_repository_test.dart` carries the BR-212
proof described above; without that seeded override the test would pass whether
or not the rule held.

## 8 · Known gaps

- **`app_settings` is one table serving two features.** This feature owns
  `card_limit`, `new_card_order`, `theme_mode`, `language`; Reminder owns
  `reminder_enabled`, `reminder_minute_of_day`, `reminder_last_delivered_at` on
  the same row. Each mapper reads only its own columns. Deliberate and
  documented, but it means "the settings row" is not wholly owned here.
- **This feature's `domain/` imports Study's `domain/`** for `StudyCardLimit` and
  `NewCardOrder`. That is allowed — the boundary rule forbids another feature's
  `data/` and `presentation/`, not its `domain/` — and BR-211 requires exactly
  one copy of the bounds. Worth knowing it is a deliberate coupling, not an
  accident. Search declines the same move for `DeckEntity` under AD-17; the
  difference is that Search wanted four fields of a large entity, while Settings
  wants the whole of a small value type.
- The Reminder entry row shows **no** Reminder state, because
  `features/settings/presentation/` importing `features/reminder/presentation/`
  is what the boundary check rejects. That is why Reminder has its own route.
