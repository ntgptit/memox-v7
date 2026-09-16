/* FlashcardList · state: delCard — move one card to Trash (A8). Recoverable — plain tone (BR-266); history travels with the card and comes back on restore. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.delCard = function (ctx) {
  const { Ic, Dialog, CardList, Note } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{ width: 34, height: 34, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Ic name="trash-2" size="xs" color="var(--memox-on-surface-variant)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>Move this card to Trash?</div>
        </div>
        <div style={{ padding: '12px 16px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: 'var(--memox-border-ghost)', marginTop: 4 }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>먹다</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>ăn</div>
        </div>
        <Note icon="history" style={{ marginTop: 12 }}>Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected.</Note>
      </div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
          <Ic name="trash-2" size="xs" color="var(--memox-on-primary)" />
          Move to Trash
        </button>
      </div>
    </Dialog>);
  return { body: CardList(), overlay };
};
})();
