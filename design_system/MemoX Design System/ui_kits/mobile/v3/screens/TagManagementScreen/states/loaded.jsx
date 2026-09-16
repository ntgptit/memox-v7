/* TagManagement · state: loaded — normal tag list. Default. */
(function () {
const R = (window.MemoXStates = window.MemoXStates || {});
const D = (R.TagManagement = R.TagManagement || {});
D.loaded = function (ctx) { return { body: ctx.TagList(false) }; };
})();
