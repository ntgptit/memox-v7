/* MemoX Mobile v3 — RecallScreenV3  (A18 · recall)
   Product corrections vs v1: a 20-second countdown drives the turn (BR-128) —
   revealing before it runs out leads to a two-choice self-check (remembered /
   forgot) that advances by itself; running out counts as wrong and waits for
   Continue (BR-159, BR-160); the speaker and edit buttons are removed (no audio;
   cards are not edited mid-session); round counter added. Split cards, reveal
   CTA and caption are v1's. States: hidden · revealed · timedOut.
   ── v1 header ──
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes RecallScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar } = window;

/* ─────── Screen: Recall (term card + hidden meaning card, reveal CTA) ─────── */
function RecallScreenV3({ go, initialRevealed = false }) {
  const accent = 'var(--memox-mastery)';
  const accentBg = 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)';
  const timedOut = initialRevealed === 'timedOut';
  const [revealed, setRevealed] = useState(initialRevealed === true);
  const left = timedOut ? 0 : revealed ? 9 : 14;
  const meaning = 'sự đặt chỗ trước — booking a table, seat or room in advance.';
  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Recall" accent={accent} accentBg={accentBg} current={8} total={12} onClose={() => go('deck')} />

      {/* Context line — deck + card direction (mirrors Match's subhead) */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Nhà hàng · Review · Recall · round 1</div>
      </div>

      {/* 20-second timer — the turn's clock (BR-128). Pauses when the app is in the background. */}
      <div style={{ padding: '0 16px 12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: timedOut ? 'var(--memox-warning-ink)' : 'var(--memox-on-surface-variant)', marginBottom: 4 }}>
          <span>{timedOut ? 'Time is up' : revealed ? 'Revealed with time left' : 'Time to recall'}</span>
          <span>{left}s / 20s</span>
        </div>
        <div style={{ height: 6, borderRadius: 999, background: 'var(--memox-surface-container)', overflow: 'hidden' }} role="progressbar" aria-valuemin={0} aria-valuemax={20} aria-valuenow={left}>
          <div style={{ height: '100%', width: `${left / 20 * 100}%`, background: timedOut ? 'var(--memox-warning)' : accent, borderRadius: 999 }} />
        </div>
      </div>

      <div style={{ flex: 1, padding: '0 16px 0', display: 'flex', flexDirection: 'column', gap: 8, minHeight: 0 }}>
        {/* Term card — always visible; this is the prompt */}
        <div className="card" style={{
          flex: 1, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          position: 'relative', minHeight: 160
        }}>
          <div className="ov" style={{ position: 'absolute', top: 16, left: 20 }}>Term</div>
          <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.15, textAlign: 'center', overflowWrap: 'anywhere' }}>
            reservation
          </div>
        </div>

        {/* Meaning card — hidden (blurred) before reveal; user recalls the meaning */}
        <div className="card" style={{
          flex: 1, padding: '16px',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          minHeight: 160,
          background: 'var(--memox-surface-container-low)'
        }}>
          {revealed || timedOut ?
          <div style={{ fontSize: 16, lineHeight: 1.55, textAlign: 'center', color: 'var(--memox-on-surface)', textWrap: 'pretty' }}>
              {meaning}
              {timedOut && <div style={{ marginTop: 12, fontSize: 12, fontWeight: 700, color: 'var(--memox-warning-ink)', textTransform: 'uppercase', letterSpacing: 0.6 }}>Counted as forgot</div>}
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
        {timedOut ?
        <button className="pill-btn primary" style={{ height: 'var(--memox-size-button)', padding: '0 36px', borderRadius: 999 }}>
            Continue
          </button> :
        !revealed ?
        <button onClick={() => setRevealed(true)} className="pill-btn primary" style={{
          height: 'var(--memox-size-button)', padding: '0 36px', borderRadius: 999
        }}>
            Show the meaning
          </button> :
        <>
            <button onClick={() => setRevealed(false)} className="pill-btn outline" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999
          }}>
              Forgot
            </button>
            <button onClick={() => setRevealed(false)} className="pill-btn primary" style={{
            flex: 1, maxWidth: 160, height: 'var(--memox-size-button)', borderRadius: 999
          }}>
              Remembered
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
        <span>{timedOut ? 'This card comes back in a later round' : revealed ? 'Be honest — the next card follows automatically' : 'Recall the meaning before the time runs out'}</span>
      </div>
    </div>);

}

Object.assign(window, { RecallScreenV3 });
})();
