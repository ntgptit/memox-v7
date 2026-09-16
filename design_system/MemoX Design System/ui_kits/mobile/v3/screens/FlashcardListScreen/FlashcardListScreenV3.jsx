/* MemoX Mobile v3 — FlashcardListScreen · MAIN  (A8 · Card list of a deck)
   Product corrections vs v1:
     EDIT   display states are new · beginning · reviewing · mastered (BR-88…91).
     EDIT   filters are All / Due / New / Flagged plus a tag filter (BR-231); the
            "Mastered" chip is removed (no such filter). Sort: newest · due soonest.
     EDIT   due badge shows overdue days in amber, "today", "in N d" or "new".
     EDIT   CTA opens the study entry ("Study this deck"), it does not start a session.
     EDIT   delete → "Move to Trash" with Undo (BR-256, BR-263); deck deletion carries
            its impact and no destructive emphasis (BR-266).
     REMOVE reorder (cards have no manual order); "Anki" import wording.
     ADD    multi-select with the bulk bar (move · Trash · flag · tag · export),
            bulk-failed (selection kept), trashed + Undo, card action sheet,
            deck action sheet (import · export · rename · Trash), no move target,
            deck not found. Long fronts/backs clamp to 2 lines (BR-240).
   ── v1 header follows ──
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
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, StudyTopBar, Fab } = window;

const deckName = 'Động từ · 동사';
/* Display-state labels (BR-88…91). 'beginning' paints with the learning token — same amber, product name. */
const statusToken = { new: 'var(--memox-status-new)', beginning: 'var(--memox-status-learning)', reviewing: 'var(--memox-status-reviewing)', mastered: 'var(--memox-status-mastered)' };
const statusLabel = { new: 'New', beginning: 'Beginning', reviewing: 'Reviewing', mastered: 'Mastered' };
/* SAMPLE_DATA · cards[0] + state distribution. */
const summary = { total: 420, due: 40, overdue: 20, fresh: 100, flagged: 3, mastery: 80 / 420, new: 100, beginning: 140, reviewing: 100, mastered: 80 };

const cards = [
  { front: '물', back: 'nước', tags: [], status: 'new', flag: true, due: 'New' },
  { front: '가다', back: 'đi', tags: ['TOPIK I', 'động từ'], status: 'new', flag: false, due: 'New' },
  { front: '먹다', back: 'ăn', tags: [], status: 'beginning', flag: false, due: 'Due today', dueTone: 'today' },
  { front: '-(으)ㄹ 뿐만 아니라: không những … mà còn … (ngữ pháp trung cấp)', back: 'Nối hai mệnh đề, nhấn mạnh rằng ngoài điều thứ nhất còn có thêm điều thứ hai. Gắn sau động từ hoặc tính từ; với danh từ dùng 뿐만 아니라 trực tiếp.', tags: ['bài 12', 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc', 'cần ôn lại', 'hay nhầm', 'liên kết câu', 'ngữ pháp', 'nói', 'TOPIK II', 'trung cấp', 'viết'], status: 'reviewing', flag: true, due: 'Overdue 30d', dueTone: 'overdue' },
  { front: '공부하다', back: 'học, học tập', tags: ['hay nhầm', 'TOPIK I', 'động từ'], status: 'reviewing', flag: true, due: 'In 17d' },
  { front: '자다', back: 'ngủ', tags: ['động từ'], status: 'mastered', flag: false, due: 'In 96d' },
  { front: '보다', back: 'xem, nhìn', tags: ['động từ'], status: 'beginning', flag: false, due: 'In 2d' }
];

const Scrim = window.Scrim;
const Dialog = window.Dialog;

/* Card row — v1 anatomy (status dot · front · back · state label + tags · flag + due chip).
   `select` swaps the status dot for a checkbox (multi-select, BR-246). Front/back clamp to 2 lines. */
const dueStyle = (c) => c.dueTone === 'overdue'
  ? { color: 'var(--memox-warning-ink)', background: 'var(--memox-warning-soft)' }
  : c.dueTone === 'today' ? { color: 'var(--memox-primary)', background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)' }
  : { color: 'var(--memox-on-surface-variant)', background: 'var(--memox-surface-container)' };
const clamp2 = { display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' };

const CardRow = ({ c, select = false, selected = false }) =>
  <div role={select ? 'checkbox' : 'button'} aria-checked={select ? selected : undefined} tabIndex={0} style={{ marginBottom: 8, padding: '12px 12px', display: 'grid', gridTemplateColumns: select ? '22px 1fr auto' : '8px 1fr auto', gap: 12, alignItems: 'flex-start', background: 'var(--memox-surface-container-lowest)', border: selected ? '1px solid var(--memox-primary)' : 'var(--memox-border-ghost)', borderRadius: 12, cursor: 'pointer' }}>
    {select ?
      <span style={{ marginTop: 2, width: 20, height: 20, borderRadius: 'var(--memox-radius-xs)', boxSizing: 'border-box', border: selected ? 'none' : '2px solid var(--memox-outline)', background: selected ? 'var(--memox-primary)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {selected && <Ic name="check" size={14} color="var(--memox-on-primary)" />}
      </span> :
      <div style={{ paddingTop: 4 }}>
        <span className="status-dot" style={{ background: statusToken[c.status], width: 8, height: 8 }} />
      </div>}
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.25, ...clamp2 }}>{c.front}</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.4, ...clamp2 }}>{c.back}</div>
      <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 4, flexWrap: 'nowrap', overflow: 'hidden' }}>
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: statusToken[c.status], flexShrink: 0 }}>{statusLabel[c.status]}</span>
        {c.tags.slice(0, 2).map((t) =>
          <span key={t} style={{ height: 18, padding: '0 8px', borderRadius: 999, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center', flexShrink: 1, minWidth: 0, maxWidth: 140 }}><span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{t}</span></span>
        )}
        {c.tags.length > 2 && <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', flexShrink: 0 }}>+{c.tags.length - 2}</span>}
      </div>
    </div>
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, paddingTop: 4 }}>
      {c.flag && <Ic name="flag" size="xs" color="var(--memox-streak)" label="Flagged" />}
      <span style={{ fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', padding: '2px 4px', borderRadius: 4, whiteSpace: 'nowrap', ...dueStyle(c) }}>{c.due}</span>
    </div>
  </div>;

const CardList = (select = false, selectedIdx = []) => <>{cards.map((c, i) => <CardRow key={c.front} c={c} select={select} selected={selectedIdx.includes(i)} />)}</>;

/* ════════════ SCREEN ════════════ */
function FlashcardListScreenV3({ go, state = 'loaded' }) {
  const isOverlay = ['delCard', 'delDeck', 'cardActions', 'deckActions', 'moveTargets', 'noMoveTarget', 'trashed', 'bulkFailed'].includes(state);
  const selecting = ['selection', 'bulkFailed', 'moveTargets', 'noMoveTarget'].includes(state);
  const breadcrumb = [{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }, { label: deckName }];

  const hidden = ['error', 'loading', 'empty', 'notFound'].includes(state);
  const showSummary = !hidden && !selecting;
  const showFilters = showSummary;
  const showCount = !hidden;

  const States = (window.MemoXStates && window.MemoXStates.FlashcardList) || {};
  const { BottomSheet, Snackbar, Note } = window;
  const ctx = { go, state, selecting, summary, cards, statusToken, statusLabel, Ic, masteryColor, Scrim, Dialog, BottomSheet, Snackbar, Note, CardRow, CardList };
  const mod = States[state] || States.loaded;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('library')} aria-label={selecting ? 'Clear selection' : 'Back'}>
          <Ic name={selecting ? 'x' : 'arrow-left'} size="sm" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
          {selecting ? '2 selected' : state === 'notFound' ? 'Deck' : deckName}
        </div>
        {selecting ?
          <button className="pill-btn" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12, background: 'transparent', border: 'none', color: 'var(--memox-primary)' }}>Select all 420</button> :
          state !== 'notFound' && <>
            <button className="icon-btn" title="Search in this deck" aria-label="Search in this deck">
              <Ic name="search" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
            <button className="icon-btn" title="Deck actions" aria-label="Deck actions">
              <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
          </>}
      </div>

      {!selecting && state !== 'notFound' && <Breadcrumb segments={breadcrumb} />}

      <div className="scroll scroll-fab">

        {/* Deck summary — populated only. */}
        {showSummary &&
          <div className="card" style={{ padding: '16px', marginBottom: 12, background: 'var(--memox-surface-hero)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 12 }}>
              <svg width="56" height="56" viewBox="0 0 40 40">
                <circle cx="20" cy="20" r="17" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3" />
                <circle cx="20" cy="20" r="17" fill="none" stroke={masteryColor(summary.mastery)} strokeWidth="3" strokeLinecap="round" strokeDasharray="106.8" strokeDashoffset={(1 - summary.mastery) * 106.8} transform="rotate(-90 20 20)" />
                <text x="20" y="22.5" textAnchor="middle" fontSize="9" fontWeight="700" fill={masteryColor(summary.mastery)} style={{ fontFamily: 'var(--memox-font-sans)' }}>{Math.round(summary.mastery * 100)}%</text>
              </svg>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ov">Deck progress · SM-2</div>
                <div style={{ fontSize: 14, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{summary.mastered} of {summary.total} cards mastered</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>
                  {summary.due > 0 ?
                    <><span style={{ color: 'var(--memox-warning-ink)', fontWeight: 600 }}>{summary.overdue} overdue</span> · {summary.due - summary.overdue} today · {summary.fresh} new</> : 'Nothing due right now'}
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', height: 6, borderRadius: 999, overflow: 'hidden', background: 'var(--memox-surface-container)', marginBottom: 8 }}>
              {[
                { v: summary.new, c: 'var(--memox-status-new)' },
                { v: summary.beginning, c: 'var(--memox-status-learning)' },
                { v: summary.reviewing, c: 'var(--memox-status-reviewing)' },
                { v: summary.mastered, c: 'var(--memox-status-mastered)' }
              ].map((s, i) => <div key={i} style={{ width: `${s.v / summary.total * 100}%`, background: s.c }} />)}
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px 8px', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', marginBottom: summary.due > 0 ? 12 : 0 }}>
              {[
                { l: 'New', v: summary.new, c: 'var(--memox-status-new)' },
                { l: 'Beginning', v: summary.beginning, c: 'var(--memox-status-learning)' },
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
                <span>{`Study this deck · ${summary.due} due`}</span>
              </button>}
          </div>}

        {/* Filter / sort row */}
        {showFilters &&
          <div style={{ padding: '0 0 8px' }}>
            <div className="scroll-x" style={{ display: 'flex', gap: 4 }}>
              {[
                { label: 'All', count: summary.total, active: true },
                { label: 'Due', count: summary.due },
                { label: 'New', count: summary.new },
                { label: 'Flagged', count: summary.flagged, ic: 'flag' },
                { label: 'Tags', ic: 'tag', chevron: true }
              ].map((f) =>
                <button key={f.label} className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: f.active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)', color: f.active ? '#fff' : 'var(--memox-on-surface)', border: f.active ? 'none' : 'var(--memox-border-ghost)', flexShrink: 0 }}>
                  {f.ic && <Ic name={f.ic} size="xs" color={f.active ? '#fff' : 'var(--memox-on-surface-variant)'} />}
                  {f.label}
                  {f.count !== undefined && <span style={{ fontSize: 12, fontWeight: 700, opacity: f.active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.count}</span>}
                  {f.chevron && <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />}
                </button>
              )}
            </div>
          </div>}

        {/* Count + sort */}
        {showCount &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">
              {state === 'searchEmpty' ? 'No matches' : selecting ? '2 of 420 selected' : `Showing ${cards.length} of ${summary.total}`}
            </span>
            {!selecting &&
              <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
                <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
                Newest first
                <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
              </button>}
          </div>}

        {body}
      </div>

      {/* FAB — loaded only (shared pinned chrome, no bottom nav on this screen) */}
      {!isOverlay && !selecting && state === 'loaded' &&
        <Fab icon="plus" label="New card" />}

      {/* Bulk action bar — in-flow footer while selecting (BR-166/167). */}
      {selecting &&
        <div style={{ flexShrink: 0, borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', padding: '8px 8px calc(8px + env(safe-area-inset-bottom, 0px))', display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)' }}>
          {[['folder-tree', 'Move'], ['flag', 'Flag'], ['tag', 'Tag'], ['upload', 'Export'], ['trash-2', 'Trash']].map(([ic, l]) =>
            <button key={l} style={{ background: 'transparent', border: 'none', fontFamily: 'inherit', color: 'var(--memox-on-surface)', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '8px 0', minHeight: 48, cursor: 'pointer', fontSize: 12, fontWeight: 600 }}>
              <Ic name={ic} size="sm" color="var(--memox-primary)" />{l}
            </button>)}
        </div>}

      {overlayNode}

    </div>);
}

Object.assign(window, { FlashcardListScreenV3 });
})();
