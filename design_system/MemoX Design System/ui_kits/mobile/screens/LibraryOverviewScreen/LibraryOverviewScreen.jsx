/* MemoX Mobile — LibraryOverviewScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     LibraryOverviewScreen/
       LibraryOverviewScreen.jsx  ← shell + shared fragments + dispatch
       states/                    ← one file per state in window.MemoXStates.LibraryOverview

   Several states are OVERLAYS (action sheet, create/rename/move/archive/delete
   dialogs) drawn over the populated folder list. So a state module here returns
     { body, overlay }
   — `body` fills the .scroll area, `overlay` is rendered as an absolute sibling
   over the chrome. Overlay states reuse ctx.FoldersList() as their body, so the
   background list is defined once and each overlay is isolated in its own file.

   ctx: { go, state, Ic, masteryColor, Scrim, FolderCard, FoldersList,
          LoadingList, EmptyCard, ErrorCard, OverflowSheet, Dialog,
          folders, seedSwatches, iconChoices, target } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar, Fab, SearchField, Badge } = window;

/* The folder these follow-up actions operate on (matches the overflow sheet). */
const target = { name: 'Korean', decks: 8, cards: 412, due: 23, seed: 'var(--memox-primary)', ic: 'flag' };
const seedSwatches = [
  'var(--memox-seed-indigo)', 'var(--memox-seed-violet)', 'var(--memox-seed-teal)',
  'var(--memox-seed-rose)', 'var(--memox-seed-amber)', 'var(--memox-seed-sage)'
];
const iconChoices = ['flag', 'book-open', 'sparkles', 'layers', 'copy'];

/* Root folders — each has its own seed color so the eye can find them. */
const folders = [
  { name: 'Korean', decks: 8, cards: 412, due: 23, fresh: 6, mastery: 0.62, lastStudied: '2h ago', ic: 'flag', seed: 'var(--memox-primary)', sub: 'TOPIK · Hangul · grammar' },
  { name: 'Japanese', decks: 5, cards: 248, due: 0, fresh: 0, mastery: 0.41, lastStudied: 'yesterday', ic: 'flag', seed: 'var(--memox-success)', sub: 'Genki · kana · kanji' },
  { name: 'Mandarin', decks: 3, cards: 180, due: 48, fresh: 12, mastery: 0.18, lastStudied: '4 days ago', ic: 'flag', seed: 'var(--memox-warning)', sub: 'HSK 1–3' },
  { name: 'Hanja & roots', decks: 2, cards: 64, due: 6, fresh: 0, mastery: 0.88, lastStudied: 'just now', ic: 'book-open', seed: 'var(--memox-tertiary)', sub: 'Sino-Korean character roots' }
];

/* ── shared inline widgets ── */
const Scrim = window.Scrim;
const BottomSheet = window.BottomSheet;
const { Skeleton, EmptyState, ErrorState } = window;

/* Centered modal-dialog shell used by create/rename/archive/delete states. */
const Dialog = window.Dialog;

const FolderCard = ({ f }) =>
  <div className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: '16px 16px', cursor: 'pointer' }}>
    <div style={{ width: 44, height: 44, borderRadius: 12, background: `color-mix(in srgb, ${f.seed} 12%, transparent)`, color: f.seed, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={f.ic} size="sm" color={f.seed} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.name}</div>
        {f.due > 0 &&
          <Badge tone="primary">{`${f.due} due`}</Badge>}
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{f.sub}</div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8, fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="layers" size="xs" color="var(--memox-on-surface-variant)" />
          {f.decks} {f.decks === 1 ? 'deck' : 'decks'}
        </span>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          <Ic name="copy" size="xs" color="var(--memox-on-surface-variant)" />
          {f.cards} cards
        </span>
        {f.fresh > 0 &&
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--memox-mastery)' }}>
            <span className="status-dot" style={{ background: 'var(--memox-mastery)', width: 6, height: 6 }} />
            {f.fresh} new
          </span>}
      </div>
      <div style={{ marginTop: 8, height: 5, background: 'var(--memox-surface-container)', borderRadius: 999, overflow: 'hidden' }}>
        <div style={{ height: '100%', width: `${f.mastery * 100}%`, background: masteryColor(f.mastery), borderRadius: 999 }} />
      </div>
    </div>
    <button className="icon-btn" style={{ width: 28, height: 28 }} title="More" onClick={(e) => e.stopPropagation()}>
      <Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" />
    </button>
  </div>;

const FoldersList = () => <>{folders.map((f) => <FolderCard key={f.name} f={f} />)}</>;

const LoadingList = () =>
  <>{[0, 1, 2, 3].map((i) =>
    <div key={i} className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr 24px', gap: 16, alignItems: 'center', padding: '16px' }}>
      <Skeleton w={44} h={44} r={12} op={0.55} />
      <div>
        <Skeleton w={100 + i * 30} r={4} op={0.55} style={{ display: 'inline-block' }} />
        <Skeleton w={140} h={10} r={4} op={0.4} style={{ marginTop: 4 }} />
        <Skeleton w="100%" h={5} r={999} op={0.35} style={{ marginTop: 8 }} />
      </div>
      <span />
    </div>
  )}</>;

const EmptyCard = () =>
  <EmptyState icon="folder-plus" title="Start your library"
    body="Folders keep related decks together — by language, course, or topic. Create your first folder to begin."
    action={
      <button className="pill-btn primary" style={{ fontSize: 14 }}>
        <Ic name="folder-plus" size="xs" color="var(--memox-on-primary)" />
        Create folder
      </button>}
    footnote="You can also import a deck and MemoX will wrap it in a folder for you." />;

const ErrorCard = () =>
  <ErrorState title="Couldn't load your library"
    body="Your data is safe on this device. Try again in a moment." />;

/* Folder overflow action sheet (the 'overflow' state). */
const OverflowSheet = () =>
  <BottomSheet scrim={false} maxHeight="none">
    <div style={{ padding: '4px 16px 4px', display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-primary) 12%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <Ic name="flag" size="xs" color="var(--memox-primary)" />
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700 }}>Korean</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>8 decks · 412 cards</div>
      </div>
    </div>
    <div style={{ padding: '4px 8px 8px' }}>
      {[
        { ic: 'folder-open', label: 'Open folder', sub: null },
        { ic: 'play', label: 'Study due cards', sub: '23 cards waiting' },
        { ic: 'pencil', label: 'Rename folder', sub: null },
        { ic: 'folder-tree', label: 'Move folder', sub: null },
        { ic: 'archive', label: 'Archive folder', sub: 'Hides from Library, keeps cards' }
      ].map((a) =>
        <button key={a.label} style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
          <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
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
      <button style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
        <div style={{ width: 30, height: 30, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Ic name="trash-2" size="xs" color="var(--memox-error)" />
        </div>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-error)', letterSpacing: '-0.1px' }}>Delete folder</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>Keeps all 412 cards</div>
        </div>
      </button>
    </div>
    <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
  </BottomSheet>;

/* ════════════ SCREEN ════════════ */
function LibraryOverviewScreen({ go, state = 'loaded' }) {
  const searchActive = state === 'search';
  const showSheet = state === 'overflow';
  const overlay = ['createFolder', 'renameFolder', 'moveFolder', 'archiveFolder', 'deleteFolder'].includes(state);
  const bgLoaded = state === 'loaded' || overlay;
  const showFAB = state !== 'empty' && state !== 'error' && !showSheet && !overlay;

  const States = (window.MemoXStates && window.MemoXStates.LibraryOverview) || {};
  const ctx = {
    go, state, Ic, masteryColor, Scrim, Dialog, FolderCard, FoldersList,
    LoadingList, EmptyCard, ErrorCard, OverflowSheet, folders, seedSwatches, iconChoices, target
  };
  const mod = States[state] || States.loaded;
  const out = mod ? mod(ctx) : null;
  const body = out && out.body !== undefined ? out.body : out;
  const overlayNode = out && out.overlay !== undefined ? out.overlay : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {/* Large title app bar */}
      <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Library</div>
        <button className="icon-btn">
          <Ic name="sliders-horizontal" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      {/* Search */}
      <div style={{ padding: '0 16px 8px' }}>
        <SearchField placeholder="Search decks, cards, tags" active={searchActive} />
      </div>

      {/* Today summary strip */}
      {bgLoaded &&
        <div style={{ padding: '0 16px 12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))', border: 'none', borderRadius: 'var(--memox-radius-lg)', cursor: 'pointer' }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-primary)', color: 'var(--memox-on-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Ic name="zap" size="sm" color="var(--memox-on-primary)" />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>77 cards due today</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1 }}>Across 3 folders · ~14 min</div>
            </div>
            <Ic name="chevron-right" size="sm" color="var(--memox-primary)" />
          </div>
        </div>}

      {/* Folders header */}
      {(bgLoaded || state === 'loading' || state === 'overflow') &&
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 20px 8px' }}>
          <span className="ov">{state === 'loading' ? 'Loading folders' : `${folders.length} folders`}</span>
          <button className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
            <Ic name="arrow-down-up" size="xs" color="var(--memox-on-surface-variant)" />
            Recent
            <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
          </button>
        </div>}

      {/* ScreenScroll — FAB floats above the bottom nav, so clear with .scroll-fab-nav */}
      <div className="scroll scroll-fab-nav">
        {body}
      </div>

      {/* FAB — shared pinned chrome, lifted above the bottom nav */}
      {showFAB && <Fab icon="folder-plus" label="New folder" aboveNav />}

      {overlayNode}

      <BottomNav active="library" onChange={go} />

    </div>);
}

Object.assign(window, { LibraryOverviewScreen });
})();
