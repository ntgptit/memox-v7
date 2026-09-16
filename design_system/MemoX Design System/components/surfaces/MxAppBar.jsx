import React from 'react';

/* MxAppBar — top app bar. 56dp; large adds an eyebrow + display title.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxAppBar({ title, eyebrow, large = false, leading, trailing, node, className = '' }) {
  if (large) {
    return (
      <header className={['appbar-lg', className].filter(Boolean).join(' ')} data-mx-node={node}
        style={{ height: 'auto', display: 'flex', flexDirection: 'column', gap: 2, paddingTop: 8, paddingBottom: 12 }}>
        {(leading || trailing) ? (
          <div style={{ display: 'flex', alignItems: 'center', width: '100%' }}>
            {leading}<div style={{ flex: 1 }} />{trailing}
          </div>
        ) : null}
        {eyebrow ? <div className="ov">{eyebrow}</div> : null}
        <div style={{ fontSize: 22, fontWeight: 700, letterSpacing: '-0.3px' }}>{title}</div>
      </header>
    );
  }
  return (
    <header className={['appbar', className].filter(Boolean).join(' ')} data-mx-node={node}>
      {leading}
      <div className="title">{title}</div>
      {trailing ? <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div> : null}
    </header>
  );
}
