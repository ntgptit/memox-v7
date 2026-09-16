/* MemoX Mobile — StatsScreen
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes StatsScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ─────── Screen: Stats ─────── */
function StatsScreen({ go }) {
  const bars = [3, 5, 8, 4, 9, 6, 11];
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg"><div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Stats</div></div>
      <div className="scroll">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 16 }}>
          <div className="card">
            <div className="ov">Reviews today</div>
            <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.6px', fontVariantNumeric: 'tabular-nums' }}>47</div>
            <div style={{ fontSize: 12, color: 'var(--memox-mastery)', fontWeight: 600 }}>+12 vs yesterday</div>
          </div>
          <div className="card">
            <div className="ov">Retention</div>
            <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.6px', fontVariantNumeric: 'tabular-nums' }}>88<span style={{ fontSize: 16, color: 'var(--memox-on-surface-variant)' }}>%</span></div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>7-day rolling</div>
          </div>
        </div>

        <div className="card" style={{ marginBottom: 16 }}>
          <div className="ov" style={{ marginBottom: 12 }}>This week</div>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 120, padding: '4px 0' }}>
            {bars.map((b, i) =>
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, height: '100%', justifyContent: 'flex-end' }}>
                <div style={{ width: '100%', height: `${b / 12 * 100}%`, background: 'var(--memox-primary)', borderRadius: 4 }} />
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 600 }}>{days[i]}</div>
              </div>
            )}
          </div>
        </div>

        <div className="ov" style={{ marginBottom: 8 }}>Mastery by deck</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {[
          { n: 'TOPIK II Vocab', p: 0.75 },
          { n: 'Genki Ch. 1–5', p: 0.52 },
          { n: 'HSK 1', p: 0.18 },
          { n: 'Hanja Roots', p: 0.88 }].
          map((d, i, a) =>
          <div key={i} style={{ padding: '16px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: 14 }}>
                <span style={{ fontWeight: 500 }}>{d.n}</span>
                <span style={{ fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{Math.round(d.p * 100)}%</span>
              </div>
              <div style={{ height: 6, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
                <div style={{ height: '100%', width: `${d.p * 100}%`, background: masteryColor(d.p) }} />
              </div>
            </div>
          )}
        </div>
      </div>
      <BottomNav active="stats" onChange={go} />
    </div>);

}

Object.assign(window, { StatsScreen });
})();
