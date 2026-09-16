/* FlashcardList · state: noMoveTarget — no other deck in this tree can hold cards right now (SAMPLE_DATA WatchCardMoveTargets · empty). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.noMoveTarget = function (ctx) {
  const { Ic, Scrim, BottomSheet, CardList } = ctx;
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false} maxHeight="none">
        <div style={{ padding: '12px 24px 8px', textAlign: 'center' }}>
          <div style={{ width: 48, height: 48, borderRadius: 16, background: 'var(--memox-surface-container)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
            <Ic name="folder-tree" size="md" color="var(--memox-on-surface-variant)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Nowhere to move these cards</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>No other deck in “한국어 TOPIK I · Từ vựng” holds cards or is empty. Create an empty sub-deck first; cards can only move within their own tree.</div>
        </div>
        <div style={{ padding: '8px 16px 16px' }}>
          <button className="pill-btn outline" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>OK</button>
        </div>
        <div style={{ height: 'env(safe-area-inset-bottom, 0px)' }} />
      </BottomSheet>
    </>);
  return { body: CardList(true, [2, 3]), overlay };
};
})();
