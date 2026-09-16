/* MemoX Mobile v3 — ProgressScreenV3 · MAIN  (A20 · overview + A21 · by deck)
   ────────────────────────────────────────────────────────────────────────
   Cloned from v1 ProgressScreen. Product corrections:
     KEEP   v1 range segmented control, Card(title · value · sub · chart) rhythm,
            single-colour day bars (now stacked learning over reviewing), dashed
            per-chart empty, streak tile pair, read-only footer line, bottom nav.
     EDIT   ranges are exactly 7 and 30 days (BR-184) — "All time" removed.
     EDIT   counting unit is the card-day; today splits into learning · reviewing
            (BR-192, BR-195); streak card's second tile is today's count and the
            "held from yesterday" state is named (BR-197).
     REMOVE accuracy chart, longest streak, box distribution, suspended / buried
            rows, "insufficient data" hint (BR-191 / no such data).
     ADD    Progress by deck: active cards · active days · learning · reviewing
            card-days per root deck (or per child inside a deck), sorted by active
            cards ↓ with inactive decks last (BR-187); never-studied vs lapsed;
            streak lost; deck level with path.
   States are flag descriptors: { range, loading, never, heldStreak, lostStreak, deckLevel, error }. */
(function () {
const { StatusBar, Ic, BottomNav, Breadcrumb, Note } = window;
const Skel = window.Skeleton;

/* Last 7 days, oldest → newest, zero-filled: [learning, reviewing] card-days. */
const week = [[4, 8], [0, 18], [0, 0], [6, 16], [2, 12], [0, 9], [5, 12]];
const dayLabels = ['W', 'T', 'F', 'S', 'S', 'M', 'T'];
/* By deck — SAMPLE_DATA shape: activeCards · activeDays · learning · reviewing for 7 / 30 days. */
const decks7 = [
  { n: '한국어 TOPIK I · Từ vựng', cards: 61, days: 6, learn: 17, rev: 62 },
  { n: 'IELTS Academic Word List', cards: 24, days: 3, learn: 0, rev: 27 },
  { n: 'Tiếng Anh giao tiếp hằng ngày', cards: 9, days: 2, learn: 0, rev: 9 },
  { n: 'IT', cards: 0, days: 0, learn: 0, rev: 0 },
  { n: 'Korean Basics', cards: 0, days: 0, learn: 0, rev: 0 }
];
const decks30 = [
  { n: '한국어 TOPIK I · Từ vựng', cards: 214, days: 24, learn: 58, rev: 380 },
  { n: 'IELTS Academic Word List', cards: 120, days: 11, learn: 40, rev: 131 },
  { n: 'Tiếng Anh giao tiếp hằng ngày', cards: 31, days: 7, learn: 12, rev: 26 },
  { n: 'Korean Basics', cards: 10, days: 2, learn: 0, rev: 10 },
  { n: 'IT', cards: 0, days: 0, learn: 0, rev: 0 }
];
const children7 = [
  { n: 'Động từ · 동사', cards: 30, days: 5, learn: 9, rev: 31 },
  { n: 'Danh từ · 명사', cards: 26, days: 4, learn: 8, rev: 27 },
  { n: 'Trạng từ · 부사', cards: 5, days: 2, learn: 0, rev: 4 },
  { n: 'Tính từ · 형용사', cards: 0, days: 0, learn: 0, rev: 0 }
];
const sum = (arr, k) => arr.reduce((a, d) => a + d[k], 0);

const Card = ({ title, value, sub, children }) =>
  <div className="card" style={{ padding: '16px', marginBottom: 12 }}>
    <div style={{ marginBottom: children ? 12 : 0 }}>
      <div className="ov">{title}</div>
      {value != null && <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px', lineHeight: 1.1, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{value}</div>}
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 4, lineHeight: 1.45 }}>{sub}</div>}
    </div>
    {children}
  </div>;

const ChartEmpty = ({ line }) =>
  <div style={{ padding: '24px 16px', textAlign: 'center', background: 'var(--memox-surface-muted)', borderRadius: 'var(--memox-radius-md)', border: '1px dashed var(--memox-outline-variant)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>{line}</div>;

const Tile = ({ ic, c, l, v, sub }) =>
  <div style={{ flex: 1, padding: '12px', background: 'var(--memox-surface-muted)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', display: 'flex', alignItems: 'center', gap: 8, minWidth: 0 }}>
    <div style={{ width: 32, height: 32, borderRadius: 'var(--memox-radius-sm)', background: `color-mix(in srgb, ${c} 12%, transparent)`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
      <Ic name={ic} size="xs" color={c} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 700 }}>{l}</div>
      <div style={{ fontSize: 14, fontWeight: 700, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{v}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{sub}</div>}
    </div>
  </div>;

/* ════════════ SCREEN ════════════ */
function ProgressScreenV3({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.Progress) || {};
  const mod = States[state] || States.loaded;
  const f = (mod ? mod() : {}) || {};
  const { range = 'week', loading = false, never = false, heldStreak = false, lostStreak = false, deckLevel = false, error = false } = f;
  const { ErrorState } = window;

  const days = never ? week.map(() => [0, 0]) : week;
  const today = heldStreak || never || lostStreak ? [0, 0] : days[6];
  const streak = never || lostStreak ? 0 : heldStreak ? 11 : 12;
  const rows = deckLevel ? children7 : range === 'week' ? decks7 : decks30;
  const scope = never ? rows.map((d) => ({ ...d, cards: 0, days: 0, learn: 0, rev: 0 })) : rows;
  const rangeLabel = range === 'week' ? 'last 7 days' : 'last 30 days';

  return (
    <div className="app">
      <StatusBar />
      <div className={'appbar' + (deckLevel ? '' : ' appbar-lg')} style={{ justifyContent: 'space-between' }}>
        {deckLevel ?
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, minWidth: 0, flex: 1 }}>
            <button className="icon-btn" aria-label="Back to library level"><Ic name="arrow-left" size="md" /></button>
            <div className="title" style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.3px', flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>한국어 TOPIK I · Từ vựng</div>
          </div> :
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Progress</div>}
      </div>
      {deckLevel && <Breadcrumb segments={[{ label: 'Progress' }, { label: '한국어 TOPIK I · Từ vựng' }]} />}

      <div className="scroll">
        {error ? <ErrorState title="Couldn't summarise your progress" body="Your study history is safe on this device. Try again in a moment." /> : <>

        {/* Range — exactly two (BR-184). Switching is instant; both come from one read. */}
        <div style={{ display: 'inline-flex', padding: 4, gap: 2, background: 'var(--memox-surface-container)', borderRadius: 'var(--memox-radius-md)', marginBottom: 16 }} role="tablist">
          {[{ id: 'week', label: 'Last 7 days' }, { id: 'month', label: 'Last 30 days' }].map((t) => {
            const active = t.id === range;
            return <button key={t.id} role="tab" aria-selected={active} style={{ height: 32, padding: '0 16px', borderRadius: 'var(--memox-radius-sm)', background: active ? 'var(--memox-surface-container-lowest)' : 'transparent', border: 'none', color: active ? 'var(--memox-on-surface)' : 'var(--memox-on-surface-variant)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', boxShadow: active ? 'var(--memox-shadow-soft)' : 'none' }}>{t.label}</button>;
          })}
        </div>

        {loading && [0, 1, 2].map((i) =>
          <div key={i} className="card" style={{ padding: '16px', marginBottom: 12 }}>
            <Skel w={80} h={9} op={0.4} /><div style={{ height: 8 }} /><Skel w={120} h={20} /><div style={{ height: 14 }} /><Skel w="100%" h={70} r={12} />
          </div>)}

        {!loading && !deckLevel && <>
          {/* 1. Today + last seven days (A20) */}
          <Card title="Today" value={never || heldStreak || lostStreak ? 0 : today[0] + today[1]} sub={never ? 'Nothing studied yet' : today[0] + today[1] === 0 ? 'No cards studied yet today' : `${today[0]} learning · ${today[1]} reviewing · a card counts once per day`}>
            {never ?
              <ChartEmpty line="Your last seven days appear here once you study. Browsing cards does not count." /> :
              <>
                <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 78, padding: '0 2px' }}>
                  {days.map(([l, r], i) => {
                    const max = Math.max(...days.map(([a, b]) => a + b), 1);
                    const isToday = i === days.length - 1;
                    const tot = l + r;
                    return (
                      <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'flex-end', height: '100%' }} title={`${tot} cards · ${l} learning · ${r} reviewing`}>
                        {tot === 0 ? <div style={{ height: 2, borderRadius: 4, background: 'var(--memox-surface-container-high)' }} /> : <>
                          <div style={{ height: `${l / max * 100}%`, borderRadius: '4px 4px 0 0', background: 'var(--memox-status-learning)', opacity: isToday ? 1 : 0.7 }} />
                          <div style={{ height: `${r / max * 100}%`, borderRadius: l ? '0 0 4px 4px' : 4, background: 'var(--memox-primary)', opacity: isToday ? 1 : 0.55 }} />
                        </>}
                      </div>);
                  })}
                </div>
                <div style={{ display: 'flex', gap: 8, marginTop: 4, padding: '0 2px', fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                  {dayLabels.map((d, i) => <span key={i} style={{ flex: 1, textAlign: 'center', fontWeight: i === 6 ? 700 : 400 }}>{i === 6 ? 'Today' : d}</span>)}
                </div>
                <div style={{ display: 'flex', gap: 12, marginTop: 12, fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><span className="status-dot" style={{ width: 6, height: 6, background: 'var(--memox-status-learning)' }} />Learning</span>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}><span className="status-dot" style={{ width: 6, height: 6, background: 'var(--memox-primary)' }} />Reviewing</span>
                </div>
              </>}
          </Card>

          {/* 2. Streak — current only; second tile is today's count. Held / lost named in text (BR-197). */}
          <Card title="Streak">
            {never ?
              <ChartEmpty line="A streak starts with your first study day." /> :
              <>
                <div style={{ display: 'flex', gap: 8 }}>
                  <Tile ic="flame" c={streak > 0 ? 'var(--memox-streak)' : 'var(--memox-on-surface-variant)'} l="Current" v={`${streak} ${streak === 1 ? 'day' : 'days'}`} sub={heldStreak ? 'held from yesterday' : lostStreak ? 'no study yesterday' : 'includes today'} />
                  <Tile ic="calendar-check" c="var(--memox-primary)" l="Today" v={`${today[0] + today[1]} cards`} sub={today[0] + today[1] === 0 ? 'nothing yet' : 'counted once each'} />
                </div>
                {heldStreak && <Note style={{ marginTop: 12 }}>Study one card today and the streak continues at 12.</Note>}
                {lostStreak && <Note style={{ marginTop: 12 }}>The streak ended on Sunday. It starts again with the next card you study.</Note>}
              </>}
          </Card>
        </>}

        {/* 3. By deck (A21) — four numbers per deck, nothing else (BR-182). */}
        {!loading && <>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '2px 4px 8px' }}>
            <span className="ov">{deckLevel ? 'Sub-decks' : 'By deck'} · {rangeLabel}</span>
            <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontVariantNumeric: 'tabular-nums' }}>{sum(scope, 'cards')} active cards · {sum(scope, 'learn') + sum(scope, 'rev')} card-days</span>
          </div>
          <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
            {scope.map((d, i, a) => {
              const active = d.cards > 0;
              return (
                <div key={d.n} role="button" tabIndex={0} style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', opacity: active ? 1 : 0.6, cursor: 'pointer' }}>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{d.n}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums' }}>
                      {active ? <>{d.days} active {d.days === 1 ? 'day' : 'days'} · <span style={{ color: 'var(--memox-warning-ink)' }}>{d.learn} learning</span> · <span style={{ color: 'var(--memox-primary)' }}>{d.rev} reviewing</span></> : 'No activity in this range'}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: 16, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{d.cards}</div>
                    <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>cards</div>
                  </div>
                </div>);
            })}
          </div>
          <div style={{ textAlign: 'center', fontSize: 12, color: 'var(--memox-on-surface-variant)', padding: '4px 0 12px' }}>
            Read-only · a card studied several times in a day counts once · resets change nothing here
          </div>
        </>}
        </>}
      </div>
      <BottomNav active="progress" onChange={go} />
    </div>);
}

Object.assign(window, { ProgressScreenV3 });
})();
