/* DeckDetail · state: overflow — sub-deck ⋮ → action sheet: open · study · rename · move · reorder · move to Trash. ADDED in v3 (v1 rows had no actions). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckOverflow = function (ctx) {
  const { Ic, Scrim, BottomSheet, DeckList } = ctx;
  const rows = [
    { ic: 'folder-open', label: 'Open', sub: '4 sub-decks · 800 cards' },
    { ic: 'play', label: 'Study this deck', sub: '46 due · 200 new' },
    { ic: 'pencil', label: 'Rename' },
    { ic: 'folder-tree', label: 'Move to another deck' },
    { ic: 'arrow-down-up', label: 'Reorder', sub: 'Move before or after a sibling' },
    { ic: 'trash-2', label: 'Move to Trash', sub: 'Recoverable for 30 days' }
  ];
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false} maxHeight="none">
        <div style={{ padding: '4px 16px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="icon-tile" style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="layers" size="xs" color="var(--memox-primary)" />
          </div>
          <div style={{ fontSize: 14, fontWeight: 700 }}>Danh từ · 명사</div>
        </div>
        <div style={{ padding: '4px 8px 8px' }}>
          {rows.map((a) =>
            <button key={a.label} style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
              <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={a.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{a.label}</div>
                {a.sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{a.sub}</div>}
              </div>
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
            </button>)}
        </div>
        <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
      </BottomSheet>
    </>);
  return { body: DeckList(), overlay };
};
})();
