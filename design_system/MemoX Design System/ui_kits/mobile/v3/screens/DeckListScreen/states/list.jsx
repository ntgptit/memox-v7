/* DeckList · the states that are just the list — identical at both levels. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
const list = function (ctx) { return { body: ctx.DeckList() }; };
const loading = function (ctx) { return { body: ctx.LoadingList() }; };
D.rootLoaded = list;
D.rootSearch = list;
D.deckLoaded = list;
D.rootLoading = loading;
D.deckLoading = loading;
})();
