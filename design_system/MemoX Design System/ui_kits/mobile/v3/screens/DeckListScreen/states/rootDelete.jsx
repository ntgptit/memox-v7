/* LibraryOverview · state: deleteDeck — "Move to Trash" → confirm with the deletion impact (A4). Recoverable for 30 days, so no destructive emphasis and no type-to-confirm (BR-256, BR-266). Replaces v1 deleteFolder. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootDelete = function (ctx) {
  const { Ic, Dialog, DeckList, Note, target, fmt } = ctx;
  const overlay = (
    <Dialog>
      <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
        <div style={{ width: 48, height: 48, borderRadius: 16, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
          <Ic name="trash-2" size="md" color="var(--memox-on-surface-variant)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Move this deck to Trash?</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
          <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{target.name}</strong> goes to Trash with its <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{target.subs} sub-decks</strong> and <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{fmt(target.cards)} cards</strong>.
        </div>
      </div>
      <div style={{ padding: '16px 20px 4px' }}>
        <Note icon="history">Recoverable from Trash for 30 days. Any open study session on this deck ends.</Note>
      </div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
          <Ic name="trash-2" size="xs" color="var(--memox-on-primary)" />
          Move to Trash
        </button>
      </div>
    </Dialog>);
  return { body: DeckList(), overlay };
};
})();
