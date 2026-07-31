import React from 'react';

import MxIcon from './MxIcon.jsx';

/**
 * A selectable pill: the control for switching between a small, fixed set of views
 * of the same content.
 *
 * Why this is not one of the others. `MxActionButton` performs something — it has
 * a variant ladder built around primary/destructive intent and no selected state,
 * because a button that stays pressed is a different idea. `MxIconButton` has no
 * label. `MxListTile` is a row, not an inline control. Nothing else held "one of
 * N, and you can see which".
 *
 * The tap target is padded to 48 while the visible shape stays at its drawn
 * height. A control that is easy to see and hard to hit is worse than one that is
 * neither.
 */
export function MxPillButton({
  label,
  isSelected,
  onPressed,
  icon,
  semanticLabel,
  className = '',
  ...rest
}) {
  return (
    <button
      type="button"
      className={[
        'mx-pill',
        isSelected ? 'mx-pill--selected' : '',
        className,
      ]
        .filter(Boolean)
        .join(' ')}
      // `aria-pressed`, not `aria-selected`: this is a toggle standing on its own,
      // not an option inside a listbox. Selection is announced rather than left to
      // the fill, which says nothing to a screen reader and nothing to a
      // colour-blind user.
      aria-pressed={isSelected}
      // Replaces the visible text for assistive technology when the label is an
      // abbreviation — "A–Z" reads as two letters, not as "sort by name". The
      // visible text is then hidden from the tree so it is not announced twice.
      aria-label={semanticLabel}
      disabled={onPressed == null}
      onClick={onPressed ?? undefined}
      {...rest}
    >
      <span className="mx-pill__shape">
        {icon ? <MxIcon name={icon} size="sm" className="mx-pill__icon" /> : null}
        <span aria-hidden={semanticLabel ? 'true' : undefined}>{label}</span>
      </span>
    </button>
  );
}

export default MxPillButton;
