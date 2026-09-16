/* DeckImport · state: failed — import failed, nothing added (terminal). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.failed = function () { return { kind: 'result', result: 'failed' }; };
})();
