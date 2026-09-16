/* LibrarySearch · state: noResults
   Query has no matches — spelling hint + alternative keyword chips. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});

D.noResults = function (ctx) {
  const { query, Ic } = ctx;
  return (
    <div className="card" style={{ padding: '36px 24px', textAlign: 'center', marginTop: 8 }}>
      <div style={{ width: 52, height: 52, borderRadius: 16, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name="search-x" size="md" color="var(--memox-on-surface-variant)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>No matches for "{query}"</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16, padding: '0 8px' }}>
        Check the spelling, or try a shorter keyword. Search runs across folders, decks, cards, and tags.
      </div>
      <div style={{ display: 'flex', gap: 4, justifyContent: 'center', flexWrap: 'wrap' }}>
        {['phrase', 'phrasal', 'phrasing'].map((s) =>
          <button key={s} style={{
            height: 28, padding: '0 12px', borderRadius: 999, fontSize: 12,
            background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)',
            border: 'none', fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4
          }}>
            <Ic name="search" size="xs" color="var(--memox-primary)" />
            {s}
          </button>
        )}
      </div>
    </div>);
};
})();
