/* DeckDetail · state: empty — an empty sub-deck (content type unset) accepts either a card or a sub-deck as its first child (BR-61). v1 "unlocked" composition, copy corrected. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckEmpty = function (ctx) {
  const { Ic, Note } = ctx;
  const body = (
    <div style={{ marginTop: 4 }}>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '4px 16px 4px 8px', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', borderRadius: 999, fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', marginBottom: 12 }}>
        <Ic name="folder-open" size="xs" color="var(--memox-primary)" />
        Empty deck
      </div>
      <div className="card" style={{ padding: '24px 20px', textAlign: 'center', marginBottom: 16 }}>
        <div style={{ width: 60, height: 60, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
          <Ic name="folder-open" size="lg" color="var(--memox-primary)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>What goes in here?</div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, padding: '0 4px' }}>
          Add cards to study them here, or nest sub-decks to organise further. A deck holds one or the other.
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <button className="pill-btn primary" style={{ flex: 1, height: 48, borderRadius: 12, fontSize: 14, gap: 8 }}>
          <Ic name="plus" size="sm" color="var(--memox-on-primary)" />
          <span>New card</span>
        </button>
        <button className="pill-btn" style={{ flex: 1, height: 48, borderRadius: 12, fontSize: 14, gap: 8, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>
          <Ic name="layers" size="sm" color="var(--memox-primary)" />
          <span>New sub-deck</span>
        </button>
      </div>
      <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, background: 'transparent', color: 'var(--memox-primary)', border: 'none', marginBottom: 16 }}>
        <Ic name="upload" size="xs" color="var(--memox-primary)" />
        Import cards from a file
      </button>
      <Note>The first card or sub-deck decides what this deck holds. Once it is empty again, both options come back.</Note>
    </div>);
  return { body };
};
})();
