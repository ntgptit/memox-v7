/* FlashcardList · state: searchEmpty — in-deck search returns nothing. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});

D.searchEmpty = function (ctx) {
  const { Ic } = ctx;
  const body = (
    <div className="card" style={{ padding: '32px 24px', textAlign: 'center' }}>
      <div style={{ width: 44, height: 44, borderRadius: 12, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
        <Ic name="search" size="sm" color="var(--memox-on-surface-variant)" />
      </div>
      <div style={{ fontSize: 14, fontWeight: 700, marginBottom: 4 }}>No cards match "도서"</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
        Try a different term, or clear the search to see all 142 cards.
      </div>
    </div>);
  return { body };
};
})();
