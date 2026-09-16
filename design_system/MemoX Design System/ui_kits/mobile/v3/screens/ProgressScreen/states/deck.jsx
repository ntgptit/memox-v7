/* Progress · state: deck — inside a deck: its direct children with the same four numbers (A21). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.Progress = R.Progress || {});
D.deck = () => ({ range: 'week', deckLevel: true });
})();
