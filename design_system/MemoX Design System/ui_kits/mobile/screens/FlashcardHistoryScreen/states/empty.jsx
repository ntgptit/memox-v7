/* FlashcardHistory · state: empty — no attempts yet; study CTA. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardHistory = R.FlashcardHistory || {});

D.empty = function (ctx) {
  const { Ic } = ctx;
  return (
    <div className="card" style={{ padding: '40px 24px 32px', textAlign: 'center' }}>
      <div style={{ width: 60, height: 60, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name="clock" size="lg" color="var(--memox-primary)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 8 }}>No reviews yet</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 20 }}>
        History appears here after you study this card. Open it in a session and your attempts will start showing up.
      </div>
      <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
        <Ic name="play" size="xs" color="var(--memox-on-primary)" />
        Study this card now
      </button>
    </div>);
};
})();
