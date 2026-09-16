/* Onboarding · state: signingIn — Google sign-in in progress (center modal). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.signingIn = function (ctx) {
  const { Ic, Spinner, Dialog } = ctx;
  const overlay = (
    <Dialog scrim={false} size="sm">
      <div style={{ padding: '24px 24px', textAlign: 'center' }}>
        <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
          <Spinner size="lg" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Signing in to Google</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>Continue in the Google sign-in window.</div>
        <button className="pill-btn outline" style={{ height: 36, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 12 }}>Cancel</button>
      </div>
    </Dialog>);
  return { overlay };
};
})();
