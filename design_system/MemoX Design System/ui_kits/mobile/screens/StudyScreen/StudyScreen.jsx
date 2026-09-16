/* MemoX Mobile — StudyScreen
   Split from index.html for isolated review/editing. Wrapped in an IIFE so its
   top-level bindings stay local (every screen file shares one global scope when
   loaded as separate <script> tags). Shared chrome (StatusBar, Ic, BottomNav,
   Breadcrumb, OfflineBanner, StudyTopBar, masteryColor) comes from
   screens/_shared.jsx via window; this file publishes StudyScreen back to window. */
(function () {
const { useState, useEffect } = React;
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ─────── Screen: Study (term + meaning visible together, swipe to next) ─────── */
function StudyScreen({ go }) {
  const cards = [
  { front: '공부하다', back: 'to study', lang: 'Korean' },
  { front: '먹다', back: 'to eat', lang: 'Korean' },
  { front: '도서관', back: 'library', lang: 'Korean' }];

  const total = 23;
  const [idx, setIdx] = useState(7);
  const card = cards[idx % cards.length];
  const cardRef = React.useRef(null);
  const [dragX, setDragX] = useState(0);
  const dragRef = React.useRef({ startX: null, captured: false });

  const advance = (dir = 1) => {
    setIdx((prev) => Math.max(0, Math.min(prev + dir, total - 1)));
  };

  React.useEffect(() => {
    const el = cardRef.current;
    if (!el) return;
    const onDown = (e) => {
      dragRef.current.startX = e.touches ? e.touches[0].clientX : e.clientX;
      dragRef.current.captured = true;
    };
    const onMove = (e) => {
      if (!dragRef.current.captured) return;
      const x = e.touches ? e.touches[0].clientX : e.clientX;
      setDragX(x - dragRef.current.startX);
    };
    const onUp = () => {
      if (!dragRef.current.captured) return;
      const dx = dragX;
      dragRef.current.captured = false;
      dragRef.current.startX = null;
      if (Math.abs(dx) > 70) {
        // Swipe is the only card navigation: left → next, right → previous.
        const dir = dx > 0 ? -1 : 1;
        setDragX(dx > 0 ? 500 : -500);
        setTimeout(() => {advance(dir);setDragX(0);}, 180);
      } else {
        setDragX(0);
      }
    };
    el.addEventListener('mousedown', onDown);
    el.addEventListener('touchstart', onDown, { passive: true });
    window.addEventListener('mousemove', onMove);
    window.addEventListener('touchmove', onMove, { passive: true });
    window.addEventListener('mouseup', onUp);
    window.addEventListener('touchend', onUp);
    return () => {
      el.removeEventListener('mousedown', onDown);
      el.removeEventListener('touchstart', onDown);
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('touchmove', onMove);
      window.removeEventListener('mouseup', onUp);
      window.removeEventListener('touchend', onUp);
    };
  }, [dragX]);

  const isSwiping = Math.abs(dragX) > 4;
  const transform = `translateX(${dragX}px) rotate(${dragX * 0.025}deg)`;
  const opacity = 1 - Math.min(Math.abs(dragX) / 400, 0.5);

  return (
    <div className="app">
      <StatusBar />
      <StudyTopBar mode="Review" current={idx + 1} total={total} onClose={() => go('deck')} />

      {/* Context line — deck + card direction (mirrors Match's subhead) */}
      <div style={{ padding: '0 16px 20px', marginTop: -4 }}>
        <div className="ov" style={{ textAlign: 'center' }}>Vocab — chapter 1 · 12 new · 11 review</div>
      </div>

      <div style={{ flex: 1, padding: '0 16px 12px', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div
          ref={cardRef}
          className="card"
          style={{
            flex: 1,
            padding: 0,
            display: 'flex', flexDirection: 'column',
            cursor: 'grab',
            userSelect: 'none',
            transform,
            opacity,
            transition: isSwiping ? 'none' : 'transform 220ms cubic-bezier(0.05,0.7,0.1,1), opacity 220ms cubic-bezier(0.2,0,0,1)',
            touchAction: 'pan-y'
          }}>
          
          {/* Top half — term */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '20px 16px 8px', position: 'relative' }}>
            <div className="ov" style={{ position: 'absolute', top: 16, left: 20 }}>{card.lang}</div>
            <div style={{ fontSize: 32, fontWeight: 700, letterSpacing: '-0.5px', textAlign: 'center', lineHeight: 1.15 }}>{card.front}</div>
          </div>

          {/* Divider */}
          <div style={{ height: 1, background: 'var(--memox-outline-variant)', opacity: 0.5, margin: '0 20px' }} />

          {/* Bottom half — meaning + example */}
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '8px 16px 20px', position: 'relative' }}>
            <div className="ov" style={{ position: 'absolute', top: 16, left: 20 }}>Meaning</div>
            <div style={{ fontSize: 24, fontWeight: 600, letterSpacing: '-0.3px', textAlign: 'center' }}>{card.back}</div>
          </div>
        </div>

        {/* Swipe is the only navigation — hint states both directions */}
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          fontSize: 12, color: 'var(--memox-on-surface-variant)',
          letterSpacing: 0.3
        }}>
          <Ic name="chevrons-right" size="xs" color="var(--memox-on-surface-variant)" />
          <span>Swipe left for next, right to go back</span>
        </div>
      </div>
    </div>);

}

Object.assign(window, { StudyScreen });
})();
