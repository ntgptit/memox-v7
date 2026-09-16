/* LibrarySearch · state: emptyQuery — field focused, nothing typed — the initial state runs no search (BR-249). v1 hints kept; recent searches removed (nothing is stored). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});
D.emptyQuery = function (ctx) {
  const { Ic, Row, T_DECK, T_CARD, T_TAG } = ctx;
  const { Note } = window;
  return (
    <>
      <div style={{ padding: '2px 4px 8px' }}>
        <div className="ov" style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="sparkles" size="xs" color="var(--memox-on-surface-variant)" />
          Search finds
        </div>
      </div>
      <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
        {[
          { ic: 'layers', c: T_DECK, l: 'a deck name', ex: 'TOPIK, Học qua phim' },
          { ic: 'copy', c: T_CARD, l: 'a card term or meaning', ex: '학생, học sinh, homework' },
          { ic: 'tag', c: T_TAG, l: 'a tag name', ex: 'verb, Học' }
        ].map((s, i, a) =>
          <Row key={s.l} ic={s.ic} color={s.c} title={s.l} sub={s.ex}
            trailing={<Ic name="arrow-up-left" size="xs" color="var(--memox-on-surface-variant)" />}
            last={i === a.length - 1} />
        )}
      </div>
      <Note>Case does not matter, accents do: “hoc” will not find “học”. Examples, hints and pronunciation are not searched.</Note>
    </>);
};
})();
