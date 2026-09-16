/* MemoX Mobile — LanguageScreen · MAIN
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
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const langs = [
  { code: 'en', native: 'English', name: 'English' },
  { code: 'vi', native: 'Tiếng Việt', name: 'Vietnamese' },
  { code: 'ko', native: '한국어', name: 'Korean' },
  { code: 'ja', native: '日本語', name: 'Japanese' },
  { code: 'zh', native: '中文 (简体)', name: 'Chinese, Simplified' },
  { code: 'es', native: 'Español', name: 'Spanish' },
  { code: 'fr', native: 'Français', name: 'French' },
  { code: 'de', native: 'Deutsch', name: 'German' },
  { code: 'pt', native: 'Português', name: 'Portuguese' },
  { code: 'id', native: 'Bahasa Indonesia', name: 'Indonesian' }
];

/* ════════════ SCREEN ════════════ */
function LanguageScreen({ go, state = 'default' }) {
  const States = (window.MemoXStates && window.MemoXStates.Language) || {};
  const mod = States[state] || States.default;
  const f = (mod ? mod() : {}) || {};
  const { searching = false, changed = false } = f;
  const query = searching ? 'viet' : '';
  const selected = changed ? 'vi' : 'en';
  const list = query ? langs.filter((l) => (l.name + ' ' + l.native).toLowerCase().includes(query)) : langs;

  return (
    <div className="app">
      <StatusBar />
      <div className="appbar">
        <button className="icon-btn" onClick={() => go('settings')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700 }}>Language</div>
        <div style={{ width: 40 }} />
      </div>

      <div className="scroll">
        {changed &&
          <div role="status" style={{ display: 'flex', alignItems: 'flex-start', gap: 8, padding: '12px 16px', marginBottom: 16, background: 'color-mix(in srgb, var(--memox-primary) 7%, var(--memox-surface-bright))', borderRadius: 12 }}>
            <Ic name="refresh-cw" size="xs" color="var(--memox-primary)" />
            <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}>
              <strong style={{ fontWeight: 700 }}>Restart to finish.</strong>{' '}
              <span style={{ color: 'var(--memox-on-surface-variant)' }}>MemoX will switch to Tiếng Việt the next time you open it.</span>
            </div>
          </div>}

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, height: 44, padding: '0 16px', marginBottom: 16, background: 'var(--memox-surface-container-low)', borderRadius: 12, border: searching ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)' }}>
          <Ic name="search" size="xs" color="var(--memox-on-surface-variant)" />
          {query ?
            <span style={{ flex: 1, fontSize: 14, color: 'var(--memox-on-surface)' }}>viet</span> :
            <span style={{ flex: 1, fontSize: 14, color: 'var(--memox-on-surface-variant)' }}>Search languages</span>}
          {query && <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />}
        </div>

        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
          {list.map((l, i, a) => {
            const sel = selected === l.code;
            return (
              <div key={l.code} role="button" tabIndex={0} aria-pressed={sel} style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', cursor: 'pointer', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', background: sel ? 'color-mix(in srgb, var(--memox-primary) 6%, transparent)' : 'transparent' }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 16, fontWeight: sel ? 700 : 500, letterSpacing: '-0.1px' }}>{l.native}</div>
                  <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{l.name}</div>
                </div>
                {sel ?
                  <span style={{ width: 24, height: 24, borderRadius: 999, background: 'var(--memox-primary)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Ic name="check" size="xs" color="var(--memox-on-primary)" />
                  </span> :
                  <span style={{ width: 24, height: 24 }} />}
              </div>);
          })}
          {list.length === 0 &&
            <div style={{ padding: '28px 20px', textAlign: 'center', fontSize: 14, color: 'var(--memox-on-surface-variant)' }}>
              No languages match “{query}”.
            </div>}
        </div>

        <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 12px 16px', lineHeight: 1.5 }}>
          Sets the app’s interface language. Your cards stay in their original language.
        </div>
      </div>
    </div>);
}

Object.assign(window, { LanguageScreen });
})();
