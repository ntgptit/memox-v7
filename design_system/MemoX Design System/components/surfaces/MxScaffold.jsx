import React from 'react';

/* MxScaffold — phone app shell: header → scroll body → bottom chrome. Mirrors MobileScaffold.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxScaffold({ appBar, bottomNav, fab, children, flush = false, node, className = '', style }) {
  return (
    <div className={['app', className].filter(Boolean).join(' ')} data-mx-node={node} style={style}>
      {appBar}
      <div className="scroll" style={flush ? { padding: 0 } : undefined}>{children}</div>
      {fab}
      {bottomNav}
    </div>
  );
}
