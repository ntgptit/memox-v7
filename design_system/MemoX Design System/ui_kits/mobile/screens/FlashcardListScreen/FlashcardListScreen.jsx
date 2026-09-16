/* MemoX Mobile — FlashcardListScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     FlashcardListScreen/
       FlashcardListScreen.jsx  ← shell (appbar/summary/filters/count/FAB) + CardRow + dispatch
       states/                  ← one file per state in window.MemoXStates.FlashcardList

   The deck-summary card, filter chips and count row are state-derived chrome kept
   in MAIN. delCard / delDeck are dialogs over the populated list, so those state
   modules return { body, overlay } and reuse ctx.CardList(). reorder reuses the
   list with drag handles (the shell re-titles the app bar from the `reorder` flag).

   ctx: { go, state, reorder, summary, cards, statusToken, statusLabel,
          Ic, masteryColor, Scrim, CardRow, CardList } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar, Fab } = window;

const deckName = 'TOPIK II — Vocab';
const statusToken = { new: 'var(--memox-status-new)', learning: 'var(--memox-status-learning)', reviewing: 'var(--memox-status-reviewing)', mastered: 'var(--memox-status-mastered)' };
const statusLabel = { new: 'New', learning: 'Learning', reviewing: 'Reviewing', mastered: 'Mastered' };
const summary = { total: 142, due: 23, fresh: 6, mastery: 0.62, new: 4, learning: 8, reviewing: 24, mastered: 106 };

const cards = [
  { front: '연구자', back: 'researcher / nhà nghiên cứu', tags: ['noun', 'people'], status: 'new', flag: false, due: 'now' },
  { front: '공부하다', back: 'to study', tags: ['verb'], status: 'mastered', flag: false, due: 'in 4d' },
  { front: '도서관', back: 'library, reading room', tags: ['noun', 'places'], status: 'learning', flag: true, due: '10m' },
  { front: '친구', back: 'friend, close companion', tags: ['noun', 'people'], status: 'reviewing', flag: false, due: '6h' },
  { front: '바다', back: 'sea, ocean', tags: ['noun', 'nature'], status: 'learning', flag: true, due: '15m' },
  { front: '영화', back: 'movie / film', tags: ['noun'], status: 'new', flag: false, due: 'now' },
  { front: '시간', back: 'time, hour', tags: ['noun'], status: 'reviewing', flag: false, due: '2d' }
];

const Scrim = window.Scrim;
const Dialog = window.Dialog;

const CardRow = ({ c, dragHandle }) =>
  <div style={{ marginBottom: 8, padding: '12px 12px', display: 'grid', gridTemplateColumns: dragHandle ? '20px 8px 1fr auto' : '8px 1fr auto', gap: 12, alignItems: 'flex-start', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12 }}>
    {dragHandle &&
      <div style={{ color: 'var(--memox-on-surface-variant)', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', paddingTop: 4, cursor: 'grab' }}>
        <Ic name="grip-vertical" size="xs" color="var(--memox-on-surface-variant)" />
      </div>}
    <div style={{ paddingTop: 4 }}>
      <span className="status-dot" style={{ background: statusToken[c.status], width: 8, height: 8 }} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.25, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.front}</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.back}</div>
      <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 4, flexWrap: 'nowrap', overflow: 'hidden' }}>
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', color: statusToken[c.status] }}>{statusLabel[c.status]}</span>
        {c.tags.slice(0, 2).map((t) =>
          <span key={t} style={{ height: 18, padding: '0 8px', borderRadius: 999, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', flexShrink: 0 }}>{t}</span>
        )}
      </div>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, paddingTop: 4 }}>
      {c.flag && <Ic name="flag" size="xs" color="var(--memox-streak)" />}
      <span style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', color: 'var(--memox-on-surface-variant)', padding: '2px 4px', borderRadius: 4, background: 'var(--memox-surface-container)' }}>{c.due}</span>
    </div>
  </div>;

const CardList = (dragHandle) => <>{cards.map((c) => <CardRow key={c.front} c={c} dragHandle={dragHandle} />)}</>;

/* ════════════ SCREEN ════════════ */
function FlashcardListScreen({ go, state = 'loaded' }) {
  const isOverlay = state === 'delCard' || state === 'delDeck';
  const reorder = state === 'reorder';
  const breadcrumb = [{ label: 'Library' }, { label: 'Korean' }, { label: 'TOPIK II' }, { label: deckName }];

  const showSummary = state !== 'error' && state !== 'loading' && state !== 'empty' && !reorder;
  const showFilters = showSummary;
  const showCount = state !== 'error' && state !== 'loading' && state !== 'empty';

  const States = (window.MemoXStates && window.MemoXStates.FlashcardList) || {};
  const ctx = { go, state, reorder, summary, cards, statusToken, statusLabel, Ic, masteryColor, Scrim, Dialog, CardRow, CardList };
  const mod = States[state] || States.loaded;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('library')}>
          <Ic name={reorder ? 'x' : 'arrow-left'} size="sm" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {reorder ? 'Reorder cards' : deckName}
        </div>
        {reorder ?
          <button className="pill-btn primary" style={{ height: 32, padding: '0 16px', borderRadius: 8, fontSize: 12 }}>Done</button> :
          <>
            <button className="icon-btn" title="Search">
              <Ic name="search" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
            <button className="icon-btn" title="More">
              <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
          </>}
      </div>

      {!reorder && <Breadcrumb segments={breadcrumb} />}

      <div className="scroll scroll-fab">

        {/* Deck summary — populated only. */}
        {showSummary &&
          <div className="card" style={{ padding: '16px', marginBottom: 12, background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 12 }}>
              <svg width="56" height="56" viewBox="0 0 40 40">
                <circle cx="20" cy="20" r="17" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3" />
                <circle cx="20" cy="20" r="17" fill="none" stroke={masteryColor(summary.mastery)} strokeWidth="3" strokeLinecap="round" strokeDasharray="106.8" strokeDashoffset={(1 - summary.mastery) * 106.8} transform="rotate(-90 20 20)" />
                <text x="20" y="22.5" textAnchor="middle" fontSize="9" fontWeight="700" fill={masteryColor(summary.mastery)} style={{ fontFamily: 'var(--memox-font-sans)' }}>{Math.round(summary.mastery * 100)}%</text>
              </svg>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ov">Deck progress</div>
                <div style={{ fontSize: 14, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{summary.mastered} of {summary.total} cards mastered</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  {summary.due > 0 ?
                    <>
                      <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-primary)', display: 'inline-block' }} />
                      {summary.due} due · {summary.fresh} new
                    </> : 'All caught up for now'}
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', height: 6, borderRadius: 999, overflow: 'hidden', background: 'var(--memox-surface-container)', marginBottom: 8 }}>
              {[
                { v: summary.new, c: 'var(--memox-status-new)' },
                { v: summary.learning, c: 'var(--memox-status-learning)' },
                { v: summary.reviewing, c: 'var(--memox-status-reviewing)' },
                { v: summary.mastered, c: 'var(--memox-status-mastered)' }
              ].map((s, i) => <div key={i} style={{ width: `${s.v / summary.total * 100}%`, background: s.c }} />)}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px 8px', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', marginBottom: summary.due > 0 ? 12 : 0 }}>
              {[
                { l: 'New', v: summary.new, c: 'var(--memox-status-new)' },
                { l: 'Learning', v: summary.learning, c: 'var(--memox-status-learning)' },
                { l: 'Reviewing', v: summary.reviewing, c: 'var(--memox-status-reviewing)' },
                { l: 'Mastered', v: summary.mastered, c: 'var(--memox-status-mastered)' }
              ].map((b) =>
                <span key={b.l} style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <span className="status-dot" style={{ width: 6, height: 6, background: b.c }} />
                  {b.l} <span style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{b.v}</span>
                </span>
              )}
            </div>
            {summary.due > 0 &&
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>
                <Ic name="play" size="xs" color="var(--memox-on-primary)" />
                Start study · {summary.due} due
              </button>}
          </div>}

        {/* Filter / sort row */}
        {showFilters &&
          <div style={{ padding: '0 0 8px' }}>
            <div className="scroll-x" style={{ display: 'flex', gap: 4 }}>
              {[
                { label: 'All', count: summary.total, active: true },
                { label: 'Due now', count: summary.due },
                { label: 'New', count: summary.new },
                { label: 'Flagged', count: 2, ic: 'flag' },
                { label: 'Mastered', count: summary.mastered }
              ].map((f) =>
                <button key={f.label} className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: f.active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)', color: f.active ? '#fff' : 'var(--memox-on-surface)', border: f.active ? 'none' : 'var(--memox-border-ghost)', flexShrink: 0 }}>
                  {f.ic && <Ic name={f.ic} size="xs" color={f.active ? '#fff' : 'var(--memox-on-surface-variant)'} />}
                  {f.label}
                  <span style={{ fontSize: 12, fontWeight: 700, opacity: f.active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.count}</span>
                </button>
              )}
            </div>
          </div>}

        {/* Count + sort */}
        {showCount &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">
              {state === 'searchEmpty' ? 'No matches' : reorder ? `${cards.length} cards · drag to reorder` : `${state === 'loaded' ? cards.length : 0} cards`}
            </span>
            {!reorder &&
              <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
                <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
                Due first
                <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
              </button>}
          </div>}

        {body}
      </div>

      {/* FAB — loaded only (shared pinned chrome, no bottom nav on this screen) */}
      {!isOverlay && !reorder && state === 'loaded' &&
        <Fab icon="plus" label="New card" />}

      {overlayNode}

    </div>);
}

Object.assign(window, { FlashcardListScreen });
})();
