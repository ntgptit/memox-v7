/* StudyHome · state: noDecks — no root decks at all — the starter library is the way forward (A15). Replaces v1 onboarding. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyHome = R.StudyHome || {});
D.noDecks = (ctx) => {
  const { Ic, EmptyState } = ctx;
  return (
    <EmptyState icon="sparkles" title="Nothing to study yet"
      body="Your library is empty. Copy a starter deck to begin with content, or create a deck in Library."
      action={
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          <button className="pill-btn primary" style={{ fontSize: 14, width: '100%' }}><Ic name="sparkles" size="xs" color="var(--memox-on-primary)" />Browse starter decks</button>
          <button className="pill-btn" style={{ fontSize: 14, width: '100%', background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>Go to Library</button>
        </div>} />);
};
})();
