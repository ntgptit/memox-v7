import React from 'react';

/* MxButton — text button. Renders the kit contract: .pill-btn + emphasis.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

const EMPHASIS = { primary: 'primary', secondary: 'secondary', outline: 'outline', ghost: '', contrast: '' };

export function MxButton({ variant = 'primary', size, icon, trailingIcon, block = false, danger = false, disabled = false, node, className = '', children, onClick, type = 'button' }) {
  const cls = ['pill-btn', EMPHASIS[variant] ?? 'primary'].filter(Boolean);
  if (className) cls.push(className);
  const style = { width: block ? '100%' : undefined, opacity: disabled ? 'var(--memox-op-disabled)' : 1 };
  if (size === 'sm') { style.height = 36; style.padding = '0 var(--memox-space-md)'; style.fontSize = 12; }
  if (size === 'lg') { style.height = 52; style.padding = '0 var(--memox-space-xl)'; }
  if (variant === 'ghost') { style.background = 'transparent'; style.color = 'var(--memox-primary)'; }
  if (variant === 'contrast') { style.background = 'var(--memox-surface-bright)'; style.color = 'var(--memox-primary)'; }
  if (danger) {
    style.background = variant === 'primary' ? 'var(--memox-error-fill)' : 'transparent';
    style.color = variant === 'primary' ? 'var(--memox-on-error-fill)' : 'var(--memox-error)';
    if (variant === 'outline') style.border = '1px solid var(--memox-error)';
  }
  return (
    <button type={type} className={cls.join(' ')} data-mx-node={node} disabled={disabled} onClick={onClick} style={style}>
      {icon ? <span className="material-symbols-rounded">{icon}</span> : null}
      {children ? <span>{children}</span> : null}
      {trailingIcon ? <span className="material-symbols-rounded">{trailingIcon}</span> : null}
    </button>
  );
}
