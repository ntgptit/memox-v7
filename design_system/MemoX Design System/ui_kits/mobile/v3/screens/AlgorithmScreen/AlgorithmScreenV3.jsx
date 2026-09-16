/* MemoX Mobile v3 — AlgorithmScreenV3  (A5 · Review algorithm and reset, root deck)  ADDED in v3
   v1 language: drill-down bar · breadcrumb · OptionRow list · Note · Dialog.
   Rules: the root owns the algorithm (BR-06); unlocked until the first card of the
   cycle finishes learning, then locked (BR-13); choosing the current algorithm
   changes nothing (BR-12); a change while unlocked closes any open session;
   Reset states what is kept and what is lost (BR-50), increments the cycle
   (generation) and, when nothing was studied, says there is nothing to lose;
   Reset is never suggested as a way to unlock a study mode (BR-100).
   States: unlocked · locked · switching · switched · switchFailed · resetConfirm · resetting · resetDone · nothingToLose */
(function () {
const { StatusBar, Ic, Breadcrumb, OptionRow, Note, Dialog, Snackbar, Spinner } = window;

const ALGOS = [
  { id: 'eight_box', t: 'Eight boxes', s: 'Remembered → one box up (1 · 2 · 4 · 8 · 16 · 32 · 64 · 128 days). Forgotten → back to box 1. Forgiving of long breaks. Review modes: match, guess, recall, fill.' },
  { id: 'sm2', t: 'SM-2', s: 'Intervals adapt to how well you recall each card; you grade yourself again · hard · good · easy. One review mode: self-assess.' }
];

function AlgorithmScreenV3({ go, state = 'locked' }) {
  const unlocked = ['unlocked', 'switching', 'switched', 'switchFailed'].includes(state);
  const nothing = state === 'nothingToLose';
  const current = state === 'switched' ? 'eight_box' : 'sm2';
  const resetOpen = ['resetConfirm', 'resetting', 'nothingToLose'].includes(state);
  return (
    <div className="app" style={{ position: 'relative' }}>
      <StatusBar />
      <div className="appbar" style={{ justifyContent: 'space-between' }}>
        <button className="icon-btn" onClick={() => go('deck')} aria-label="Back"><Ic name="arrow-left" size="md" /></button>
        <div className="title" style={{ fontSize: 16, fontWeight: 700, flex: 1, textAlign: 'left', marginLeft: 4 }}>Review algorithm</div>
      </div>
      <Breadcrumb segments={[{ label: 'Library' }, { label: '한국어 TOPIK I · Từ vựng' }, { label: 'Review algorithm' }]} />
      <div className="scroll">
        {/* Status strip — lock named in text, not colour alone */}
        <div className="card" style={{ padding: '12px 16px', marginBottom: 16, display: 'grid', gridTemplateColumns: '36px 1fr auto', gap: 12, alignItems: 'center', background: unlocked ? 'var(--memox-surface-hero)' : 'var(--memox-warning-soft)' }}>
          <div style={{ width: 36, height: 36, borderRadius: 'var(--memox-radius-md)', background: unlocked ? 'var(--memox-primary)' : 'var(--memox-warning)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Ic name={unlocked ? 'unlock' : 'lock'} size="sm" color={unlocked ? 'var(--memox-on-primary)' : 'var(--memox-on-warning)'} />
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 700 }}>{unlocked ? 'Can still be changed' : 'Locked · cycle 1'}</div>
            <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', marginTop: 2, lineHeight: 1.45 }}>{unlocked ? 'Locks once the first card finishes learning.' : 'The first card finished learning on 15 Oct 2025. Only a reset opens a new cycle.'}</div>
          </div>
        </div>

        <div className="ov" style={{ padding: '0 4px 8px' }}>Algorithm</div>
        <div className="card" style={{ padding: 0, overflow: 'hidden', marginBottom: 8, opacity: unlocked ? 1 : 0.7 }}>
          {ALGOS.map((a, i) => <OptionRow key={a.id} title={a.t} sub={a.s} selected={current === a.id} disabled={!unlocked || state === 'switching'} last={i === ALGOS.length - 1} trailing={state === 'switching' && a.id === 'eight_box' ? <Spinner size="xs" /> : null} />)}
        </div>
        {unlocked ?
          <Note style={{ marginBottom: 16 }}>Switching re-initialises every card's schedule in this tree and closes any open study session. Choosing the current algorithm changes nothing.</Note> :
          <Note icon="lock" style={{ marginBottom: 16 }}>To change the algorithm now, reset learning progress below and choose the algorithm for the new cycle.</Note>}
        {state === 'switchFailed' &&
          <div style={{ padding: '12px 16px', background: 'var(--memox-danger-soft)', border: '1px solid var(--memox-danger-border)', borderRadius: 'var(--memox-radius-md)', display: 'flex', gap: 8, alignItems: 'center', marginBottom: 16, fontSize: 12, lineHeight: 1.5 }}>
            <Ic name="alert-circle" size="xs" color="var(--memox-error)" />
            <span style={{ flex: 1 }}><strong style={{ fontWeight: 700 }}>Couldn’t switch.</strong> <span style={{ color: 'var(--memox-on-surface-variant)' }}>The deck still uses SM-2.</span></span>
            <button className="pill-btn primary" style={{ height: 32, padding: '0 12px', borderRadius: 'var(--memox-radius-sm)', fontSize: 12 }}>Retry</button>
          </div>}

        <div className="ov" style={{ padding: '0 4px 8px' }}>Start over</div>
        <div className="card" style={{ padding: 16, marginBottom: 16 }}>
          <div style={{ fontSize: 14, fontWeight: 600, marginBottom: 4 }}>Reset learning progress</div>
          <div style={{ fontSize: 12, color: 'var(--memox-on-surface-variant)', lineHeight: 1.5, marginBottom: 12 }}>Every card in this tree becomes new and a new cycle begins. You choose the algorithm for it. Decks, cards, tags and past history are kept.</div>
          <button className="pill-btn outline" style={{ height: 'var(--memox-size-button)', padding: '0 16px', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8 }}><Ic name="rotate-ccw" size="xs" color="var(--memox-on-surface)" />Reset learning progress…</button>
        </div>
      </div>

      {resetOpen &&
        <Dialog>
          <div style={{ padding: '20px 20px 4px' }}>
            <div style={{ fontSize: 16, fontWeight: 700, letterSpacing: '-0.2px', marginBottom: 4 }}>Reset learning progress?</div>
            <div style={{ fontSize: 14, color: 'var(--memox-on-surface-variant)', lineHeight: 1.55 }}>{nothing ? 'Nothing has been studied in this cycle yet, so there is nothing to lose. A new cycle starts with the algorithm you pick.' : 'This starts cycle 2 for 한국어 TOPIK I · Từ vựng and its 1,248 cards.'}</div>
          </div>
          {!nothing &&
            <div style={{ padding: '12px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              <div style={{ padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', background: 'color-mix(in srgb, var(--memox-mastery) 8%, transparent)', border: '1px solid color-mix(in srgb, var(--memox-mastery) 20%, transparent)', fontSize: 12, lineHeight: 1.5 }}>
                <div style={{ fontWeight: 700, color: 'var(--memox-mastery)', marginBottom: 2 }}>Kept</div>Decks, sub-decks, cards, tags, notes, and every past answer (labelled cycle 1)
              </div>
              <div style={{ padding: '10px 12px', borderRadius: 'var(--memox-radius-md)', background: 'var(--memox-warning-soft)', border: '1px solid var(--memox-warning-border)', fontSize: 12, lineHeight: 1.5 }}>
                <div style={{ fontWeight: 700, color: 'var(--memox-warning-ink)', marginBottom: 2 }}>Lost</div>Every card's schedule, due date and progress; the open session. All 1,248 cards become new
              </div>
            </div>}
          <div style={{ padding: '12px 20px 4px' }}>
            <div className="ov" style={{ marginBottom: 4 }}>Algorithm for the new cycle</div>
            <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
              <OptionRow title="Keep SM-2" selected />
              <OptionRow title="Switch to Eight boxes" last />
            </div>
          </div>
          <div style={{ padding: '16px 16px 16px', display: 'flex', gap: 8 }}>
            <button className="pill-btn outline" style={{ flex: 1, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14 }}>Cancel</button>
            <button className="pill-btn primary" disabled={state === 'resetting'} style={{ flex: 1.3, height: 'var(--memox-size-button)', borderRadius: 'var(--memox-radius-md)', fontSize: 14, gap: 8 }}>{state === 'resetting' ? <><Spinner color="var(--memox-on-primary)" size="xs" />Resetting…</> : <><Ic name="rotate-ccw" size="xs" color="var(--memox-on-primary)" />Reset and start cycle 2</>}</button>
          </div>
        </Dialog>}
      {state === 'switched' && <Snackbar>Switched to Eight boxes · every card starts fresh</Snackbar>}
      {state === 'resetDone' && <Snackbar>Cycle 2 started · 1,248 cards are new again</Snackbar>}
    </div>);
}

Object.assign(window, { AlgorithmScreenV3 });
})();
