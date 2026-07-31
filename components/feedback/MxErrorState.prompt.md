# MxErrorState

Something failed, and the user may be able to retry.

## Use it when

A read or a write failed. **Not** when a list is simply empty — that is
`MxEmptyState`, and using this one there tells the user something is broken when
nothing is.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `title` | `string` | Required, already-localized. |
| `message` | `string` | Required, already-localized, already free of technical detail. |
| `retryLabel` + `onRetry` | `string` + `() => void` | Both, or neither. |

## It takes a string, never an error object

Two reasons, and both bite later. A shared component that knows the domain error
type drags the error layer into every UI test. And it would decide *how a failure
reads*, which is the screen's job — "couldn't load your decks" is not "couldn't
load this deck", and a deck deleted elsewhere needs a way back rather than a retry
that will fail again.

**The failure itself must not reach the user.** Map the error *type* to copy at the
call site; a raw message is written for whoever reads a log and can name a table or
carry private content.

## Both halves of the retry, or neither

Half the pair leaves an error the user can read and cannot act on — the worst of
the two states this component has.

## Rules the component enforces

- **`role="alert"`.** Unlike the loading state's `status`: a failure is worth
  interrupting for, because the user is waiting on something that is not coming.
- **The retry is `primary`, not `secondary`.** An error state has exactly one thing
  to do and nothing to weigh it against, so an outlined button there reads as
  optional.
- **The icon is `danger`.** The one place in this pair where colour carries the
  difference — and the title carries it too, so the meaning is not colour alone.
