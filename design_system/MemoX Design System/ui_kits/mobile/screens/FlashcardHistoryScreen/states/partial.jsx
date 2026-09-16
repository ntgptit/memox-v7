/* FlashcardHistory · state: partial — events with missing fields degrade
   gracefully; no end marker. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardHistory = R.FlashcardHistory || {});
D.partial = function (ctx) { return ctx.Timeline(ctx.partialEvents, false); };
})();
