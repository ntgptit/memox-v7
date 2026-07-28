# Product requirements — <app name>

_Status: draft | reviewed | approved · Last updated: YYYY-MM-DD_

## Problem

<One paragraph. What goes wrong today for the user, without mentioning the app.>

## Target users

| Group | Context | What they need | Not the target |
|---|---|---|---|
| | | | |

## Core value

<One sentence: if the app did only this, it would still be worth using.>

## Platform decisions

| Decision | Choice | Consequence |
|---|---|---|
| Android | yes/no · min SDK | |
| iOS | yes/no · min version | |
| Web | yes/no | affects plugin choice, responsive scope |
| Desktop | yes/no | |
| Data posture | online-first / offline-first / hybrid | drives source of truth + sync |
| Authentication | none / required / optional | drives router guards + token handling |
| Roles & permissions | | |

## Sensitive data

| Data | Why sensitive | Protection |
|---|---|---|
| | | secure storage / encrypted db / not stored / redacted in logs |

Anything listed here must not appear in logs, analytics, or crash reports.

---

# MVP scope

## Must-have

| # | Feature | Done when |
|---|---|---|
| M1 | | |

## Should-have

| # | Feature | Done when |
|---|---|---|
| S1 | | |

## Nice-to-have

| # | Feature | Notes |
|---|---|---|
| N1 | | |

## Explicitly out of MVP

| Feature | Why deferred | Revisit when |
|---|---|---|

Recording the *why* matters — it is what stops the same feature being re-argued
every planning session.

## Primary business flows

<The two or three end-to-end journeys the app exists for. Each should map to a
vertical slice in the WBS.>

1.
2.
