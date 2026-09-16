/* MemoX Mobile — StudyResultScreen · MAIN
   ────────────────────────────────────────────────────────────────────────
   Folder layout:
     StudyResultScreen/
       StudyResultScreen.jsx  ← shell (appbar + footer) + shared fragments + dispatch
       states/                ← one file per state; each registers its scroll body into
                                window.MemoXStates.StudyResult[<state>]

   The result screen shares one layout across states (hero, breakdown, box changes,
   streak/goal, tough cards) with per-state variations. The MAIN file owns the
   chrome (app bar, footer action bar) and the reusable fragments; each state file
   declares which fragments it shows and with what data — so editing the
   "defensive" state can't disturb "loaded".

   Contract:  window.MemoXStates.StudyResult.<name> = (ctx) => <React body for .scroll>
   ctx: { Ic, Skel, ResultRow, fmtDur, makeResult, CONSTS,
          Hero, FinFailedBanner, DefensiveNote, Breakdown, BoxChanges, StreakGoal,
          ToughCards, LoadingBody } */
(function () {
const { StatusBar, masteryColor, Ic, Breadcrumb, BottomNav, OfflineBanner, StudyTopBar } = window;

const CONSTS = { streakDays: 12, dailyGoal: 20, completedTotal: 23 };
const fmtDur = (s) => `${Math.floor(s / 60)}m ${s % 60}s`;

/* Build the sample result for a state. defensive → all-zero; toughEmpty → 0 tough. */
function makeResult({ defensive = false, toughEmpty = false } = {}) {
  return defensive
    ? { reviewed: 0, durationS: 12, correct: 0, recovered: 0, forgot: 0, accuracy: 0, boxesUp: 0, boxesHeld: 0, boxesDown: 0, tough: 0 }
    : { reviewed: 20, durationS: 14 * 60 + 8, correct: 14, recovered: 4, forgot: 2, accuracy: 0.78, boxesUp: 14, boxesHeld: 3, boxesDown: 3, tough: toughEmpty ? 0 : 3 };
}

/* ── shared primitives ── */
const Skel = window.Skeleton;

const ResultRow = ({ ic, color, label, value, sub, last }) =>
  <div style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)' }}>
    <div style={{ width: 30, height: 30, borderRadius: 8, background: `${color}1F`, color: color, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={ic} size="xs" color={color} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{sub}</div>}
    </div>
    <div style={{ fontSize: 16, fontWeight: 700, color: color, fontVariantNumeric: 'tabular-nums' }}>{value}</div>
  </div>;

/* ════════════ BODY FRAGMENTS ════════════ */

/* Completion hero — calm, no confetti. defensive uses a neutral, paused treatment. */
function Hero({ result, defensive = false }) {
  return (
    <div className="card" style={{
      padding: '24px 24px 20px', textAlign: 'center', marginBottom: 16,
      background: defensive ? 'var(--memox-surface-container-lowest)' : 'color-mix(in srgb, var(--memox-mastery) 8%, var(--memox-surface-bright))',
      border: defensive ? '1px solid var(--memox-outline-variant)' : '1px solid color-mix(in srgb, var(--memox-mastery) 22%, transparent)'
    }}>
      <div style={{
        width: 60, height: 60, borderRadius: 20,
        background: defensive ? 'var(--memox-surface-container)' : 'color-mix(in srgb, var(--memox-mastery) 16%, transparent)',
        color: defensive ? 'var(--memox-on-surface-variant)' : 'var(--memox-mastery)',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16
      }}>
        <Ic name={defensive ? 'pause-circle' : 'check-circle-2'} size="lg" color={defensive ? 'var(--memox-on-surface-variant)' : 'var(--memox-mastery)'} />
      </div>
      <div style={{ fontSize: defensive ? 18 : 22, fontWeight: 700, letterSpacing: '-0.4px', marginBottom: 4, lineHeight: 1.15 }}>
        {defensive ? 'Session ended early' : 'Nice session.'}
      </div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: defensive ? 0 : 16 }}>
        {defensive
          ? 'You exited before answering any cards. Nothing has changed.'
          : <>You worked through <strong style={{ color: 'var(--memox-on-surface)', fontWeight: 700 }}>{result.reviewed} cards</strong> in TOPIK II — Vocab.</>}
      </div>
      {!defensive &&
        <div style={{ display: 'flex', gap: 8, padding: '0 4px', fontVariantNumeric: 'tabular-nums' }}>
          {[
            { v: result.reviewed, l: 'Reviewed' },
            { v: fmtDur(result.durationS), l: 'Duration' },
            { v: `${Math.round(result.accuracy * 100)}%`, l: 'Accuracy', c: 'var(--memox-mastery)' }
          ].map((s) =>
            <div key={s.l} style={{ flex: 1 }}>
              <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', color: s.c }}>{s.v}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.3, textTransform: 'uppercase', fontWeight: 700 }}>{s.l}</div>
            </div>
          )}
        </div>}
    </div>);
}

/* Finalization failure banner — visible but not panicky. Done stays enabled. */
function FinFailedBanner() {
  return (
    <div style={{ padding: '12px 16px', background: 'color-mix(in srgb, var(--memox-streak) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-streak) 22%, transparent)', borderRadius: 12, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
      <Ic name="cloud-off" size="xs" color="var(--memox-streak)" />
      <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: 'var(--memox-on-surface)' }}>
        <div style={{ fontWeight: 700, marginBottom: 2 }}>Couldn't save this summary</div>
        <div style={{ color: 'var(--memox-on-surface-variant)' }}>Your answers are saved on this device. The summary will sync next time.</div>
      </div>
      <button style={{ height: 30, padding: '0 12px', borderRadius: 8, background: 'color-mix(in srgb, var(--memox-streak) 14%, transparent)', color: 'var(--memox-streak)', border: 'none', fontSize: 12, fontWeight: 600, fontFamily: 'inherit', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
        <Ic name="refresh-cw" size="xs" color="var(--memox-streak)" />
        Retry
      </button>
    </div>);
}

/* Defensive note — replaces the analytical cards when no cards were graded. */
function DefensiveNote() {
  return (
    <div style={{ padding: '8px 12px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)', fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, display: 'flex', gap: 8, alignItems: 'flex-start', marginBottom: 16 }}>
      <Ic name="info" size="xs" color="var(--memox-on-surface-variant)" />
      <span>No reviews counted. Your streak and goal are unchanged.</span>
    </div>);
}

/* Result breakdown — correct / recovered / forgot only (no Hard/Easy per spec). */
function Breakdown({ result }) {
  return (
    <>
      <div className="ov" style={{ padding: '0 4px 8px' }}>Result breakdown</div>
      <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
        <ResultRow ic="check" color="var(--memox-mastery)" label="Correct" sub="Answered confidently" value={result.correct} />
        <ResultRow ic="corner-up-right" color="var(--memox-streak)" label="Recovered" sub="Got it after a slip" value={result.recovered} />
        <ResultRow ic="rotate-ccw" color="var(--memox-error)" label="Forgot" sub="Will come back sooner" value={result.forgot} last />
      </div>
    </>);
}

/* Box changes — stacked bar + 3 legends. */
function BoxChanges({ result }) {
  return (
    <>
      <div className="ov" style={{ padding: '0 4px 8px' }}>Box changes</div>
      <div className="card" style={{ padding: '16px', marginBottom: 16 }}>
        <div style={{ display: 'flex', height: 8, borderRadius: 999, overflow: 'hidden', background: 'var(--memox-surface-container)', marginBottom: 16 }}>
          <div style={{ width: `${result.boxesUp / result.reviewed * 100}%`, background: 'var(--memox-mastery)' }} />
          <div style={{ width: `${result.boxesHeld / result.reviewed * 100}%`, background: 'var(--memox-primary)' }} />
          <div style={{ width: `${result.boxesDown / result.reviewed * 100}%`, background: 'var(--memox-error)', opacity: 0.85 }} />
        </div>
        <div style={{ display: 'flex', gap: 4 }}>
          {[
            { l: 'Moved up', v: result.boxesUp, c: 'var(--memox-mastery)', ic: 'arrow-up' },
            { l: 'Held', v: result.boxesHeld, c: 'var(--memox-primary)', ic: 'minus' },
            { l: 'Moved down', v: result.boxesDown, c: 'var(--memox-error)', ic: 'arrow-down' }
          ].map((b) =>
            <div key={b.l} style={{ flex: 1, padding: '8px 8px', background: 'var(--memox-surface-container-lowest)', border: 'var(--memox-border-ghost)', borderRadius: 'var(--memox-radius-md)' }}>
              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 700, letterSpacing: 0.3, textTransform: 'uppercase', color: b.c }}>
                <Ic name={b.ic} size="xs" color={b.c} />
                {b.l}
              </div>
              <div style={{ fontSize: 16, fontWeight: 700, marginTop: 4, fontVariantNumeric: 'tabular-nums' }}>{b.v}</div>
            </div>
          )}
        </div>
      </div>
    </>);
}

/* Streak + goal — only rendered when goal is enabled (state decides). */
function StreakGoal() {
  const { streakDays, dailyGoal, completedTotal } = CONSTS;
  return (
    <>
      <div className="ov" style={{ padding: '0 4px 8px' }}>Streak and goal</div>
      <div className="card" style={{ padding: '16px', marginBottom: 16 }}>
        <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-streak) 12%, transparent)', color: 'var(--memox-streak)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Ic name="flame" size="xs" color="var(--memox-streak)" />
            </div>
            <div>
              <div className="ov">Streak</div>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.3px', fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
                {streakDays} days
                <span style={{ fontSize: 12, color: 'var(--memox-mastery)', fontWeight: 700, marginLeft: 4, padding: '1px 4px', borderRadius: 999, background: 'color-mix(in srgb, var(--memox-mastery) 12%, transparent)' }}>+1</span>
              </div>
            </div>
          </div>
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 8 }}>
            <svg width="36" height="36" viewBox="0 0 40 40" style={{ flexShrink: 0 }}>
              <circle cx="20" cy="20" r="16" fill="none" stroke="var(--memox-surface-container)" strokeWidth="3.5" />
              <circle cx="20" cy="20" r="16" fill="none" stroke="var(--memox-primary)" strokeWidth="3.5" strokeLinecap="round" strokeDasharray="100.5" strokeDashoffset={(1 - Math.min(completedTotal / dailyGoal, 1)) * 100.5} transform="rotate(-90 20 20)" />
            </svg>
            <div>
              <div className="ov">Today’s goal</div>
              <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.3px', fontVariantNumeric: 'tabular-nums', marginTop: 1 }}>
                {completedTotal}<span style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', fontWeight: 600 }}> / {dailyGoal}</span>
              </div>
            </div>
          </div>
        </div>
        {completedTotal >= dailyGoal &&
          <div style={{ padding: '8px 8px', background: 'color-mix(in srgb, var(--memox-mastery) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-mastery) 20%, transparent)', borderRadius: 8, fontSize: 12, lineHeight: 1.5, display: 'flex', gap: 4, alignItems: 'center', color: 'var(--memox-on-surface)' }}>
            <Ic name="check" size="xs" color="var(--memox-mastery)" />
            <span>Daily goal hit. New cards are still available if you want a head start.</span>
          </div>}
      </div>
    </>);
}

/* Tough cards entry — toughEmpty shows the calm "nothing to revisit" treatment. */
function ToughCards({ result, toughEmpty = false }) {
  return (
    <>
      <div className="ov" style={{ padding: '0 4px 8px' }}>Tough cards</div>
      <div className="card" style={{ padding: '16px', marginBottom: 20, opacity: toughEmpty ? 0.75 : 1 }}>
        {toughEmpty ?
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-mastery) 10%, transparent)', color: 'var(--memox-mastery)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Ic name="leaf" size="xs" color="var(--memox-mastery)" />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>No tough cards from this session</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.4 }}>You handled everything cleanly.</div>
            </div>
          </div> :
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
            <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-danger) 10%, transparent)', color: 'var(--memox-error)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
              <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 14, fontWeight: 700, letterSpacing: '-0.1px' }}>{result.tough} cards to revisit</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.4 }}>Forgot or struggled with these. A quick re-pass tomorrow helps.</div>
            </div>
            <Ic name="chevron-right" size="xs" color="var(--memox-on-surface-variant)" />
          </div>}
      </div>
    </>);
}

/* Loading skeletons (hero + breakdown). */
function LoadingBody() {
  return (
    <>
      <div className="card" style={{ padding: '28px 24px', textAlign: 'center', marginBottom: 16 }}>
        <Skel w={56} h={56} r={16} />
        <div style={{ height: 14 }} />
        <Skel w={180} h={20} r={6} />
        <div style={{ height: 6 }} />
        <Skel w={120} h={11} op={0.4} />
        <div style={{ height: 18 }} />
        <Skel w="100%" h={50} r={11} />
      </div>
      <div className="card" style={{ padding: '16px', marginBottom: 12 }}>
        <Skel w={80} h={10} />
        <div style={{ height: 12 }} />
        {[0, 1, 2].map((i) =>
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: i < 2 ? 16 : 0 }}>
            <Skel w={28} h={28} r={8} />
            <div style={{ flex: 1 }}>
              <Skel w={80} h={11} />
              <div style={{ height: 5 }} />
              <Skel w={120} h={9} op={0.4} />
            </div>
            <Skel w={30} h={15} />
          </div>
        )}
      </div>
    </>);
}

/* ════════════ SCREEN ════════════ */
function StudyResultScreen({ go, state = 'loaded' }) {
  const loading = state === 'loading';
  const finFailed = state === 'finFailed';
  const defensive = state === 'defensive';

  const States = (window.MemoXStates && window.MemoXStates.StudyResult) || {};
  const ctx = {
    Ic, Skel, ResultRow, fmtDur, makeResult, CONSTS,
    Hero, FinFailedBanner, DefensiveNote, Breakdown, BoxChanges, StreakGoal, ToughCards, LoadingBody
  };
  const renderBody = States[state] || States.loaded;

  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />

      {/* Minimal app bar — no back button (result must not be re-enterable after Done). */}
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <div className="title" style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface-variant)' }}>Session complete</div>
        <button className="icon-btn" title="Share summary" disabled={loading || defensive} style={{ opacity: loading || defensive ? 0.4 : 1 }}>
          <Ic name="share-2" size="xs" color="var(--memox-on-surface-variant)" />
        </button>
      </div>

      <div className="scroll">
        {renderBody ? renderBody(ctx) : null}
      </div>

      {/* Final action bar — Done always available. */}
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {!defensive && !loading &&
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
              <Ic name="play" size="xs" color="var(--memox-primary)" />
              Study more
            </button>}
          <button className="pill-btn primary" disabled={loading} style={{ flex: defensive || loading ? 1 : 1.2, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: loading ? 0.45 : 1, pointerEvents: loading ? 'none' : 'auto' }}>
            <Ic name="check" size="xs" color="var(--memox-on-primary)" />
            Done
          </button>
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {loading ? 'Saving your session…' :
            finFailed ? 'Done returns you home — summary syncs later.' :
            defensive ? 'No progress saved. Done returns you home.' :
            'Done returns you to where you started.'}
        </div>
      </div>

    </div>);
}

Object.assign(window, { StudyResultScreen });
})();
