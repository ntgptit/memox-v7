/* LibraryOverview · state: moveFolder
   Sheet "Move folder" → destination picker bottom sheet (scrollable list). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});

D.moveFolder = function (ctx) {
  const { Ic, Scrim, FoldersList } = ctx;
  const { BottomSheet } = window;
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false}>
        <div style={{ padding: '4px 20px 12px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Move "Korean" to…</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
            Nest it under another folder, or keep it at the top of your library.
          </div>
        </div>

        <div className="hide-scroll" style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', padding: '0 8px 8px' }}>
          {[
            { name: 'Library (root)', ic: 'home', count: '4 folders', current: true },
            { name: 'Japanese', ic: 'flag', count: '5 decks · 248 cards' },
            { name: 'Mandarin', ic: 'flag', count: '3 decks · 180 cards' },
            { name: 'Hanja & roots', ic: 'book-open', count: '2 decks · 64 cards' },
            { name: 'Archive', ic: 'archive', count: 'Hidden from Library' }
          ].map((t) =>
            <button key={t.name} disabled={t.current} style={{ width: '100%', display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: t.current ? 'default' : 'pointer', textAlign: 'left', opacity: t.current ? 0.45 : 1 }}>
              <div style={{ width: 28, height: 28, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={t.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{t.name}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{t.count}</div>
              </div>
              {t.current ?
                <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>Current</span> :
                <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />}
            </button>
          )}
        </div>

        <div style={{ padding: '8px 16px 16px', display: 'flex', gap: 8, borderTop: 'var(--memox-border-ghost)' }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
            <Ic name="folder-tree" size="xs" color="var(--memox-on-primary)" />
            Move here
          </button>
        </div>
      </BottomSheet>
    </>);
  return { body: FoldersList(), overlay };
};
})();
