/* DeckImport · state: fileSelected — file chosen, awaiting Preview. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.fileSelected = function () { return { kind: 'flow', fileChosen: true, parsing: false, preview: null, importing: false }; };
})();
