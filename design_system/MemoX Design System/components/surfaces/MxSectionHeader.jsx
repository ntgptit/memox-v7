import React from 'react';

/* MxSectionHeader — overline label above a group, with an optional trailing action.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxSectionHeader({ title, caption, action, onAction, node }) {
  return (
    <div data-mx-node={node} style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8, padding: '0 4px 8px' }}>
      <div style={{ minWidth: 0 }}>
        <div className="ov">{title}</div>
        {caption ? <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{caption}</div> : null}
      </div>
      {action ? (
        <span role="button" tabIndex={0} onClick={onAction} style={{ fontSize: 14, fontWeight: 700, color: 'var(--memox-primary)', cursor: 'pointer', whiteSpace: 'nowrap' }}>{action}</span>
      ) : null}
    </div>
  );
}
