/* FlashcardList · state: trashed — one card moved to Trash: the list updates live, the snackbar offers Undo (BR-263). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.trashed = function (ctx) {
  const { Snackbar, cards, CardRow } = ctx;
  const body = <>{cards.filter((c) => c.front !== '먹다').map((c) => <CardRow key={c.front} c={c} />)}</>;
  return { body, overlay: <Snackbar action="Undo">“먹다” moved to Trash</Snackbar> };
};
})();
