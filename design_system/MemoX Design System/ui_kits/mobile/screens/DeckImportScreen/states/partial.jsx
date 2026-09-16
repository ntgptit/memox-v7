/* DeckImport · state: partial — partial success, some rows skipped (terminal). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.partial = function () { return { kind: 'result', result: 'partial' }; };
})();
