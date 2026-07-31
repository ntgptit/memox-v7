# MxConfirmDialog

Asks the user to confirm one action.

## Use it when

An action is irreversible or expensive: delete, discard unsaved work, reset
progress. Not for information — a dialog with one button is a message, and a
message belongs in a snackbar or on the page.

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `title` / `message` | `string` | Already-localized, and **complete**. |
| `confirmLabel` / `cancelLabel` | `string` | Name the action: "Delete deck", not "OK". |
| `onConfirm` / `onCancel` | `() => void` | |
| `variant` | `'normal' \| 'destructive'` | |
| `isSubmitting` | `boolean` | Both actions inert; confirm shows a spinner. |

## It counts nothing

A caller deleting a deck knows it is taking four sub-decks and eleven cards with
it. That sentence is built at the call site, already localized and already
pluralised, and arrives as `message`. A shared dialog that knew about decks could
not be used for anything else, and one that did its own pluralisation would do it
in one language.

## It does not close itself

The caller dismisses it in its callback, **after** the work succeeded or failed. A
dialog that dismissed on press would unmount before `isSubmitting` could ever be
shown, and the user would watch the screen behind it while the delete was still
running.

## Destructive changes two things, not one

`variant: 'destructive'` styles the confirm button **and** moves the initial focus
to cancel, so a stray Enter cannot delete anything. That pairing is why it is a
variant and not an `isDestructive` flag beside a colour: a flag and a colour can be
passed independently, and the mismatch produces a dialog that looks safe and is
not.

On a `normal` dialog **neither** action is autofocused — pre-selecting "confirm"
makes the keyboard path skip the question the dialog exists to ask.

## Rules the component enforces

- **`role="alertdialog"`, `aria-modal`, labelled by the title and described by the
  message.**
- **Escape and the barrier both cancel — unless submitting.** Cancelling a delete
  that has already been sent does not un-send it.
- **The message scrolls.** The alternative is silent truncation, not an error: at a
  3× text scale on a 320-wide screen a translated message clips mid-word, and the
  user confirms a delete having read half the sentence describing it.
- **Actions wrap to a stack** when they no longer fit side by side, which is what
  happens at 320 wide and a 2× text scale.
