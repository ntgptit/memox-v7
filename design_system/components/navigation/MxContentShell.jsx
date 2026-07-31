import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * The screen shell every screen uses, so padding and the app-bar shape are
 * decided once. The app bar sits on the PAGE colour with no elevation and no
 * scroll tint — during a review the header must stay still, because a colour
 * shift behind the card reads as the card itself changing.
 */
export function MxContentShell({ title, leading, actions, subheader, children, padding, isScrollable = false, fab, isCompact = false, style }) {
  const gutter = padding !== undefined ? padding : (isCompact ? 'var(--space-md)' : 'var(--space-lg)');
  // The bar's separator is derived from the body's scroll position rather than
  // drawn always, so a screen whose content fits shows no line at all.
  const [scrolled, setScrolled] = React.useState(false);
  const barClass = [
    'mx-shell__bar',
    leading ? 'mx-shell__bar--leading' : '',
    scrolled ? 'mx-shell__bar--divided' : '',
  ].filter(Boolean).join(' ');
  return (
    <div className="mx-shell" style={style}>
      {title !== undefined ? (
        <header className={barClass}>
          {leading}
          <h1 className="mx-shell__title" style={isCompact ? { fontSize: 'var(--text-title-lg-compact)' } : undefined}>{title}</h1>
          {actions}
        </header>
      ) : null}
      {subheader ? <div className="mx-shell__sub">{subheader}</div> : null}
      <div
        className={`mx-shell__body${isScrollable ? ' mx-shell__body--scroll' : ''}`}
        style={{ padding: gutter }}
        onScroll={(e) => setScrolled(e.currentTarget.scrollTop > 2)}
      >
        {children}
      </div>
      {fab ? (
        <button type="button" className="mx-shell__fab" onClick={fab.onPress} aria-label={fab.label} title={fab.label}>
          <MxIcon name={fab.icon || 'add'} filled />
        </button>
      ) : null}
    </div>
  );
}
