/* MemoX Mobile — AppearanceScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     AppearanceScreen/
       AppearanceScreen.jsx  ← shared layout, rendered from the active theme mode
       states/               ← one file per state in window.MemoXStates.Appearance

   The three states only change which theme card is selected, so each state file
   returns its mode:
     window.MemoXStates.Appearance.<name> = () => ({ mode: 'system'|'light'|'dark' })
   and MAIN renders the shared theme/accent/display layout from it. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const selectedSeed = 'indigo';
const themes = [
  { id: 'system', label: 'System', desc: 'Match phone' },
  { id: 'light', label: 'Light', desc: 'Tokyo Pure' },
  { id: 'dark', label: 'Dark', desc: 'Tokyo Nebula' }
];
const seeds = [
  { id: 'indigo', label: 'Indigo', hex: 'var(--memox-seed-indigo)' },
  { id: 'violet', label: 'Violet', hex: 'var(--memox-seed-violet)' },
  { id: 'teal', label: 'Teal', hex: 'var(--memox-seed-teal)' },
  { id: 'rose', label: 'Rose', hex: 'var(--memox-seed-rose)' },
  { id: 'amber', label: 'Amber', hex: 'var(--memox-seed-amber)' },
  { id: 'sage', label: 'Sage', hex: 'var(--memox-seed-sage)' }
];

const Toggle = window.Toggle;

const Preview = ({ kind }) => {
  const dark = kind === 'dark';
  const split = kind === 'system';
  const line = dark ? 'var(--memox-outline-fixed-dark)' : 'var(--memox-outline-fixed-light)';
  return (
    <div style={{ height: 62, borderRadius: 8, overflow: 'hidden', position: 'relative', background: dark ? 'var(--memox-surface-fixed-dark)' : 'var(--memox-surface-fixed-light)', border: '1px solid color-mix(in srgb, var(--memox-outline) 18%, transparent)' }}>
      {split && <div style={{ position: 'absolute', top: 0, right: 0, bottom: 0, width: '50%', background: 'var(--memox-surface-fixed-dark)' }} />}
      <div style={{ position: 'absolute', left: 8, top: 9, width: 20, height: 20, borderRadius: 4, background: 'var(--memox-seed-indigo)' }} />
      <div style={{ position: 'absolute', left: 8, top: 35, width: 28, height: 5, borderRadius: 999, background: line }} />
      <div style={{ position: 'absolute', left: 8, top: 45, width: 18, height: 5, borderRadius: 999, background: line }} />
    </div>);
};

/* ════════════ SCREEN ════════════ */
function AppearanceScreen({ go, state = 'system' }) {
  const States = (window.MemoXStates && window.MemoXStates.Appearance) || {};
  const mod = States[state] || States.system;
  const cfg = (mod ? mod() : {}) || {};
  const mode = cfg.mode || 'system';

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Appearance</div>
        <div style={{ width: 40 }} />
      </div>

      <div className="scroll">
        <div className="ov" style={{ padding: '0 4px 8px' }}>Theme</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 20 }}>
          {themes.map((t) => {
            const sel = mode === t.id;
            return (
              <div key={t.id} role="button" tabIndex={0} aria-pressed={sel} style={{ borderRadius: 16, padding: 8, cursor: 'pointer', background: 'var(--memox-surface-bright)', border: sel ? '2px solid var(--memox-primary)' : '1px solid var(--memox-outline-variant)', boxShadow: sel ? '0 1px 2px rgba(15,22,56,0.05)' : 'none' }}>
                <Preview kind={t.id} />
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 4, marginTop: 8 }}>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{t.label}</span>
                  {sel && <Ic name="check" size="xs" color="var(--memox-primary)" />}
                </div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{t.desc}</div>
              </div>);
          })}
        </div>

        <div className="ov" style={{ padding: '0 4px 8px' }}>Accent color</div>
        <div className="card" style={{ marginBottom: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 4 }}>
            {seeds.map((s) => {
              const sel = selectedSeed === s.id;
              return (
                <div key={s.id} role="button" tabIndex={0} aria-pressed={sel} title={s.label} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, cursor: 'pointer' }}>
                  <span style={{ width: 38, height: 38, borderRadius: 999, background: s.hex, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', boxShadow: sel ? '0 0 0 2px var(--memox-surface-bright), 0 0 0 4px ' + s.hex : 'none' }}>
                    {sel && <Ic name="check" size="xs" color="#fff" />}
                  </span>
                  <span style={{ fontSize: 12, color: sel ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', fontWeight: sel ? 600 : 500 }}>{s.label}</span>
                </div>);
            })}
          </div>
        </div>

        <div className="ov" style={{ padding: '0 4px 8px' }}>Display</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
          {[
            { ic: 'contrast', label: 'High contrast', sub: 'Stronger borders and text', on: false },
            { ic: 'zap-off', label: 'Reduce motion', sub: 'Minimize animations and transitions', on: false, last: true }
          ].map((r) =>
            <div key={r.label} style={{ display: 'grid', gridTemplateColumns: '34px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: r.last ? 'none' : 'var(--memox-border-ghost)' }}>
              <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name={r.ic} size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{r.label}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{r.sub}</div>
              </div>
              <Toggle on={r.on} />
            </div>
          )}
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 16px', lineHeight: 1.5 }}>
          Changes apply instantly.
        </div>
      </div>
    </div>);
}

Object.assign(window, { AppearanceScreen });
})();
