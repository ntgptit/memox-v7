import React from 'react';

/* MxIconButton — icon-only button. 36px ink box, 48dp hit target via .icon-btn::after.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

export function MxIconButton({ icon, variant, size, node, className = '', onClick, ariaLabel }) {
  const cls = ['icon-btn'];
  if (className) cls.push(className);
  const style = {};
  if (size === 'sm') { style.width = 30; style.height = 30; }
  if (variant === 'danger') style.color = 'var(--memox-error)';
  if (variant === 'primary') style.color = 'var(--memox-primary)';
  return (
    <button type="button" className={cls.join(' ')} data-mx-node={node} onClick={onClick} aria-label={ariaLabel || icon} style={style}>
      <span className="material-symbols-rounded">{icon}</span>
    </button>
  );
}
