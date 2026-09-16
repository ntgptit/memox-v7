/* MemoX Mobile — FlashcardHistoryScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     FlashcardHistoryScreen/
       FlashcardHistoryScreen.jsx  ← shell + card preview + progress summary + Timeline builder
       states/                     ← one file per state in window.MemoXStates.FlashcardHistory

   The card preview, current-progress card and timeline section header are
   flag-derived chrome kept in MAIN. Each state file supplies the scroll body
   (real timeline / partial timeline / skeleton / empty / error) via the shared
   ctx.Timeline() builder, so editing one state never touches the others.

   ctx: { Ic, Skel, BoxMove, kinds, events, partialEvents, Timeline } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const front = '연구자';
const back = 'Researcher / Nhà nghiên cứu';
const totalBoxes = 5;
const summary = { box: 3, due: 'in 6 days', reviewCount: 14, lapseCount: 2, recallRate: 0.78, streak: 4, sinceCreated: '23 days' };

const events = [
  { t: '2h ago', date: 'today, 14:32', kind: 'correct', mode: 'Recall', ms: 1400, from: 2, to: 3, note: 'Answered correctly' },
  { t: 'yesterday', date: 'May 26, 09:10', kind: 'recovered', mode: 'Fill', ms: 4200, from: 1, to: 2, lapseAck: true, note: 'Got it back after a slip' },
  { t: '2 days ago', date: 'May 25, 21:48', kind: 'forgot', mode: 'Recall', ms: 6800, from: 3, to: 1, note: 'Couldn’t recall — reset to box 1', lapse: true },
  { t: '4 days ago', date: 'May 23, 08:00', kind: 'edited', note: 'Edit · meaning updated' },
  { t: 'a week ago', date: 'May 20, 19:14', kind: 'correct', mode: 'Match', ms: 900, from: 2, to: 3, note: 'Answered correctly' },
  { t: '10 days ago', date: 'May 17, 07:32', kind: 'correct', mode: 'Review', ms: 1600, from: 1, to: 2, note: 'Answered correctly' },
  { t: '13 days ago', date: 'May 14, 22:08', kind: 'audio', note: 'Pronunciation recorded' },
  { t: '23 days ago', date: 'May  4, 10:00', kind: 'created', note: 'Card added to TOPIK II — Vocab' }
];

const partialEvents = events.map((e, i) =>
  i === 1 ? { ...e, ms: null } : i === 2 ? { ...e, from: null, to: null, note: 'Logged with missing details' } : e);

const kinds = {
  correct: { label: 'Correct', color: 'var(--memox-primary)', bg: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', ic: 'check' },
  recovered: { label: 'Recovered', color: 'var(--memox-streak)', bg: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', ic: 'corner-up-right' },
  forgot: { label: 'Forgot', color: 'var(--memox-error)', bg: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', ic: 'rotate-ccw' },
  edited: { label: 'Edited', color: 'var(--memox-on-surface-variant)', bg: 'var(--memox-surface-container)', ic: 'pencil' },
  created: { label: 'Created', color: 'var(--memox-mastery)', bg: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', ic: 'sparkles' },
  audio: { label: 'Audio added', color: 'var(--memox-on-surface-variant)', bg: 'var(--memox-surface-container)', ic: 'mic' }
};

const Skel = window.Skeleton;

const BoxMove = ({ from, to, color }) => {
  if (from == null || to == null) {
    return <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontStyle: 'italic' }}>box change unavailable</span>;
  }
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8 }}>
      <span style={{ fontSize: 12, fontWeight: 700, color: color, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <span style={{ opacity: 0.6, fontWeight: 600 }}>B{from}</span>
        <Ic name={to > from ? 'arrow-right' : 'arrow-left'} size="xs" color={color} />
        <span>B{to}</span>
      </span>
    </div>);
};

/* Shared timeline builder used by the loaded + partial states. */
function Timeline(evts, showEnd) {
  return (
    <div style={{ position: 'relative', paddingLeft: 24 }}>
      <div style={{ position: 'absolute', left: 11, top: 8, bottom: 8, width: 2, background: 'var(--memox-surface-container)', borderRadius: 999 }} />
      {evts.map((e, i) => {
        const k = kinds[e.kind];
        return (
          <div key={i} style={{ position: 'relative', marginBottom: 12 }}>
            <span style={{ position: 'absolute', left: -19, top: 8, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface)', border: `3px solid ${k.color}`, boxSizing: 'border-box' }} />
            <div style={{ background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 12, padding: '12px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 8, marginBottom: 8 }}>
                <span style={{ height: 22, padding: '0 8px', borderRadius: 999, background: k.bg, color: k.color, fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                  <Ic name={k.ic} size="xs" color={k.color} />
                  {k.label}
                </span>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
                  <div style={{ fontWeight: 600, color: 'var(--memox-on-surface)' }}>{e.t}</div>
                  <div style={{ fontSize: 12, opacity: 0.7, marginTop: 1 }}>{e.date}</div>
                </div>
              </div>
              <div style={{ fontSize: 14, lineHeight: 1.45, color: 'var(--memox-on-surface)', marginBottom: e.from != null || e.mode || e.ms ? 8 : 0 }}>{e.note}</div>
              {(e.from != null || e.to != null || e.mode || e.ms != null) &&
                <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '4px 8px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                  {(e.from != null || e.to != null) && <BoxMove from={e.from} to={e.to} color={k.color} />}
                  {e.mode &&
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
                      <Ic name="layers" size="xs" color="var(--memox-on-surface-variant)" />
                      {e.mode}
                    </span>}
                  {e.ms != null ?
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontVariantNumeric: 'tabular-nums' }}>
                      <Ic name="timer" size="xs" color="var(--memox-on-surface-variant)" />
                      {(e.ms / 1000).toFixed(1)}s
                    </span> :
                    e.ms === null && e.mode && <span style={{ fontStyle: 'italic', opacity: 0.7 }}>duration not logged</span>}
                </div>}
            </div>
          </div>);
      })}
      {showEnd &&
        <div style={{ position: 'relative', marginTop: 4 }}>
          <span style={{ position: 'absolute', left: -19, top: 4, width: 14, height: 14, borderRadius: 999, background: 'var(--memox-surface-container)', border: '2px solid var(--memox-outline-variant)', boxSizing: 'border-box' }} />
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', paddingTop: 4, fontStyle: 'italic' }}>Beginning of history</div>
        </div>}
    </div>);
}

/* ════════════ SCREEN ════════════ */
function FlashcardHistoryScreen({ go, state = 'loaded' }) {
  const loading = state === 'loading';
  const error = state === 'error';
  const empty = state === 'empty';

  const showSummary = !loading && !error;
  const showHeader = !error;

  const States = (window.MemoXStates && window.MemoXStates.FlashcardHistory) || {};
  const ctx = { Ic, Skel, BoxMove, kinds, events, partialEvents, Timeline };
  const mod = States[state] || States.loaded;
  const body = mod ? mod(ctx) : null;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('cards')}>
          <Ic name="arrow-left" size="md" />
        </button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Card history</div>
        {!loading && !error &&
          <button className="pill-btn" style={{ height: 32, padding: '0 12px', borderRadius: 8, fontSize: 12, gap: 4, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>
            <Ic name="pencil" size="xs" color="var(--memox-primary)" />
            Edit
          </button>}
      </div>

      <Breadcrumb segments={[{ label: 'Library' }, { label: 'Korean' }, { label: 'TOPIK II — Vocab' }, { label: 'History' }]} />

      <div className="scroll">

        {/* Card preview */}
        <div className="card" style={{ padding: '16px 16px', marginBottom: 16, display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center' }}>
          <div style={{ minWidth: 0 }}>
            {loading ?
              <>
                <Skel w={140} h={18} />
                <div style={{ height: 6 }} />
                <Skel w={180} h={11} op={0.4} />
              </> :
              <>
                <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', lineHeight: 1.2 }}>{front}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{back}</div>
              </>}
          </div>
          {!loading &&
            <span style={{ height: 24, padding: '0 8px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)', fontSize: 12, fontWeight: 700, fontVariantNumeric: 'tabular-nums', display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
              <Ic name="zap" size="xs" color="var(--memox-primary)" />
              Box {summary.box} / {totalBoxes}
            </span>}
        </div>

        {/* Progress summary */}
        {showSummary &&
          <div className="card" style={{ padding: '16px', marginBottom: 16 }}>
            <div className="ov" style={{ marginBottom: 8 }}>Current progress</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
              {Array.from({ length: totalBoxes }).map((_, i) => {
                const idx = i + 1;
                const isCurrent = idx === summary.box;
                const isPast = idx < summary.box;
                return <div key={i} style={{ flex: 1, height: isCurrent ? 10 : 6, borderRadius: 999, background: isCurrent ? 'var(--memox-primary)' : isPast ? 'color-mix(in srgb, var(--memox-primary) 40%, transparent)' : 'var(--memox-surface-container-high)', transition: 'all 200ms ease' }} />;
              })}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums', marginBottom: 16, padding: '0 2px' }}>
              <span>Box 1</span>
              <span>Box 3</span>
              <span>Box 5</span>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', rowGap: 16, columnGap: 16 }}>
              {[
                { l: 'Due', v: summary.due, ic: 'clock' },
                { l: 'Reviews', v: summary.reviewCount, ic: 'repeat' },
                { l: 'Recall rate', v: `${Math.round(summary.recallRate * 100)}%`, ic: 'target' },
                { l: 'Lapses', v: summary.lapseCount, ic: 'rotate-ccw' },
                { l: 'Correct streak', v: `${summary.streak} in a row`, ic: 'flame' },
                { l: 'Since added', v: summary.sinceCreated, ic: 'calendar' }
              ].map((s) =>
                <div key={s.l} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 28, height: 28, borderRadius: 8, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Ic name={s.ic} size="xs" color="var(--memox-primary)" />
                  </div>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.2, marginBottom: 1 }}>{s.l}</div>
                    <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', fontVariantNumeric: 'tabular-nums', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.v}</div>
                  </div>
                </div>
              )}
            </div>
          </div>}

        {/* Timeline section header */}
        {showHeader &&
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">{loading ? 'Loading timeline' : empty ? 'Timeline' : `Timeline · ${events.length} events`}</span>
            {!loading && !empty &&
              <button className="pill-btn" style={{ height: 26, padding: '0 8px', borderRadius: 999, fontSize: 12, gap: 4, background: 'transparent', border: 'none', color: 'var(--memox-on-surface-variant)' }}>
                <Ic name="filter" size="xs" color="var(--memox-on-surface-variant)" />
                All events
                <Ic name="chevron-down" size="xs" color="var(--memox-on-surface-variant)" />
              </button>}
          </div>}

        {body}
      </div>

    </div>);
}

Object.assign(window, { FlashcardHistoryScreen });
})();
