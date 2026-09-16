/* DeckDetail · state: notFound — the deck was moved to Trash from another area while open (A1 "deck not found"). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckNotFound = function (ctx) {
  const { Ic } = ctx;
  const { EmptyState } = window;
  const body = (
    <EmptyState icon="search-x" title="This deck is no longer here"
      body="It was moved to Trash or deleted while you were away. Anything in Trash can still be restored."
      action={
        <div style={{ display: 'flex', gap: 8, justifyContent: 'center' }}>
          <button className="pill-btn primary" style={{ fontSize: 14 }}>Back to Library</button>
          <button className="pill-btn outline" style={{ fontSize: 14 }}>Open Trash</button>
        </div>} />);
  return { body };
};
})();
