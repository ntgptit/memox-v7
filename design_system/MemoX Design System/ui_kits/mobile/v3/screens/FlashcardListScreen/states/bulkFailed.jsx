/* FlashcardList · state: bulkFailed — a bulk action failed as a whole (all-or-nothing, BR-166); the selection is kept and the failure named (BR-232). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.bulkFailed = function (ctx) {
  const { Snackbar, CardList } = ctx;
  return { body: CardList(true, [2, 3]), overlay: <Snackbar action="Retry" style={{ bottom: 'calc(72px + env(safe-area-inset-bottom, 0px))' }}>Couldn’t move 2 cards. Nothing was changed.</Snackbar> };
};
})();
