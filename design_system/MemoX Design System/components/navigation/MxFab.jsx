import React from 'react';

/* MxFab — extended FAB — 52dp, radius-lg. Position comes from .fab.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxFab({ icon, label, variant, round = false, node, onClick }) {
  const isRound = round || !label;
  const style = isRound ? { width: 52, padding: 0, justifyContent: 'center' } : undefined;
  return (
    <button type="button" className={'fab' + (variant ? ' fab--' + variant : '')} data-mx-node={node} onClick={onClick} aria-label={label || icon} style={style}>
      {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
      {label ? <span>{label}</span> : null}
    </button>
  );
}
