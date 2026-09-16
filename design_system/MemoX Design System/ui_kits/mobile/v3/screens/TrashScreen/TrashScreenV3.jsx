/* MemoX Mobile v3 — TrashScreenV3  (A14 · Trash)  ADDED in v3
   v1 language: drill-down bar · filter chips with counts · card rows (tile · name ·
   meta · ⋮) · selection checkboxes · in-flow bulk bar · sheets · dialogs · snackbar.
   Rules: entries newest first, filtered all / cards / decks; each shows name, type,
   when deleted, days left, original location (information only, BR-267), and for
   decks how many decks and cards are inside; restore always asks for a target
   (BR-261); a selection never mixes cards and decks (BR-266); permanent deletion
   is the only destructive action — strong confirmation, exact count, history lost,
   safe default (BR-266); an entry that contains a younger entry cannot be purged
   yet (BR-265); 30 × 24 h retention (BR-264).
   States: all · cards · decks · selection · restoreTarget · noTarget · restored ·
   undoRefused · purgeConfirm · purged · youngerInside · empty · loading · error */
(function () {
const { StatusBar, Ic, Badge, Note, Scrim, BottomSheet, Dialog, Snackbar, EmptyState, ErrorState, Skeleton } = window;

/* SAMPLE_DATA · trash[0] */
const entries = [
  { id: 'b1', type: 'card', name: '먹다 · ăn', when: '4 minutes ago', left: 30, from: '한국어 TOPIK I · Từ vựng › Động từ · 동사' },
  { id: 'b2', type: 'deck', name: 'Korean Basics', when: 'yesterday', left: 29, from: 'Top level', subs: 2, cards: 10, root: true },
  { id: 'b3', type: 'deck', name: 'Nơi chốn · 장소', when: '28 days ago', left: 2, from: '한국어 TOPIK I · Từ vựng › Danh từ · 명사', subs: 0, cards: 180, younger: true },
  { id: 'b4', type: 'card', name: 'homework · bài tập về nhà', when: '30 days ago', left: 0, hours: 1, from: 'Tiếng Anh giao tiếp hằng ngày › Học qua phim' }
];
const leftTone = (e) => e.left <= 3 ? 'var(--memox-warning-ink)' : 'var(--memox-on-surface-variant)';
const leftText = (e) => e.left === 0 ? `${e.hours}h left` : `${e.left} ${e.left === 1 ? 'day' : 'days'} left`;

const Row = ({ e, select = false, selected = false }) =>
  <div className="card" role={select ? 'checkbox' : 'button'} aria-checked={select ? selected : undefined} tabIndex={0} style={{ marginBottom: 8, display: 'grid', gridTemplateColumns: select ? '22px 1fr auto' : '40px 1fr auto', gap: 12, alignItems: 'flex-start', padding: '12px 16px', border: selected ? '1px solid var(--memox-primary)' : undefined }}>
    {select ?
      <span style={{ marginTop: 8, width: 20, height: 20, borderRadius: 'var(--memox-radius-xs)', boxSizing: 'border-box', border: selected ? 'none' : '2px solid var(--memox-outline)', background: selected ? 'var(--memox-primary)' : 'transparent', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{selected && <Ic name="check" size={14} color="var(--memox-on-primary)" />}</span> :
      <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-surface-container)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Ic name={e.type === 'deck' ? 'layers' : 'copy'} size="sm" color="var(--memox-on-surface-variant)" /></div>}
    <div style={{ minWidth: 0 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
        <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{e.name}</div>
        <span style={{ fontSize: 12, fontWeight: 700, color: leftTone(e), whiteSpace: 'nowrap', fontVariantNumeric: 'tabular-nums' }}>{leftText(e)}</span>
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>
        {e.type === 'deck' ? `Deck · ${e.subs} sub-decks · ${e.cards} cards` : 'Card'} · deleted {e.when}
      </div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'flex', gap: 4, alignItems: 'center', minWidth: 0 }}>
        <Ic name="corner-left-up" size={12} color="var(--memox-outline)" /><span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>Was in {e.from}</span>
      </div>
    </div>
    {!select && <button className="icon-btn" style={{ width: 28, height: 28 }} aria-label={`Actions for ${e.name}`}><Ic name="more-vertical" size="xs" color="var(--memox-on-surface-variant)" /></button>}
  </div>;

const SheetBtn = ({ ic, label, sub, danger }) =>
  <button style={{ width: '100%', display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: danger ? 'var(--memox-error)' : 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
    <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: danger ? 'var(--memox-danger-soft)' : 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Ic name={ic} size="xs" color={danger ? 'var(--memox-error)' : 'var(--memox-primary)'} /></div>
    <div><div style={{ fontSize: 14, fontWeight: 600 }}>{label}</div>{sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{sub}</div>}</div>
    <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
  </button>;

function TrashScreenV3({ go, state = 'all' }) {
  const filter = state === 'cards' ? 'card' : state === 'decks' ? 'deck' : null;
  const selecting = ['selection', 'purgeConfirm', 'purged'].includes(state);
  const list = state === 'purged' ? entries.filter((e) => e.type !== 'card') : state === 'restored' ? entries.filter((e) => e.id !== 'b1') : filter ? entries.filter((e) => e.type === filter) : entries;
  const counts = { all: entries.length, card: entries.filter((e) => e.type === 'card').length, deck: entries.filter((e) => e.type === 'deck').length };
  let overlay = null;
  if (state === 'actions') overlay = <><Scrim /><BottomSheet scrim={false} maxHeight="none">
    <div style={{ padding: '4px 16px 8px' }}><div style={{ fontSize: 14, fontWeight: 700 }}>먹다 · ăn</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>Card · deleted 4 minutes ago · was in Động từ · 동사</div></div>
    <div style={{ padding: '0 8px 8px' }}><SheetBtn ic="rotate-ccw" label="Restore…" sub="Choose which deck it goes to" /><div style={{ height: 1, background: 'var(--memox-outline-variant)', margin: '8px 8px' }} /><SheetBtn ic="trash-2" label="Delete permanently" sub="Cannot be undone · history lost" danger /></div>
    <div style={{ height: 'env(safe-area-inset-bottom, 12px)' }} />
  </BottomSheet></>;
  if (state === 'restoreTarget' || state === 'noTarget') overlay = <><Scrim /><BottomSheet scrim={false}>
    <div style={{ padding: '4px 20px 12px' }}><div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Restore “먹다 · ăn” to…</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Its schedule, history, flag and tags come back with it. Only decks in the same tree that hold cards or are empty are offered.</div></div>
    {state === 'noTarget' ?
      <div style={{ padding: '8px 20px 16px' }}><EmptyState compact icon="folder-tree" title="Nowhere to restore right now" body="No deck in “한국어 TOPIK I · Từ vựng” can hold cards at the moment. Create an empty sub-deck there, then restore." style={{ marginTop: 0 }} /></div> :
      <div style={{ flex: 1, overflowY: 'auto', padding: '0 8px 8px' }}>
        {[{ n: 'Động từ · 동사', p: '한국어 TOPIK I · Từ vựng', s: '419 cards · where it was' }, { n: 'Trạng từ · 부사', p: '한국어 TOPIK I · Từ vựng', s: '28 cards' }, { n: 'Tính từ · 형용사', p: '한국어 TOPIK I · Từ vựng', s: 'Empty' }].map((t) =>
          <button key={t.n} style={{ width: '100%', display: 'grid', gridTemplateColumns: '30px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 8px', background: 'transparent', border: 'none', color: 'var(--memox-on-surface)', borderRadius: 'var(--memox-radius-md)', fontFamily: 'inherit', cursor: 'pointer', textAlign: 'left' }}>
            <div style={{ width: 28, height: 28, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><Ic name="copy" size="xs" color="var(--memox-primary)" /></div>
            <div style={{ minWidth: 0 }}><div style={{ fontSize: 14, fontWeight: 600 }}>{t.n}</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{t.p} · {t.s}</div></div>
            <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
          </button>)}
      </div>}
    <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)' }}><button className="pill-btn outline" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>{state === 'noTarget' ? 'OK' : 'Cancel'}</button></div>
  </BottomSheet></>;
  if (state === 'purgeConfirm') overlay = <Dialog>
    <div style={{ padding: '20px 20px 4px', textAlign: 'center' }}>
      <div style={{ width: 48, height: 48, borderRadius: 16, background: 'var(--memox-danger-soft)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}><Ic name="trash-2" size="md" color="var(--memox-error)" /></div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Delete 2 cards permanently?</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, padding: '0 4px' }}>They disappear for good, together with their <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>study history</strong>. This cannot be undone.</div>
    </div>
    <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
      <button className="pill-btn primary" autoFocus style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Keep in Trash</button>
      <button className="pill-btn" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, background: 'var(--memox-error-fill)', color: 'var(--memox-on-error-fill)', border: 'none', fontWeight: 600, gap: 4 }}><Ic name="trash-2" size="xs" color="var(--memox-on-error-fill)" />Delete 2</button>
    </div>
  </Dialog>;
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('library')} aria-label={selecting ? 'Clear selection' : 'Back'}><Ic name={selecting ? 'x' : 'arrow-left'} size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>{selecting ? '2 cards selected' : 'Trash'}</div>
        {!selecting && state !== 'empty' && state !== 'loading' && state !== 'error' && <button className="pill-btn" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12, background: 'transparent', border: 'none', color: 'var(--memox-primary)' }}>Select</button>}
      </div>
      <div className="scroll">
        {state === 'error' ? <ErrorState title="Couldn't open Trash" body="Your data is safe on this device. Try again in a moment." /> :
         state === 'empty' ? <EmptyState icon="trash-2" title="Trash is empty" body="Decks and cards you delete stay here for 30 days before they are removed for good." /> : <>
          <Note icon="history" style={{ marginBottom: 12 }}>Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go.</Note>
          {!selecting &&
            <div className="scroll-x" style={{ display: 'flex', gap: 4, marginBottom: 12 }}>
              {[{ id: null, l: 'All', c: counts.all }, { id: 'card', l: 'Cards', c: counts.card }, { id: 'deck', l: 'Decks', c: counts.deck }].map((f) => {
                const active = f.id === filter;
                return <button key={f.l} className="pill-btn" style={{ height: 28, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: active ? 'var(--memox-primary)' : 'var(--memox-surface-container-lowest)', color: active ? 'var(--memox-on-primary)' : 'var(--memox-on-surface)', border: active ? 'none' : 'var(--memox-border-ghost)', flexShrink: 0 }}>{f.l}<span style={{ fontWeight: 700, opacity: active ? 0.75 : 0.6, fontVariantNumeric: 'tabular-nums' }}>{f.c}</span></button>;
              })}
            </div>}
          <div style={{ padding: '0 4px 8px' }}><span className="ov">{selecting ? '2 of 2 cards' : `${list.length} ${list.length === 1 ? 'entry' : 'entries'} · newest first`}</span></div>
          {state === 'loading' ? [0, 1, 2].map((i) => <div key={i} className="card" style={{ marginBottom: 8, padding: '12px 16px', display: 'grid', gridTemplateColumns: '40px 1fr', gap: 12 }}><Skeleton w={36} h={36} r={12} /><div><Skeleton w={140} h={11} /><div style={{ height: 6 }} /><Skeleton w={200} h={9} op={0.4} /></div></div>) :
            list.map((e) => <Row key={e.id} e={e} select={selecting} selected={selecting && e.type === 'card'} />)}
          {selecting && <Note>Only cards are selectable while cards are selected — a selection never mixes cards and decks.</Note>}
          {state === 'youngerInside' && <Note icon="alert-circle" style={{ marginTop: 4 }}>“Nơi chốn · 장소” still contains a card deleted later (“homework”). It can be removed for good once that entry is gone.</Note>}
        </>}
      </div>
      {selecting &&
        <div style={{ flexShrink: 0, borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', padding: '8px 16px calc(12px + env(safe-area-inset-bottom, 0px))', display: 'flex', gap: 8 }}>
          <button className="pill-btn primary" style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}><Ic name="rotate-ccw" size="xs" color="var(--memox-on-primary)" />Restore 2…</button>
          <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, color: 'var(--memox-error)', borderColor: 'color-mix(in srgb, var(--memox-danger) 40%, transparent)' }}><Ic name="trash-2" size="xs" color="var(--memox-error)" />Delete for good</button>
        </div>}
      {overlay}
      {state === 'restored' && <Snackbar>“먹다 · ăn” restored to Động từ · 동사</Snackbar>}
      {state === 'undoRefused' && <Snackbar>Can’t undo — “Động từ · 동사” is in Trash too. Restore it from here and choose a deck.</Snackbar>}
      {state === 'purged' && <Snackbar>2 cards deleted permanently</Snackbar>}
    </div>);
}

Object.assign(window, { TrashScreenV3 });
})();
