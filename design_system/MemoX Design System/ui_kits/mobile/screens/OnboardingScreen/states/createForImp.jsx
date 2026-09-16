/* Onboarding · state: createForImp — inline form: create a destination deck for an import. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Onboarding = R.Onboarding || {});

D.createForImp = function (ctx) {
  const { Ic } = ctx;
  const { BottomSheet } = window;
  const overlay = (
    <BottomSheet scrim={false} maxHeight="none">
      <div style={{ padding: '4px 20px 12px' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, padding: '4px 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)', fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', marginBottom: 8 }}>
          <Ic name="upload" size="xs" color="var(--memox-mastery)" />
          Step 1 of 2
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Where should the imported cards go?</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>We need a destination deck first. We won’t create it until you pick the file.</div>
      </div>
      <div style={{ padding: '0 20px 16px' }}>
        <div className="ov" style={{ marginBottom: 4 }}>Deck name</div>
        <div style={{ height: 44, padding: '0 16px', background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, fontSize: 14, fontWeight: 600 }}>
          <span>Imported vocabulary</span>
          <span style={{ display: 'inline-block', width: 2, height: 18, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite' }} />
        </div>
        <div style={{ padding: '8px 12px', background: 'color-mix(in srgb, var(--memox-streak) 5%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-streak) 16%, transparent)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start', marginTop: 12 }}>
          <Ic name="info" size="xs" color="var(--memox-streak)" />
          <span>If you cancel after this step, the empty deck is discarded — nothing left behind.</span>
        </div>
      </div>
      <div style={{ padding: '4px 16px 0', display: 'flex', gap: 8 }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" style={{ flex: 1.4, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 4 }}>
          Continue to import
          <Ic name="arrow-right" size="xs" color="var(--memox-on-primary)" />
        </button>
      </div>
    </BottomSheet>);
  return { overlay };
};
})();
