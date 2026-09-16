/* DeckImport · state: parsing — parser running over the file. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.parsing = function () { return { kind: 'flow', fileChosen: true, parsing: true, preview: null, importing: false }; };
})();
