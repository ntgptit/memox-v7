import React from 'react';
import { MxIcon } from './MxIcon.jsx';

/**
 * A low-emphasis action drawn as a bare label — the third weight, under
 * MxActionButton's filled and outlined variants.
 *
 * It carries no padding, no radius and no hover surface, and that is the point:
 * a text button with a background is an outlined button with the border turned
 * off. The label sits flush with the screen gutter, the 48px target comes from
 * `min-height` alone, and every state lives on the text itself — hover darkens
 * and underlines, focus underlines at 2px, active darkens further.
 *
 * The underline is carried by `.mx-textbtn__label`, never by the button:
 * `text-decoration` on the button inherits into icon spans and underlines the
 * glyph's ligature text.
 *
 * Colour is `--color-primary-accent`, not `--color-primary` — the accent is the
 * variant that reads as a label on the page (dark #8A8AE0, 6.26:1, where the
 * fill colour measures 3.33:1 and fails AA at label size).
 *
 * `isCompact` drops the label to `--text-label-md`, for a link sharing a row
 * with a heading set at that rung — a control larger than the thing it names
 * has the hierarchy backwards. Only the type moves; the 48 target does not.
 *
 * `semanticLabel` is for a link whose label is a VALUE rather than an action:
 * the deck list's sort control paints the order it is in, and "Recent, button"
 * tells a reader a word and not what pressing it does. The announcement
 * CONTAINS the painted label rather than replacing it (WCAG 2.5.3).
 */
export function MxTextButton({ label, onClick, icon, trailingIcon, isDisabled = false, isDestructive = false, isCompact = false, semanticLabel }) {
  return (
    <button
      type="button"
      className={'mx-textbtn' + (isDestructive ? ' mx-textbtn--destructive' : '') + (isCompact ? ' mx-textbtn--compact' : '')}
      aria-label={semanticLabel}
      onClick={onClick}
      disabled={isDisabled || !onClick}
    >
      {icon ? <MxIcon name={icon} filled size="var(--icon-sm)" /> : null}
      <span className="mx-textbtn__label">{label}</span>
      {trailingIcon ? <MxIcon name={trailingIcon} filled size="var(--icon-sm)" /> : null}
    </button>
  );
}
