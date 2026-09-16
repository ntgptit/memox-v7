import React from 'react';

/* MxBottomNav — glass bottom nav, 4 destinations, active pill behind the icon.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxBottomNav({ items = [], value, onChange, node }) {
  return (
    <div className="bottom-nav-wrap" data-mx-node={node}>
      <nav className="bottom-nav" role="navigation" aria-label="Primary">
        {items.map((it) => {
          const active = it.id === value;
          return (
            <button key={it.id} type="button" aria-current={active ? 'page' : undefined} aria-label={it.label}
              className={'bn-item' + (active ? ' active' : '')} onClick={() => onChange && onChange(it.id)}>
              <span className="bn-pill"><span className="material-symbols-rounded">{it.icon}</span></span>
              <span>{it.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
}
