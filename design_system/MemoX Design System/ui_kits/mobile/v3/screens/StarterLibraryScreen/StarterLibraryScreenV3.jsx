/* MemoX Mobile v3 — StarterLibraryScreenV3  (A6 · Starter library)  ADDED in v3
   v1 language: drill-down bar · Note · deck cards (44px tile · title · meta) · sheet
   with OptionRow. Rules: templates are development fixtures and say so (BR-87);
   adding creates an ordinary, independent deck with the chosen algorithm (the
   template suggests one); adding a template that is already present copies
   nothing unless a second copy is explicitly confirmed (BR-37, BR-38).
   States: list · choose · adding · added · alreadyPresent · secondCopy · addFailed · loading · none · loadFailed */
(function () {
const { StatusBar, Ic, Note, Badge, OptionRow, Scrim, BottomSheet, Dialog, Snackbar, Spinner, EmptyState, ErrorState, Skeleton } = window;

/* SAMPLE_DATA · starterLibrary[0] */
const templates = [
  { t: 'English → Vietnamese · Everyday', lang: 'English · Vietnamese', cards: 120, subs: 4, src: 'Development fixture', algo: 'Eight boxes', installed: true },
  { t: 'Korean → Romanisation · Hangul basics', lang: 'Korean · Latin', cards: 60, subs: 2, src: 'Development fixture', algo: 'SM-2' }
];

const TemplateCard = ({ x }) =>
  <div className="card" style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: '48px 1fr', gap: 16, padding: 16 }}>
    <div className="icon-tile" style={{ width: 44, height: 44, borderRadius: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Ic name="sparkles" size="sm" color="var(--memox-primary)" /></div>
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', lineHeight: 1.25 }}>{x.t}</div>
        {x.installed && <Badge tone="neutral">In library</Badge>}
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{x.lang} · {x.cards} cards · {x.subs} sub-decks · {x.src}</div>
      <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
        <button className="pill-btn primary" style={{ height: 40, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, flexShrink: 0, whiteSpace: 'nowrap' }}><Ic name="plus" size="xs" color="var(--memox-on-primary)" />{x.installed ? 'Add another copy' : 'Add to library'}</button>
        <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', alignSelf: 'center', minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>Suggests {x.algo}</span>
      </div>
    </div>
  </div>;

function StarterLibraryScreenV3({ go, state = 'list' }) {
  const x = templates[1];
  let overlay = null;
  if (['choose', 'adding', 'addFailed'].includes(state)) overlay = (
    <><Scrim /><BottomSheet scrim={false}>
      <div style={{ padding: '4px 20px 8px' }}><div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px' }}>Add “{x.t}”</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4 }}>{x.cards} cards in {x.subs} sub-decks, as a new deck of your own.</div></div>
      <div className="ov" style={{ padding: '4px 20px 4px' }}>Review algorithm · required</div>
      <div style={{ padding: '0 4px' }}>
        <OptionRow title="SM-2" sub="Suggested for this deck · grade yourself, intervals adapt" selected disabled={state === 'adding'} />
        <OptionRow title="Eight boxes" sub="Boxes 1–8 · match, guess, recall, fill" disabled={state === 'adding'} last />
      </div>
      {state === 'addFailed' && <div style={{ margin: '4px 20px 8px', padding: '10px 12px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 12, fontSize: 12, lineHeight: 1.5, display: 'flex', gap: 8 }}><Ic name="alert-circle" size="xs" color="var(--memox-error)" /><span><strong style={{ fontWeight: 700 }}>Couldn’t add the deck.</strong> Nothing was copied — try again.</span></div>}
      <div style={{ padding: '8px 16px 16px', display: 'flex', gap: 8, borderTop: 'var(--memox-border-ghost)' }}>
        <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
        <button className="pill-btn primary" disabled={state === 'adding'} style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8 }}>{state === 'adding' ? <><Spinner color="var(--memox-on-primary)" size="xs" />Adding…</> : state === 'addFailed' ? 'Try again' : <><Ic name="plus" size="xs" color="var(--memox-on-primary)" />Add deck</>}</button>
      </div>
    </BottomSheet></>);
  if (state === 'secondCopy') overlay = (
    <Dialog size="md">
      <div style={{ padding: '20px 20px 4px' }}><div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Add a second copy?</div><div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>“{templates[0].t}” is already in your library. A second copy is a separate deck with its own progress.</div></div>
      <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}><button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button><button className="pill-btn primary" style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Add second copy</button></div>
    </Dialog>);
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('library')} aria-label="Back"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Starter decks</div>
      </div>
      <div className="scroll">
        {state === 'loadFailed' ? <ErrorState title="Couldn't load starter decks" body="Your library is unaffected. Try again in a moment." /> :
         state === 'none' ? <EmptyState icon="sparkles" title="No starter decks in this build" body="This version ships without practice content. Create a deck or import cards instead." action={<button className="pill-btn primary" style={{ fontSize: 14 }}>Create a deck</button>} /> : <>
          <Note icon="flask-conical" style={{ marginBottom: 16 }}>These decks are practice fixtures for development and testing, not published course material. Anything you add is yours to edit.</Note>
          {state === 'loading' ? [0, 1].map((i) => <div key={i} className="card" style={{ marginBottom: 8, padding: 16, display: 'grid', gridTemplateColumns: '48px 1fr', gap: 16 }}><Skeleton w={44} h={44} r={12} /><div><Skeleton w={180} h={12} /><div style={{ height: 6 }} /><Skeleton w={220} h={10} op={0.4} /><div style={{ height: 12 }} /><Skeleton w={120} h={40} r={10} op={0.4} /></div></div>) :
            templates.map((t) => <TemplateCard key={t.t} x={t} />)}
        </>}
      </div>
      {overlay}
      {state === 'added' && <Snackbar action="Open">Added “{x.t}” · SM-2 · 60 new cards</Snackbar>}
      {state === 'alreadyPresent' && <Snackbar>Already in your library — nothing was copied</Snackbar>}
    </div>);
}

Object.assign(window, { StarterLibraryScreenV3 });
})();
