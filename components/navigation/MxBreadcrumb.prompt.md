# MxBreadcrumb

Where am I, and how do I get back up.

## Use it when

The user is inside a hierarchy that goes deeper than one level and the title alone
cannot say where.

Not for: switching between siblings at a fixed top level (`MxNavigationBar`), or one
of N views of the same content (`MxPillButton` — a set, not a sequence).

## Props

| Prop | Type | Notes |
| --- | --- | --- |
| `items` | `MxBreadcrumbItem[]` | `{ label, onTap? }`, ordered top-down. |
| `semanticLabel` | `string` | Names the strip: "deck path". |

## The current step is the one with no `onTap`

Not the last one in the list. Keying it on position is the same thing only while
every caller ends its path with the current step — the first caller that does not
gets a working link drawn as though it were not one. **A control's appearance has
to follow whether it acts.**

A step with no handler renders as quiet text with `aria-current="page"`, not as a
disabled button: there is nowhere to go, so it is not a control that does nothing.

## Empty renders nothing

Not an empty bar. A path with one element says only "you are here", which the title
already said — a caller with nothing above the current step should not build this.

## Rules the component enforces

- **It scrolls horizontally and cannot overflow.** A path can be ten deep and a
  320-wide screen at a 2× text scale fits about one and a half names. Wrapping turns
  a deep path into five lines of chrome above the content it is meant to help you
  scan; collapsing the middle hides exactly the steps a user goes to a breadcrumb to
  find.
- **Left-aligned, never pinned to the end.** The steps nearest the top of the
  hierarchy are the ones a caller cannot reach any other way.
- **Every step is its own 48-tall target**, so a deep path is a row of real controls
  rather than a line of text with hot spots in it.
- **The separators are hidden from the accessibility tree.** "Chevron right" nine
  times is noise the user has to sit through; the grouping is carried by
  `semanticLabel`.
