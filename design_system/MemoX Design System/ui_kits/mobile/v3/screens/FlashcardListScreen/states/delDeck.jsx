/* FlashcardList · state: delDeck — move the whole deck to Trash with its impact (A4). No type-to-confirm, no destructive emphasis — recoverable (BR-266). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.delDeck = function (ctx) {
  const { Ic, Dialog, CardList, Note } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
        <div style={{ width: 48, height: 48, borderRadius: 16, background: 'var(--memox-surface-container)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
          <Ic name="trash-2" size="md" color="var(--memox-on-surface-variant)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Move this deck to Trash?</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
          <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>Động từ · 동사</strong> goes to Trash with its <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>420 cards</strong>.
        </div>
      </div>
      <div style={{ padding: '16px 20px 4px' }}>
        <Note icon="history">Recoverable from Trash for 30 days. The open study session on this deck ends.</Note>
      </div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
          <Ic name="trash-2" size="xs" color="var(--memox-on-primary)" />
          Move to Trash
        </button>
      </div>
    </Dialog>);
  return { body: CardList(), overlay };
};
})();
