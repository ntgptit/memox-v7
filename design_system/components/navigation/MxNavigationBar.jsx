import React from 'react';
import { MxIcon } from '../core/MxIcon.jsx';

/**
 * The bottom bar. Render-only and deliberately ignorant: it takes an index, a
 * callback and destinations, and never navigates. Labels are always visible on
 * every destination — the M3 default leaves three unlabelled icons and one
 * labelled, which makes selection readable as colour alone.
 *
 * The row is capped at 120px per destination and centred, so two tabs on a phone
 * sit either side of the middle instead of hard against each edge.
 */
export function MxNavigationBar({ selectedIndex, onDestinationSelected, destinations }) {
  return (
    <nav className="mx-nav">
      <div className="mx-nav__row" style={{ maxWidth: destinations.length * 120 }}>
        {destinations.map((d, i) => {
          const selected = i === selectedIndex;
          return (
            <button key={d.label} type="button" className="mx-nav__dest" aria-selected={selected} onClick={() => onDestinationSelected(i)}>
              <span className="mx-nav__pill"><MxIcon name={selected ? (d.selectedIcon || d.icon) : d.icon} filled={selected} /></span>
              {d.label}
            </button>
          );
        })}
      </div>
    </nav>
  );
}
