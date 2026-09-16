/* MemoX Mobile — RecallScreen
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes RecallScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ─────── Screen: Recall (term card + hidden meaning card, reveal CTA) ─────── */
function RecallScreen({ go, initialRevealed = false }) {
  const accent = 'var(--memox-mastery)';
  const accentBg = 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)';
  const [revealed, setRevealed] = useState(initialRevealed);
  const meaning = 'Researcher / Nhà nghiên cứu — person who conducts research. Hán-Việt: Nghiên cứu giả (硏究者). 연구 = research, 자 = person.';
  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Recall" accent={accent} accentBg={accentBg} current={8} total={12} onClose={() => go('deck')} />

      {/* Context line — deck + card direction (mirrors Match's subhead) */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Vocab — chapter 1 · Term → meaning</div>
      </div>

      <div style={{ flex: 1, padding: '0 16px 0', display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0 }}>
        {/* Term card — always visible; this is the prompt */}
        <div className="card" style={{
          flex: 1, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', minHeight: 160
        }}>
          <button className="icon-btn" style={{ position: 'absolute', top: 8, right: 8, width: 32, height: 32 }}>
            <Ic name="pencil" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
          <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.15, textAlign: 'center' }}>
            연구자
          </div>
          <button className="icon-btn" style={{ position: 'absolute', bottom: 8, right: 8, width: 32, height: 32 }}>
            <Ic name="volume-2" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
        </div>

        {/* Meaning card — hidden (blurred) before reveal; user recalls the meaning */}
        <div className="card" style={{
          flex: 1, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          minHeight: 160,
          background: 'var(--memox-surface-container-low)'
        }}>
          {revealed ?
          <div style={{ fontSize: 14, lineHeight: 1.55, textAlign: 'center', color: 'var(--memox-on-surface)', textWrap: 'pretty' }}>
              {meaning}
            </div> :

          <div style={{
            width: 140, height: 14, borderRadius: 999,
            background: 'var(--memox-surface-container-high)',
            opacity: 0.7, filter: 'blur(2px)'
          }} />
          }
        </div>
      </div>

      <div style={{ padding: '16px 16px 0', display: 'flex', justifyContent: 'center', gap: 8, flexShrink: 0 }}>
        {!revealed &&
        <button onClick={() => setRevealed(true)} className="pill-btn primary" style={{
          height: 'var(--memox-size-button)', padding: '0 36px', borderRadius: 999
        }}>
            Show answer
          </button>
        }
        {revealed &&
        <>
            <button onClick={() => setRevealed(false)} className="pill-btn primary" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999
          }}>
              Forgot
            </button>
            <button onClick={() => setRevealed(false)} className="pill-btn primary" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999
          }}>
              Got it
            </button>
          </>
        }
      </div>

      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        padding: '8px 16px 16px', flexShrink: 0,
        fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3
      }}>
        <Ic name="check" size="xs" color="var(--memox-on-surface-variant)" />
        <span>{revealed ? 'Rate how well you recalled it' : 'Recall the meaning, then show the answer'}</span>
      </div>
    </div>);

}

Object.assign(window, { RecallScreen });
})();
