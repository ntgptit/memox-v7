import React from 'react';

/**
 * The app's one raised surface: a bordered panel that carries elevation.
 * The shadow appears in light and not in dark, by measurement — the dark page is
 * at the bottom of the lightness scale, so its 7.70 L* surface step already does
 * the work a shadow would.
 */
export function MxCard({ children, elevation = 'card', onClick, padding = 'var(--space-lg)', className = '', style }) {
  const classes = `mx-card mx-card--${elevation} ${className}`.trim();
  const merged = { padding, ...style };
  if (!onClick) return <div className={classes} style={merged}>{children}</div>;
  return (
    <button type="button" className={classes} style={merged} onClick={onClick}>
      {children}
    </button>
  );
}
