/* MemoX Mobile — FolderDetailScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     FolderDetailScreen/
       FolderDetailScreen.jsx  ← shell + mode-derived summary/header + shared rows + dispatch
       states/                 ← one file per state in window.MemoXStates.FolderDetail

   A folder is in one "content mode" (subfolders / decks / unlocked) derived from
   the state; the summary card, section header and FAB follow the mode and stay in
   the MAIN file. delConfirm / moveSheet are overlays over the decks-mode list, so
   their state modules return { body, overlay } and reuse ctx.DeckList() behind the
   scrim. Each state's list/empty/dialog lives in its own file.

   ctx: { go, state, mode, summary, Ic, masteryColor, Scrim,
          SubfolderRow, DeckRow, SubfolderList, DeckList, subfolders, decks } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar, Fab } = window;

const SUMMARY = {
  subfolders: { dueTotal: 41, freshTotal: 12, deckCount: 0, subfolderCount: 4, cardTotal: 286, mastery: 0.58 },
  decks: { dueTotal: 23, freshTotal: 6, deckCount: 5, subfolderCount: 0, cardTotal: 412, mastery: 0.62 },
  unlocked: { dueTotal: 0, freshTotal: 0, deckCount: 0, subfolderCount: 0, cardTotal: 0, mastery: 0 }
};

const subfolders = [
  { name: 'TOPIK I', decks: 3, cards: 124, due: 8, mastery: 0.72, ic: 'flag', seed: 'var(--memox-primary)' },
  { name: 'TOPIK II', decks: 5, cards: 412, due: 23, mastery: 0.62, ic: 'flag', seed: 'var(--memox-primary)', hot: true },
  { name: 'Hangul', decks: 2, cards: 74, due: 4, mastery: 0.91, ic: 'book-open', seed: 'var(--memox-success)' },
  { name: 'Grammar', decks: 4, cards: 138, due: 6, mastery: 0.34, ic: 'sparkles', seed: 'var(--memox-warning)' }
];

const decks = [
  { n: 'Vocab — chapter 1', cards: 62, due: 8, pct: 0.84, col: 'var(--memox-primary)', last: '2h ago' },
  { n: 'Vocab — chapter 2', cards: 58, due: 12, pct: 0.52, col: 'var(--memox-primary)', last: 'yesterday' },
  { n: 'Idioms', cards: 34, due: 3, pct: 0.78, col: 'var(--memox-tertiary)', last: '3 days ago' },
  { n: 'Verb conjugation', cards: 148, due: 0, pct: 0.94, col: 'var(--memox-success)', last: 'a week ago' },
  { n: 'Particles', cards: 30, due: 0, pct: 0.41, col: 'var(--memox-warning)', last: 'never' }
];

const Scrim = window.Scrim;
const Dialog = window.Dialog;

const SubfolderRow = ({ f }) =>
  <div className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '40px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', cursor: 'pointer' }}>
    <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: `${f.seed}1A`, color: f.seed, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name="folder" size="sm" color={f.seed} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.name}</div>
        {f.due > 0 &&
          <span style={{ flexShrink: 0, height: 18, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center' }}>{f.due} due</span>}
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{f.decks} decks · {f.cards} cards</div>
      <div style={{ marginTop: 4, height: 4, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${f.mastery * 100}%`, background: masteryColor(f.mastery) }} />
      </div>
    </div>
    <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />
  </div>;

const DeckRow = ({ d }) =>
  <div className="card" role="button" tabIndex={0} style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '40px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', cursor: 'pointer' }}>
    <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: `${d.col}1A`, color: d.col, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name="layers" size="sm" color={d.col} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.n}</div>
        {d.due > 0 &&
          <span style={{ flexShrink: 0, height: 18, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center' }}>{d.due} due</span>}
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <span>{d.cards} cards</span>
        <span style={{ opacity: 0.5 }}>·</span>
        <span>last {d.last}</span>
      </div>
      <div style={{ marginTop: 4, height: 4, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${d.pct * 100}%`, background: masteryColor(d.pct) }} />
      </div>
    </div>
    <Ic name="chevron-right" size="sm" color="var(--memox-on-surface-variant)" />
  </div>;

const SubfolderList = () => <>{subfolders.map((f) => <SubfolderRow key={f.name} f={f} />)}</>;
const DeckList = () => <>{decks.map((d) => <DeckRow key={d.n} d={d} />)}</>;

/* ════════════ SCREEN ════════════ */
function FolderDetailScreen({ go, state = 'decks' }) {
  const mode = state === 'subfolders' ? 'subfolders' : state === 'unlocked' ? 'unlocked' : 'decks';
  const isOverlay = state === 'delConfirm' || state === 'moveSheet';
  const summary = SUMMARY[mode];
  const folderName = mode === 'subfolders' ? 'Korean' : 'TOPIK II';
  const breadcrumb = mode === 'subfolders'
    ? [{ label: 'Library' }, { label: 'Korean' }]
    : [{ label: 'Library' }, { label: 'Korean' }, { label: 'TOPIK II' }];

  const showSummary = state !== 'error' && state !== 'loading';
  const showHeader = state !== 'error' && state !== 'loading' && mode !== 'unlocked';
  const showFAB = !isOverlay && state !== 'error' && state !== 'loading' && state !== 'searchEmpty' && mode !== 'unlocked';

  const States = (window.MemoXStates && window.MemoXStates.FolderDetail) || {};
  const ctx = { go, state, mode, summary, Ic, masteryColor, Scrim, Dialog, SubfolderRow, DeckRow, SubfolderList, DeckList, subfolders, decks };
  const mod = States[state] || States.decks;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('library')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{folderName}</div>
        <button className="icon-btn">
          <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      <Breadcrumb segments={breadcrumb} />

      <div className="scroll scroll-fab">

        {/* Folder summary — bigger for decks, slim for subfolders, hidden for unlocked/error/loading. */}
        {showSummary &&
          <>
            {mode === 'unlocked' ? null : mode === 'decks' ?
              <div className="card" style={{ padding: '16px', marginBottom: 12, background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: summary.dueTotal > 0 ? 12 : 0 }}>
                  <svg width="56" height="56" viewBox="0 0 40 40">
                    <circle cx="20" cy="20" r="17" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3" />
                    <circle cx="20" cy="20" r="17" fill="none" stroke={masteryColor(summary.mastery)} strokeWidth="3" strokeLinecap="round" strokeDasharray="106.8" strokeDashoffset={(1 - summary.mastery) * 106.8} transform="rotate(-90 20 20)" />
                    <text x="20" y="22.5" textAnchor="middle" fontSize="9" fontWeight="700" fill={masteryColor(summary.mastery)} style={{ fontFamily: 'var(--memox-font-sans)' }}>{Math.round(summary.mastery * 100)}%</text>
                  </svg>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="ov">Folder mastery</div>
                    <div style={{ fontSize: 14, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{summary.deckCount} decks · {summary.cardTotal} cards</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      {summary.dueTotal > 0 ?
                        <>
                          <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-primary)', display: 'inline-block' }} />
                          {summary.dueTotal} due · {summary.freshTotal} new
                        </> : 'All caught up'}
                    </div>
                  </div>
                </div>
                {summary.dueTotal > 0 &&
                  <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14 }}>
                    <Ic name="play" size="xs" color="var(--memox-on-primary)" />
                    Start study · {summary.dueTotal} due
                  </button>}
              </div> :
              <div className="card" style={{ padding: '12px 16px', marginBottom: 12, display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', alignItems: 'baseline', rowGap: 4 }}>
                {[
                  { n: summary.subfolderCount, l: 'subfolders' },
                  { n: summary.cardTotal, l: 'cards' },
                  { n: summary.dueTotal, l: 'due total' }
                ].map((s, i) =>
                  <div key={i} style={{ borderLeft: i === 0 ? 'none' : '1px solid var(--memox-outline-variant)', paddingLeft: i === 0 ? 0 : 12 }}>
                    <div style={{ fontSize: 20, fontWeight: 700, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.4px', color: i === 2 && s.n > 0 ? 'var(--memox-primary)' : 'var(--memox-on-surface)' }}>{s.n}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>{s.l}</div>
                  </div>
                )}
              </div>}
          </>}

        {/* Section header */}
        {showHeader &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <span className="ov">
                {state === 'searchEmpty' ? 'No matches' : mode === 'subfolders' ? `${summary.subfolderCount} subfolders` : `${summary.deckCount} decks`}
              </span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
              <button className="icon-btn" style={{ width: 30, height: 30 }} title="Search this folder">
                <Ic name="search" size="xs" color="var(--memox-on-surface-variant)" />
              </button>
              <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
                <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
                {mode === 'subfolders' ? 'Most due' : 'Recent'}
                <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
              </button>
            </div>
          </div>}

        {body}
      </div>

      {/* Mode-aware FAB — shared pinned chrome (no bottom nav on this screen) */}
      {showFAB &&
        <Fab
          icon={mode === 'subfolders' ? 'folder-plus' : 'plus'}
          label={mode === 'subfolders' ? 'New subfolder' : 'New card'} />}

      {overlayNode}

    </div>);
}

Object.assign(window, { FolderDetailScreen });
})();
