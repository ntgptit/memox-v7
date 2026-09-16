/* StudyHome · state: noCards — root decks exist but none holds a card — the library is the way forward; no starter prompt, no made-up numbers (A15). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.StudyHome = R.StudyHome || {});
D.noCards = (ctx) => {
  const { Ic, EmptyState } = ctx;
  return (
    <EmptyState icon="copy" title="Your decks have no cards yet"
      body="Add cards to a sub-deck, or import them from a file, and they will show up here."
      action={<button className="pill-btn primary" style={{ fontSize: 14 }}><Ic name="layers" size="xs" color="var(--memox-on-primary)" />Go to Library</button>} />);
};
})();
