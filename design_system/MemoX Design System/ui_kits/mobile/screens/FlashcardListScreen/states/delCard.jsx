/* FlashcardList · state: delCard — delete one flashcard, shows the card. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});

D.delCard = function (ctx) {
  const { Ic, Dialog, CardList } = ctx;
  const overlay = (
    <>
      <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
              <div style={{ width: 34, height: 34, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-danger) 12%, transparent)', color: 'var(--memox-error)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Ic name="trash-2" size="xs" color="var(--memox-error)" />
              </div>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>Delete this flashcard?</div>
            </div>
            <div style={{ padding: '12px 16px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)', border: 'var(--memox-border-ghost)', marginTop: 4 }}>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>도서관</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>library, reading room</div>
            </div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginTop: 12 }}>
              Review history for this card will be removed. Other cards in this deck are unaffected.
            </div>
          </div>
          <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
            <button className="pill-btn" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-error-fill)', color: 'var(--memox-on-error-fill)', border: 'none', fontWeight: 600, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4 }}>
              <Ic name="trash-2" size="xs" color="var(--memox-on-error-fill)" />
              Delete card
            </button>
          </div>
      </Dialog>
    </>);
  return { body: CardList(false), overlay };
};
})();
