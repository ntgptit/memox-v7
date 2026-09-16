import React from 'react';

/* MxSearchDock — search field — 52px (--memox-size-input), leading glyph, trailing action.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxSearchDock({ placeholder = 'Search', value, onChange, focused = false, flat = false, trailing, node }) {
  return (
    <div role="search" data-mx-node={node} style={{
      display: 'flex', alignItems: 'center', gap: 8,
      height: 'var(--memox-size-input)', padding: '0 4px 0 16px',
      background: flat ? 'transparent' : focused ? 'var(--memox-surface-container-lowest)' : 'var(--memox-surface-container)',
      border: focused ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)',
      borderRadius: 'var(--memox-radius-input)',
      transition: 'background 160ms var(--memox-ease-standard), border-color 160ms var(--memox-ease-standard)'
    }}>
      <span className="material-symbols-rounded" style={{ color: focused ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)' }}>search</span>
      <input placeholder={placeholder} value={value} onChange={onChange} style={{
        flex: 1, minWidth: 0, border: 'none', outline: 'none', background: 'transparent',
        fontFamily: 'inherit', fontSize: 16, color: 'var(--memox-on-surface)'
      }} />
      {trailing}
    </div>
  );
}
