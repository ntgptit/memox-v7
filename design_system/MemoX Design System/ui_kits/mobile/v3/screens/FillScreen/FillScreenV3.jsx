/* MemoX Mobile v3 — FillScreenV3  (A18 · fill)
   Product corrections vs v1: the prompt is the meaning, the answer is the term;
   correct = same text ignoring case and outer spaces, accents matter (BR-134);
   the hint is the card's own hint, shown on request and recorded (BR-136) — a
   card without a hint has no Hint button; on a wrong answer the correct term is
   shown and the card returns in a later round (BR-138) — there is no "mark
   correct" and no "try again"; speaker removed. States: input · hint · wrong.
   ── v1 header ──
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes FillScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

/* ─────── Screen: Fill (meaning prompt + term input) ─────── */
function FillScreenV3({ go, initialState = 'input' }) {
  const accent = 'var(--memox-mastery)';
  const accentBg = 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)';
  const meaning = 'Make someone laugh / Làm cho cười, gây cười, buồn cười (Động từ, là dạng sai khiến của động từ "웃다 – cười", mang nghĩa khiến người khác bật cười hoặc thấy buồn cười).';
  const [state, setState] = useState(initialState); // 'input' | 'hint' | 'wrong'
  const hint = 'Đồng nghĩa: booking';
  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Fill" accent={accent} accentBg={accentBg} current={12} total={15} onClose={() => go('deck')} />

      {/* Context line — deck + card direction (mirrors Match's subhead) */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Nhà hàng · Review · Fill · round 2</div>
      </div>

      <div style={{ flex: 1, padding: '0 16px 0', display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0 }}>
        {/* Meaning card — prompt the user reads */}
        <div className="card" style={{
          flex: 1, padding: '20px 16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', minHeight: 160
        }}>
          <button className="icon-btn" style={{ position: 'absolute', top: 8, right: 8, width: 32, height: 32 }}>
            <Ic name="pencil" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
          <div style={{
            fontSize: 14, lineHeight: 1.55, textAlign: 'center',
            color: 'var(--memox-on-surface)', textWrap: 'pretty'
          }}>
            {meaning}
          </div>
        </div>

        {/* Answer card — input cursor in 'input' state, wrong+correct stacked in 'wrong' */}
        <div className="card" style={{
          flex: 1, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative',
          minHeight: 160,
          background: 'var(--memox-surface-container-low)'
        }}>
          {state === 'hint' &&
          <div style={{ position: 'absolute', top: 12, left: 16, right: 16, display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
              <Ic name="lightbulb" size="xs" color="var(--memox-on-surface-variant)" />
              <span>{hint}</span>
            </div>
          }

          {(state === 'input' || state === 'hint') &&
          <div style={{
            fontSize: 32, fontWeight: 700, letterSpacing: '-0.4px',
            display: 'inline-flex', alignItems: 'center', gap: 4
          }}>
              <span>reserv</span>
              <span style={{
              display: 'inline-block', width: 2, height: 30,
              background: accent,
              animation: 'fillCursorBlink 1s infinite'
            }} />
            </div>
          }

          {state === 'wrong' &&
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
              <div style={{
              fontSize: 24, fontWeight: 700, letterSpacing: '-0.3px',
              color: 'var(--memox-rating-again)',
              textDecoration: 'line-through',
              textDecorationThickness: 1
            }}>reservetion</div>
              <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.3px' }}>reservation</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--memox-warning-ink)', textTransform: 'uppercase', letterSpacing: 0.6, marginTop: 8 }}>Wrong · comes back this round</div>
            </div>
          }
        </div>
      </div>

      {/* CTAs — depends on state */}
      <div style={{ padding: '16px 16px 0', display: 'flex', justifyContent: 'center', gap: 8, flexShrink: 0 }}>
        {(state === 'input' || state === 'hint') &&
        <>
            {state === 'input' &&
            <button onClick={() => setState('hint')} className="pill-btn" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999,
            background: 'transparent', color: 'var(--memox-primary)',
            border: '1px solid var(--memox-primary)', gap: 8
          }}><Ic name="lightbulb" size="xs" color="var(--memox-primary)" />Show hint</button>}
            <button onClick={() => setState('wrong')} className="pill-btn primary" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999
          }}>Check</button>
          </>
        }
        {state === 'wrong' &&
        <button onClick={() => setState('input')} className="pill-btn primary" style={{
            height: 'var(--memox-size-button)', padding: '0 36px', borderRadius: 999
          }}>Continue</button>
        }
      </div>

      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        padding: '8px 16px 16px', flexShrink: 0,
        fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3
      }}>
        <Ic name="pencil" size="xs" color="var(--memox-on-surface-variant)" />
        <span>{state === 'wrong' ? 'Case and spaces are ignored, accents are not' : state === 'hint' ? 'Using the hint is noted; it changes nothing' : 'Type the term for this meaning, then check'}</span>
      </div>

      <style>{`@keyframes fillCursorBlink { 0%, 50% { opacity:1; } 50.01%, 100% { opacity:0; } }`}</style>
    </div>);

}

Object.assign(window, { FillScreenV3 });
})();
