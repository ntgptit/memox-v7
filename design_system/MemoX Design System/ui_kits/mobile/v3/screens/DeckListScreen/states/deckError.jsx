/* DeckDetail · state: error — read failed, retry (v1). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.deckError = function (ctx) {
  const { ErrorState } = window;
  return { body: <ErrorState title="Couldn't open this deck" body="Your data is safe on this device. Try again in a moment." /> };
};
})();
