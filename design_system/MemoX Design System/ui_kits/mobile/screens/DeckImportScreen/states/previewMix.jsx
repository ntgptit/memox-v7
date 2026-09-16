/* DeckImport · state: previewMix — preview with mixed valid / invalid / duplicate rows. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.previewMix = function () { return { kind: 'flow', fileChosen: true, parsing: false, preview: 'mix', importing: false }; };
})();
