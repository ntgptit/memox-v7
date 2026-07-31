import React from 'react';

/**
 * A row in a list. Deliberately generic — a String title and optional widgets,
 * never an entity. DeckTile and CardTile are built ON this, in their features.
 */
export function MxListTile({ title, subtitle, leading, trailing, onClick, isEnabled = true, isSelected = false }) {
  const classes = [
    'mx-tile',
    isSelected ? 'mx-tile--selected' : '',
    !isEnabled ? 'mx-tile--disabled' : '',
  ].filter(Boolean).join(' ');
  const inner = (
    <>
      {leading ? <span className="mx-tile__icon">{leading}</span> : null}
      <span style={{ flex: 1, minWidth: 0 }}>
        <span className="mx-tile__title" style={{ display: 'block' }}>{title}</span>
        {subtitle ? <span className="mx-tile__subtitle" style={{ display: 'block' }}>{subtitle}</span> : null}
      </span>
      {trailing ? <span className="mx-tile__icon">{trailing}</span> : null}
    </>
  );
  if (!onClick || !isEnabled) return <div className={classes}>{inner}</div>;
  return <button type="button" className={classes} onClick={onClick}>{inner}</button>;
}
