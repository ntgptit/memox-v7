const { MxContentShell, MxIconButton, MxCard, MxIcon, MxActionButton, MxEmptyState, MxProgressBar } = window.MemoxDesignSystem_3a620f;

const SESSION_LENGTH = 20;

/**
 * The review session. Redesign: the session's own progress is now the first
 * thing on the screen and it is a bar, not a fraction — "3 of 20" tells you
 * where you are only after you divide, and the thing that keeps somebody going
 * is seeing the remaining distance shrink.
 *
 * The answer is hidden until the card is turned. Showing it beside the prompt
 * made the verdict buttons a self-assessment of something already read.
 */
function ReviewScreen({ onClose, deckName, isCompact }) {
  const [index, setIndex] = React.useState(0);
  const [turned, setTurned] = React.useState(false);
  const [tally, setTally] = React.useState({ kept: 0, lost: 0 });

  const cards = window.MEMOX_CARDS;
  const card = cards[index % cards.length];
  const done = index >= SESSION_LENGTH;

  function answer(remembered) {
    setTally((t) => ({ kept: t.kept + (remembered ? 1 : 0), lost: t.lost + (remembered ? 0 : 1) }));
    setTurned(false);
    setIndex((i) => i + 1);
  }

  return (
    <MxContentShell
      title={deckName || 'Review'}
      leading={<MxIconButton icon="close" filled semanticLabel="End session" onClick={onClose} />}
      isCompact={isCompact}
    >
      {done ? <SessionComplete tally={tally} onClose={onClose} /> : (
        <div style={{ height: '100%', display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
          <MxProgressBar value={index / SESSION_LENGTH} label={'Card ' + (index + 1) + ' of ' + SESSION_LENGTH} valueLabel={SESSION_LENGTH - index + ' left'} />

          {/* The card takes every pixel the screen is not using for the progress
              bar and the answer controls. It is the reason the screen exists;
              floating it at the top as a small tile says the opposite. */}
          <MxCard padding="var(--space-xl)" elevation="raised" style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
            <div style={{ fontFamily: 'var(--font-display)', fontSize: isCompact ? 'var(--text-card-prompt-compact)' : 'var(--text-card-prompt)', lineHeight: 'var(--leading-card-prompt)', letterSpacing: 'var(--tracking-card-prompt)', fontWeight: 700 }}>{card.front}</div>
            {turned ? (
              <div style={{ marginTop: 'var(--space-lg)', paddingTop: 'var(--space-lg)', borderTop: '1px solid var(--color-border-subtle)' }}>
                <div style={{ fontSize: 'var(--text-body-lg)', lineHeight: 'var(--leading-body-lg)' }}>{card.part}</div>
                <div style={{ fontSize: 'var(--text-body-md)', lineHeight: 'var(--leading-body-md)', color: 'var(--color-text-secondary)', marginTop: 'var(--space-md)' }}>{card.example}</div>
              </div>
            ) : (
              <div style={{ flex: 1, display: 'flex', alignItems: 'flex-end', fontSize: 'var(--text-body-sm)', color: 'var(--color-text-secondary)' }}>Answer hidden — turn the card when you have committed to one.</div>
            )}
          </MxCard>

          {/* Pinned: the answer controls never move between cards, so the user
              can settle into answering without re-finding the buttons. */}
          <div style={{ flex: 'none', display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
            {turned ? (
              <div style={{ display: 'flex', gap: 'var(--space-md)' }}>
                <VerdictAction label="Forgotten" icon="replay" tint="var(--color-danger)" onClick={() => answer(false)} />
                <VerdictAction label="Remembered" icon="done" tint="var(--color-success)" onClick={() => answer(true)} />
              </div>
            ) : (
              <MxActionButton label="Show answer" isBlock onClick={() => setTurned(true)} />
            )}
            <SessionTally tally={tally} />
          </div>
        </div>
      )}
    </MxContentShell>
  );
}

/**
 * Idle is a neutral tile with a semantic border and a semantic label; the fill
 * stays neutral even on press, because a tint of the verdict's own hue eats the
 * label's contrast at exactly the moment the label matters.
 */
function VerdictAction({ label, icon, tint, onClick }) {
  return (
    <button type="button" onClick={onClick}
      style={{ flex: 1, minHeight: 56, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 'var(--space-sm)', cursor: 'pointer',
        background: 'var(--color-surface)', borderRadius: 'var(--radius-md)', border: '1.5px solid ' + tint, color: tint,
        fontFamily: 'var(--font-body)', fontSize: 'var(--text-label-lg)', letterSpacing: 'var(--tracking-label-lg)', fontWeight: 600,
        transition: 'background-color var(--duration-fast) var(--ease-standard)' }}>
      <MxIcon name={icon} filled size="var(--icon-sm)" />{label}
    </button>
  );
}

/** Quiet, and below the fold of the decision — a running score during a review is a distraction, but its absence afterwards is a loss. */
function SessionTally({ tally }) {
  if (tally.kept + tally.lost === 0) return null;
  return (
    <div style={{ display: 'flex', gap: 'var(--space-lg)', fontSize: 'var(--text-body-sm)', color: 'var(--color-text-secondary)' }}>
      <span><b style={{ color: 'var(--color-success)' }}>{tally.kept}</b> remembered</span>
      <span><b style={{ color: 'var(--color-danger)' }}>{tally.lost}</b> to revisit</span>
    </div>
  );
}

function SessionComplete({ tally, onClose }) {
  const total = tally.kept + tally.lost || 1;
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
      <div style={{ flex: 1, minHeight: 0 }}>
        <MxEmptyState title="Session complete" message={tally.kept + ' of ' + total + ' remembered. Nothing else is due in this deck today.'} />
      </div>
      <MxProgressBar value={tally.kept / total} label="Recall this session" valueLabel={Math.round((tally.kept / total) * 100) + '%'} />
      <MxActionButton label="Back to decks" isBlock onClick={onClose} />
    </div>
  );
}

Object.assign(window, { ReviewScreen, VerdictAction, SessionTally, SessionComplete });
