/* DeckImport · state: success — import success summary (terminal). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.success = function () { return { kind: 'result', result: 'success' }; };
})();
