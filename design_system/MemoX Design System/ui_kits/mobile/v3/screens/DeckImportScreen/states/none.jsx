/* DeckImport · state: none — every row was a duplicate: nothing added, deck unchanged (noCardsAdded). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.none = () => ({ kind: 'result', result: 'none' });
})();
