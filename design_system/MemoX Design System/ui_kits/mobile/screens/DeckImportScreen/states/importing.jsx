/* DeckImport · state: importing — commit in progress (Step 3). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.importing = function () { return { kind: 'flow', fileChosen: true, parsing: false, preview: null, importing: true }; };
})();
