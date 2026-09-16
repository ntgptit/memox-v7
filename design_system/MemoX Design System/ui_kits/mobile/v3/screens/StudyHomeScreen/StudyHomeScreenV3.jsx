/* MemoX Mobile v3 — StudyHomeScreen · MAIN  (A15 · Study home)
   ────────────────────────────────────────────────────────────────────────
   Cloned from v1 DashboardScreen. Product corrections:
     EDIT   "Home" → the Study area (four areas: Library · Study · Progress · Settings).
     KEEP   v1 composition: resume card → tinted workload hero → deck list.
     EDIT   hero: one merged "N cards due" → overdue · due today · new stated
            separately (BR-150); no minutes estimate; no "start all" — sessions
            are started per root deck (A16), so the hero is a summary, not a CTA.
     EDIT   "Recent decks" → every root deck with its whole-tree workload, ordered
            overdue ↓ today ↓ new ↓ name (BR-201); zero-workload decks stay, last.
     REMOVE greeting by name (no profile), streak + daily goal (Study home has no
            such data; streak lives in Progress), "start new learning" button,
            multi-resume (one resumable session), offline banner, streak-broken banner.
     ADD    the three loaded states the product distinguishes (BR-202): no decks ·
            decks without cards · decks with cards; zero workload as a normal state.

   ctx: { go, state, Ic, Skel, ContinueStudying, Workload, DeckList, LoadingBody, ErrorCard, decks } */
(function () {
const { StatusBar, Ic, BottomNav, Badge, Note } = window;
const { EmptyState } = window;
const Skel = window.Skeleton;
const fmt = (n) => n.toLocaleString('en-US');

/* SAMPLE_DATA · studyHome[0] */
const decks = [
  { n: 'IELTS Academic Word List', algo: 'Eight boxes', cards: 10000, overdue: 1100, today: 160, fresh: 7400 },
  { n: '한국어 TOPIK I · Từ vựng', algo: 'SM-2', cards: 1248, overdue: 41, today: 45, fresh: 312 },
  { n: 'Tiếng Anh giao tiếp hằng ngày', algo: 'Eight boxes', cards: 64, overdue: 0, today: 12, fresh: 0 },
  { n: 'IT', algo: 'Eight boxes', cards: 5, overdue: 0, today: 0, fresh: 5 },
  { n: 'Korean Basics', algo: 'SM-2', cards: 10, overdue: 0, today: 0, fresh: 0 },
  { n: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp trong báo cáo thường niên của doanh nghiệp niêm yết', algo: 'SM-2', cards: 0, overdue: 0, today: 0, fresh: 0 }
];
const sum = (k) => decks.reduce((a, d) => a + d[k], 0);

/* Continue studying — v1 resume card. Product: today's in-progress session (deck · kind · current mode). */
function ContinueStudying() {
  return (
    <div style={{ marginBottom: 16 }}>
      <div className="ov" style={{ padding: '0 4px 8px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <span style={{ width: 6, height: 6, borderRadius: 999, background: 'var(--memox-streak)', display: 'inline-block', animation: 'memoxPulseDot 1.8s ease-in-out infinite' }} />
        Continue studying
      </div>
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <div style={{ width: 42, height: 42, borderRadius: 12, background: 'var(--memox-streak)', color: 'var(--memox-on-streak)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <Ic name="pause" size="sm" color="var(--memox-on-streak)" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>Động từ · 동사</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <span>Review · Self-assess</span>
              <span style={{ opacity: 0.5 }}>·</span>
              <span>12 / 20 cards</span>
            </div>
            <div style={{ marginTop: 8, height: 4, background: 'color-mix(in srgb, var(--memox-primary) 15%, transparent)', borderRadius: 999, overflow: 'hidden', width: '100%' }}>
              <div style={{ height: '100%', width: '60%', background: 'var(--memox-primary)' }} />
            </div>
          </div>
        </div>
        <button className="pill-btn" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, background: 'var(--memox-primary-soft)', color: 'var(--memox-primary)', border: 'none' }}>
          <Ic name="play" size="xs" color="var(--memox-primary)" />
          Resume
        </button>
      </div>
    </div>);
}

/* Workload hero — v1 "Today's review" card as a summary. Zero workload is normal (BR-202). */
function Workload({ zero = false } = {}) {
  if (zero) return (
    <div className="card" style={{ padding: '20px 16px', marginBottom: 16, textAlign: 'center' }}>
      <div style={{ width: 44, height: 44, borderRadius: 12, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 8 }}>
        <Ic name="check-circle-2" size="sm" color="var(--memox-mastery)" />
      </div>
      <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Nothing due right now</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>Every card is resting. The next one becomes due tomorrow at 00:00.</div>
    </div>);
  const due = sum('overdue') + sum('today');
  return (
    <div className="card" style={{ padding: '20px', marginBottom: 16, background: 'var(--memox-surface-hero)' }}>
      <div className="ov" style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--memox-primary)', marginBottom: 8 }}>
        <Ic name="zap" size="xs" color="var(--memox-primary)" />
        Waiting for you
      </div>
      <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.1, fontVariantNumeric: 'tabular-nums', marginBottom: 4 }}>{fmt(due)} cards due</div>
      <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, fontVariantNumeric: 'tabular-nums' }}>
        <span style={{ color: 'var(--memox-warning-ink)', fontWeight: 600 }}>{fmt(sum('overdue'))} overdue</span> · {sum('today')} due today · {fmt(sum('fresh'))} new across {decks.filter((d) => d.overdue + d.today + d.fresh > 0).length} decks
      </div>
    </div>);
}

/* Root deck list — v1 RecentDecks rows; trailing badge = due, quiet meta = overdue · today · new. */
function DeckList({ zero = false } = {}) {
  const rows = zero ? decks.map((d) => ({ ...d, overdue: 0, today: 0, fresh: 0 })) : decks;
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 8px' }}>
        <div className="ov">Your decks</div>
        <button style={{ background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          Library
          <Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
        </button>
      </div>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {rows.map((d, i, a) => {
          const due = d.overdue + d.today;
          const studiable = d.cards > 0;
          return (
            <div key={d.n} role={studiable ? 'button' : undefined} aria-disabled={!studiable || undefined} style={{ display: 'grid', gridTemplateColumns: '34px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', cursor: studiable ? 'pointer' : 'default', opacity: studiable ? 1 : 'var(--memox-op-disabled)' }}>
              <div className="icon-tile" style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Ic name="layers" size="xs" color="var(--memox-primary)" />
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', lineHeight: 1.35, display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical', overflow: 'hidden' }}>{d.n}</div>
                <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, fontVariantNumeric: 'tabular-nums', lineHeight: 1.5 }}>
                  {!studiable ? <span>No cards yet</span> : due + d.fresh === 0 ? <span>{fmt(d.cards)} cards · nothing due</span> : <>
                    {d.overdue > 0 && <span style={{ color: 'var(--memox-warning-ink)', fontWeight: 600, whiteSpace: 'nowrap' }}>{fmt(d.overdue)} overdue</span>}
                    {d.overdue > 0 && (d.today > 0 || d.fresh > 0) && ' · '}
                    {d.today > 0 && <span style={{ whiteSpace: 'nowrap' }}>{d.today} today</span>}
                    {d.today > 0 && d.fresh > 0 && ' · '}
                    {d.fresh > 0 && <span style={{ color: 'var(--memox-status-new)', whiteSpace: 'nowrap' }}>{fmt(d.fresh)} new</span>}
                  </>}
                </div>
              </div>
              {due > 0 ? <Badge tone="primary">{fmt(due)} due</Badge> : <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />}
            </div>);
        })}
      </div>
    </>);
}

function LoadingBody() {
  return (
    <>
      <div className="card" style={{ padding: '20px', marginBottom: 16 }}>
        <Skel w={90} h={9} op={0.4} />
        <div style={{ height: 10 }} />
        <Skel w={140} h={24} />
        <div style={{ height: 8 }} />
        <Skel w="70%" h={10} op={0.4} />
      </div>
      <div style={{ padding: '0 4px 8px' }}><Skel w={80} h={9} op={0.4} /></div>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {[0, 1, 2].map((i) =>
          <div key={i} style={{ padding: '12px 16px', display: 'grid', gridTemplateColumns: '34px 1fr 40px', gap: 12, alignItems: 'center', borderBottom: i < 2 ? 'var(--memox-border-ghost)' : 'none' }}>
            <Skel w={30} h={30} r={8} />
            <div><Skel w={120 + i * 30} h={11} /><div style={{ height: 6 }} /><Skel w={90} h={9} op={0.4} /></div>
            <Skel w={40} h={22} r={999} op={0.4} />
          </div>)}
      </div>
    </>);
}

function ErrorCard() {
  const { ErrorState } = window;
  return <ErrorState title="Couldn't load your study overview" body="Your cards are safe on this device. You can still open Library directly." />;
}

/* ════════════ SCREEN ════════════ */
function StudyHomeScreenV3({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.StudyHome) || {};
  const ctx = { go, state, Ic, Skel, Note, EmptyState, ContinueStudying, Workload, DeckList, LoadingBody, ErrorCard, decks };
  const renderBody = States[state] || States.loaded;
  return (
    <div className="app">
      <StatusBar />
      <div className="appbar appbar-lg" style={{ justifyContent: 'space-between' }}>
        <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.5px' }}>Study</div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>Tuesday, 16 Sep</div>
      </div>
      <div className="scroll">
        {renderBody ? renderBody(ctx) : null}
      </div>
      <BottomNav active="study" onChange={go} />
      <style>{`@keyframes memoxPulseDot { 0%, 100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.4); opacity: 0.6; } }`}</style>
    </div>);
}

Object.assign(window, { StudyHomeScreenV3 });
})();
