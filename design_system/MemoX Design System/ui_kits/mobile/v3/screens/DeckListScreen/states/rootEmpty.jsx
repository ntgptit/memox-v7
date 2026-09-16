/* LibraryOverview · state: empty — first launch: no decks at all (A1). Create a deck or copy a starter deck. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootEmpty = function (ctx) { return { body: ctx.EmptyCard() }; };
})();
