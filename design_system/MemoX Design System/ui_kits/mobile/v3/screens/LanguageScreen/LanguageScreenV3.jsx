/* MemoX Mobile v3 — LanguageScreenV3 · MAIN  (A22 · language)
   Product corrections vs v1: exactly three choices — follow the system, English,
   Vietnamese (unmatched system languages fall back to English); the change
   applies at once without restart (BR-215), so the restart banner and the search
   field are removed. v1 list rows kept. States: default · changed · system.
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     LanguageScreen/
       LanguageScreen.jsx  ← shared layout, rendered from { searching, changed }
       states/             ← one file per state in window.MemoXStates.Language

   The three states are flag-driven variations of one layout (search field +
   language list + optional restart banner). Each state file returns its flags:
     window.MemoXStates.Language.<name> = () => ({ searching, changed })
   and MAIN derives the query / selected language / filtered list from them. */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

const langs = [
  { code: 'system', native: 'Follow the system', name: 'Phone is set to Tiếng Việt · falls back to English' },
  { code: 'en', native: 'English', name: 'English' },
  { code: 'vi', native: 'Tiếng Việt', name: 'Vietnamese' }
];

/* ════════════ SCREEN ════════════ */
function LanguageScreenV3({ go, state = 'default' }) {
  const States = (window.MemoXStates && window.MemoXStates.Language) || {};
  const mod = States[state] || States.default;
  const f = (mod ? mod() : {}) || {};
  const { changed = false, system = false } = f;
  const selected = system ? 'system' : changed ? 'vi' : 'en';
  const list = langs;
  const { Snackbar } = window;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')} aria-label="Back">
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Language</div>
        <div style={{ width: 40 }} />
      </div>

      <div className="scroll">
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
          {list.map((l, i, a) => {
            const sel = selected === l.code;
            return (
              <div key={l.code} role="button" tabIndex={0} aria-pressed={sel} style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', cursor: 'pointer', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', background: sel ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'transparent' }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 16, fontWeight: sel ? 700 : 500, letterSpacing: '-0.1px' }}>{l.native}</div>
                  <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>{l.name}</div>
                </div>
                {sel ?
                  <span style={{ width: 24, height: 24, borderRadius: 999, background: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Ic name="check" size="xs" color="var(--memox-on-primary)" />
                  </span> :
                  <span style={{ width: 24, height: 24 }} />}
              </div>);
          })}
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 12px 16px', lineHeight: 1.5 }}>
          Applies at once — no restart, and you stay where you are. Your cards stay in their own language.
        </div>
      </div>
      {changed && <Snackbar>Đã chuyển sang Tiếng Việt</Snackbar>}
    </div>);
}

Object.assign(window, { LanguageScreenV3 });
})();
