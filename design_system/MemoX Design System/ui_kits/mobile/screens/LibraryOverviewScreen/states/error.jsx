/* LibraryOverview · state: error — load failed, retry CTA. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});
D.error = function (ctx) { return { body: ctx.ErrorCard() }; };
})();
