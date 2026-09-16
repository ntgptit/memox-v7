/* LibraryOverview · state: empty — first-time user, no folders yet. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.LibraryOverview = R.LibraryOverview || {});
D.empty = function (ctx) { return { body: ctx.EmptyCard() }; };
})();
