/* FlashcardList · state: moveTargets — move the selection: only sub-decks of the same root that hold cards or are empty, not this deck (BR-165). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.moveTargets = function (ctx) {
  const { Ic, Scrim, BottomSheet, CardList } = ctx;
  const targets = [
    { name: 'Danh từ chỉ người · 사람', path: 'Danh từ · 명사', sub: '260 cards' },
    { name: 'Nơi chốn · 장소', path: 'Danh từ · 명사', sub: '180 cards' },
    { name: 'Tính từ · 형용사', path: '한국어 TOPIK I · Từ vựng', sub: 'Empty' },
    { name: 'Trạng từ · 부사', path: '한국어 TOPIK I · Từ vựng', sub: '28 cards' }
  ];
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false}>
        <div style={{ padding: '4px 20px 12px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Move 2 cards to…</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Schedule, history, flags and tags travel with the cards. Decks in other trees are not offered.</div>
        </div>
        <div style={{ flex: 1, overflowY: 'auto', padding: '0 8px 8px' }}>
          {targets.map((t) =>
            <button key={t.name} style={{ width: '100%', display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
              <div style={{ width: 28, height: 28, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="copy" size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{t.name}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{t.path} · {t.sub}</div>
              </div>
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
            </button>)}
        </div>
        <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)' }}>
          <button className="pill-btn outline" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        </div>
      </BottomSheet>
    </>);
  return { body: CardList(true, [2, 3]), overlay };
};
})();
