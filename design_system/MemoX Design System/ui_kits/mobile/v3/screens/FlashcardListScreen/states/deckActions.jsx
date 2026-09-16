/* FlashcardList · state: deckActions — app-bar ⋮ → deck actions: study · import · export · rename · move · Trash (A8 / A11 / A12). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.deckActions = function (ctx) {
  const { Ic, Scrim, BottomSheet, CardList } = ctx;
  const rows = [
    { ic: 'play', label: 'Study this deck', sub: '40 due · 100 new' },
    { ic: 'download', label: 'Import cards', sub: 'CSV, TSV, XLSX or pasted text' },
    { ic: 'upload', label: 'Export all 420 cards', sub: 'CSV · TSV · XLSX — content only' },
    { ic: 'pencil', label: 'Rename' },
    { ic: 'folder-tree', label: 'Move to another deck' },
    { ic: 'trash-2', label: 'Move to Trash', sub: 'Recoverable for 30 days' }
  ];
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false} maxHeight="none">
        <div style={{ padding: '4px 16px 8px', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="icon-tile" style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name="copy" size="xs" color="var(--memox-primary)" />
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 700 }}>Động từ · 동사</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>420 cards · 한국어 TOPIK I · Từ vựng</div>
          </div>
        </div>
        <div style={{ padding: '0 8px 8px' }}>
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
  return { body: CardList(), overlay };
};
})();
