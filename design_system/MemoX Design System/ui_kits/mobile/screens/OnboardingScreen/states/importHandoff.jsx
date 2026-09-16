/* Onboarding · state: importHandoff — transient bridge before opening the import screen. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.importHandoff = function (ctx) {
  const { Ic, Spinner, Dialog } = ctx;
  const overlay = (
    <Dialog scrim={false} size="sm">
      <div style={{ padding: '24px 24px', textAlign: 'center' }}>
        <div style={{ width: 44, height: 44, borderRadius: 12, background: 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)', color: 'var(--memox-mastery)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
          <Ic name="check" size="sm" color="var(--memox-mastery)" />
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Deck ready</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>"Imported vocabulary" was created. Opening the import screen…</div>
        <Spinner size="xs" />
      </div>
    </Dialog>);
  return { overlay };
};
})();
