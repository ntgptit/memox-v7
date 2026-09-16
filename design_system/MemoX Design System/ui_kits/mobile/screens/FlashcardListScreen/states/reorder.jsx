/* FlashcardList · state: reorder — manual sort, drag handles visible.
   (Shell re-titles the app bar and count row from the `reorder` flag.) */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.reorder = function (ctx) { return { body: ctx.CardList(true) }; };
})();
