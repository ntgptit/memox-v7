/* Onboarding · state: restoring — restore in progress (center modal + progress). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.restoring = function (ctx) {
  const { Spinner, Dialog } = ctx;
  const overlay = (
    <Dialog scrim={false} size="md">
      <div style={{ padding: '24px 24px', textAlign: 'center' }}>
        <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
          <Spinner size="lg" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Restoring your library</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>Pulling 326 cards from Drive. Don’t close the app yet.</div>
        <div style={{ height: 5, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
          <div style={{ height: '100%', width: '42%', background: 'var(--memox-primary)', borderRadius: 999, animation: 'memoxProgPulse 1.4s ease-in-out infinite' }} />
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 8, fontVariantNumeric: 'tabular-nums' }}>136 of 326</div>
      </div>
    </Dialog>);
  return { overlay };
};
})();
