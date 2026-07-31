# MxEmptyState

There is nothing to display, and that is fine.

## Use it when

A list is empty because the user has finished, has not started, or has filtered
everything out. **Nothing has failed.**

If something failed, use `MxErrorState`. Getting this wrong is the whole point of
the two being separate components: "you have finished everything due today" is good
news, and rendering it in error styling tells the user something is broken when
nothing is (BR-29).

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `title` | `string` | Required, already-localized. |
| `message` | `string` | Optional second line, quieter. |
| `actionLabel` + `onAction` | `string` + `() => void` | Both, or neither. |
| `icon` | `MxIconName` | Defaults to `check-circle`, drawn at `lg`. |

## Both halves of the action, or neither

With only a label the button renders and does nothing; with only a callback it
never renders at all. Either way the screen looks deliberately action-free and no
test fails, so the component warns rather than letting it pass quietly.

## Rules the component enforces

- **The icon is `primary`, not `danger`.** That colour is the difference between
  "you are done" and "this broke".
- **The action is `primary`.** One thing to do, nothing to weigh it against — an
  outlined button on an otherwise empty screen reads as optional.
- **It scrolls.** A translated message at a 3× text scale clips rather than
  erroring, which is a bug nobody's test catches.

## Copy

The title is the state, the message is what to do about it. "No cards due today" /
"Come back tomorrow, or add a deck to study ahead." Both arrive localized — the
component reads no catalogue.
