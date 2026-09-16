/* MemoX Mobile — GuessScreen
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes GuessScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ─────── Screen: Guess (multiple choice A/B/C/D/E, auto-advance) ─────── */
function GuessScreen({ go }) {
  const prompt = '도서관';
  const options = [
  { l: 'A', text: 'kitchen', state: 'fade' },
  { l: 'B', text: 'library', state: 'correct' },
  { l: 'C', text: 'school', state: 'wrong' },
  { l: 'D', text: 'office', state: 'fade' },
  { l: 'E', text: 'classroom', state: 'fade' }];

  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Guess" current={5} total={20} onClose={() => go('deck')} />

      {/* Context line — deck + card direction (mirrors Match's subhead) */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Vocab — chapter 1 · Term → meaning</div>
      </div>

      {/* Everything fits the viewport — prompt is fixed, the 5 options share the rest. */}
      <div style={{ flex: 1, minHeight: 0, padding: '0 16px 0', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {/* Prompt — absorbs all slack so it stays the dominant block */}
        <div className="card" style={{ flex: 1, boxSizing: 'border-box', minHeight: 180, padding: '20px 16px', textAlign: 'center', display: 'flex', flexDirection: 'column', justifyContent: 'center', gap: 8 }}>
          <div className="ov">What is this?</div>
          <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.15 }}>{prompt}</div>
        </div>

        {/* Options — fixed compact rows, never scroll */}
        <div style={{ flexShrink: 0, display: 'flex', flexDirection: 'column', gap: 8 }}>
            {options.map((o, i) => {
              const styles = {
                idle: {
                  bg: 'var(--memox-surface-container-lowest)',
                  fg: 'var(--memox-on-surface)',
                  border: 'var(--memox-border-ghost)'
                },
                correct: {
                  bg: 'color-mix(in srgb, var(--memox-mastery) 14%, transparent)',
                  fg: 'var(--memox-mastery)',
                  border: '1px solid color-mix(in srgb, var(--memox-mastery) 40%, transparent)'
                },
                wrong: {
                  bg: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)',
                  fg: 'var(--memox-error)',
                  border: '1px solid color-mix(in srgb, var(--memox-danger) 35%, transparent)'
                },
                fade: {
                  bg: 'var(--memox-surface-container-lowest)',
                  fg: 'var(--memox-on-surface-variant)',
                  border: 'var(--memox-border-ghost)',
                  opacity: 0.36
                }
              }[o.state];
              return (
                <div key={i} style={{
                  boxSizing: 'border-box',
                  minHeight: 50,
                  padding: '8px 16px',
                  background: styles.bg,
                  color: styles.fg,
                  border: styles.border,
                  borderRadius: 12,
                  display: 'flex', alignItems: 'center', gap: 12,
                  opacity: styles.opacity ?? 1,
                  transition: 'all 200ms cubic-bezier(0.2,0,0,1)'
                }}>
                  <span style={{
                    width: 28, height: 28, borderRadius: 999,
                    border: '1.5px solid currentColor',
                    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 12, fontWeight: 700,
                    opacity: 0.85, flexShrink: 0
                  }}>{o.l}</span>
                  <div style={{ flex: 1, minWidth: 0, fontSize: 16, fontWeight: 500, letterSpacing: '-0.1px', lineHeight: 1.25 }}>{o.text}</div>
                  {o.state === 'correct' && <Ic name="check" size="sm" color="var(--memox-mastery)" />}
                  {o.state === 'wrong' && <Ic name="x" size="md" color="var(--memox-error)" />}
                </div>);

            })}
        </div>
      </div>

      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        padding: '8px 16px 16px', flexShrink: 0,
        fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3
      }}>
        <Ic name="check" size="xs" color="var(--memox-on-surface-variant)" />
        <span>Answer shown — the correct option is highlighted</span>
      </div>
    </div>);

}

Object.assign(window, { GuessScreen });
})();
