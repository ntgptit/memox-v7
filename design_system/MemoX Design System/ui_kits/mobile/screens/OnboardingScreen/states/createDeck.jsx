/* Onboarding · state: createDeck — bottom sheet to name the first deck. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.createDeck = function (ctx) {
  const { Ic } = ctx;
  const { BottomSheet } = window;
  const overlay = (
    <BottomSheet scrim={false} maxHeight="none">
      <div style={{ padding: '4px 20px 16px' }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Name your first deck</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>You can rename it or move it into folders anytime.</div>
      </div>
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ov" style={{ marginBottom: 4 }}>Deck name</div>
        <div style={{ height: 44, padding: '0 16px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface)' }}>
          <span>Korean — TOPIK starter</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginTop: 16, marginBottom: 4 }}>
          <Ic name="sparkles" size="xs" color="var(--memox-on-surface-variant)" />
          <span className="ov">Or try a starter</span>
        </div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4 }}>
          {['Korean basics', 'Japanese kana', 'Vocabulary', 'GRE words'].map((t) =>
            <button key={t} style={{ height: 28, padding: '0 12px', borderRadius: 999, fontSize: 12, background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', color: 'var(--memox-on-surface)', fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer' }}>{t}</button>
          )}
        </div>
      </div>
      <div style={{ padding: '4px 16px 0', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 4 }}>
          <Ic name="check" size="xs" color="var(--memox-on-primary)" />
          Create deck
        </button>
      </div>
    </BottomSheet>);
  return { overlay };
};
})();
