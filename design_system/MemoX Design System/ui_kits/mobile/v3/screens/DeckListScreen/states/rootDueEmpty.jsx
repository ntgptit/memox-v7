/* LibraryOverview · state: dueEmpty — filter "due only" is on and no deck has due cards. Normal, not an error (BR-29). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootDueEmpty = function (ctx) {
  const { Ic } = ctx;
  const { EmptyState } = window;
  const body = (
    <EmptyState compact icon="check-circle-2" title="Nothing due right now"
      body="No deck has cards waiting. The next card becomes due tomorrow at 00:00."
      action={<button className="pill-btn" style={{ fontSize: 14, background: 'color-mix(in srgb, var(--memox-primary) 8%, transparent)', color: 'var(--memox-primary)', border: 'none' }}>Show all decks</button>} />);
  return { body };
};
})();
