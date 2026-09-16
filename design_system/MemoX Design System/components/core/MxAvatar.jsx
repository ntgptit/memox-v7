import React from 'react';

/* MxAvatar — account identity — image or initials fallback.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

const AV_SIZE = { sm: 32, md: 48, lg: 64 };

export function MxAvatar({ name, src, size = 'md', variant, ring = false, node }) {
  const px = AV_SIZE[size] || AV_SIZE.md;
  const bg = variant === 'accent' ? 'var(--memox-accent)' : 'var(--memox-primary)';
  const initials = name ? name.split(' ').map((w) => w[0]).slice(0, 2).join('').toUpperCase() : '';
  return (
    <span data-mx-node={node} style={{
      width: px, height: px, borderRadius: '50%', flexShrink: 0, overflow: 'hidden',
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      background: bg, color: 'var(--memox-on-primary)',
      fontSize: Math.round(px * 0.36), fontWeight: 700, letterSpacing: '-0.2px',
      boxShadow: ring ? '0 0 0 2px var(--memox-surface), 0 0 0 4px ' + bg : 'none'
    }}>
      {src ? <img src={src} alt={name || ''} style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : initials}
    </span>
  );
}
