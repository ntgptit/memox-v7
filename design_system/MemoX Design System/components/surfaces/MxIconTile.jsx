import React from 'react';

/* MxIconTile — tinted square holding a leading glyph. Mirrors the shared IconTile.
   Contract mirrors ui_kits/mobile/screens/_shared.jsx (canonical) + components.css. */

const TILE = { sm: { box: 28, r: 8 }, md: { box: 36, r: 12 }, lg: { box: 44, r: 12 } };
const TILE_TONE = {
  accent: 'var(--memox-accent)', success: 'var(--memox-mastery)',
  warning: 'var(--memox-streak)', error: 'var(--memox-error)'
};

export function MxIconTile({ icon, tone, size = 'md', solid = false, node, className = '' }) {
  const t = TILE[size] || TILE.md;
  const seed = TILE_TONE[tone];
  const tinted = seed
    ? { background: solid ? seed : `color-mix(in srgb, ${seed} 12%, transparent)`, color: solid ? 'var(--memox-on-primary)' : seed }
    : solid ? { background: 'var(--memox-primary)', color: 'var(--memox-on-primary)' } : null;
  return (
    <span className={[seed || solid ? '' : 'icon-tile', className].filter(Boolean).join(' ')} data-mx-node={node} style={{
      width: t.box, height: t.box, borderRadius: t.r, flexShrink: 0,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center', ...tinted
    }}>
      <span className="material-symbols-rounded">{icon}</span>
    </span>
  );
}
