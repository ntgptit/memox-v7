/* LibraryOverview · state: sortFilter — the sort pill opens one sheet with the five sorts and the due-only filter (A1). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootSortFilter = function (ctx) {
  const { Ic, Scrim, OptionRow, DeckList } = ctx;
  const { BottomSheet, Toggle } = window;
  const sorts = [
    { t: 'Manual order', s: 'Drag decks to arrange them', on: true },
    { t: 'Date added', s: 'Newest first' },
    { t: 'Name', s: 'A → Z' },
    { t: 'Most due cards' },
    { t: 'Progress', s: 'Least mastered first' }
  ];
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false}>
        <div style={{ padding: '4px 20px 8px', fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>Sort & filter</div>
        <div className="ov" style={{ padding: '4px 20px 4px' }}>Sort by</div>
        <div style={{ padding: '0 4px' }}>
          {sorts.map((o, i) => <OptionRow key={o.t} title={o.t} sub={o.s} selected={!!o.on} last={i === sorts.length - 1} />)}
        </div>
        <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '4px 20px' }} />
        <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 20px' }}>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Only decks with due cards</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>Hides decks where nothing is waiting</div>
          </div>
          <Toggle on={false} />
        </div>
        <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)' }}>
          <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Done</button>
        </div>
      </BottomSheet>
    </>);
  return { body: DeckList(), overlay };
};
})();
