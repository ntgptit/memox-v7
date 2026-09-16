/* FlashcardList · state: loaded — populated deck card list. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.loaded = function (ctx) { return { body: ctx.CardList(false) }; };
})();
