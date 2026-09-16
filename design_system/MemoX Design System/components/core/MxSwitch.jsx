import React from 'react';

/* MxSwitch — on/off toggle. 44×26, 20px thumb — the size every real screen uses.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxSwitch({ checked = false, disabled = false, onChange, node }) {
  return (
    <button type="button" role="switch" aria-checked={checked} aria-disabled={disabled || undefined}
      data-mx-node={node} disabled={disabled} onClick={() => onChange && onChange(!checked)}
      style={{
        position: 'relative', width: 44, height: 26, borderRadius: 999, flexShrink: 0, border: 'none', padding: 0,
        background: checked ? 'var(--memox-primary)' : 'var(--memox-surface-container-highest)',
        opacity: disabled ? 'var(--memox-op-disabled)' : 1,
        cursor: disabled ? 'default' : 'pointer',
        transition: 'background 160ms var(--memox-ease-standard)'
      }}>
      <span style={{
        position: 'absolute', top: 3, left: checked ? 21 : 3, width: 20, height: 20, borderRadius: 999,
        background: 'var(--memox-surface-bright)', boxShadow: 'var(--memox-shadow-soft)',
        transition: 'left 160ms var(--memox-ease-standard)'
      }} />
    </button>
  );
}
