/* MemoX Mobile v3 — StudyEntryScreenV3  (A16 · Study entry for a deck)  ADDED in v3
   Drawn in v1's language: drill-down app bar · breadcrumb · tinted summary card ·
   OptionRow lists · sticky footer CTA + caption. Product rules:
     new and due stated separately (BR-150); Learn when new > 0, Review when due > 0;
     eight_box review → choose one of match · guess · recall · fill, each with its
     capacity and, at zero, the reason (needs an example · needs five meanings ·
     needs two pairs) — never suggesting Reset (BR-100); sm2 review → no mode
     choice, choose the question direction, locked for the session (BR-203);
     an open session from today can be continued or replaced (BR-103); nothing due
     is a normal state (BR-29); showing counts never starts a session (BR-101).
   States: sm2 · eightBox · onlyNew · nothing · resume · starting · refused · startFailed · loading */
(function () {
const { StatusBar, Ic, Breadcrumb, OptionRow, Note, Badge, Spinner, Skeleton } = window;

const CTX = {
  sm2: { deck: 'Động từ · 동사', path: ['Library', '한국어 TOPIK I · Từ vựng'], algo: 'SM-2', fresh: 100, due: 40, overdue: 20 },
  eightBox: { deck: 'Nhà hàng', path: ['Library', 'Tiếng Anh giao tiếp hằng ngày'], algo: 'Eight boxes', fresh: 0, due: 12, overdue: 0, fillable: 3, meanings: 4 }
};

const Head = ({ c, fresh, due, overdue }) =>
  <div className="card" style={{ padding: '16px', marginBottom: 16, background: 'var(--memox-surface-hero)' }}>
    <div className="ov">{c.algo} · cards per session 20</div>
    <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
      {[{ v: fresh, l: 'New', c: 'var(--memox-status-new)' }, { v: due, l: 'Due', c: 'var(--memox-primary)' }].map((s) =>
        <div key={s.l} style={{ flex: 1, padding: '10px 12px', background: 'var(--memox-surface-container-lowest)', borderRadius: 'var(--memox-radius-md)' }}>
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', fontVariantNumeric: 'tabular-nums', color: s.v > 0 ? s.c : 'var(--memox-on-surface-variant)' }}>{s.v}</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.6 }}>{s.l}</div>
        </div>)}
    </div>
    {overdue > 0 && <div style={{ fontSize: 12, marginTop: 8, color: 'var(--memox-warning-ink)', fontWeight: 600 }}>{overdue} of the due cards are overdue</div>}
  </div>;

function StudyEntryScreenV3({ go, state = 'sm2' }) {
  const eb = ['eightBox', 'refused'].includes(state);
  const c = eb ? CTX.eightBox : CTX.sm2;
  const fresh = state === 'nothing' || state === 'eightBox' || state === 'refused' ? (eb ? 0 : 0) : c.fresh;
  const due = state === 'nothing' || state === 'onlyNew' ? 0 : c.due;
  const overdue = due ? c.overdue : 0;
  const nothing = state === 'nothing';
  const onlyNew = state === 'onlyNew';
  const loading = state === 'loading';
  const modes = [
    { t: 'Match', s: 'Pair terms with meanings, up to 5 at a time', cap: 12 },
    { t: 'Guess', s: 'Pick the meaning out of five', cap: c.meanings >= 5 ? 12 : 0, why: 'Needs five different meanings among the due cards' },
    { t: 'Recall', s: 'Recall the meaning within 20 seconds', cap: 12, on: true },
    { t: 'Fill', s: 'Type the term for the meaning', cap: c.fillable, why: 'Only cards that have an example can be filled in' }
  ];
  const directions = [
    { t: 'Term first', s: 'See the Korean, recall the meaning', on: true },
    { t: 'Meaning first', s: 'See the meaning, recall the Korean' },
    { t: 'Mixed', s: 'Half each way, evenly split' }
  ];
  const cta = nothing ? null : state === 'starting' ? <><Spinner color="var(--memox-on-primary)" size="xs" /> Starting…</> : onlyNew ? <><Ic name="sparkles" size="xs" color="var(--memox-on-primary)" />Learn 20 new cards</> : <><Ic name="play" size="xs" color="var(--memox-on-primary)" />Review {Math.min(due, 20)} due cards</>;
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('deck')} aria-label="Back"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{c.deck}</div>
        <button className="icon-btn" title="Study options" aria-label="Study options"><Ic name="sliders-horizontal" size="sm" color="var(--memox-on-surface-variant)" /></button>
      </div>
      <Breadcrumb segments={[...c.path.map((l) => ({ label: l })), { label: c.deck }]} />
      <div className="scroll">
        {loading ? <>
          <div className="card" style={{ padding: 16, marginBottom: 16 }}><Skeleton w={120} h={9} op={0.4} /><div style={{ height: 10 }} /><Skeleton w="100%" h={56} r={12} /></div>
          <div className="card" style={{ padding: 16 }}>{[0, 1, 2].map((i) => <div key={i} style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: i < 2 ? 16 : 0 }}><Skeleton w={20} h={20} shape="circle" /><div style={{ flex: 1 }}><Skeleton w={120} h={11} /><div style={{ height: 5 }} /><Skeleton w={200} h={9} op={0.4} /></div></div>)}</div>
        </> : <>
          <Head c={c} fresh={fresh} due={due} overdue={overdue} />

          {state === 'resume' &&
            <div className="card" style={{ padding: 16, marginBottom: 16 }}>
              <div className="ov" style={{ display: 'inline-flex', alignItems: 'center', gap: 4, marginBottom: 8 }}><span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-streak)', display: 'inline-block' }} />Session from today</div>
              <div style={{ fontSize: 14, fontWeight: 700 }}>Review · Self-assess · 12 of 20 cards</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>Continue where you stopped, or start something new — that ends this one and keeps its answers.</div>
              <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, marginTop: 12, gap: 8 }}><Ic name="play" size="xs" color="var(--memox-on-primary)" />Continue</button>
            </div>}

          {nothing &&
            <div className="card" style={{ padding: '24px 20px', textAlign: 'center', marginBottom: 16 }}>
              <div style={{ width: 52, height: 52, borderRadius: 16, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}><Ic name="check-circle-2" size="md" color="var(--memox-mastery)" /></div>
              <div style={{ fontSize: 16, fontWeight: 700, marginBottom: 4 }}>Nothing to do right now</div>
              <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Every card is learned and resting. Cards cannot be reviewed before they are due.</div>
            </div>}

          {fresh > 0 && !nothing &&
            <div className="card" style={{ padding: 16, marginBottom: 16, display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center' }}>
              <div><div style={{ fontSize: 14, fontWeight: 700 }}>Learn new cards</div><div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{c.algo === 'SM-2' ? 'Browse, then self-assess' : 'Browse → match → guess → recall → fill'} · 20 of {fresh} new · in creation order</div></div>
              <button className="pill-btn" style={{ height: 40, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, background: 'color-mix(in srgb, var(--memox-status-new) 12%, transparent)', color: 'var(--memox-status-new)', border: 'none' }}><Ic name="sparkles" size="xs" color="var(--memox-status-new)" />Learn</button>
            </div>}

          {due > 0 && !onlyNew && <>
            <div className="ov" style={{ padding: '0 4px 8px' }}>{eb ? 'Review · choose how cards are asked' : 'Review · question direction'}</div>
            <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8 }}>
              {(eb ? modes : directions).map((o, i, a) =>
                <OptionRow key={o.t} title={o.t} sub={o.cap === 0 ? o.why : o.s} selected={!!o.on} disabled={o.cap === 0} last={i === a.length - 1}
                  trailing={eb ? <Badge tone={o.cap === 0 ? 'neutral' : 'primary'}>{o.cap === 0 ? 'Not available' : `${o.cap} cards`}</Badge> : null} />)}
            </div>
            <Note style={{ marginBottom: 16 }}>{eb ? 'A mode that is not available lacks suitable cards for this review — it comes back when the cards qualify.' : 'SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy. The direction cannot change once the session starts.'}</Note>
          </>}

          {state === 'refused' &&
            <div style={{ padding: '12px 16px', background: 'var(--memox-warning-soft)', border: '1px solid var(--memox-warning-border)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
              <Ic name="alert-circle" size="xs" color="var(--memox-warning)" />
              <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}><strong style={{ fontWeight: 700 }}>Nothing is due any more.</strong> <span style={{ color: 'var(--memox-on-surface-variant)' }}>The due cards were reviewed from another session or moved to Trash since this screen was opened. Counts are up to date now.</span></div>
            </div>}
          {state === 'startFailed' &&
            <div style={{ padding: '12px 16px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'center', marginBottom: 16 }}>
              <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
              <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55 }}><strong style={{ fontWeight: 700 }}>Couldn’t start the session.</strong> <span style={{ color: 'var(--memox-on-surface-variant)' }}>Nothing was written. Try again.</span></div>
            </div>}
        </>}
      </div>
      {!loading && !nothing &&
        <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className="pill-btn primary" disabled={state === 'starting' || state === 'refused'} style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: state === 'refused' ? 0.45 : 1 }}>{state === 'startFailed' ? <><Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />Try again</> : state === 'resume' ? <><Ic name="play" size="xs" color="var(--memox-on-primary)" />Start a new review instead</> : cta}</button>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>{onlyNew ? 'Nothing is due — review is available once cards come due.' : eb ? 'Recall · 12 due cards · oldest first' : 'Term first · 20 of 40 due · oldest first'}</div>
        </div>}
    </div>);
}

Object.assign(window, { StudyEntryScreenV3 });
})();
