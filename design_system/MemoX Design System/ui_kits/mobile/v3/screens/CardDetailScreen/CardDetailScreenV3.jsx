/* MemoX Mobile v3 — CardDetailScreen · MAIN  (A10 · Card detail and review history)
   ────────────────────────────────────────────────────────────────────────
   Cloned from v1 FlashcardHistoryScreen. Product corrections:
     EDIT   "Card history" → the card's read-only detail: content (only fields with
            values, BR-240), tags, flag, current schedule, then history.
     EDIT   eight boxes, not five (BR-15); facts are due · learned · last answered ·
            answers · lapses · box (eight_box) or ease · interval · repetitions (sm2).
     REMOVE recall rate, correct streak, answer durations (no accuracy or timing
            anywhere, BR-243); "edited / created / audio added" events (history
            holds review events only); the event filter (no such action).
     EDIT   events show stored values: kind (learning · scheduled · relearning),
            action, mode, hint used, timeout, box or ease/interval before → after
            for the algorithm they were recorded under, next due (BR-242).
     ADD    generation groups identified in text (BR-243); load more (50/page);
            card-not-found state.
   Timeline anatomy (dot marker · badge · relative + absolute time · meta row) is v1's.

   ctx: { Ic, Skel, Timeline, events, olderEvents, Note } */
(function () {
const { StatusBar, Ic, Breadcrumb, Note, StatusBadge } = window;
const Skel = window.Skeleton;

/* SAMPLE_DATA · cardDetail[0]: eight_box, generation 2, after a reset that switched from SM-2. */
const card = { front: 'reservation', back: 'sự đặt chỗ trước', example: "I'd like to make a reservation for two at seven.", hint: 'Đồng nghĩa: booking', pronunciation: '/ˌrez.əˈveɪ.ʃən/', tags: ['restaurant', 'travel'], flagged: false };
const sched = { state: 'reviewing', box: 5, due: 'Sat 20 Sep · 00:00', learned: '20 Aug 2026', last: '4 Sep 2026 · 19:00', answers: 4, lapses: 0, algo: 'Eight boxes', gen: 2 };

/* Generation 2 events (newest first), then the SM-2 generation 1 group. */
const events = [
  { t: '12 days ago', date: '4 Sep · 19:00', kind: 'scheduled', action: 'remembered', mode: 'Recall', from: 4, to: 5, next: '20 Sep' },
  { t: '3 weeks ago', date: '27 Aug · 20:10', kind: 'scheduled', action: 'remembered', mode: 'Fill', from: 3, to: 4, next: '4 Sep', hint: true },
  { t: '3 weeks ago', date: '23 Aug · 18:00', kind: 'scheduled', action: 'remembered', mode: 'Guess', from: 2, to: 3, next: '27 Aug' },
  { t: '4 weeks ago', date: '21 Aug · 19:40', kind: 'scheduled', action: 'remembered', mode: 'Match', from: 1, to: 2, next: '23 Aug' },
  { t: '4 weeks ago', date: '20 Aug · 08:09', kind: 'learning', action: 'remembered', mode: 'Fill', note: 'Finished learning · box 1, due 21 Aug' },
  { t: '4 weeks ago', date: '20 Aug · 08:08', kind: 'relearning', action: 'remembered', mode: 'Recall' },
  { t: '4 weeks ago', date: '20 Aug · 08:07', kind: 'learning', action: 'forgot', mode: 'Recall', timeout: true },
  { t: '4 weeks ago', date: '20 Aug · 08:05', kind: 'learning', action: 'remembered', mode: 'Guess' },
  { t: '4 weeks ago', date: '20 Aug · 08:03', kind: 'learning', action: 'remembered', mode: 'Match' }
];
const olderEvents = [
  { t: '5 months ago', date: '12 Apr · 21:00', kind: 'scheduled', action: 'good', mode: 'Self-assess', ease: [2.36, 2.36], interval: [6, 15], next: '27 Apr' },
  { t: '5 months ago', date: '6 Apr · 20:30', kind: 'scheduled', action: 'hard', mode: 'Self-assess', ease: [2.5, 2.36], interval: [1, 6], next: '12 Apr' },
  { t: '6 months ago', date: '5 Mar · 16:10', kind: 'learning', action: 'good', mode: 'Self-assess', note: 'Finished learning · interval 1 day' }
];

/* Kind badge — names the kind in text (BR-243); action decides the colour. */
const KIND = { learning: 'Learning', scheduled: 'Review', relearning: 'Repeat' };
const tone = (e) => (e.action === 'forgot' || e.action === 'again')
  ? { color: 'var(--memox-warning-ink)', bg: 'var(--memox-warning-soft)', ic: 'rotate-ccw' }
  : e.kind === 'relearning' ? { color: 'var(--memox-on-surface-variant)', bg: 'var(--memox-surface-container)', ic: 'repeat' }
  : { color: 'var(--memox-primary)', bg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', ic: 'check' };
const ACTION = { remembered: 'Remembered', forgot: 'Forgot', again: 'Again', hard: 'Hard', good: 'Good', easy: 'Easy' };

const Move = ({ label, from, to, color }) =>
  <span style={{ fontSize: 12, fontWeight: 700, color, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
    <span style={{ opacity: 0.6, fontWeight: 600 }}>{label} {from}</span>
    <Ic name="arrow-right" size="xs" color={color} />
    <span>{to}</span>
  </span>;

/* Shared timeline builder — v1 anatomy. */
function Timeline(evts, { end = false } = {}) {
  return (
    <div style={{ position: 'relative', paddingLeft: 24 }}>
      <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
      {evts.map((e, i) => {
        const k = tone(e);
        return (
          <div key={i} style={{ position: 'relative', marginBottom: 12 }}>
            <span style={{ position: 'absolute', left: -19, top: 8, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface)', border: `3px solid ${k.color}`, boxSizing: 'border-box' }} />
            <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 8 }}>
                <span style={{ height: 22, padding: '0 8px', borderRadius: 999, background: k.bg, color: k.color, fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Ic name={k.ic} size="xs" color={k.color} />
                  {KIND[e.kind]} · {ACTION[e.action]}
                </span>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
                  <div style={{ fontWeight: 600, color: 'var(--memox-on-surface)' }}>{e.t}</div>
                  <div style={{ fontSize: 12, opacity: 0.7, marginTop: 2 }}>{e.date}</div>
                </div>
              </div>
              {e.note && <div style={{ fontSize: 14, lineHeight: 1.45, color: 'var(--memox-on-surface)', marginBottom: 8 }}>{e.note}</div>}
              <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '4px 10px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><Ic name="layers" size="xs" color="var(--memox-on-surface-variant)" />{e.mode}</span>
                {e.from != null && <Move label="Box" from={e.from} to={e.to} color={k.color} />}
                {e.ease && <Move label="Ease" from={e.ease[0]} to={e.ease[1]} color={k.color} />}
                {e.interval && <Move label="Interval" from={e.interval[0] + 'd'} to={e.interval[1] + 'd'} color={k.color} />}
                {e.hint && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><Ic name="lightbulb" size="xs" color="var(--memox-on-surface-variant)" />Hint used</span>}
                {e.timeout && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><Ic name="timer-off" size="xs" color="var(--memox-on-surface-variant)" />Time ran out</span>}
                {e.next && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontVariantNumeric: 'tabular-nums' }}><Ic name="calendar" size="xs" color="var(--memox-on-surface-variant)" />Next due {e.next}</span>}
              </div>
            </div>
          </div>);
      })}
      {end &&
        <div style={{ position: 'relative', marginTop: 4 }}>
          <span style={{ position: 'absolute', left: -19, top: 4, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface-container)', border: '2px solid var(--memox-outline-variant)', boxSizing: 'border-box' }} />
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', paddingTop: 4, fontStyle: 'italic' }}>Beginning of history · card added 5 Mar 2026</div>
        </div>}
    </div>);
}

const GenHeader = ({ label, sub }) =>
  <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 4px 8px' }}>
    <span className="ov">{label}</span>
    <span style={{ flex: 1, height: 1, background: 'var(--memox-outline-variant)' }} />
    <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>{sub}</span>
  </div>;

/* ════════════ SCREEN ════════════ */
function CardDetailScreenV3({ go, state = 'loaded' }) {
  const loading = state === 'loading';
  const error = state === 'error';
  const empty = state === 'empty';
  const notFound = state === 'notFound';
  const showSummary = !loading && !error && !notFound;

  const States = (window.MemoXStates && window.MemoXStates.CardDetail) || {};
  const ctx = { Ic, Skel, Timeline, GenHeader, events, olderEvents, Note };
  const mod = States[state] || States.loaded;
  const body = mod ? mod(ctx) : null;

  const facts = [
    { l: 'Due', v: sched.due, ic: 'clock' },
    { l: 'Learned', v: sched.learned, ic: 'check-circle-2' },
    { l: 'Last answered', v: sched.last, ic: 'history' },
    { l: 'Answers', v: sched.answers, ic: 'repeat' },
    { l: 'Lapses', v: sched.lapses, ic: 'rotate-ccw' },
    { l: 'Algorithm', v: `${sched.algo} · cycle ${sched.gen}`, ic: 'refresh-ccw' }
  ];

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')} aria-label="Back">
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Card</div>
        {showSummary &&
          <button className="pill-btn" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12, gap: 4, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>
            <Ic name="pencil" size="xs" color="var(--memox-primary)" />
            Edit
          </button>}
      </div>

      {!notFound && <Breadcrumb segments={[{ label: 'Library' }, { label: 'Tiếng Anh giao tiếp hằng ngày' }, { label: 'Nhà hàng' }, { label: 'Card' }]} />}

      <div className="scroll">
        {notFound ? body : <>
        {/* Card content — every field that has a value; absent fields do not appear (BR-240). */}
        <div className="card" style={{ padding: '16px 16px', marginBottom: 16 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'start' }}>
            <div style={{ minWidth: 0 }}>
              {loading ? <><Skel w={140} h={18} /><div style={{ height: 6 }} /><Skel w={180} h={11} op={0.4} /></> : <>
                <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', lineHeight: 1.2, overflowWrap: 'anywhere' }}>{card.front}</div>
                <div style={{ fontSize: 14, color: 'var(--memox-on-surface)', marginTop: 4, lineHeight: 1.45 }}>{card.back}</div>
              </>}
            </div>
            {!loading && <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>{card.flagged && <Ic name="flag" size="xs" color="var(--memox-streak)" label="Flagged" />}<StatusBadge status={sched.state} /></div>}
          </div>
          {!loading &&
            <div style={{ marginTop: 12, paddingTop: 12, borderTop: 'var(--memox-border-ghost)', display: 'flex', flexDirection: 'column', gap: 8 }}>
              {[['message-square', 'Example', card.example], ['lightbulb', 'Hint', card.hint], ['type', 'Pronunciation', card.pronunciation]].filter((r) => r[2]).map(([ic, l, v]) =>
                <div key={l} style={{ display: 'grid', gridTemplateColumns: '16px 1fr', gap: 8, alignItems: 'start' }}>
                  <Ic name={ic} size="xs" color="var(--memox-on-surface-variant)" />
                  <div><div style={{ fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase', color: 'var(--memox-on-surface-variant)' }}>{l}</div><div style={{ fontSize: 14, lineHeight: 1.45, marginTop: 4, overflowWrap: 'anywhere' }}>{v}</div></div>
                </div>)}
              {card.tags.length > 0 &&
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 4, marginTop: 4 }}>
                  {card.tags.map((t) => <span key={t} style={{ height: 22, padding: '0 8px', borderRadius: 999, background: 'var(--memox-surface-container)', color: 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, display: 'inline-flex', alignItems: 'center' }}>{t}</span>)}
                </div>}
            </div>}
        </div>

        {/* Current schedule — v1 progress card: eight boxes + facts. */}
        {showSummary &&
          <div className="card" style={{ padding: '16px', marginBottom: 16 }}>
            <div className="ov" style={{ marginBottom: 8 }}>Current schedule · Box {sched.box} of 8</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
              {Array.from({ length: 8 }).map((_, i) => {
                const idx = i + 1;
                const isCurrent = idx === sched.box;
                const isPast = idx < sched.box;
                return <div key={i} style={{ flex: 1, height: isCurrent ? 10 : 6, borderRadius: 999, background: isCurrent ? 'var(--memox-primary)' : isPast ? 'color-mix(in srgb, var(--memox-primary) 40%, transparent)' : 'var(--memox-surface-container-high)' }} />;
              })}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', marginBottom: 16, padding: '0 2px' }}>
              <span>Box 1 · 1 day</span><span>Box 8 · 128 days</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', rowGap: 16, columnGap: 16 }}>
              {facts.map((s) =>
                <div key={s.l} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 28, height: 28, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Ic name={s.ic} size="xs" color="var(--memox-primary)" />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.2, marginBottom: 2 }}>{s.l}</div>
                    <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.v}</div>
                  </div>
                </div>)}
            </div>
          </div>}

        {!error &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">{loading ? 'Loading history' : empty ? 'History' : 'History · newest first'}</span>
          </div>}

        {body}
        </>}
      </div>
    </div>);
}

Object.assign(window, { CardDetailScreenV3 });
})();
