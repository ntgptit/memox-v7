/* LibraryOverview · state: createDeck — "New deck" FAB → dialog: name + review algorithm, both required (A2, BR-11). The algorithm locks after the first card finishes learning (BR-13). Replaces v1 createFolder (colour + icon pickers removed: no such fields). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootCreate = function (ctx) {
  const { Ic, Dialog, DeckList, OptionRow, Note } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
        <div className="icon-tile" style={{ width: 44, height: 44, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
          <Ic name="layers" size="sm" color="var(--memox-primary)" />
        </div>
        <div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>New deck</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>Holds sub-decks; sub-decks hold cards.</div>
        </div>
      </div>
      <div style={{ padding: '12px 20px 4px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
          <span className="ov">Name</span>
          <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>10 / 200</span>
        </div>
        <div style={{ height: 'var(--memox-size-input)', padding: '0 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)' }}>
          <span>Tiếng Nhật</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
        </div>
      </div>
      <div style={{ padding: '12px 20px 4px' }}>
        <div className="ov" style={{ marginBottom: 4 }}>Review algorithm · required</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <OptionRow title="Eight boxes" sub="Cards move up a box each time you remember them, back to box 1 when you forget. Forgiving of long breaks." selected />
          <OptionRow title="SM-2" sub="Intervals adapt to how well you recall each card. You grade yourself: again · hard · good · easy." last />
        </div>
        <Note icon="lock" style={{ marginTop: 8 }}>Locks once the first card finishes learning. After that, only “Reset learning progress” starts a new cycle.</Note>
      </div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}><Ic name="plus" size="xs" color="var(--memox-on-primary)" />Create deck</button>
      </div>
    </Dialog>);
  return { body: DeckList(), overlay };
};
})();
