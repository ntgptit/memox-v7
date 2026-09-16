/* MemoX Mobile v3 — AppearanceScreenV3  (A22 · theme)
   v1 theme picker kept (system · light · dark, BR-214). REMOVED accent-colour
   seeds and Display toggles — the product has no such settings.
   ── v1 header ── · MAIN
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
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

const themes = [
  { id: 'system', label: 'System', desc: 'Match phone' },
  { id: 'light', label: 'Light', desc: 'Tokyo Pure' },
  { id: 'dark', label: 'Dark', desc: 'Tokyo Nebula' }
];

const Toggle = window.Toggle;

const Preview = ({ kind }) => {
  const dark = kind === 'dark';
  const split = kind === 'system';
  const line = dark ? 'var(--memox-outline-fixed-dark)' : 'var(--memox-outline-fixed-light)';
  return (
    <div style={{ height: 62, borderRadius: 'var(--memox-radius-sm)', overflow: 'hidden', position: 'relative', background: dark ? 'var(--memox-surface-fixed-dark)' : 'var(--memox-surface-fixed-light)', border: '1px solid color-mix(in srgb, var(--memox-outline) 18%, transparent)' }}>
      {split && <div style={{ position: 'absolute', top: 0, right: 0, bottom: 0, width: '50%', background: 'var(--memox-surface-fixed-dark)' }} />}
      <div style={{ position: 'absolute', left: 8, top: 9, width: 20, height: 20, borderRadius: 4, background: 'var(--memox-seed-indigo)' }} />
      <div style={{ position: 'absolute', left: 8, top: 35, width: 28, height: 5, borderRadius: 999, background: line }} />
      <div style={{ position: 'absolute', left: 8, top: 45, width: 18, height: 5, borderRadius: 999, background: line }} />
    </div>);
};

/* ════════════ SCREEN ════════════ */
function AppearanceScreenV3({ go, state = 'system' }) {
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
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8, marginBottom: 16 }}>
          {themes.map((t) => {
            const sel = mode === t.id;
            return (
              <div key={t.id} role="button" tabIndex={0} aria-pressed={sel} style={{ borderRadius: 16, padding: 8, cursor: 'pointer', background: 'var(--memox-surface-bright)', border: sel ? '2px solid var(--memox-primary)' : '1px solid var(--memox-outline-variant)', boxShadow: sel ? 'var(--memox-shadow-soft)' : 'none' }}>
                <Preview kind={t.id} />
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 4, marginTop: 8 }}>
                  <span style={{ fontSize: 14, fontWeight: 600 }}>{t.label}</span>
                  {sel && <Ic name="check" size="xs" color="var(--memox-primary)" />}
                </div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{t.desc}</div>
              </div>);
          })}
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 16px', lineHeight: 1.5 }}>
          Applies at once — no restart, and you stay where you are.
        </div>
      </div>
    </div>);
}

Object.assign(window, { AppearanceScreenV3 });
})();
