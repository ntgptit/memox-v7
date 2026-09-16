/* MemoX Mobile — MatchScreen
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes MatchScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ─────── Screen: Match (pair fronts & backs) ─────── */
function MatchScreen({ go }) {
  // 10 tiles → 5 pairs (board fills the viewport to the bottom, no dead space).
  // State per tile: 'idle' | 'selected' | 'matched'
  const initial = [
  { id: 1, text: '공부하다', kind: 'front', pair: 1, state: 'matched' },
  { id: 2, text: 'to study', kind: 'back', pair: 1, state: 'matched' },
  { id: 3, text: '먹다', kind: 'front', pair: 2, state: 'selected' },
  { id: 4, text: 'to eat', kind: 'back', pair: 2, state: 'idle' },
  { id: 5, text: '하늘', kind: 'front', pair: 3, state: 'idle' },
  { id: 6, text: 'sky', kind: 'back', pair: 3, state: 'idle' },
  { id: 7, text: '도서관', kind: 'front', pair: 4, state: 'idle' },
  { id: 8, text: 'library', kind: 'back', pair: 4, state: 'idle' },
  { id: 9, text: '친구', kind: 'front', pair: 5, state: 'idle' },
  { id: 10, text: 'friend', kind: 'back', pair: 5, state: 'idle' }];

  const [tiles, setTiles] = useState(initial);
  const totalPairs = 5;
  const pairsLeft = totalPairs - tiles.filter((t) => t.state === 'matched').length / 2;

  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Match" current={1} total={5} onClose={() => go('deck')} />

      {/* Pulled up 6px: the appbar centers its 4px bar, leaving ~26px of dead
          space below it — this balances the gap above/below the label at ~20px. */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Board 1 of 3 · {pairsLeft} pairs left</div>
      </div>

      <div style={{ flex: 1, minHeight: 0, padding: '0 16px 8px', display: 'grid', gridTemplateColumns: '1fr 1fr', gridTemplateRows: 'repeat(5, 1fr)', gap: 8 }}>
        {tiles.map((t) => {
          const matched = t.state === 'matched';
          const selected = t.state === 'selected';
          return (
            <div key={t.id} style={{
              minHeight: 0,
              borderRadius: 12,
              padding: '16px 12px',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              textAlign: 'center',
              background: matched ?
              'color-mix(in srgb, var(--memox-mastery) 12%, transparent)' :
              selected ?
              'var(--memox-primary)' :
              'var(--memox-surface-container-lowest)',
              color: matched ?
              'var(--memox-mastery)' :
              selected ?
              'var(--memox-on-primary)' :
              'var(--memox-on-surface)',
              border: matched ?
              '1px solid color-mix(in srgb, var(--memox-mastery) 30%, transparent)' :
              selected ?
              '1px solid var(--memox-primary)' :
              'var(--memox-border-ghost)',
              fontSize: t.kind === 'front' ? 18 : 14,
              fontWeight: t.kind === 'front' ? 700 : 600,
              letterSpacing: t.kind === 'front' ? '-0.4px' : 0,
              opacity: matched ? 0.7 : 1,
              transition: 'all 200ms cubic-bezier(0.2,0,0,1)'
            }}>
              {matched && <Ic name="check" size="xs" color="var(--memox-mastery)" />}
              <span style={{ marginLeft: matched ? 4 : 0 }}>{t.text}</span>
            </div>);

        })}
      </div>

      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        padding: '8px 16px 16px',
        fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3
      }}>
        <Ic name="check" size="xs" color="var(--memox-on-surface-variant)" />
        <span>Tap a term, then its meaning to match</span>
      </div>
    </div>);

}

Object.assign(window, { MatchScreen });
})();
