import React from 'react';

/* MxBadge — count / status pill. Mirrors the shared Badge primitive.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

const TONE = {
  primary: 'var(--memox-primary)',
  success: 'var(--memox-mastery)',
  warning: 'var(--memox-streak)',
  error: 'var(--memox-error)',
  neutral: 'var(--memox-on-surface-variant)'
};

export function MxBadge({ children, tone = 'primary', soft = false, dot = false, node }) {
  const c = TONE[tone] || TONE.primary;
  if (dot) return <span className="status-dot" data-mx-node={node} style={{ background: c }} />;
  return (
    <span data-mx-node={node} style={{
      height: 22, padding: '0 8px', borderRadius: 999, flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4,
      fontSize: 12, fontWeight: 700, lineHeight: 1, whiteSpace: 'nowrap', fontVariantNumeric: 'tabular-nums',
      color: c, background: `color-mix(in srgb, ${c} 12%, transparent)`
    }}>{children}</span>
  );
}
