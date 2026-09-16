/* LibrarySearch · state: noResults — “hoc” finds nothing — accent-sensitive (SAMPLE_DATA · search[1]). Suggestion chips removed (nothing to derive them from); the accent rule is stated instead. */
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
      <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>No matches for “{query}”</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 8px' }}>
        Accents matter — “hoc” does not find “học”. Search covers deck names, card terms and meanings, and tag names.
      </div>
    </div>);
};
})();
