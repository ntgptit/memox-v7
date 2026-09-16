/* TagManagement · state: busy — an operation is running on one tag row (spinner). */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});
D.busy = function (ctx) { return { body: ctx.TagList(true) }; };
})();
