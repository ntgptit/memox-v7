/* LibrarySearch · state: error
   Search failed — reassure (library is safe, local-first) + retry. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibrarySearch = R.LibrarySearch || {});

D.error = function (ctx) {
  const { Ic } = ctx;
  return (
    <div className="card" style={{ padding: '40px 24px', textAlign: 'center', marginTop: 8 }}>
      <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', color: 'var(--memox-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name="cloud-off" size="md" color="var(--memox-error)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Search didn't run</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 16 }}>
        Your library is safe on this device. Try again in a moment.
      </div>
      <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
        <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />
        Retry
      </button>
    </div>);
};
})();
