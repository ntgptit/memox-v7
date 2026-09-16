import React from 'react';

/* MxChip — filter / choice chip. Pill, 32px, tonal when selected.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

const CHIP_TONE = { accent: 'var(--memox-accent)', ghost: 'var(--memox-on-surface-variant)' };

export function MxChip({ label, icon, selected = false, variant, node, onClick, children }) {
  const c = CHIP_TONE[variant] || 'var(--memox-primary)';
  return (
    <button type="button" data-mx-node={node} onClick={onClick} style={{
      height: 32, padding: icon ? '0 14px 0 10px' : '0 16px', borderRadius: 999,
      display: 'inline-flex', alignItems: 'center', gap: 4,
      fontSize: 12, fontWeight: 700, fontFamily: 'inherit', cursor: 'pointer',
      border: selected ? 'none' : '1px solid var(--memox-outline-variant)',
      color: selected ? c : 'var(--memox-on-surface-variant)',
      background: selected ? `color-mix(in srgb, ${c} 14%, transparent)` : 'transparent'
    }}>
      {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
      {label || children}
    </button>
  );
}
