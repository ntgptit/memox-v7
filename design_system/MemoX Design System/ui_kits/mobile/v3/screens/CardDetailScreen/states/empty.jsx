/* CardDetail · state: empty — a new card has no history — valid, not an error (BR-244). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.CardDetail = R.CardDetail || {});
D.empty = (ctx) => (
  <div className="card" style={{ padding: '28px 24px', textAlign: 'center' }}>
    <div style={{ width: 48, height: 48, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
      <ctx.Ic name="history" size="sm" color="var(--memox-on-surface-variant)" />
    </div>
    <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Not studied yet</div>
    <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Every answer in a learning or review session will appear here, newest first.</div>
  </div>);
})();
