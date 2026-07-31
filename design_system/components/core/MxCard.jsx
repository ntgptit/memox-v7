import React from 'react';

/**
 * The app's one raised surface: a bordered panel that carries elevation.
 * The shadow appears in light and not in dark, by measurement — the dark page is
 * at the bottom of the lightness scale, so its 7.70 L* surface step already does
 * the work a shadow would.
 *
 * `onClick` does NOT turn the card into a `<button>`. It used to, and a button
 * may not contain another control — so any card that needed both a tap and a
 * trailing menu had to wrap *part* of itself in a button instead, which is how a
 * card ends up with a hover that covers its top half and two regions below that
 * look tappable and are not. The card is a plain surface with a full-bleed
 * button laid underneath its content; the content lets pointer events through,
 * and a real control asks for them back with `mx-card__control`.
 */
export function MxCard({ children, elevation = 'card', onClick, actionLabel, padding = 'var(--space-lg)', className = '', style }) {
  const classes = `mx-card mx-card--${elevation} ${className}`.trim();
  if (!onClick) return <div className={classes} style={{ padding, ...style }}>{children}</div>;
  return (
    <div className={`${classes} mx-card--actionable`} style={style}>
      <button type="button" className="mx-card__action" onClick={onClick} aria-label={actionLabel} />
      <div className="mx-card__content" style={{ padding }}>{children}</div>
    </div>
  );
}
