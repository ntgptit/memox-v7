# MxAsyncView

The three cases of an async read, with one loading treatment.

## Use it when

A screen or region renders data that is fetched. Reach for this rather than
branching on `isLoading` at the call site.

## What it actually centralises

A **policy**, not four lines of branching. Every call site silently inherits an
answer to "does a refresh show a spinner", and the default is not obvious. Here it
is written down once:

| Case | Renders |
| --- | --- |
| First load, no previous value | Spinner. There is nothing to keep showing, so a screen never presents stale data as fresh. |
| **Refresh** — re-reading the same question | The previous value. Replacing a populated list with a spinner on every resume is motion in place of information. |
| **Reload** — a dependency changed | Spinner. The previous value answers a question nobody is asking any more. |
| Failure | Your `error` render function. |

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `value` | `MxAsyncValue<T>` | `{ isLoading, hasValue, hasError, data, error, isRefreshing }`. |
| `loadingLabel` | `string` | **Required**, already-localized. |
| `data` | `(value) => ReactNode` | |
| `error` | `(error, stack) => ReactNode` | **No default, on purpose.** |
| `loadingFrame` | `(loading) => ReactNode` | Chrome around the spinner. |

## Why `error` has no default

A generic "something went wrong" is how every screen ends up with the same
unhelpful sentence. "Couldn't load your decks" is not "couldn't load this deck",
and a deck deleted elsewhere needs a way back rather than a retry that will fail
again. Loading is the same everywhere; failure copy never is.

**The failure itself must not reach the user.** Map the error *type* to copy inside
your `error` function.

## `loadingFrame`

For the screen whose title comes from the data it is still loading — it cannot put
one shell around all three branches. Without this, such a screen renders a bare
spinner with no page chrome and the route below shows through. `undefined` means
the spinner is used as-is, which is right whenever the caller already sits inside a
shell.

## Generic on purpose

It knows no domain type. That is what keeps it shared.
