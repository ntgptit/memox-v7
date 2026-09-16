/* MemoX Mobile v3 — DeckListScreen · ONE recursive deck list  (A1)
   ────────────────────────────────────────────────────────────────────────
   Replaces LibraryOverviewScreen (01) + DeckDetailScreen (02). The product
   spec already treats both as one area (A1 top level · A1 inside a deck) and
   the data model is recursive (deck → sub-decks, depth ≤ 10), so this is one
   screen with a `level`, not two screens.

   What is SHARED (written once here): the row, the list, the section header +
   sort pill, the create FAB, the scroll/clearance, and the loading / loaded /
   error / trashed states.

   What is LEVEL-SPECIFIC (three branches, nothing more):
     app bar      root → large "Library" + starter/tags/trash
                  deck → back + deck name + ⋮
     context slot root → search + today strip (the one bridge to Study)
                  deck → summary card (donut · algo · level totals) + Study CTA
     chrome       root → bottom nav, FAB "New deck"
                  deck → breadcrumb, FAB "New sub-deck" (none at level 10, BR-55)

   Row anatomy: 44px tile · 14px/700 name clamped to 2 lines · due chip · structure
   meta · 5px mastery bar. Bold at 14 carries the name without shouting; the
   internal rhythm is 4 (name → meta) and 12 (meta → bar), which belongs to the
   item card, not to the dense 48px list row (that one stays at 2).

   Rows carry structure + one due chip. The overdue · today · new breakdown is
   Study home's job: it orders by it and starts the session. Library only
   manages. The chip keeps the deck sorts and the "Due only" filter meaningful.

   State ids are level-prefixed (rootLoaded, deckOverflow, …); the modules in
   states/ receive the un-prefixed id as ctx.state.

   ctx: { go, state, level, isRoot, summary, target, decks, children, Ic,
          masteryColor, fmt, Scrim, Dialog, BottomSheet, Snackbar, Note,
          OptionRow, Badge, DeckRow, DeckCard, DeckList, LoadingList,
          EmptyCard, ErrorCard, OverflowSheet } */
(function () {
const { StatusBar, masteryColor, Ic, BottomNav, Breadcrumb, Fab, SearchField, Badge, Snackbar, Note, OptionRow } = window;
const { Skeleton, EmptyState, ErrorState, Scrim, Dialog, BottomSheet } = window;

const fmt = (n) => n.toLocaleString('en-US');

/* ── Data · SAMPLE_DATA.json ───────────────────────────────────────────── */
/* Root decks — library[0]. Order is manual (default sort). */
const rootDecks = [
  { name: '한국어 TOPIK I · Từ vựng', subs: 4, cards: 1248, due: 86, overdue: 41, overdueDays: 3, fresh: 312, mastery: 0.1635, algo: 'SM-2' },
  { name: 'Tiếng Anh giao tiếp hằng ngày', subs: 3, cards: 64, due: 12, overdue: 0, overdueDays: 0, fresh: 0, mastery: 0, algo: 'Eight boxes' },
  { name: 'IELTS Academic Word List', subs: 12, cards: 10000, due: 1260, overdue: 1100, overdueDays: 47, fresh: 7400, mastery: 0.035, algo: 'Eight boxes' },
  { name: 'Korean Basics', subs: 2, cards: 10, due: 0, overdue: 0, overdueDays: 0, fresh: 0, mastery: 1, algo: 'SM-2' },
  { name: 'IT', subs: 1, cards: 5, due: 0, overdue: 0, overdueDays: 0, fresh: 5, mastery: 0, algo: 'Eight boxes' },
  { name: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp trong báo cáo thường niên của doanh nghiệp niêm yết', subs: 0, cards: 0, due: 0, overdue: 0, overdueDays: 0, fresh: 0, mastery: 0, algo: 'SM-2' }
];
/* Children — library[1], inside "한국어 TOPIK I · Từ vựng" (root, SM-2). A child
   holds cards OR sub-decks OR is empty (BR-65). */
const children = [
  { n: 'Động từ · 동사', type: 'card', cards: 420, due: 40, overdue: 20, fresh: 100, pct: 0.19 },
  { n: 'Danh từ · 명사', type: 'deck', subs: 4, cards: 800, due: 46, overdue: 21, fresh: 200, pct: 0.155 },
  { n: 'Tính từ · 형용사', type: 'unset', cards: 0, due: 0, overdue: 0, fresh: 0, pct: 0 },
  { n: 'Trạng từ · 부사', type: 'card', cards: 28, due: 0, overdue: 0, fresh: 12, pct: 0.5 }
];
const summary = { subs: 4, cards: 1248, mastery: 0.1635, due: 86, overdue: 41, today: 45, fresh: 312, scheduled: 850, algo: 'SM-2' };
/* Whole-library level totals for the today strip (BR-150). */
const LEVEL = { due: 1358, overdue: 1141, today: 217, fresh: 7717 };
/* The deck the overflow / rename / delete states operate on. */
const target = { name: '한국어 TOPIK I · Từ vựng', subs: 4, cards: 1248, due: 86, algo: 'SM-2', locked: true };

/* ── DeckRow — the one row, every level ────────────────────────────────── */
const DeckRow = ({ d }) => {
  const name = d.name || d.n;
  const type = d.type || 'deck';
  const pct = d.mastery != null ? d.mastery : (d.pct || 0);
  const icon = type === 'card' ? 'copy' : type === 'unset' ? 'folder-open' : 'layers';
  return (
    <div className="card" role="button" tabIndex={0} style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: '16px', cursor: 'pointer' }}>
      <div className="icon-tile" style={{ width: 44, height: 44, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ic name={icon} size="sm" color="var(--memox-primary)" />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 }}>
          <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', lineHeight: 1.35, minWidth: 0, overflowWrap: 'anywhere', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{name}</div>
          {d.due > 0 && <Badge tone="primary" style={{ marginTop: 4 }}>{`${fmt(d.due)} due`}</Badge>}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', flexWrap: 'wrap' }}>
          {type === 'unset' ? <span>Empty · add cards or a sub-deck</span> : <>
            {d.subs != null &&
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap' }}>
                <Ic name="layers" size="xs" color="var(--memox-on-surface-variant)" />
                {d.subs} {d.subs === 1 ? 'sub-deck' : 'sub-decks'}
              </span>}
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, whiteSpace: 'nowrap' }}>
              <Ic name="copy" size="xs" color="var(--memox-on-surface-variant)" />
              {fmt(d.cards)} cards
            </span>
          </>}
        </div>
        {type !== 'unset' && (d.cards > 0 ?
          <div style={{ marginTop: 12, height: 5, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
            <div style={{ height: '100%', width: `${pct * 100}%`, background: masteryColor(pct), borderRadius: 999 }} />
          </div> :
          <div style={{ marginTop: 6, fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>Empty · add a sub-deck</div>)}
      </div>
      <button className="icon-btn" style={{ width: 28, height: 28 }} title="More" aria-label={`More actions for ${name}`} onClick={(e) => e.stopPropagation()}>
        <Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" />
      </button>
    </div>);
};
/* Alias kept for the root state modules, which pass the deck as `f`. */
const DeckCard = ({ f }) => <DeckRow d={f} />;

/* One loading list for both levels — mirrors the row grid above. */
const LoadingList = () =>
  <>{[0, 1, 2, 3].map((i) =>
    <div key={i} className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: '16px' }}>
      <Skeleton w={44} h={44} r="var(--memox-radius-md)" op={0.55} />
      <div>
        <Skeleton w={100 + i * 30} r={4} op={0.55} style={{ display: 'inline-block' }} />
        <Skeleton w={140} h={10} r={4} op={0.4} style={{ marginTop: 4 }} />
        <Skeleton w="100%" h={5} r={999} op={0.35} style={{ marginTop: 8 }} />
      </div>
      <span />
    </div>
  )}</>;

/* First launch — the library is empty (A1). */
const EmptyCard = () =>
  <EmptyState icon="layers" title="Start your library"
    body="A deck groups the sub-decks that hold your cards. Create one, or copy a starter deck to begin with content."
    action={
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        <button className="pill-btn primary" style={{ fontSize: 14, width: '100%' }}>
          <Ic name="plus" size="xs" color="var(--memox-on-primary)" />
          Create deck
        </button>
        <button className="pill-btn" style={{ fontSize: 14, width: '100%', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>
          <Ic name="sparkles" size="xs" color="var(--memox-primary)" />
          Browse starter decks
        </button>
      </div>}
    footnote="Everything stays on this device. Nothing is added until you choose." />;

const ErrorCard = () =>
  <ErrorState title="Couldn't load your library"
    body="Your data is safe on this device. Try again in a moment." />;

/* Root deck overflow sheet — root decks own the algorithm and cannot move (BR-70). */
const OverflowSheet = () =>
  <BottomSheet scrim={false} maxHeight="none">
    <div style={{ padding: '4px 16px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <div className="icon-tile" style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
        <Ic name="layers" size="xs" color="var(--memox-primary)" />
      </div>
      <div style={{ minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{target.name}</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{target.subs} sub-decks · {fmt(target.cards)} cards · {target.algo}</div>
      </div>
    </div>
    <div style={{ padding: '4px 8px 8px' }}>
      {[
        { ic: 'folder-open', label: 'Open deck', sub: null },
        { ic: 'play', label: 'Study this deck', sub: `${target.due} due · 312 new` },
        { ic: 'pencil', label: 'Rename', sub: null },
        { ic: 'sliders-horizontal', label: 'Study options', sub: 'Cards per session · new-card order' },
        { ic: 'refresh-ccw', label: 'Review algorithm', sub: `${target.algo} · locked · reset to start over` }
      ].map((a) =>
        <button key={a.label} style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
          <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name={a.ic} size="xs" color="var(--memox-primary)" />
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{a.label}</div>
            {a.sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{a.sub}</div>}
          </div>
          <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
        </button>
      )}
      <div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '8px 8px' }} />
      {/* Moving to Trash is recoverable — plain tone, not destructive (BR-266). */}
      <button style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
        <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Ic name="trash-2" size="xs" color="var(--memox-on-surface-variant)" />
        </div>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>Move to Trash</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>Recoverable for 30 days</div>
        </div>
      </button>
    </div>
    <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
  </BottomSheet>;

/* Level-prefixed state id → the id the state module was written against. */
const RAW = {
  rootLoaded: 'loaded', rootLoading: 'loading', rootEmpty: 'empty', rootError: 'error',
  rootSearch: 'search', rootSortFilter: 'sortFilter', rootDueEmpty: 'dueEmpty',
  rootOverflow: 'overflow', rootCreate: 'createDeck', rootRename: 'renameDeck',
  rootDelete: 'deleteDeck', rootTrashed: 'trashed',
  deckLoaded: 'loaded', deckLoading: 'loading', deckEmpty: 'empty', deckError: 'error',
  deckNotFound: 'notFound', deckMaxDepth: 'maxDepth', deckOverflow: 'overflow',
  deckMove: 'moveSheet', deckDelete: 'delConfirm', deckTrashed: 'trashed'
};

/* ════════════ SCREEN ════════════ */
function DeckListScreenV3({ go, state = 'rootLoaded' }) {
  const isRoot = state.indexOf('root') === 0;
  const raw = RAW[state] || 'loaded';
  /* 'root' · 'deck' · 'unset' (an empty child) · 'deep' (level 10) */
  const level = isRoot ? 'root' : state === 'deckEmpty' ? 'unset' : state === 'deckMaxDepth' ? 'deep' : 'deck';

  const searchActive = state === 'rootSearch';
  const dueFilter = state === 'rootDueEmpty';
  const showSheet = ['rootOverflow', 'rootSortFilter', 'deckOverflow', 'deckMove'].includes(state);
  const isDialog = ['rootCreate', 'rootRename', 'rootDelete', 'deckDelete'].includes(state);
  const blank = ['rootEmpty', 'rootError', 'rootLoading', 'deckError', 'deckLoading', 'deckNotFound'].includes(state);
  /* The header belongs to the list, so it stays over the loading skeleton too. */
  const hasList = !['rootEmpty', 'rootError', 'deckError', 'deckNotFound'].includes(state) && level !== 'unset';

  const showTodayStrip = isRoot && !['rootEmpty', 'rootError', 'rootLoading'].includes(state);
  const showSummary = level === 'deck' && !blank;
  const showHeader = hasList;
  const showFAB = !blank && !showSheet && !isDialog && level !== 'deep';

  const deckName = level === 'unset' ? 'Tính từ · 형용사' : level === 'deep' ? 'Cấp 10' : '한국어 TOPIK I · Từ vựng';
  const breadcrumb = level === 'unset'
    ? [{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Tính từ · 형용사' }]
    : level === 'deep'
      ? [{ label: 'Library' }, { label: 'IELTS Academic Word List' }, { label: '…' }, { label: 'Cấp 9' }, { label: 'Cấp 10' }]
      : [{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }];

  const rows = isRoot ? rootDecks : children;
  const DeckList = () => <>{rows.map((d) => <DeckRow key={d.name || d.n} d={d} />)}</>;

  const States = (window.MemoXStates && window.MemoXStates.DeckList) || {};
  const ctx = {
    go, state: raw, level, isRoot, summary, target, decks: rows, children, Ic, masteryColor, fmt,
    Scrim, Dialog, BottomSheet, Snackbar, Note, OptionRow, Badge,
    DeckRow, DeckCard, DeckList, LoadingList, EmptyCard, ErrorCard, OverflowSheet
  };
  const mod = States[state] || States.rootLoaded;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;

  const sectionLabel = state === 'rootLoading' ? 'Loading decks'
    : state === 'deckLoading' ? 'Loading sub-decks'
    : isRoot ? (dueFilter ? 'Decks with due cards' : `${rootDecks.length} decks`)
    : level === 'deep' ? '3 sub-decks · level 10' : `${summary.subs} sub-decks`;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {/* App bar — the only place the two levels look different. */}
      {isRoot ?
        <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Library</div>
          <div style={{ display: 'flex', gap: 0 }}>
            <button className="icon-btn" title="Starter decks" aria-label="Starter decks">
              <Ic name="sparkles" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
            <button className="icon-btn" title="Tags" aria-label="Tags">
              <Ic name="tag" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
            <button className="icon-btn" title="Trash" aria-label="Trash">
              <Ic name="trash-2" size="sm" color="var(--memox-on-surface-variant)" />
            </button>
          </div>
        </div> :
        <div className="appbar" style={{ justifyContent: 'space-between' }}>
          <button className="icon-btn" onClick={() => go('library')} aria-label="Back">
            <Ic name="arrow-left" size="md" />
          </button>
          <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{state === 'deckNotFound' ? 'Deck' : deckName}</div>
          {state !== 'deckNotFound' &&
            <button className="icon-btn" aria-label="Deck actions">
              <Ic name="more-vertical" size="sm" color="var(--memox-on-surface-variant)" />
            </button>}
        </div>}

      {!isRoot && state !== 'deckNotFound' && <Breadcrumb segments={breadcrumb} />}

      {/* Root context: search + the one bridge to Study (level totals, BR-150). */}
      {isRoot && <>
        <div style={{ padding: '0 16px 8px' }}>
          <SearchField placeholder="Search decks, cards, tags" active={searchActive} />
        </div>
        {showTodayStrip &&
          <div style={{ padding: '0 16px 12px' }}>
            <div role="button" tabIndex={0} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', background: 'var(--memox-surface-hero)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-lg)', cursor: 'pointer' }}>
              <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-primary)', color: 'var(--memox-on-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                <Ic name="zap" size="sm" color="var(--memox-on-primary)" />
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', fontVariantNumeric: 'tabular-nums' }}>{fmt(LEVEL.due)} cards due</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>{fmt(LEVEL.overdue)} overdue · {LEVEL.today} today · {fmt(LEVEL.fresh)} new</div>
              </div>
              <Ic name="chevron-right" size="sm" color="var(--memox-primary)" />
            </div>
          </div>}
      </>}

      <div className={'scroll ' + (isRoot ? 'scroll-fab-nav' : 'scroll-fab')}>

        {/* Deck context: summary + the CTA that opens study entry (BR-101).
            Line 2 = level totals, which add up to the card total (BR-162). */}
        {showSummary &&
          <div className="card" style={{ padding: '16px', marginBottom: 12, background: 'var(--memox-surface-hero)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 12 }}>
              <svg width="56" height="56" viewBox="0 0 40 40" role="img" aria-label={`${Math.round(summary.mastery * 100)}% mastered`}>
                <circle cx="20" cy="20" r="17" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3" />
                <circle cx="20" cy="20" r="17" fill="none" stroke={masteryColor(summary.mastery)} strokeWidth="3" strokeLinecap="round" strokeDasharray="106.8" strokeDashoffset={(1 - summary.mastery) * 106.8} transform="rotate(-90 20 20)" />
                <text x="20" y="22.5" textAnchor="middle" fontSize="9" fontWeight="700" fill={masteryColor(summary.mastery)} style={{ fontFamily: 'var(--memox-font-sans)' }}>{Math.round(summary.mastery * 100)}%</text>
              </svg>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ov">Mastered · {summary.algo}</div>
                <div style={{ fontSize: 14, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{summary.subs} sub-decks · {fmt(summary.cards)} cards</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums', lineHeight: 1.5 }}>
                  <span style={{ color: 'var(--memox-warning-ink)', fontWeight: 600, whiteSpace: 'nowrap' }}>{summary.overdue} overdue</span> · <span style={{ color: 'var(--memox-primary)', fontWeight: 600, whiteSpace: 'nowrap' }}>{summary.today} today</span> · <span style={{ whiteSpace: 'nowrap' }}>{summary.fresh} new</span> · <span style={{ whiteSpace: 'nowrap' }}>{summary.scheduled} scheduled</span>
                </div>
              </div>
            </div>
            <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>
              <Ic name="play" size="xs" color="var(--memox-on-primary)" />
              <span>{`Study this deck · ${summary.due} due`}</span>
            </button>
          </div>}

        {/* Section header — count + sort pill. Same at every level. */}
        {showHeader &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">{sectionLabel}</span>
            <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: dueFilter ? 'color-mix(in srgb, var(--memox-primary) 10%, transparent)' : 'transparent', border: 'none', color: dueFilter ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)' }}>
              <Ic name="arrow-down-up" size="xs" color={dueFilter ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
              {dueFilter ? 'Manual · Due only' : 'Manual'}
              <Ic name="chevron-down" size="xs" color={dueFilter ? 'var(--memox-primary)' : 'var(--memox-on-surface-variant)'} />
            </button>
          </div>}

        {body}
      </div>

      {/* A deck holding sub-decks offers only sub-deck creation (BR-66); at level
          10 nothing can be nested (BR-55), so no FAB. */}
      {showFAB && <Fab icon="plus" label={isRoot ? 'New deck' : 'New sub-deck'} aboveNav={isRoot} />}

      {overlayNode}

      {isRoot && <BottomNav active="library" onChange={go} />}
    </div>);
}

Object.assign(window, { DeckListScreenV3 });
})();
