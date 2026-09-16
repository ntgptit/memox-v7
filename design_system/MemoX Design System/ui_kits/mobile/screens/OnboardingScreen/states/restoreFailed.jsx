/* Onboarding · state: restoreFailed — restore error (center dialog, two paths). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.restoreFailed = function (ctx) {
  const { Ic, Dialog } = ctx;
  const overlay = (
    <Dialog scrim={false} size="md">
      <div>
        <div style={{ padding: '24px 24px 4px', textAlign: 'center' }}>
          <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', color: 'var(--memox-error)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
            <Ic name="cloud-off" size="md" color="var(--memox-error)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Restore didn’t finish</div>
          <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>
            Nothing was added to your device. You can try again, or start with a fresh deck.
          </div>
        </div>
        <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8, flexDirection: 'column' }}>
          <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 4 }}>
            <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />
            Try restore again
          </button>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Continue without restoring</button>
        </div>
      </div>
    </Dialog>);
  return { overlay };
};
})();
