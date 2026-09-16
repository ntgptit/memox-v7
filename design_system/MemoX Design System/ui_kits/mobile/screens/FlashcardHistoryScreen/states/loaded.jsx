/* FlashcardHistory · state: loaded — full timeline with end marker. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.FlashcardHistory = R.FlashcardHistory || {});
D.loaded = function (ctx) { return ctx.Timeline(ctx.events, true); };
})();
