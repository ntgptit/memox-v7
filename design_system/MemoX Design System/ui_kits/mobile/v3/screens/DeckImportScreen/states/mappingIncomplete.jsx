/* DeckImport · state: mappingIncomplete — meaning not mapped — both front and back are required (BR-169). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.mappingIncomplete = () => ({ kind: 'flow', fileChosen: true, mapping: true, mappingIncomplete: true });
})();
