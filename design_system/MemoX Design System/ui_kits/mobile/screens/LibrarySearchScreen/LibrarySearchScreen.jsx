/* MemoX Mobile — LibrarySearchScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout (one screen = one folder):
     LibrarySearchScreen/
       LibrarySearchScreen.jsx   ← this file: shell + shared helpers + dispatch
       states/                   ← one file per state; each registers its scroll
                                   body into window.MemoXStates.LibrarySearch[<state>]

   Each state is isolated in its own file — adding/editing one can't disturb the
   others. The MAIN file owns the shared chrome (search app bar, filter chips,
   scroll wrapper) and the reusable helpers (Skel, Group, Highlight, Row + the
   type-color tokens), and computes the state-derived flags. State files are thin
   compositions that render just the scroll body.

   Contract — a state module is:
     window.MemoXStates.LibrarySearch.<name> = (ctx) => <React body for .scroll>
   ctx exposes:
     { go, state, query, empty, loading, error, noRes, showResults,
       Ic, Skel, Group, Highlight, Row, T_FOLDER, T_DECK, T_CARD, T_TAG } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

/* ── shared skeleton ── */
const Skel = window.Skeleton;

/* ── Group of results — header counts on the right; "See all" if more ── */
const Group = ({ title, ic, color, count, more, children }) =>
  <div style={{ marginBottom: 16 }}>
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 8px' }}>
      <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <Ic name={ic} size="xs" color={color} />
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.4, textTransform: 'uppercase', color: color }}>{title}</span>
        <span style={{
          fontSize: 12, fontWeight: 700, color: 'var(--memox-on-surface-variant)',
          padding: '0 4px', borderRadius: 999, background: 'var(--memox-surface-container)', fontVariantNumeric: 'tabular-nums'
        }}>{count}</span>
      </div>
      {more &&
        <button style={{
          background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600,
          fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4
        }}>
          See all
          <Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
        </button>}
    </div>
    <div className="card" style={{ padding: 0, overflow: 'hidden' }}>{children}</div>
  </div>;

/* ── Highlighted query inside text ── */
const Highlight = ({ text, q }) => {
  if (!q) return <>{text}</>;
  const i = text.toLowerCase().indexOf(q.toLowerCase());
  if (i < 0) return <>{text}</>;
  return (
    <>
      {text.slice(0, i)}
      <mark style={{
        background: 'color-mix(in srgb, var(--memox-primary) 18%, transparent)', color: 'var(--memox-primary)',
        padding: '0 2px', borderRadius: 4, fontWeight: 700
      }}>{text.slice(i, i + q.length)}</mark>
      {text.slice(i + q.length)}
    </>);
};

/* ── Result row — generic shell with type-specific icon/leading ── */
const Row = ({ ic, color, title, sub, trailing, last }) =>
  <div style={{
    display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px',
    borderBottom: last ? 'none' : 'var(--memox-border-ghost)', cursor: 'pointer'
  }}>
    <div style={{ width: 26, height: 26, borderRadius: 8, background: `color-mix(in srgb, ${color} 12%, transparent)`, color: color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={ic} size="xs" color={color} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{title}</div>
      {sub &&
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>}
    </div>
    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>{trailing}</div>
  </div>;

/* ── Type color tokens (shared across states) ── */
const T_FOLDER = 'var(--memox-primary)'; // primary indigo
const T_DECK = 'var(--memox-accent)';    // accent
const T_CARD = 'var(--memox-mastery)';
const T_TAG = 'var(--memox-streak)';

/* ════════════════════════════════════════════════════════════════════════
   SCREEN — search app bar + filter chips (chrome) + delegated scroll body.
   ════════════════════════════════════════════════════════════════════════ */
function LibrarySearchScreen({ go, state = 'emptyQuery' }) {
  const empty = state === 'emptyQuery';
  const loading = state === 'loading';
  const error = state === 'error';
  const noRes = state === 'noResults';
  const showResults = state === 'results';
  const query = empty ? '' : noRes ? 'phras' : '연구';

  const States = (window.MemoXStates && window.MemoXStates.LibrarySearch) || {};
  const ctx = {
    go, state, query, empty, loading, error, noRes, showResults,
    Ic, Skel, Group, Highlight, Row, T_FOLDER, T_DECK, T_CARD, T_TAG
  };
  const renderBody = States[state] || States.emptyQuery;

  return (
    <div className="app">
      <StatusBar />

      {/* Search app bar — prominent, focused */}
      <div className="appbar" style={{ justifyContent: 'flex-start', gap: 8 }}>
        <button className="icon-btn" onClick={() => go('library')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div style={{
          flex: 1, display: 'flex', alignItems: 'center', gap: 8, height: 38, padding: '0 12px',
          background: 'var(--memox-surface-container-lowest)', border: '1px solid var(--memox-primary)', borderRadius: 'var(--memox-radius-md)'
        }}>
          <Ic name="search" size="xs" color="var(--memox-primary)" />
          <span style={{
            flex: 1, fontSize: 14, color: empty ? 'var(--memox-on-surface-variant)' : 'var(--memox-on-surface)',
            fontWeight: empty ? 500 : 600, display: 'inline-flex', alignItems: 'center', whiteSpace: 'nowrap', overflow: 'hidden'
          }}>
            {empty ? 'Search library' : query}
            <span style={{ display: 'inline-block', width: 2, height: 16, background: 'var(--memox-primary)', animation: 'memoxBlink 1s infinite', marginLeft: empty ? 4 : 2 }} />
          </span>
          {!empty &&
            <button className="icon-btn" style={{ width: 24, height: 24 }} title="Clear">
              <Ic name="x-circle" size="xs" color="var(--memox-on-surface-variant)" />
            </button>}
        </div>
      </div>

      {/* Filter chips — type filter (only when not empty/error) */}
      {!error && !empty &&
        <div style={{ padding: '0 16px 8px' }}>
          <div className="scroll-x" style={{ display: 'flex', gap: 4 }}>
            {[
              { label: 'All', active: true, count: noRes ? 0 : 18 },
              { label: 'Folders', ic: 'folder', count: noRes ? 0 : 1, c: T_FOLDER },
              { label: 'Decks', ic: 'layers', count: noRes ? 0 : 2, c: T_DECK },
              { label: 'Flashcards', ic: 'copy', count: noRes ? 0 : 12, c: T_CARD },
              { label: 'Tags', ic: 'tag', count: noRes ? 0 : 3, c: T_TAG }
            ].map((f) =>
              <button key={f.label} style={{
                height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12,
                background: f.active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)',
                color: f.active ? 'var(--memox-on-primary)' : 'var(--memox-on-surface)', border: f.active ? 'none' : 'var(--memox-border-ghost)',
                display: 'inline-flex', alignItems: 'center', gap: 4, fontFamily: 'inherit', fontWeight: 600, flexShrink: 0, cursor: 'pointer'
              }}>
                {f.ic && !f.active && <Ic name={f.ic} size="xs" color={f.c || 'var(--memox-on-surface-variant)'} />}
                {f.label}
                <span style={{ fontSize: 12, fontWeight: 700, opacity: f.active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.count}</span>
              </button>
            )}
          </div>
        </div>}

      <div className="scroll">
        {renderBody ? renderBody(ctx) : null}
      </div>

    </div>);
}

Object.assign(window, { LibrarySearchScreen });
})();
