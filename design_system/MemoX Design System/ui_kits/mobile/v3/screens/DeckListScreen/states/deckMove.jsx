/* DeckDetail · state: moveSheet — move a sub-deck: every candidate target carries its eligibility reason (A3 · SAMPLE_DATA WatchDeckMoveTargets). v1 sheet, targets corrected. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckMove = function (ctx) {
  const { Ic, Scrim, BottomSheet, DeckList } = ctx;
  const targets = [
    { name: '한국어 TOPIK I · Từ vựng', depth: 1, why: 'Already the parent' },
    { name: 'Động từ · 동사', depth: 2, why: 'Holds cards' },
    { name: 'Danh từ · 명사', depth: 2, why: 'This deck' },
    { name: 'Danh từ chỉ người · 사람', depth: 3, why: 'Inside this deck' },
    { name: 'Tính từ · 형용사', depth: 2, ok: true, sub: 'Empty' },
    { name: 'Tiếng Anh giao tiếp hằng ngày', depth: 1, why: 'Different review algorithm' },
    { name: 'IELTS › … › Cấp 8', depth: 8, why: 'Would go past level 10' }
  ];
  const overlay = (
    <>
      <Scrim />
      <BottomSheet scrim={false}>
        <div style={{ padding: '4px 20px 12px' }}>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Move “Danh từ · 명사” to…</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
            Its 4 sub-decks and 800 cards come along, schedules included. Only decks in the same review algorithm can receive it.
          </div>
        </div>
        <div className="hide-scroll" style={{ flex: 1, overflowY: 'auto', overflowX: 'hidden', padding: '0 8px 8px' }}>
          {targets.map((t) =>
            <button key={t.name} disabled={!t.ok} aria-disabled={!t.ok} style={{ width: '100%', display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', paddingLeft: 8 + Math.min(t.depth - 1, 3) * 12, background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: t.ok ? 'pointer' : 'default', textAlign: 'left', opacity: t.ok ? 1 : 0.55 }}>
              <div style={{ width: 28, height: 28, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="layers" size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{t.name}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{t.ok ? `Level ${t.depth} · ${t.sub}` : t.why}</div>
              </div>
              {t.ok ? <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" /> : <Ic name="ban" size="xs" color="var(--memox-outline)" />}
            </button>)}
        </div>
        <div style={{ padding: '8px 16px 16px', display: 'flex', gap: 8, borderTop: 'var(--memox-border-ghost)' }}>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
          <button className="pill-btn primary" disabled style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, opacity: 'var(--memox-op-disabled)' }}>
            <Ic name="folder-tree" size="xs" color="var(--memox-on-primary)" />
            Move here
          </button>
        </div>
      </BottomSheet>
    </>);
  return { body: DeckList(), overlay };
};
})();
