/* FlashcardList · state: notFound — the deck was moved to Trash from another area while its card list was open (A8). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.notFound = function (ctx) {
  const { EmptyState } = window;
  return { body: <EmptyState icon="search-x" title="This deck is no longer here" body="It was moved to Trash while you were away. Its cards can still be restored from Trash." action={<button className="pill-btn primary" style={{ fontSize: 14 }}>Back to Library</button>} /> };
};
})();
