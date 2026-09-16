/* DeckImport · state: rejects — target became a deck holding sub-decks between preview and import (BR-168). ADDED in v3. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckImport = R.DeckImport || {});
D.rejects = () => ({ kind: 'result', result: 'rejects' });
})();
