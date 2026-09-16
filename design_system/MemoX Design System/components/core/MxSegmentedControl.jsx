import React from 'react';

/* MxSegmentedControl — 2–3 exclusive choices in a tonal track.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxSegmentedControl({ segments = [], value, onChange, block = false, node }) {
  return (
    <div data-mx-node={node} style={{
      display: block ? 'flex' : 'inline-flex', width: block ? '100%' : undefined,
      padding: 4, borderRadius: 999, gap: 2, background: 'var(--memox-surface-container)'
    }}>
      {segments.map((s) => {
        const v = typeof s === 'string' ? s : s.value;
        const label = typeof s === 'string' ? s : s.label;
        const icon = typeof s === 'object' ? s.icon : null;
        const active = v === value;
        return (
          <button key={v} type="button" onClick={() => onChange && onChange(v)} style={{
            flex: block ? 1 : undefined, padding: '4px 16px', borderRadius: 999, border: 'none',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4,
            fontSize: 12, fontWeight: 700, fontFamily: 'inherit', cursor: 'pointer',
            background: active ? 'var(--memox-surface-container-lowest)' : 'transparent',
            color: active ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)',
            boxShadow: active ? 'var(--memox-shadow-soft)' : 'none'
          }}>
            {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
            {label}
          </button>
        );
      })}
    </div>
  );
}
