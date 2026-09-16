/* FlashcardList · state: selection — multi-select: touching a card toggles it (BR-246); "Select all 420" covers the whole matching set (BR-167); the bulk bar sits in-flow at the bottom. ADDED in v3 (replaces reorder). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardList = R.FlashcardList || {});
D.selection = function (ctx) { return { body: ctx.CardList(true, [2, 3]) }; };
})();
