/* TagManagement · state: empty — no tags at all. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});

D.empty = function (ctx) {
  const { Ic } = ctx;
  const body = (
    <div className="card" style={{ padding: '40px 24px', textAlign: 'center' }}>
      <div style={{ width: 56, height: 56, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name="tag" size="lg" color="var(--memox-primary)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>No tags yet</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
        Tags appear here as you add them when creating or editing flashcards.
      </div>
      <button className="pill-btn primary" style={{ height: 38, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
        <Ic name="layers" size="xs" color="var(--memox-on-primary)" />
        Go to library
      </button>
    </div>);
  return { body };
};
})();
