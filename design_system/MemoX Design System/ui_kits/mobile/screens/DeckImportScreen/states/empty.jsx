/* DeckImport · state: empty — no source picked yet (Step 1). Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.empty = function () { return { kind: 'flow', fileChosen: false, parsing: false, preview: null, importing: false }; };
})();
