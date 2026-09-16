/* LibraryOverview · state: error — load failed, retry CTA. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.DeckList = R.DeckList || {});
D.rootError = function (ctx) { return { body: ctx.ErrorCard() }; };
})();
