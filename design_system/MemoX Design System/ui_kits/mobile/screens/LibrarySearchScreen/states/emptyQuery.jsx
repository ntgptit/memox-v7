/* LibrarySearch · state: emptyQuery
   Search bar focused, no query — recent searches + suggestions + hint. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});

D.emptyQuery = function (ctx) {
  const { Ic, Row, T_FOLDER, T_DECK, T_CARD, T_TAG } = ctx;
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="clock" size="xs" color="var(--memox-on-surface-variant)" />
          <span className="ov">Recent searches</span>
        </div>
        <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>
          Clear
        </button>
      </div>
      <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 20 }}>
        {[
          { q: '연구자', meta: '12 results' },
          { q: 'TOPIK II', meta: '7 results · folder' },
          { q: 'verb', meta: '1 tag · 71 cards' },
          { q: '도서관', meta: '1 card' }
        ].map((r, i, a) =>
          <div key={r.q} style={{
            display: 'grid', gridTemplateColumns: '24px 1fr 24px', gap: 12, alignItems: 'center', padding: '8px 16px',
            borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', cursor: 'pointer'
          }}>
            <Ic name="rotate-ccw" size="xs" color="var(--memox-on-surface-variant)" />
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.q}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{r.meta}</div>
            </div>
            <button className="icon-btn" style={{ width: 24, height: 24 }} title="Remove">
              <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />
            </button>
          </div>
        )}
      </div>

      <div style={{ padding: '2px 4px 8px' }}>
        <div className="ov" style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="sparkles" size="xs" color="var(--memox-on-surface-variant)" />
          Try searching
        </div>
      </div>
      <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
        {[
          { ic: 'folder', c: T_FOLDER, l: 'a folder name', ex: 'Korean, Japanese' },
          { ic: 'layers', c: T_DECK, l: 'a deck', ex: 'TOPIK II — Vocab' },
          { ic: 'copy', c: T_CARD, l: 'a card term or meaning', ex: '연구자, library' },
          { ic: 'tag', c: T_TAG, l: 'a tag', ex: 'noun, verb, food' }
        ].map((s, i, a) =>
          <Row key={s.l} ic={s.ic} color={s.c} title={s.l} sub={s.ex}
            trailing={<Ic name="arrow-up-left" size="xs" color="var(--memox-on-surface-variant)" />}
            last={i === a.length - 1} />
        )}
      </div>

      <div style={{
        padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)',
        borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5,
        display: 'flex', gap: 8, alignItems: 'flex-start'
      }}>
        <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
        <span>Search is case-insensitive. Korean, English, and Vietnamese all work.</span>
      </div>
    </>);
};
})();
