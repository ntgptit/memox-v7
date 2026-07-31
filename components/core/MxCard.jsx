import React from 'react';

/**
 * The app's one raised surface: a bordered panel that carries elevation.
 *
 * The shadow appears in light and not in dark, by measurement. The dark page sits
 * at the bottom of the lightness scale, so a shadow there moves it by ΔL* 0.26
 * where the surface step already moves it 7.70. Dark keeps its ladder and its
 * border; light gains a shadow and gives some border back. Neither mode decides
 * that here — `--mx-shadow-*` already resolves per mode.
 *
 * `onTap` makes the whole surface one target rather than requiring a nested
 * button. That is a generic capability, not a feature one: any card that stands
 * for a thing the user can open wants it, and hand-rolling the interaction at each
 * call site is how two call sites end up with different states.
 *
 * The card looks identical when `onTap` is null — the element changes, the paint
 * does not.
 */
export function MxCard({
  children,
  elevation = 'card',
  onTap,
  className = '',
  ...rest
}) {
  const classes = [
    'mx-card',
    `mx-card--elevation-${elevation}`,
    onTap ? 'mx-card--interactive mx-focus-ring' : '',
    className,
  ]
    .filter(Boolean)
    .join(' ');

  if (!onTap) {
    return (
      <div className={classes} {...rest}>
        {children}
      </div>
    );
  }

  // A real `<button>`, not a div with a click handler and `role="button"`. The
  // element brings the button role, focusability, keyboard activation on both
  // Enter and Space, and the disabled semantics with it; the hand-rolled version
  // gets two of those and loses the rest on the first browser that disagrees.
  //
  // No `aria-label`. The children are readable text and already name the card —
  // a label here would REPLACE that content for a screen reader rather than add
  // to it, which is the mistake the first version of this made.
  return (
    <button type="button" className={classes} onClick={onTap} {...rest}>
      {children}
    </button>
  );
}

export default MxCard;
