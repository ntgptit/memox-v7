/* Onboarding · state: restorePrompt — after sign-in, ask before restoring (bottom sheet). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.restorePrompt = function (ctx) {
  const { Ic } = ctx;
  const { BottomSheet } = window;
  const overlay = (
    <BottomSheet scrim={false} maxHeight="none">
      <div style={{ padding: '4px 20px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
          <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Ic name="cloud-download" size="xs" color="var(--memox-streak)" />
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>We found a backup</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>alex@memox.app · 326 cards · saved 4 days ago</div>
          </div>
        </div>
        <div style={{ fontSize: 14, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
          Restoring will pull all decks, cards, and history from Drive onto this device.
        </div>
      </div>
      <div style={{ padding: '0 16px', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Not now</button>
        <button className="pill-btn primary" style={{ flex: 1.4, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 4 }}>
          <Ic name="cloud-download" size="xs" color="var(--memox-on-primary)" />
          Restore now
        </button>
      </div>
      <div style={{ textAlign: 'center', marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>You can do this later from Settings.</div>
    </BottomSheet>);
  return { overlay };
};
})();
