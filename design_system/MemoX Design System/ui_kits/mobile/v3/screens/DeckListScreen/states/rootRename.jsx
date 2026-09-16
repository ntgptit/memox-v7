/* LibraryOverview · state: renameDeck — sheet "Rename" → dialog, pre-filled name selected for overwrite (A2). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootRename = function (ctx) {
  const { Ic, Dialog, DeckList, target } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px' }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Rename deck</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
          Only the name changes — sub-decks, cards and schedules stay as they are.
        </div>
      </div>
      <div style={{ padding: '12px 20px 4px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 4 }}>
          <span className="ov">Name</span>
          <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>23 / 200</span>
        </div>
        <div style={{ minHeight: 'var(--memox-size-input)', padding: '10px 12px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 0, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)', lineHeight: 1.4 }}>
          <span style={{ background: 'color-mix(in srgb, var(--memox-primary) 22%, transparent)', borderRadius: 4, padding: '1px 1px' }}>{target.name}</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, marginLeft: 1, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite', flexShrink: 0 }} />
        </div>
      </div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Rename</button>
      </div>
    </Dialog>);
  return { body: DeckList(), overlay };
};
})();
