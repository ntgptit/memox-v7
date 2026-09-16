/* MemoX Mobile — DashboardScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout (one screen = one folder):
     DashboardScreen/
       DashboardScreen.jsx   ← this file: shell + shared data + body fragments + dispatch
       states/               ← one file per state; each registers its body into
                               window.MemoXStates.Dashboard[<stateName>]

   Why this shape: every state is isolated in its own file, so adding or editing
   a state can't disturb the others. The MAIN file owns only what is genuinely
   shared — the device shell (status bar, app bar, bottom nav), the base data,
   and the reusable body fragments (StreakGoal, ContinueStudying, …). Each state
   file is a small, declarative composition of those fragments.

   Contract — a state module is:
     window.MemoXStates.Dashboard.<name> = (ctx) => <React body for the .scroll area>
   ctx (built fresh per render) exposes:
     { go, state, Ic, Skel, data, OfflineBanner,
       Onboarding, StreakBrokenBanner, ContinueStudying, LoadingBody,
       StreakGoal, PrimaryCTA, RecentDecks, ErrorCard }

   Shared chrome (StatusBar, Ic, BottomNav, OfflineBanner …) comes from
   screens/_shared.jsx via window. This file publishes DashboardScreen back to
   window. Wrapped in an IIFE so its locals stay private. */
(function () {
const { StatusBar, Ic, BottomNav, OfflineBanner, Badge } = window;

/* Base data — the populated-day numbers. States override fields as needed
   (e.g. streakBroken passes streak:0). Kept here because it's shared scaffolding;
   per-state values are passed explicitly from each state file. */
const BASE = {
  greeting: 'Good evening, Alex',
  subgreeting: 'Tuesday, May 27',
  streak: 11,
  dailyGoal: 20,
  completedToday: 12,
  dueTotal: 23,
  freshTotal: 6,
  minutesEst: 14
};

const Skel = window.Skeleton;

/* ════════════════════════════════════════════════════════════════════════
   BODY FRAGMENTS — reusable, explicitly-parameterised pieces of the scroll body.
   States compose these; visibility/data is decided by the STATE, not in here.
   ════════════════════════════════════════════════════════════════════════ */

/* Onboarding — zero-content hero + 3 reassurance points. */
function Onboarding() {
  return (
    <div style={{ marginTop: 8 }}>
      <div className="card" style={{ padding: '32px 24px 28px', textAlign: 'center', marginBottom: 16 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 20,
          background: 'color-mix(in srgb, var(--memox-primary) 10%, transparent)', color: 'var(--memox-primary)',
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16
        }}>
          <Ic name="sparkles" size="lg" color="var(--memox-primary)" />
        </div>
        <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', marginBottom: 8 }}>
          Ready to remember more?
        </div>
        <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 20, padding: '0 4px' }}>
          Create your first deck and add a handful of cards. MemoX will surface the right ones to review each day — calmly, on your schedule.
        </div>
        <button className="pill-btn primary" style={{
          height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14, marginBottom: 8, width: '100%'
        }}>
          <Ic name="layers" size="xs" color="var(--memox-on-primary)" />
          Create first deck
        </button>
        <button className="pill-btn" style={{
          height: 'var(--memox-size-button)', padding: '0 20px', borderRadius: 12, fontSize: 14,
          background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)',
          border: 'none', width: '100%', gap: 8
        }}>
          <Ic name="upload" size="xs" color="var(--memox-primary)" />
          Import a deck
        </button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {[
          { ic: 'cloud', l: 'Local first', s: 'Your cards live on this device. Sync is optional.' },
          { ic: 'sun', l: 'A daily rhythm', s: 'Short sessions; we pick what’s due each day.' },
          { ic: 'shield-check', l: 'No streak pressure', s: 'Skip a day and your progress is safe.' }
        ].map((b) =>
          <div key={b.l} className="card" style={{
            padding: '12px 16px', display: 'grid', gridTemplateColumns: '32px 1fr', gap: 12, alignItems: 'center'
          }}>
            <div style={{
              width: 28, height: 28, borderRadius: 8,
              background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)',
              display: 'flex', alignItems: 'center', justifyContent: 'center'
            }}>
              <Ic name={b.ic} size="xs" color="var(--memox-primary)" />
            </div>
            <div>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>{b.l}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, lineHeight: 1.4 }}>{b.s}</div>
            </div>
          </div>
        )}
      </div>
    </div>);
}

/* Streak-broken banner — one-time, gentle. */
function StreakBrokenBanner() {
  return (
    <div style={{
      display: 'flex', alignItems: 'flex-start', gap: 8, padding: '12px 16px',
      background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)',
      borderRadius: 12, marginBottom: 16
    }}>
      <Ic name="leaf" size="xs" color="var(--memox-mastery)" />
      <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
        <strong style={{ fontWeight: 700 }}>Streak paused at 11 days.</strong>{' '}
        <span style={{ color: 'var(--memox-on-surface-variant)' }}>That's fine — pick up whenever you're ready. Your cards waited for you.</span>
      </div>
      <button className="icon-btn" style={{ width: 24, height: 24 }} title="Dismiss">
        <Ic name="x" size="xs" color="var(--memox-on-surface-variant)" />
      </button>
    </div>);
}

/* Continue studying — resume card. multiResume adds the "other sessions" chip. */
function ContinueStudying({ multiResume = false } = {}) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div className="ov" style={{ padding: '0 4px 8px', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
        <span style={{
          width: 6, height: 6, borderRadius: 999, background: 'var(--memox-streak)',
          display: 'inline-block', animation: 'memoxPulseDot 1.8s ease-in-out infinite'
        }} />
        Continue studying
      </div>
      <div className="card" style={{ padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
          <div style={{
            width: 42, height: 42, borderRadius: 12, background: 'var(--memox-streak)', color: 'var(--memox-on-streak)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
          }}>
            <Ic name="pause" size="sm" color="var(--memox-on-streak)" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>TOPIK II — Vocab</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <span>Recall · 7 / 20 cards</span>
              <span style={{ opacity: 0.5 }}>·</span>
              <span>paused 32m ago</span>
            </div>
            <div style={{ marginTop: 8, height: 4, background: 'color-mix(in srgb, var(--memox-primary) 15%, transparent)', borderRadius: 999, overflow: 'hidden', width: '100%' }}>
              <div style={{ height: '100%', width: '35%', background: 'var(--memox-primary)' }} />
            </div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8, background: 'var(--memox-primary-soft)', color: 'var(--memox-primary)', border: 'none' }}>
            <Ic name="play" size="xs" color="var(--memox-primary)" />
            Resume
          </button>
          <button className="pill-btn outline" style={{
            height: 'var(--memox-size-button)', padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 12,
            color: 'var(--memox-on-surface-variant)', borderColor: 'var(--memox-outline-variant)'
          }}>
            Discard
          </button>
        </div>
        {multiResume &&
          <button style={{
            marginTop: 8, width: '100%', height: 32, borderRadius: 8, fontSize: 12, fontWeight: 600,
            background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)',
            border: 'none', cursor: 'pointer', fontFamily: 'inherit',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 4
          }}>
            3 other paused sessions
            <Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
          </button>}
      </div>
    </div>);
}

/* Loading — section-level skeletons. */
function LoadingBody() {
  return (
    <>
      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        <div className="card" style={{ padding: '16px', flex: 1 }}>
          <Skel w={60} h={9} op={0.4} />
          <div style={{ height: 10 }} />
          <Skel w={80} h={22} />
        </div>
        <div className="card" style={{ padding: '16px', width: 120, textAlign: 'center' }}>
          <Skel w={60} h={60} r={999} />
          <div style={{ height: 8 }} />
          <Skel w={50} h={9} op={0.4} />
        </div>
      </div>
      <div className="card" style={{ padding: '16px', marginBottom: 8 }}>
        <Skel w={120} h={11} />
        <div style={{ height: 8 }} />
        <Skel w="60%" h={20} />
        <div style={{ height: 14 }} />
        <Skel w="100%" h={44} r={11} />
      </div>
      <div style={{ padding: '8px 4px 8px' }}>
        <Skel w={80} h={9} op={0.4} />
      </div>
      {[0, 1].map((i) =>
        <div key={i} className="card" style={{
          marginBottom: 8, padding: '12px 16px', display: 'grid',
          gridTemplateColumns: '36px 1fr 18px', gap: 12, alignItems: 'center'
        }}>
          <Skel w={32} h={32} r={8} />
          <div>
            <Skel w={120 + i * 30} h={11} />
            <div style={{ height: 6 }} />
            <Skel w={70} h={9} op={0.4} />
          </div>
          <span />
        </div>
      )}
    </>);
}

/* Streak + goal summary row. showStreak/showGoal toggle each card; the streak
   card additionally hides itself at streak === 0 (per spec). */
function StreakGoal({ streak = BASE.streak, completedToday = BASE.completedToday, dailyGoal = BASE.dailyGoal, showStreak = true, showGoal = true } = {}) {
  const goalPct = Math.min(completedToday / dailyGoal, 1);
  if (!((showStreak && streak > 0) || showGoal)) return null;
  return (
    <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
      {showStreak && streak > 0 &&
        <div className="card" style={{ padding: '12px 16px', flex: 1, display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{
            width: 38, height: 38, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)',
            color: 'var(--memox-streak)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
          }}>
            <Ic name="flame" size="sm" color="var(--memox-streak)" />
          </div>
          <div style={{ minWidth: 0 }}>
            <div className="ov">Streak</div>
            <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
              {streak} <span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 600 }}>days</span>
            </div>
          </div>
        </div>}
      {showGoal &&
        <div className="card" style={{ padding: '12px 16px', flex: 1, display: 'flex', alignItems: 'center', gap: 12 }}>
          <svg width="38" height="38" viewBox="0 0 40 40" style={{ flexShrink: 0 }}>
            <circle cx="20" cy="20" r="16" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3.5" />
            <circle cx="20" cy="20" r="16" fill="none" stroke="var(--memox-primary)" strokeWidth="3.5"
              strokeLinecap="round" strokeDasharray="100.5" strokeDashoffset={(1 - goalPct) * 100.5} transform="rotate(-90 20 20)" />
          </svg>
          <div style={{ minWidth: 0 }}>
            <div className="ov">Today’s goal</div>
            <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.3px', fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
              {completedToday}<span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 600 }}> / {dailyGoal}</span>
            </div>
          </div>
        </div>}
    </div>);
}

/* Primary CTA — today's review (or "all caught up") + start new learning. */
function PrimaryCTA({ hasDue = true, dueTotal = BASE.dueTotal, minutesEst = BASE.minutesEst, freshTotal = BASE.freshTotal } = {}) {
  return (
    <>
      {hasDue ?
        <div className="card" style={{ padding: '20px', marginBottom: 12, background: 'color-mix(in srgb, var(--memox-primary) 6%, var(--memox-surface-bright))' }}>
          <div className="ov" style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: 'var(--memox-primary)', marginBottom: 8 }}>
            <Ic name="zap" size="xs" color="var(--memox-primary)" />
            Today’s review
          </div>
          <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', lineHeight: 1.1, fontVariantNumeric: 'tabular-nums', marginBottom: 4 }}>
            {dueTotal} cards due
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 16 }}>
            Across 3 decks · about {minutesEst} minutes
          </div>
          <button className="pill-btn primary" style={{ width: '100%', height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
            <Ic name="play" size="xs" color="var(--memox-on-primary)" />
            Start today’s review
          </button>
        </div> :
        <div className="card" style={{ padding: '20px 16px', marginBottom: 8, textAlign: 'center' }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12, background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)',
            display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 8
          }}>
            <Ic name="check-circle-2" size="sm" color="var(--memox-mastery)" />
          </div>
          <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>
            All caught up for today
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5 }}>
            Nothing is due. New cards are still available if you want a head start.
          </div>
        </div>}

      <button className="pill-btn" style={{
        width: '100%', height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14,
        background: 'transparent', color: 'var(--memox-primary)',
        border: 'none', gap: 8, marginBottom: 20
      }}>
        <Ic name="sparkles" size="xs" color="var(--memox-primary)" />
        Start new learning
        <Badge tone="primary">{freshTotal} new</Badge>
      </button>
    </>);
}

/* Recent decks list. */
function RecentDecks() {
  return (
    <>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 4px 8px' }}>
        <div className="ov">Recent decks</div>
        <button style={{
          background: 'transparent', border: 'none', padding: 0, color: 'var(--memox-primary)', fontSize: 12, fontWeight: 600,
          fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4
        }}>
          Library
          <Ic name="chevron-right" size="xs" color="var(--memox-primary)" />
        </button>
      </div>
      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {[
          { n: 'TOPIK II — Vocab', cards: 142, due: 23, last: '2h ago', col: 'var(--memox-primary)' },
          { n: 'Idioms', cards: 34, due: 3, last: 'yesterday', col: 'var(--memox-tertiary)' },
          { n: 'Verb conjugation', cards: 148, due: 0, last: 'a week ago', col: 'var(--memox-success)' }
        ].map((d, i, a) =>
          <div key={d.n} style={{
            display: 'grid', gridTemplateColumns: '34px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px',
            borderBottom: i < a.length - 1 ? 'var(--memox-border-ghost)' : 'none', cursor: 'pointer'
          }}>
            <div style={{ width: 30, height: 30, borderRadius: 8, background: `color-mix(in srgb, ${d.col} 12%, transparent)`, color: d.col, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="layers" size="xs" color={d.col} />
            </div>
            <div style={{ minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.n}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 1, fontVariantNumeric: 'tabular-nums' }}>
                {d.cards} cards · last {d.last}
              </div>
            </div>
            {d.due > 0 ?
              <Badge tone="primary">{d.due} due</Badge> :
              <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />}
          </div>
        )}
      </div>
    </>);
}

/* Error card — inline data-load failure. */
function ErrorCard() {
  return (
    <div className="card" style={{
      padding: '20px', marginBottom: 16, background: 'color-mix(in srgb, var(--memox-danger) 5%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-danger) 20%, transparent)',
      display: 'flex', gap: 12, alignItems: 'flex-start'
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-danger) 12%, transparent)', color: 'var(--memox-error)',
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0
      }}>
        <Ic name="cloud-off" size="xs" color="var(--memox-error)" />
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px', marginBottom: 4 }}>
          Couldn't load today's summary
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: 12 }}>
          Your cards are safe on this device. You can still open Library directly.
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="pill-btn primary" style={{ height: 34, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 12 }}>
            <Ic name="refresh-cw" size="xs" color="var(--memox-on-primary)" />
            Retry
          </button>
          <button className="pill-btn outline" style={{ height: 34, padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 12 }}>
            Open Library
          </button>
        </div>
      </div>
    </div>);
}

/* ── App bar (shell chrome) — greeting is state-aware (onboarding / loading). ── */
function AppBar({ state }) {
  const onboarding = state === 'onboarding';
  const loading = state === 'loading';
  return (
    <div className="appbar appbar-lg" style={{
      flexDirection: 'column', alignItems: 'flex-start', gap: 2, paddingTop: 20, paddingBottom: 16, position: 'relative'
    }}>
      {loading ?
        <>
          <Skel w={180} h={22} />
          <div style={{ height: 6 }} />
          <Skel w={120} h={11} op={0.4} />
        </> :
        <>
          <div style={{ fontSize: 20, fontWeight: 700, letterSpacing: '-0.4px' }}>
            {onboarding ? 'Welcome to MemoX' : BASE.greeting}
          </div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)' }}>
            {onboarding ? 'Let’s build your first deck' : BASE.subgreeting}
          </div>
        </>}
      <div style={{ position: 'absolute', right: 14, top: 18, display: 'flex', gap: 4 }}>
        <button className="icon-btn" title="Search" aria-label="Search">
          <Ic name="search" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
        <button className="icon-btn" title="Settings" aria-label="Settings">
          <Ic name="settings" size="sm" color="var(--memox-on-surface-variant)" />
        </button>
      </div>
    </div>);
}

/* ════════════════════════════════════════════════════════════════════════
   SCREEN — builds ctx, renders the shell, delegates the scroll body to the
   matching state module. Falls back to 'loaded' if a state isn't registered.
   ════════════════════════════════════════════════════════════════════════ */
function DashboardScreen({ go, state = 'loaded' }) {
  const States = (window.MemoXStates && window.MemoXStates.Dashboard) || {};
  const ctx = {
    go, state, Ic, Skel, data: BASE, OfflineBanner,
    Onboarding, StreakBrokenBanner, ContinueStudying, LoadingBody,
    StreakGoal, PrimaryCTA, RecentDecks, ErrorCard
  };
  const renderBody = States[state] || States.loaded;
  return (
    <div className="app">
      <StatusBar />
      <AppBar state={state} />
      <div className="scroll">
        {renderBody ? renderBody(ctx) : null}
      </div>
      <BottomNav active="home" onChange={go} />
      <style>{`
        @keyframes memoxPulseDot { 0%, 100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.4); opacity: 0.6; } }
      `}</style>
    </div>);
}

Object.assign(window, { DashboardScreen });
})();
