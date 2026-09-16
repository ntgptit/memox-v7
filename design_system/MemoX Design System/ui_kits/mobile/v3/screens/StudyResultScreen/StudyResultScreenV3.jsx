/* MemoX Mobile v3 — StudyResultScreenV3 · MAIN  (A19 · Session summary)
   ────────────────────────────────────────────────────────────────────────
   Cloned from v1 StudyResultScreen. Product corrections:
     KEEP   v1 hero (calm, no confetti) · result card list · footer action bar + caption.
     EDIT   the summary reports exactly: session kind, how it ended (status + reason),
            cards that finished learning / were reviewed, cards answered, wrong turns
            out of total turns (A19). The hero's three stats are now finished ·
            answered · wrong/total.
     REMOVE accuracy %, duration, box-changes bar, streak + daily goal, tough cards,
            share button (BR-191 / no such data or actions).
     ADD    every end state the product has: completed (learning / review),
            abandoned (left early · interrupted), invalidated (reset · algorithm
            changed · content trashed), failed (save error) — with "everything
            answered so far is kept" where relevant (BR-86); a 200-card session.
   ctx: { Ic, Skel, Hero, Facts, EndNote, LoadingBody } */
(function () {
const { StatusBar, Ic, Note } = window;
const Skel = window.Skeleton;

const ResultRow = ({ ic, color, label, value, sub, last }) =>
  <div style={{ display: 'grid', gridTemplateColumns: '32px 1fr auto', gap: 12, alignItems: 'center', padding: '12px 16px', borderBottom: last ? 'none' : 'var(--memox-border-ghost)' }}>
    <div style={{ width: 30, height: 30, borderRadius: 'var(--memox-radius-sm)', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <Ic name={ic} size="xs" color={color || 'var(--memox-primary)'} />
    </div>
    <div style={{ minWidth: 0 }}>
      <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: '-0.1px' }}>{label}</div>
      {sub && <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2 }}>{sub}</div>}
    </div>
    <div style={{ fontSize: 16, fontWeight: 700, color: color || 'var(--memox-on-surface)', fontVariantNumeric: 'tabular-nums' }}>{value}</div>
  </div>;

/* Completion hero — v1 card. tone: ok (completed) · paused (left early / interrupted) · ended (invalidated) · error (save failure). */
function Hero({ kind, deck, tone = 'ok', title, body, stats }) {
  const c = tone === 'ok' ? 'var(--memox-mastery)' : tone === 'error' ? 'var(--memox-error)' : tone === 'ended' ? 'var(--memox-warning)' : 'var(--memox-on-surface-variant)';
  const bg = tone === 'ok' ? 'color-mix(in srgb, var(--memox-mastery) 8%, var(--memox-surface-bright))' : tone === 'error' ? 'var(--memox-danger-soft)' : tone === 'ended' ? 'var(--memox-warning-soft)' : 'var(--memox-surface-container-lowest)';
  const bd = tone === 'ok' ? 'color-mix(in srgb, var(--memox-mastery) 22%, transparent)' : tone === 'error' ? 'var(--memox-danger-border)' : tone === 'ended' ? 'var(--memox-warning-border)' : 'var(--memox-outline-variant)';
  const icon = tone === 'ok' ? 'check-circle-2' : tone === 'error' ? 'alert-circle' : tone === 'ended' ? 'rotate-ccw' : 'pause-circle';
  return (
    <div className="card" style={{ padding: '24px 24px 20px', textAlign: 'center', marginBottom: 16, background: bg, border: `1px solid ${bd}` }}>
      <div style={{ width: 60, height: 60, borderRadius: 20, background: `color-mix(in srgb, ${c} 16%, transparent)`, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
        <Ic name={icon} size="lg" color={c} />
      </div>
      <div className="ov" style={{ marginBottom: 4 }}>{kind === 'learning' ? 'Learning session' : 'Review session'} · {deck}</div>
      <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', marginBottom: 4, lineHeight: 1.15 }}>{title}</div>
      <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55, marginBottom: stats ? 16 : 0 }}>{body}</div>
      {stats &&
        <div style={{ display: 'flex', gap: 8, padding: '0 4px', fontVariantNumeric: 'tabular-nums' }}>
          {stats.map((s) =>
            <div key={s.l} style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 24, fontWeight: 700, letterSpacing: '-0.4px', color: s.c }}>{s.v}</div>
              <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', letterSpacing: 0.6, textTransform: 'uppercase', fontWeight: 700 }}>{s.l}</div>
            </div>)}
        </div>}
    </div>);
}

/* The summary's facts — exactly what the contract carries. */
function Facts({ kind, finished, answered, wrong, total }) {
  return (
    <>
      <div className="ov" style={{ padding: '0 4px 8px' }}>This session</div>
      <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 16 }}>
        <ResultRow ic="check-circle-2" color="var(--memox-mastery)" label={kind === 'learning' ? 'Cards that finished learning' : 'Cards reviewed'} sub={kind === 'learning' ? 'Now scheduled, due tomorrow' : 'Schedules updated'} value={finished} />
        <ResultRow ic="copy" label="Cards answered" value={answered} />
        <ResultRow ic="rotate-ccw" color={wrong > 0 ? 'var(--memox-warning-ink)' : undefined} label="Wrong turns" sub={`of ${total} turns${wrong > 0 ? ' · wrong cards came back in later rounds' : ''}`} value={`${wrong} / ${total}`} last />
      </div>
    </>);
}

function EndNote({ icon = 'info', children }) { return <Note icon={icon} style={{ marginBottom: 16 }}>{children}</Note>; }

function LoadingBody() {
  return (
    <>
      <div className="card" style={{ padding: '28px 24px', textAlign: 'center', marginBottom: 16 }}>
        <Skel w={56} h={56} r={16} /><div style={{ height: 14 }} /><Skel w={180} h={20} r={6} /><div style={{ height: 6 }} /><Skel w={120} h={11} op={0.4} />
      </div>
      <div className="card" style={{ padding: '16px', marginBottom: 12 }}>
        {[0, 1, 2].map((i) =>
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: i < 2 ? 16 : 0 }}>
            <Skel w={28} h={28} r={8} /><div style={{ flex: 1 }}><Skel w={80} h={11} /><div style={{ height: 5 }} /><Skel w={120} h={9} op={0.4} /></div><Skel w={30} h={15} />
          </div>)}
      </div>
    </>);
}

/* ════════════ SCREEN ════════════ */
function StudyResultScreenV3({ go, state = 'loaded' }) {
  const loading = state === 'loading';
  const States = (window.MemoXStates && window.MemoXStates.StudyResult) || {};
  const ctx = { Ic, Skel, Hero, Facts, EndNote, LoadingBody };
  const renderBody = States[state] || States.loaded;
  const canStudyMore = ['loaded', 'learning', 'large', 'leftEarly'].includes(state);
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      {/* Minimal app bar — no back button (v1). Share removed. */}
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <div className="title" style={{ fontSize: 14, fontWeight: 600, color: 'var(--memox-on-surface-variant)' }}>Session summary</div>
      </div>
      <div className="scroll">{renderBody ? renderBody(ctx) : null}</div>
      <div style={{ padding: '8px 16px 16px', borderTop: 'var(--memox-border-ghost)', background: 'var(--memox-surface)', display: 'flex', flexDirection: 'column', gap: 8 }}>
        <div style={{ display: 'flex', gap: 8 }}>
          {canStudyMore &&
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8 }}>
              <Ic name="play" size="xs" color="var(--memox-primary)" />
              Study this deck
            </button>}
          <button className="pill-btn primary" disabled={loading} style={{ flex: 1.2, height: 'var(--memox-size-button)', borderRadius: 12, fontSize: 14, gap: 8, opacity: loading ? 0.45 : 1, pointerEvents: loading ? 'none' : 'auto' }}>
            <Ic name="check" size="xs" color="var(--memox-on-primary)" />
            Done
          </button>
        </div>
        <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', textAlign: 'center', opacity: 0.7 }}>
          {loading ? 'Loading your summary…' : 'Done returns you to the deck.'}
        </div>
      </div>
    </div>);
}

Object.assign(window, { StudyResultScreenV3 });
})();
