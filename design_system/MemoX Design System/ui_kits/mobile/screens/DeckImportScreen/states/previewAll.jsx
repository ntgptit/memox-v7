/* DeckImport · state: previewAll — preview with every row valid. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.previewAll = function () { return { kind: 'flow', fileChosen: true, parsing: false, preview: 'all', importing: false }; };
})();
